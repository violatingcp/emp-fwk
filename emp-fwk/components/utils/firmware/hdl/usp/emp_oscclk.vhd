library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
library unisim;
use unisim.VComponents.all;

entity emp_oscclk is
  generic (
    OSC_FREQ: real
  );
  port (
    -- X MHz on-board differential, from oscillator
    osc_clk_p    : in  std_logic;
    osc_clk_n    : in  std_logic;
   -- Clock 40, generated from oscillator
    clk_40ext    : out std_logic
  );
end emp_oscclk;

architecture rtl of emp_oscclk is

  signal clk_fb_osc               : std_logic;  -- mmcm feedback signals
  signal osc_clk                  : std_logic;

  signal clk_40ext_i, clk_40ext_b : std_logic;

begin

  ibufds_osc : IBUFDS
    generic map (
      DQS_BIAS => "FALSE"               -- (FALSE, TRUE)
      )
    port map (
      O  => osc_clk,    -- 1-bit output: Buffer output
      I  => osc_clk_p,  -- 1-bit input: Diff_p buffer input (connect directly to top-level port)
      IB => osc_clk_n   -- 1-bit input: Diff_n buffer input (connect directly to top-level port)
      );

  -- Convert pcie user clock to LHC clock (40 Mhz)
  mmcm_osc_clk : MMCME4_BASE
    generic map(
      clkin1_period   => 1000.0 / OSC_FREQ,
      clkfbout_mult_f => 1200.0 / OSC_FREQ,
      clkout1_divide  => 30
     --clkout2_divide => 24,
     --clkout3_divide => 24,
     --clkout4_divide => 24 / CLOCK_AUX_RATIO(0),
     --clkout5_divide => 24 / CLOCK_AUX_RATIO(1),
     --clkout6_divide => 24 / CLOCK_AUX_RATIO(2)
      )
    port map(
      clkin1   => osc_clk,
      clkfbin  => clk_fb_osc,
      clkfbout => clk_fb_osc,
      clkout1  => clk_40ext_i,
      clkout2  => open,
      clkout3  => open,
      clkout4  => open,
      clkout5  => open,
      clkout6  => open,
      rst      => '0',
      pwrdwn   => '0'
      );
  
  -- Clock buffer - (derived) exteranl clock40
  bufg_40ext: BUFG port map(
    i => clk_40ext_i,
    o => clk_40ext_b
  );

  clk_40ext <= clk_40ext_b;

end rtl;

