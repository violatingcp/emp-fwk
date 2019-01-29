library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
library unisim;
use unisim.VComponents.all;

entity emp_clocks is
  port (
    -- 100 Mhz differential, from connector
    sys_clk_p    : in  std_logic;
    sys_clk_n    : in  std_logic;
    -- AXI clock, from the xdma core. f=125 Mhz
    user_clk     : in  std_logic;
    -- Output clocks
    sys_clk      : out std_logic;       -- PCIe system clock
    sys_clk_gt   : out std_logic;       -- PCIe system clock copy
    ipb_clk      : out std_logic;       -- IPBus clock
    clk_40pseudo : out std_logic;       -- Pseudo clock 40, from pcie clocks
    onehz        : out std_logic        -- heartbeat signal    
    );
end emp_clocks;

architecture rtl of emp_clocks is

  signal clk_fb_osc, clk_fb_user : std_logic;  -- mmcm feedback signals

  signal sys_rst_d : std_logic;
  signal ipb_clk_i, ipb_clk_b : std_logic;
  signal ipb_rst_i : std_logic;
  signal clk_40pseudo_i, clk_40pseudo_b : std_logic;

  signal heartbeat : std_logic_vector(25 downto 0);

begin

  ibufds_gte3_sys_clk : IBUFDS_GTE3
    generic map (
      REFCLK_HROW_CK_SEL => "00"        -- clock divider 1 for ODiv2
      )
    port map (
      O     => sys_clk_gt,              -- 100 MHz output clock
      ODIV2 => sys_clk,                 -- also 100 mHz
      CEB   => '0',
      I     => sys_clk_p,
      IB    => sys_clk_n
      );


  -- Convert pcie user clock into ipbus clock (31.2 Mhz) and LHC clock (40 Mhz)
  mmcm_user_clk : MMCME3_BASE
    generic map(
      clkin1_period   => 8.0,           -- clkin 125 Mhz
      clkfbout_mult_f => 8.0,           -- VCO freq 1000MHz
      clkout1_divide  => 32,
      clkout2_divide  => 25
     --clkout3_divide => 24,
     --clkout4_divide => 24 / CLOCK_AUX_RATIO(0),
     --clkout5_divide => 24 / CLOCK_AUX_RATIO(1),
     --clkout6_divide => 24 / CLOCK_AUX_RATIO(2)
      )
    port map(
      clkin1   => user_clk,
      clkfbin  => clk_fb_user,
      clkfbout => clk_fb_user,
      clkout1  => ipb_clk_i,
      clkout2  => clk_40pseudo_i,
      clkout3  => open,
      clkout4  => open,
      clkout5  => open,
      clkout6  => open,
      rst      => '0',
      pwrdwn   => '0'
      );

  -- Clock buffer - ipbus
  bufg_ipb: BUFG port map(
    i => ipb_clk_i,
    o => ipb_clk_b
  );

  -- Clock buffer - Pseudo-clock40
  bufg_40pseudo: BUFG port map(
    i => clk_40pseudo_i,
    o => clk_40pseudo_b
  );

  clk_40pseudo <= clk_40pseudo_b;
  ipb_clk <= ipb_clk_b;

  -- In Andy's ultra design it was tied to the pcie reset
  -- Doens't seem to be required here
  ipb_rst_i <= '0';


  process (ipb_clk_i)
  begin
    if rising_edge(ipb_clk_i) then
      if (ipb_rst_i = '1') then
        heartbeat <= (others => '0');
      else
        heartbeat <= heartbeat + '1';
      end if;
    end if;
  end process;
  onehz <= heartbeat(25);
end rtl;

