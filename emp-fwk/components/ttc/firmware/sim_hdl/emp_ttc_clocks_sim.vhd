-- ttc_clocks
--
-- Clock generation for LHC clocks
--
-- Dave Newbold, June 2013

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.emp_framework_decl.all;

use work.emp_project_decl.all;

-------------------------------------------------------------------------------
entity emp_ttc_clocks_sim is
  port(
    clko_40  : out std_logic;
    clko_p   : out std_logic;
    clko_aux : out std_logic_vector(2 downto 0);
    rsto_40  : out std_logic;
    rsto_p   : out std_logic;
    rsto_aux : out std_logic_vector(2 downto 0);
    stopped  : out std_logic;
    locked   : out std_logic;
    rst_mmcm : in  std_logic;
    rsti     : in  std_logic
    );

end emp_ttc_clocks_sim;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
architecture rtl of emp_ttc_clocks_sim is

  signal clk40, clk_p : std_logic                    := '1';
  signal clk_aux      : std_logic_vector(2 downto 0) := (others => '1');

begin

  clk40   <= not clk40 after 12 ns;
  clko_40 <= clk40;
  rsto_40 <= rsti or rst_mmcm;
  clk_p   <= not clk_p after (12 / CLOCK_RATIO) * ns;
  clko_p  <= clk_p;
  rsto_p  <= rsti or rst_mmcm;

  gen : for i in 2 downto 0 generate

    clk_aux(i)  <= not clk_aux(i) after (12 / CLOCK_AUX_RATIO(i)) * ns;
    clko_aux(i) <= clk_aux(i);
    rsto_aux(i) <= rsti or rst_mmcm;

  end generate;

  stopped <= '0';
  locked  <= '1';

end rtl;
-------------------------------------------------------------------------------
