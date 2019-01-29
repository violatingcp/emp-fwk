-- emp_ctrl
--
-- Genral control /status registers
-- 
-- 

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_emp_ctrl.all;

entity emp_ctrl is
  port(
    -- ipbus signals
    clk        : in  std_logic;
    rst        : in  std_logic;
    ipb_in     : in  ipb_wbus;
    ipb_out    : out ipb_rbus;
    debug      : in  std_logic_vector(7 downto 0) := X"00";  -- General debug input
    -- Clock 40 status signals
    clk40_lock : in  std_logic;
    clk40_stop : in  std_logic;
    -- Output signals
    nuke       : out std_logic;
    soft_rst   : out std_logic;
    -- TTC clock control and status
    clk40_rst  : out std_logic;
    clk40_sel  : out std_logic
    );
end emp_ctrl;

architecture rtl of emp_ctrl is

  signal ctrl, stat : ipb_reg_v(0 downto 0);
  signal ipbw       : ipb_wbus_array(N_SLAVES - 1 downto 0);
  signal ipbr       : ipb_rbus_array(N_SLAVES - 1 downto 0);

begin

  fabric : entity work.ipbus_fabric_sel
    generic map(
      NSLV      => N_SLAVES,
      SEL_WIDTH => IPBUS_SEL_WIDTH)
    port map(
      ipb_in          => ipb_in,
      ipb_out         => ipb_out,
      sel             => ipbus_sel_emp_ctrl(ipb_in.ipb_addr),
      ipb_to_slaves   => ipbw,
      ipb_from_slaves => ipbr
      );


  csr : entity work.ipbus_ctrlreg_v
    generic map(
      N_CTRL => 1,
      N_STAT => 1
      )
    port map(
      clk       => clk,
      reset     => rst,
      ipbus_in  => ipbw(N_SLV_CSR),
      ipbus_out => ipbr(N_SLV_CSR),
      d         => stat,
      q         => ctrl
      );

  loc : entity work.ipbus_reg_v
    generic map(
      N_REG => 1
      )
    port map(
      clk       => clk,
      reset     => rst,
      ipbus_in  => ipbw(N_SLV_BOARD_ID),
      ipbus_out => ipbr(N_SLV_BOARD_ID),
      q         => open
      );

  id : entity work.board_const_reg
    port map(
      ipb_in  => ipbw(N_SLV_ID),
      ipb_out => ipbr(N_SLV_ID)
      );

  stat(0) <= X"0000" & debug & "000000" & clk40_stop & clk40_lock;

  nuke      <= ctrl(0)(0);
  clk40_rst <= ctrl(0)(1);
  clk40_sel <= ctrl(0)(2);
  soft_rst  <= ctrl(0)(3);

end rtl;
