-- ipbus_pcie_test_infra: Minimal clocks & control I/O module for Ultrascale+ IPbus PCIe test designs
--
-- Raghunandan Shukla (TIFR), Kristian Harder (RAL), Tom Williams (RAL)
-- based on code from Dave Newbold

library IEEE;
use IEEE.std_logic_1164.all;

use work.ipbus.all;
use work.ipbus_trans_decl.all;
use work.pcie_decl.all;

library UNISIM;
use UNISIM.VComponents.all;

entity ipbus_pcie_test_usp_infra is
  port (
      -- PCIe clock and reset (active low)
      pcie_sys_clk_p : in std_logic;
      pcie_sys_clk_n : in std_logic;
      pcie_sys_rst_n : in std_logic;
      -- PCIe lanes
      pcie_rxp : in std_logic_vector(C_PCIE_LANES-1 downto 0);
      pcie_rxn : in std_logic_vector(C_PCIE_LANES-1 downto 0);
      pcie_txp : out std_logic_vector(C_PCIE_LANES-1 downto 0);
      pcie_txn : out std_logic_vector(C_PCIE_LANES-1 downto 0);
      -- IPbus clock and reset
      ipb_clk : out std_logic;
      ipb_rst : out std_logic;
      -- IPbus (from / to slaves)
      ipb_in  : in ipb_rbus;
      ipb_out : out ipb_wbus
  );
end ipbus_pcie_test_usp_infra;


architecture rtl of ipbus_pcie_test_usp_infra is

  signal ipb_clk_i, ipb_rst_i : std_logic;

  signal usr_clk, sys_clk, sys_clk_gt : std_logic;
  signal pcie_sys_rst_n_c : std_logic;

  signal ram_wr_en, ram_wr_we, ram_rd_en : std_logic;
  signal ram_wr_addr, ram_rd_addr : std_logic_vector(10 downto 0);
  signal ram_wr_data, ram_rd_data : std_logic_vector(63 downto 0);
  signal h2c0_dsc_done : std_logic;

  signal ipb_req : std_logic;
  signal trans_in : ipbus_trans_in;
  signal trans_out : ipbus_trans_out;

  component buffer_trans_if
    port (
      user_clk : in std_logic;
      ipb_clk : in std_logic;
      sys_rst_n : in std_logic;

      h2c0_dsc_done : in std_logic;

      ram_wr_addr : in std_logic_vector(10 downto 0);
      ram_wr_data : in std_logic_vector(63 downto 0);
      ram_wr_en : in std_logic;
      ram_wr_we : in std_logic;

      ram_rd_en : in std_logic;
      ram_rd_addr : in std_logic_vector(10 downto 0);
      ram_rd_data : out std_logic_vector(63 downto 0);

      trans_in_pkt_rdy : out std_logic;
      trans_in_rdata : out std_logic_vector(31 downto 0);
      trans_in_busy : out std_logic;

      trans_out_raddr : in std_logic_vector(11 downto 0);
      trans_out_pkt_done : in std_logic;
      trans_out_we : in std_logic;
      trans_out_waddr : in std_logic_vector(11 downto 0);
      trans_out_wdata : in std_logic_vector(31 downto 0);

      ipb_req : in std_logic;
      ipb_rst : out std_logic
    );
  end component;

begin

  ipb_clk <= ipb_clk_i;
  ipb_rst <= ipb_rst_i;

  sys_rst_n_ibuf: IBUF
    port map (
      O => pcie_sys_rst_n_c,
      I => pcie_sys_rst_n
    );


  clocks: entity work.emp_clocks
    port map (
      sys_clk_p => pcie_sys_clk_p,
      sys_clk_n => pcie_sys_clk_n,
      user_clk => usr_clk,
      sys_clk => sys_clk,
      sys_clk_gt => sys_clk_gt,
      ipb_clk => ipb_clk_i,
      clk_40pseudo => open,
      onehz => open
    );


  dma: entity work.pcie_dma_if
    port map (
      pci_exp_txp => pcie_txp,
      pci_exp_txn => pcie_txn,
      pci_exp_rxp => pcie_rxp,
      pci_exp_rxn => pcie_rxn,

      sys_clk => sys_clk,
      sys_clk_gt => sys_clk_gt,
      user_clk_o => usr_clk,
      sys_rst_n_c => pcie_sys_rst_n_c,

      -- RAM interface
      ram_wr_addr => ram_wr_addr,
      ram_wr_data => ram_wr_data,
      ram_wr_en => ram_wr_en,
      ram_wr_we => ram_wr_we,

      ram_rd_en => ram_rd_en,
      ram_rd_addr => ram_rd_addr,
      ram_rd_data => ram_rd_data,

      h2c0_dsc_done => h2c0_dsc_done,
      pcie_int_event0 => trans_out.pkt_done
    );


  ram_to_trans_converter: buffer_trans_if
    port map (
      user_clk => usr_clk,
      ipb_clk => ipb_clk_i,
      sys_rst_n => pcie_sys_rst_n_c,

      h2c0_dsc_done => h2c0_dsc_done,

      ram_wr_addr => ram_wr_addr,
      ram_wr_data => ram_wr_data,
      ram_wr_en => ram_wr_en,
      ram_wr_we => ram_wr_we,

      ram_rd_en => ram_rd_en,
      ram_rd_addr => ram_rd_addr,
      ram_rd_data => ram_rd_data,

      trans_in_pkt_rdy => trans_in.pkt_rdy,
      trans_in_rdata => trans_in.rdata,
      trans_in_busy => trans_in.busy,

      trans_out_raddr => trans_out.raddr,
      trans_out_pkt_done => trans_out.pkt_done,
      trans_out_we => trans_out.we,
      trans_out_waddr => trans_out.waddr,
      trans_out_wdata => trans_out.wdata,

      ipb_req => ipb_req,
      ipb_rst => ipb_rst_i
    );


  ipbus_transactor: entity work.transactor
    port map (
      clk => ipb_clk_i,
      rst => ipb_rst_i,
      ipb_out => ipb_out,
      ipb_in => ipb_in,
      ipb_req => ipb_req, 
      ipb_grant => '1',
      trans_in => trans_in,
      trans_out => trans_out,
      cfg_vector_in => (Others => '0'),
      cfg_vector_out => open
    );

end rtl;
