-- emp_ttc_cmd
--
-- Decoder for TTC commands
--
-- All signals synchronous to clk unless stated
-- Priority for commands is:
--      external TTC
--      internal BC0 (highest priority)
--      internal
--      no action (default)
--
-- Dave Newbold, July 2013

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.VComponents.all;

use work.mp7_ttc_decl.all;

-------------------------------------------------------------------------------
entity emp_ttc_cmd is
  generic(
    LHC_BUNCH_COUNT : integer
    );
  port(
    clk        : in  std_logic;         -- Main TTC clock
    rst        : in  std_logic;
    sclk       : in  std_logic;         -- Sampling clock for TTC data
    ttc_in_p   : in  std_logic;         -- TTC datastream from AMC13
    ttc_in_n   : in  std_logic;
    l1a        : out std_logic;         -- L1A output
    cmd        : out ttc_cmd_t;  -- B-command output (zero if no command)
    sinerr_ctr : out std_logic_vector(15 downto 0);
    dberr_ctr  : out std_logic_vector(15 downto 0);
    c_delay    : in  std_logic_vector(4 downto 0);  -- Coarse delay for TTC signals
    en_ttc     : in  std_logic;         -- enable TTC inputs
    err_rst    : in  std_logic          -- Err ctr reset
    );

end emp_ttc_cmd;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
architecture rtl of emp_ttc_cmd is

  signal ttc_data, ttc_data_d                        : std_logic_vector(1 downto 0);
  signal ttc_in, ttc_in_d, sinerr, dberr, stb_ttc    : std_logic;
  signal cmd_ttc, cmda, cmdb, cmdc, ext_cmd_i        : ttc_cmd_t;
  signal ttc_l1a, ext_cmd_pend, ext_cmd_rx, cmd_slot : std_logic;
  signal sinerr_ctr_i, dberr_ctr_i                   : unsigned(15 downto 0);

begin

  --buf: IBUFDS
  --    port map(
  --            i => ttc_in_p,
  --            ib => ttc_in_n,
  --            o => ttc_in
  --    );
  --ttc_in <= '0';

  --ddr: IDDRE1
  --    generic map(
  --            DDR_CLK_EDGE => "SAME_EDGE"
  --    )
  --    port map(
  --            q1 => ttc_data(0),
  --            q2 => ttc_data(1),
  --            c => sclk,
  --            cb => not sclk, --ce => '1',
  --            d => ttc_in,
  --            r => '0' --,
  --            --s => '0'
  --    );

  ttc_data <= (others => '0');

  cdel0 : SRLC32E
    port map(
      q   => ttc_data_d(0),
      d   => ttc_data(0),
      clk => clk,
      ce  => '1',
      a   => c_delay
      );

  cdel1 : SRLC32E
    port map(
      q   => ttc_data_d(1),
      d   => ttc_data(1),
      clk => clk,
      ce  => '1',
      a   => c_delay
      );

  decode : entity work.ttc_decoder
    port map(
      ttc_clk   => clk,
      ttc_data  => ttc_data_d,
      l1accept  => ttc_l1a,
      sinerrstr => sinerr,
      dberrstr  => dberr,
      brcststr  => stb_ttc,
      brcst     => cmd_ttc
      );

  l1a <= ttc_l1a and en_ttc;
  cmd <= cmd_ttc when en_ttc = '1' and stb_ttc = '1' else TTC_BCMD_NULL;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' or err_rst = '1' then
        sinerr_ctr_i <= (others => '0');
        dberr_ctr_i  <= (others => '0');
      else
        if sinerr = '1' and sinerr_ctr_i /= X"ffff" then
          sinerr_ctr_i <= sinerr_ctr_i + 1;
        end if;
        if dberr = '1' and dberr_ctr_i /= X"ffff" then
          dberr_ctr_i <= dberr_ctr_i + 1;
        end if;
      end if;
    end if;
  end process;

  sinerr_ctr <= std_logic_vector(sinerr_ctr_i);
  dberr_ctr  <= std_logic_vector(dberr_ctr_i);

end rtl;
-------------------------------------------------------------------------------
