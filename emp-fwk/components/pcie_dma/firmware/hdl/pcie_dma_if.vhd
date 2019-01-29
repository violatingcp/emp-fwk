----------------------------------------------------------------------------------
-- Module encapsulating Xilinx xdma core and interface to native dual BRAM
-- Raghunandan Shukla, TIFR
--

----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


use work.pcie_decl.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pcie_dma_if is
  generic(
    C_M_AXI_ID_WIDTH: natural := 4;
    C_S_AXI_DATA_WIDTH : natural := C_AXI_DATA_WIDTH;
    C_M_AXI_DATA_WIDTH : natural := C_AXI_DATA_WIDTH;
    C_S_AXI_ADDR_WIDTH : natural := 64;
    C_M_AXI_ADDR_WIDTH : natural := 64;
    C_NUM_USR_IRQ : natural := 1
  );
  port (
    pci_exp_txp: out std_logic_vector (C_PCIE_LANES - 1 downto 0 );
    pci_exp_txn: out std_logic_vector (C_PCIE_LANES - 1 downto 0 );
    pci_exp_rxp: in std_logic_vector (C_PCIE_LANES - 1 downto 0 );
    pci_exp_rxn: in std_logic_vector (C_PCIE_LANES - 1 downto 0 );

    -- clk and reset
    sys_clk    : in std_logic;
    sys_clk_gt : in std_logic;
    user_clk_o   : out std_logic;
    sys_rst_n_c: in std_logic;

    -- Native RAM interface

    ram_wr_addr: out std_logic_vector( 10 downto 0 );
    ram_wr_data: out std_logic_vector( C_M_AXI_DATA_WIDTH - 1 downto 0 );
    ram_wr_en  : out std_logic;
    ram_wr_we  : out std_logic;

    ram_rd_en:  out std_logic;
    ram_rd_addr: out std_logic_vector( 10 downto 0 );
    ram_rd_data: in std_logic_vector( C_M_AXI_DATA_WIDTH - 1 downto 0 );

    -- descriptor status
    h2c0_dsc_done: out std_logic;
    -- User interrupts
    pcie_int_event0: in std_logic
  );
end pcie_dma_if;

