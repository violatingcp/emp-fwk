-- Top-level simulationdesign for KU115 framework firmware
--

library IEEE;
use IEEE.std_logic_1164.all;

-- IPBus
use work.ipbus.all;
-- MP7 
use work.mp7_ttc_decl.all;
--use work.mp7_readout_decl.all;

-- MPUltra
use work.ipbus_decode_sim.all;
use work.emp_data_types.all;
use work.emp_device_decl.all;

entity top is
  generic(
    MAC_ADDR : std_logic_vector(47 downto 0) := X"000A3501EDF2";
    IP_ADDR  : std_logic_vector(31 downto 0) := X"c0a8c902"
    );
end top;

architecture rtl of top is

  -- IPBus signals
  signal ipb_clk, ipb_rst : std_logic;

  signal ipb_w : ipb_wbus;
  signal ipb_r : ipb_rbus;

  signal ipb_w_array : ipb_wbus_array(N_SLAVES - 1 downto 0);
  signal ipb_r_array : ipb_rbus_array(N_SLAVES - 1 downto 0);

  -- LHC clocks and signals
  signal clk40ish, clk40ext   : std_logic;
  signal clk40_rst, clk40_sel : std_logic;

  -- Clock domain reset outputs
  signal clk40    : std_logic;
  signal rst40    : std_logic;
  signal clk_p    : std_logic;
  signal rst_p    : std_logic;
  signal clks_aux : std_logic_vector(2 downto 0);
  signal rsts_aux : std_logic_vector(2 downto 0);

  -- Clock signals
  signal clk40_lock, clk40_stop : std_logic;

  -- TTC signals  
  signal ttc_l1a, ttc_l1a_dist, dist_lock, oc_flag, ec_flag, payload_bc0, ttc_l1a_throttle, ttc_l1a_flag : std_logic;
  signal ttc_cmd, ttc_cmd_dist                                                                           : ttc_cmd_t;
  signal bunch_ctr                                                                                       : bctr_t;
  signal evt_ctr, orb_ctr                                                                                : eoctr_t;
  signal tmt_sync                                                                                        : tmt_sync_t;

  -- Others
  signal soft_rst : std_logic;

  -- Datapath signals
  signal payload_d, payload_q     : ldata(N_REGION * 4 - 1 downto 0);
  signal clkmon                   : std_logic_vector(2 downto 0);
  signal ctrs                     : ttc_stuff_array(N_REGION - 1 downto 0);
  signal rst_loc, clken_loc       : std_logic_vector(N_REGION - 1 downto 0);

begin

-- Infrastructure

  infra : entity work.sim_infra
    generic map(
      MAC_ADDR => MAC_ADDR,
      IP_ADDR  => IP_ADDR
      )
    port map(
      soft_rst => soft_rst,
      ipb_clk  => ipb_clk,
      ipb_rst  => ipb_rst,
      ipb_in   => ipb_r,
      ipb_out  => ipb_w
      );

-- ipbus fabric selector

  fabric : entity work.ipbus_fabric_sel
    generic map(
      NSLV      => N_SLAVES,
      SEL_WIDTH => IPBUS_SEL_WIDTH)
    port map(
      ipb_in          => ipb_w,
      ipb_out         => ipb_r,
      sel             => ipbus_sel_sim(ipb_w.ipb_addr),
      ipb_to_slaves   => ipb_w_array,
      ipb_from_slaves => ipb_r_array
      );


-- info block (constant registers containing version numbers, build info, etc)
  info : entity work.emp_info
    port map(
      ipb_in  => ipb_w_array(N_SLV_INFO),
      ipb_out => ipb_r_array(N_SLV_INFO)
      );

  ctrl : entity work.emp_ctrl
    port map (
      clk        => ipb_clk,
      rst        => ipb_rst,
      ipb_in     => ipb_w_array(N_SLV_CTRL),
      ipb_out    => ipb_r_array(N_SLV_CTRL),
      soft_rst   => soft_rst,
      debug      => (others => '0'),
      clk40_lock => clk40_lock,
      clk40_stop => clk40_stop,
      clk40_sel  => clk40_sel,
      clk40_rst  => clk40_rst
      );

-- TTC block
  ttc : entity work.ttc_sim
    port map(
      clk          => ipb_clk,
      rst          => ipb_rst,
      mmcm_rst     => clk40_rst,
      sel          => clk40_sel,
      lock         => clk40_lock,
      stop         => clk40_stop,
      ipb_in       => ipb_w_array(N_SLV_TTC),
      ipb_out      => ipb_r_array(N_SLV_TTC),
      clk40        => clk40,
      rst40        => rst40,
      clk_p        => clk_p,
      rst_p        => rst_p,
      clks_aux     => clks_aux,
      rsts_aux     => rsts_aux,
      ttc_cmd      => ttc_cmd,
      ttc_cmd_dist => ttc_cmd_dist,
      ttc_l1a      => ttc_l1a,
      ttc_l1a_flag => ttc_l1a_flag,
      ttc_l1a_dist => ttc_l1a_dist,
      l1a_throttle => '0',              -- ttc_l1a_throttle,
      dist_lock    => dist_lock,
      bunch_ctr    => bunch_ctr,
      evt_ctr      => (others => '0'),
      orb_ctr      => open,
      oc_flag      => oc_flag,
      ec_flag      => ec_flag,
      tmt_sync     => tmt_sync,
      monclk       => clkmon
      );

-- Datapath block
  datapath : entity work.emp_datapath
    port map(
      clk         => ipb_clk,
      rst         => ipb_rst,
      ipb_in      => ipb_w_array(N_SLV_DATAPATH),
      ipb_out     => ipb_r_array(N_SLV_DATAPATH),
      board_id    => (others => '0'),
      clk40       => clk40,
      clk_p       => clk_p,
      rst_p       => rst_p,
      ttc_cmd     => ttc_cmd_dist,
      ttc_l1a     => ttc_l1a_dist,
      lock        => dist_lock,
      ctrs_out    => ctrs,
      rst_out     => rst_loc,
      clken_out   => clken_loc,
      tmt_sync    => tmt_sync,
      payload_bc0 => payload_bc0,
      refclkp => (others => '0'),
      refclkn => (others => '0'),
      clkmon      => clkmon,
      q           => payload_d,
      d           => payload_q
      );

  -- And finally, the payload
  payload : entity work.emp_payload
    port map(
      clk         => ipb_clk,
      rst         => ipb_rst,
      ipb_in      => ipb_w_array(N_SLV_PAYLOAD),
      ipb_out     => ipb_r_array(N_SLV_PAYLOAD),
      clk_payload => clks_aux,
      rst_payload => rsts_aux,
      clk_p       => clk_p,
      rst_loc     => rst_loc,
      clken_loc   => clken_loc,
      ctrs        => ctrs,
      bc0         => payload_bc0,
      d           => payload_d,
      q           => payload_q,
      gpio        => open,
      gpio_en     => open
      );


end rtl;

