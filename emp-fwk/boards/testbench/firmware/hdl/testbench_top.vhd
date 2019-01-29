--! Using the IEEE Library
library IEEE;
--! Using STD_LOGIC
use IEEE.STD_LOGIC_1164.all;
--! Using NUMERIC TYPES
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;

--use STD.TEXTIO.all;

--! Using the "mp7_data" data-types
use work.emp_data_types.all;

--! Using TTC data-types
use work.mp7_ttc_decl.all;

--! Using EMP device declaration
use work.emp_device_decl.all;

--! Using Testbench declaration
use work.tb_decl.all;

--! Using the testbench helper package
use work.emp_capture_tools.all;
use work.emp_testbench_helpers.all;
--
--! Using ipbus definitions
use work.ipbus.all;

use work.emp_project_decl.all;


--! @brief An entity providing a TestBench
--! @details Detailed description
entity top is
  generic(
    --timeout               : INTEGER := cTestbenchTowersInHalfEta + 70;
    --numberOfFrames        : INTEGER := cTestbenchTowersInHalfEta;
    sourcefile : string  := "";
    sinkfile   : string  := "";
    striphdr   : boolean := TB_STRIPHEADER;
    inserthdr  : boolean := TB_INSERTHEADER;
    playlen    : integer := TB_NUMFRAMES;
    playoffset : integer := TB_INITSETTLECYCLES;
    caplen     : integer := TB_NUMFRAMES;
    capoffset  : integer := TB_INITSETTLECYCLES;
    dryrun     : boolean := false;
    debug      : boolean := false
    );
end top;

--! @brief Architecture definition for entity TestBench
--! @details Detailed description
architecture behavioral of top is

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  constant LHC_CLOCK_FREQ   : real := 40.0; -- Mhz
  constant LHC_CLOCK_PERIOD : real := 1.0 / LHC_CLOCK_FREQ; -- us
-- CLOCK SIGNALS
  signal clk_lhc, clk_ipb : std_logic := '0';
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LINK SIGNALS
  signal payload_d : ldata(N_LINKS - 1 downto 0) := (others => LWORD_NULL);
  signal payload_q : ldata(N_LINKS - 1 downto 0) := (others => LWORD_NULL);
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PAYLOAD SIGNALS

  signal rst_ipb, rst_p  : std_logic                               := '1';
  signal ipb_in_payload  : ipb_wbus                                := IPB_WBUS_NULL;
  signal ipb_out_payload : ipb_rbus                                := IPB_RBUS_NULL;
  signal rst_loc         : std_logic_vector(N_REGION - 1 downto 0) := (others => '0');
  signal clken_loc       : std_logic_vector(N_REGION - 1 downto 0) := (others => '1');
  signal ctrs            : ttc_stuff_array(N_REGION - 1 downto 0)  := (others => TTC_STUFF_NULL);
  signal en_clks         : boolean                                 := false;
  signal clk_p           : std_logic                               := '0';
  signal clks_aux        : std_logic_vector(2 downto 0)            := (others => '0');
  signal rsts_aux        : std_logic_vector(2 downto 0)            := (others => '0');

--! Reminder of the MP7 payload interface
  --ipb_in: in ipb_wbus;
  --ipb_out: out ipb_rbus;
  --clk: in std_logic; -- ipbus signals
  --rst: in std_logic;
  --ipb_in: in ipb_wbus;
  --ipb_out: out ipb_rbus;
  --clk_payload: in std_logic_vector(2 downto 0);
  --rst_payload: in std_logic_vector(2 downto 0);
  --clk_p: in std_logic; -- data clock
  --rst_loc: in std_logic_vector(N_REGION - 1 downto 0);
  --clken_loc: in std_logic_vector(N_REGION - 1 downto 0);
  --ctrs: in ttc_stuff_array;
  --bc0: out std_logic;
  --d: in ldata(4 * N_REGION - 1 downto 0); -- data in
  --q: out ldata(4 * N_REGION - 1 downto 0); -- data out
  --gpio: out std_logic_vector(29 downto 0); -- IO to mezzanine connector
  --gpio_en: out std_logic_vector(29 downto 0) -- IO to mezzanine connector (three-state enables)
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


begin

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  clk_ipb <= not clk_ipb after 30 ns;
  clk_lhc <= not clk_lhc after (LHC_CLOCK_PERIOD / 2.0) * 1.0 us;
  en_clks <= true when rising_edge(clk_lhc);
  clk_p <= not clk_p after (LHC_CLOCK_PERIOD / real(CLOCK_RATIO) / 2.0) * 1 us when en_clks else '1' when rising_edge(clk_lhc);

  gClks: for k in 2 downto 0 generate
  begin
    clks_aux(k) <= not clks_aux(k) after (LHC_CLOCK_PERIOD / real(CLOCK_AUX_RATIO(k)) / 2.0) * 1 us when en_clks else '1' when rising_edge(clk_lhc);
  end generate;
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  rst_ipb <= '0'         after 1 ns;
  rst_p   <= '0'         after 25 ns;
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Datapath replacement
  source : entity work.EMPCaptureFileReader
    generic map(
      gFileName       => sourcefile,
      gPlaybackFrames => playlen,
      gPlaybackOffset => playoffset,
      gFileBufferSize => TB_PLAYBACKBUFFERSIZE,
      gStripHeader    => striphdr,
      gDebugMessages  => debug
      )
    port map(
      clk_p,
      rst_p,
      payload_d
      );

---- Payload

  payload : entity work.emp_payload
    port map(
      clk         => clk_ipb,
      rst         => rst_ipb,
      ipb_in      => ipb_in_payload,
      ipb_out     => ipb_out_payload,
      clk_payload => clks_aux,
      rst_payload => rsts_aux,
      clk_p       => clk_p,
      rst_loc     => rst_loc,
      clken_loc   => clken_loc,
      ctrs        => ctrs,
      bc0         => open,              -- payload_bc0,
      d           => payload_d,
      q           => payload_q,
      gpio        => open,
      gpio_en     => open
      );

  sink : entity work.EMPCaptureFileWriter
    generic map(
      gFileName      => sinkfile,
      gCaptureOffset => capoffset,
      gCaptureLength => caplen,
      gInsertHeader  => inserthdr,
      gDebugMessages => debug
      )
    port map(
      clk_p,
      rst_p,
      payload_q
      );
---- -------------------------------------------------------------



-- =========================================================================================================================================================================================

end architecture behavioral;