architecture rtl of pcie_dma_if is
  -- signals

  signal user_lnk_up: std_logic;
  signal user_resetn: std_logic;

  signal usr_irq_req: std_logic_vector ( C_NUM_USR_IRQ - 1 downto 0 );  -- pass to the upper module
  signal usr_irq_ack: std_logic_vector ( C_NUM_USR_IRQ - 1 downto 0 );  -- pass to the upper module

  -- AXI Master Write Address Channel
  signal m_axi_awaddr: std_logic_vector ( C_M_AXI_ADDR_WIDTH - 1 downto 0 );
  signal m_axi_awid: std_logic_vector ( C_M_AXI_ID_WIDTH - 1 downto 0 );
  signal m_axi_awprot: std_logic_vector ( 2 downto 0 ) ;
  signal m_axi_awburst: std_logic_vector ( 1 downto 0 );
  signal m_axi_awsize: std_logic_vector ( 2 downto 0 ) ;
  signal m_axi_awcache: std_logic_vector ( 3 downto 0 ) ;
  signal m_axi_awlen: std_logic_vector ( 7 downto 0 ) ;
  signal m_axi_awlock: std_logic;
  signal m_axi_awvalid: std_logic;
  signal m_axi_awready: std_logic;

  -- AXI Master Write Data Channel
  signal m_axi_wdata: std_logic_vector ( C_M_AXI_DATA_WIDTH - 1downto 0 );
  signal m_axi_wstrb: std_logic_vector ( ( C_M_AXI_DATA_WIDTH / 8 ) - 1 downto 0 );
  signal m_axi_wlast: std_logic;
  signal m_axi_wvalid: std_logic;
  signal m_axi_wready: std_logic;
  -- AXI Master Write Response Channel
  signal m_axi_bvalid: std_logic;
  signal m_axi_bready: std_logic;
  signal m_axi_bid : std_logic_vector ( C_M_AXI_ID_WIDTH - 1  downto 0 ) ;
  signal m_axi_bresp: std_logic_vector ( 1 downto 0 ) ;

  -- AXI Master Read Address Channel
  signal m_axi_arid: std_logic_vector ( C_M_AXI_ID_WIDTH - 1  downto 0 );
  signal m_axi_araddr: std_logic_vector ( C_M_AXI_ADDR_WIDTH - 1 downto 0 );
  signal m_axi_arlen: std_logic_vector ( 7 downto 0 );
  signal m_axi_arsize: std_logic_vector ( 2 downto 0 );
  signal m_axi_arburst: std_logic_vector ( 1 downto 0 ) ;
  signal m_axi_arprot: std_logic_vector ( 2 downto 0 );
  signal m_axi_arvalid: std_logic;
  signal m_axi_arready: std_logic;
  signal m_axi_arlock: std_logic;
  signal m_axi_arcache: std_logic_vector ( 3 downto 0 ) ;

  -- AXI Master Read Data Channel
  signal m_axi_rid: std_logic_vector ( C_M_AXI_ID_WIDTH - 1  downto 0 ) ;
  signal m_axi_rdata: std_logic_vector ( C_M_AXI_DATA_WIDTH - 1 downto 0 );
  signal m_axi_rresp: std_logic_vector ( 1 downto 0 ) ;
  signal m_axi_rvalid: std_logic;
  signal m_axi_rready: std_logic;
  signal m_axi_rlast: std_logic;

  -- AXI LITE
  -- AXI Master Write Address Channel
  signal m_axil_awaddr: std_logic_vector ( 31 downto 0 ) ;
  signal m_axil_awprot: std_logic_vector ( 2 downto 0 ) ;
  signal m_axil_awvalid: std_logic;
  signal m_axil_awready: std_logic;

  -- AXI Master Write Data Channel
  signal m_axil_wdata: std_logic_vector ( 31 downto 0 ) ;
  signal m_axil_wstrb: std_logic_vector ( 3 downto 0 ) ;
  signal m_axil_wvalid: std_logic;
  signal m_axil_wready: std_logic;
  -- AXI Master Write Response Channel
  signal m_axil_bvalid: std_logic;
  signal m_axil_bready: std_logic;
  -- AXI Master Read Address Channel
  signal  m_axil_araddr: std_logic_vector ( 31 downto 0 );
  signal m_axil_arprot: std_logic_vector ( 2 downto 0 ) ;
  signal m_axil_arvalid: std_logic;
  signal m_axil_arready: std_logic;
  -- AXI Master Read Data Channel
  signal m_axil_rdata: std_logic_vector ( 31 downto 0 );
  signal m_axil_rresp: std_logic_vector ( 1 downto 0 );
  signal m_axil_rvalid: std_logic;
  signal m_axil_rready: std_logic;
  signal m_axil_bresp: std_logic_vector ( 1 downto 0 );

  signal msi_vector_width: std_logic_vector ( 2 downto 0 );
  signal msi_enable: std_logic;


  signal cfg_ltssm_state: std_logic_vector ( 5 downto 0 ) ;

  signal c2h_sts_0: std_logic_vector ( 7 downto 0 ) ;
  signal h2c_sts_0: std_logic_vector ( 7 downto 0 ) ;

  signal bram_addr_a: std_logic_vector (12 downto 0) ;
  signal bram_addr_b: std_logic_vector (12 downto 0) ;
  signal clka, clkb: std_logic;

  signal user_clk: std_logic;
  signal ram_wr_we_o: std_logic_vector(7 downto 0);


  -- components

  COMPONENT xdma_0
    PORT (
      sys_clk : IN STD_LOGIC;
      sys_clk_gt : IN STD_LOGIC;
      sys_rst_n : IN STD_LOGIC;
      user_lnk_up : OUT STD_LOGIC;
      pci_exp_txp : OUT STD_LOGIC_VECTOR(C_PCIE_LANES - 1 DOWNTO 0);
      pci_exp_txn : OUT STD_LOGIC_VECTOR(C_PCIE_LANES - 1 DOWNTO 0);
      pci_exp_rxp : IN STD_LOGIC_VECTOR(C_PCIE_LANES - 1 DOWNTO 0);
      pci_exp_rxn : IN STD_LOGIC_VECTOR(C_PCIE_LANES - 1 DOWNTO 0);
      axi_aclk : OUT STD_LOGIC;
      axi_aresetn : OUT STD_LOGIC;
      usr_irq_req : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      usr_irq_ack : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      msi_enable : OUT STD_LOGIC;
      msi_vector_width : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_awready : IN STD_LOGIC;
      m_axi_wready : IN STD_LOGIC;
      m_axi_bid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_bvalid : IN STD_LOGIC;
      m_axi_arready : IN STD_LOGIC;
      m_axi_rid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_rdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      m_axi_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_rlast : IN STD_LOGIC;
      m_axi_rvalid : IN STD_LOGIC;
      m_axi_awid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_awaddr : OUT STD_LOGIC_VECTOR(C_M_AXI_DATA_WIDTH - 1 DOWNTO 0);
      m_axi_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axi_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_awvalid : OUT STD_LOGIC;
      m_axi_awlock : OUT STD_LOGIC;
      m_axi_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_wdata : OUT STD_LOGIC_VECTOR(C_M_AXI_DATA_WIDTH - 1 DOWNTO 0);
      m_axi_wstrb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axi_wlast : OUT STD_LOGIC;
      m_axi_wvalid : OUT STD_LOGIC;
      m_axi_bready : OUT STD_LOGIC;
      m_axi_arid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_araddr : OUT STD_LOGIC_VECTOR(C_M_AXI_DATA_WIDTH - 1 DOWNTO 0);
      m_axi_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axi_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_arvalid : OUT STD_LOGIC;
      m_axi_arlock : OUT STD_LOGIC;
      m_axi_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_rready : OUT STD_LOGIC;

      m_axil_awaddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axil_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axil_awvalid : OUT STD_LOGIC;
      m_axil_awready : IN STD_LOGIC;
      m_axil_wdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axil_wstrb : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axil_wvalid : OUT STD_LOGIC;
      m_axil_wready : IN STD_LOGIC;
      m_axil_bvalid : IN STD_LOGIC;
      m_axil_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axil_bready : OUT STD_LOGIC;
      m_axil_araddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axil_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axil_arvalid : OUT STD_LOGIC;
      m_axil_arready : IN STD_LOGIC;
      m_axil_rdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axil_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axil_rvalid : IN STD_LOGIC;
      m_axil_rready : OUT STD_LOGIC;
      cfg_mgmt_addr : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
      cfg_mgmt_write : IN STD_LOGIC;
      cfg_mgmt_write_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      cfg_mgmt_byte_enable : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      cfg_mgmt_read : IN STD_LOGIC;
      cfg_mgmt_read_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      cfg_mgmt_read_write_done : OUT STD_LOGIC;
      cfg_mgmt_type1_cfg_reg_access : IN STD_LOGIC;
      c2h_sts_0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      h2c_sts_0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      int_qpll1lock_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      int_qpll1outrefclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      int_qpll1outclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
  END COMPONENT;


  COMPONENT axi_bram_ctrl_0 IS
    PORT (
      s_axi_aclk : IN STD_LOGIC;
      s_axi_aresetn : IN STD_LOGIC;
      s_axi_awid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      s_axi_awaddr : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
      s_axi_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      s_axi_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      s_axi_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      s_axi_awlock : IN STD_LOGIC;
      s_axi_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      s_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      s_axi_awvalid : IN STD_LOGIC;
      s_axi_awready : OUT STD_LOGIC;
      s_axi_wdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      s_axi_wstrb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      s_axi_wlast : IN STD_LOGIC;
      s_axi_wvalid : IN STD_LOGIC;
      s_axi_wready : OUT STD_LOGIC;
      s_axi_bid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      s_axi_bvalid : OUT STD_LOGIC;
      s_axi_bready : IN STD_LOGIC;
      s_axi_arid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      s_axi_araddr : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
      s_axi_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      s_axi_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      s_axi_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      s_axi_arlock : IN STD_LOGIC;
      s_axi_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      s_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      s_axi_arvalid : IN STD_LOGIC;
      s_axi_arready : OUT STD_LOGIC;
      s_axi_rid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      s_axi_rdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      s_axi_rlast : OUT STD_LOGIC;
      s_axi_rvalid : OUT STD_LOGIC;
      s_axi_rready : IN STD_LOGIC;
      bram_rst_a : OUT STD_LOGIC;
      bram_clk_a : OUT STD_LOGIC;
      bram_en_a : OUT STD_LOGIC;
      bram_we_a : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      bram_addr_a : OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
      bram_wrdata_a : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      bram_rddata_a : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      bram_rst_b : OUT STD_LOGIC;
      bram_clk_b : OUT STD_LOGIC;
      bram_en_b : OUT STD_LOGIC;
      bram_we_b : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      bram_addr_b : OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
      bram_wrdata_b : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      bram_rddata_b : IN STD_LOGIC_VECTOR(63 DOWNTO 0)
    );
  END COMPONENT;


  COMPONENT blk_mem_gen_0 IS
    PORT (
      s_aclk : IN STD_LOGIC;
      s_aresetn : IN STD_LOGIC;
      s_axi_awaddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      s_axi_awvalid : IN STD_LOGIC;
      s_axi_awready : OUT STD_LOGIC;
      s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      s_axi_wvalid : IN STD_LOGIC;
      s_axi_wready : OUT STD_LOGIC;
      s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      s_axi_bvalid : OUT STD_LOGIC;
      s_axi_bready : IN STD_LOGIC;
      s_axi_araddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      s_axi_arvalid : IN STD_LOGIC;
      s_axi_arready : OUT STD_LOGIC;
      s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      s_axi_rvalid : OUT STD_LOGIC;
      s_axi_rready : IN STD_LOGIC
    );
  END COMPONENT;

begin

  user_clk_o <= user_clk;
  h2c0_dsc_done <= h2c_sts_0( 3 );

  xdma_0_i : xdma_0
    port map (
      sys_clk           => sys_clk,
      sys_clk_gt        => sys_clk_gt,
      sys_rst_n         => sys_rst_n_c,
      user_lnk_up       => user_lnk_up,
      pci_exp_txp       => pci_exp_txp,
      pci_exp_txn       => pci_exp_txn,
      pci_exp_rxp       => pci_exp_rxp,
      pci_exp_rxn       => pci_exp_rxn,
      axi_aclk          => user_clk,
      axi_aresetn       => user_resetn,
      usr_irq_req       => usr_irq_req,
      usr_irq_ack       => usr_irq_ack,
      msi_enable        => msi_enable,
      msi_vector_width  => msi_vector_width,
      m_axi_awready     => m_axi_awready,
      m_axi_wready      => m_axi_wready,
      m_axi_bid         => m_axi_bid,
      m_axi_bresp       => m_axi_bresp,
      m_axi_bvalid      => m_axi_bvalid,
      m_axi_arready     => m_axi_arready,
      m_axi_rid         => m_axi_rid,
      m_axi_rdata       => m_axi_rdata,
      m_axi_rresp       => m_axi_rresp,
      m_axi_rlast       => m_axi_rlast,
      m_axi_rvalid      => m_axi_rvalid,
      m_axi_awid        => m_axi_awid,
      m_axi_awaddr      => m_axi_awaddr,
      m_axi_awlen       => m_axi_awlen,
      m_axi_awsize      => m_axi_awsize,
      m_axi_awburst     => m_axi_awburst,
      m_axi_awprot      => m_axi_awprot,
      m_axi_awvalid     => m_axi_awvalid,
      m_axi_awlock      => m_axi_awlock,
      m_axi_awcache     => m_axi_awcache,
      m_axi_wdata       => m_axi_wdata,
      m_axi_wstrb       => m_axi_wstrb,
      m_axi_wlast       => m_axi_wlast,
      m_axi_wvalid      => m_axi_wvalid,
      m_axi_bready      => m_axi_bready,
      m_axi_arid        => m_axi_arid,
      m_axi_araddr      => m_axi_araddr,
      m_axi_arlen       => m_axi_arlen,
      m_axi_arsize      => m_axi_arsize,
      m_axi_arburst     => m_axi_arburst,
      m_axi_arprot      => m_axi_arprot,
      m_axi_arvalid     => m_axi_arvalid,
      m_axi_arlock      => m_axi_arlock,
      m_axi_arcache     => m_axi_arcache,
      m_axi_rready      => m_axi_rready,
      m_axil_awaddr     => m_axil_awaddr,
      m_axil_awprot     => m_axil_awprot,
      m_axil_awvalid    => m_axil_awvalid,
      m_axil_awready    => m_axil_awready,
      m_axil_wdata      => m_axil_wdata,
      m_axil_wstrb      => m_axil_wstrb,
      m_axil_wvalid     => m_axil_wvalid,
      m_axil_wready     => m_axil_wready,
      m_axil_bvalid     => m_axil_bvalid,
      m_axil_bresp      => m_axil_bresp,
      m_axil_bready     => m_axil_bready,
      m_axil_araddr     => m_axil_araddr,
      m_axil_arprot     => m_axil_arprot,
      m_axil_arvalid    => m_axil_arvalid,
      m_axil_arready    => m_axil_arready,
      m_axil_rdata      => m_axil_rdata,
      m_axil_rresp      => m_axil_rresp,
      m_axil_rvalid     => m_axil_rvalid,
      m_axil_rready     => m_axil_rready,
      -- CFG
      cfg_mgmt_addr        => "000" & X"0000",
      cfg_mgmt_write       => '0',
      cfg_mgmt_write_data  => X"00000000",
      cfg_mgmt_byte_enable => X"0",
      cfg_mgmt_read        => '0',
      cfg_mgmt_read_data   => open,
      cfg_mgmt_type1_cfg_reg_access => '0',

      c2h_sts_0            => c2h_sts_0,
      h2c_sts_0            => h2c_sts_0,

      int_qpll1lock_out      => open,
      int_qpll1outrefclk_out => open,
      int_qpll1outclk_out    => open
    );


  DP_BRAM_control: axi_bram_ctrl_0
    port map (
      s_axi_aclk       => user_clk,

      s_axi_aresetn    => user_resetn,
      s_axi_awid       => m_axi_awid,
      s_axi_awaddr     => m_axi_awaddr(12 downto 0),
      s_axi_awlen      => m_axi_awlen,
      s_axi_awsize     => m_axi_awsize,
      s_axi_awburst    => m_axi_awburst,

      s_axi_awlock     => m_axi_awlock,
      s_axi_awcache    => m_axi_awcache,
      s_axi_awprot     => m_axi_awprot,

      s_axi_awvalid    => m_axi_awvalid,
      s_axi_awready    => m_axi_awready,
      s_axi_wdata      => m_axi_wdata,
      s_axi_wstrb      => m_axi_wstrb,
      s_axi_wlast      => m_axi_wlast,
      s_axi_wvalid     => m_axi_wvalid,
      s_axi_wready     => m_axi_wready,
      s_axi_bid        => m_axi_bid,
      s_axi_bresp      => m_axi_bresp,
      s_axi_bvalid     => m_axi_bvalid,
      s_axi_bready     => m_axi_bready,
      s_axi_arid       => m_axi_arid,
      s_axi_araddr     => m_axi_araddr(12 downto 0),
      s_axi_arlen      => m_axi_arlen,
      s_axi_arsize     => m_axi_arsize,
      s_axi_arburst    => m_axi_arburst,

      s_axi_arlock     => m_axi_arlock,
      s_axi_arcache    => m_axi_arcache,
      s_axi_arprot     => m_axi_arprot,

      s_axi_arvalid    => m_axi_arvalid,
      s_axi_arready    => m_axi_arready,
      s_axi_rid        => m_axi_rid,
      s_axi_rdata      => m_axi_rdata,
      s_axi_rresp      => m_axi_rresp,
      s_axi_rlast      => m_axi_rlast,
      s_axi_rvalid     => m_axi_rvalid,
      s_axi_rready     => m_axi_rready,

      -- Native BRAM interface: true dual port RAM interface : need to tie to simple DP RAM
      -- clka = clkb = user_clk; thus can be left unconnected and just pass on user_clk.

      bram_rst_a       => open,
      bram_clk_a       => clka,
      bram_en_a        => ram_wr_en,
      bram_we_a        => ram_wr_we_o,
      bram_addr_a      => bram_addr_a,
      bram_wrdata_a    => ram_wr_data,
      bram_rddata_a    => X"0000000000000000",

      bram_rst_b       => open,
      bram_clk_b       => clkb,
      bram_en_b        => ram_rd_en,
      bram_we_b        => open,
      bram_addr_b      => bram_addr_b,
      bram_wrdata_b    => open,
      bram_rddata_b    => ram_rd_data
    );


  ram_wr_we <= ram_wr_we_o(0);

  ram_wr_addr <= '0' & bram_addr_a (12 downto 3);
  ram_rd_addr <= '0' & bram_addr_b (12 downto 3);


  blk_mem_axiLM_inst: blk_mem_gen_0
    port map (
      s_aclk         =>  user_clk,
      s_aresetn      =>  user_resetn,
      s_axi_awaddr   =>  m_axil_awaddr,
      s_axi_awvalid  =>  m_axil_awvalid,
      s_axi_awready  =>  m_axil_awready,
      s_axi_wdata    =>  m_axil_wdata,
      s_axi_wstrb    =>  m_axil_wstrb,
      s_axi_wvalid   =>  m_axil_wvalid,
      s_axi_wready   =>  m_axil_wready,
      s_axi_bresp    =>  m_axil_bresp,
      s_axi_bvalid   =>  m_axil_bvalid,
      s_axi_bready   =>  m_axil_bready,
      s_axi_araddr   =>  m_axil_araddr,
      s_axi_arvalid  =>  m_axil_arvalid,
      s_axi_arready  =>  m_axil_arready,
      s_axi_rdata    =>  m_axil_rdata,
      s_axi_rresp    =>  m_axil_rresp,
      s_axi_rvalid   =>  m_axil_rvalid,
      s_axi_rready   =>  m_axil_rready
    );

  irq_gen: entity work.pcie_int_gen_msix
    port map (
      pcie_usr_clk     => user_clk,
      pcie_sys_rst_n   => user_resetn,
      pcie_usr_int_req => usr_irq_req(0),
      pcie_usr_int_ack => usr_irq_ack(0),
      pcie_event0      => pcie_int_event0
    );


end rtl;
