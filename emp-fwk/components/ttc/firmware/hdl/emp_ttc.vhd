-- ttc
--
-- TTC decoder, counters, LHC clock distribution, etc
--
-- Dave Newbold, June 2013

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_mp7_ttc.all;
use work.mp7_ttc_decl.all;

use work.emp_project_decl.all;

-------------------------------------------------------------------------------
entity emp_ttc is
  port(
    -- ipbus clock & rst
    clk          : in  std_logic;
    rst          : in  std_logic;
    -- clock domain full reset
    mmcm_rst     : in  std_logic;
    -- TTC clock / internal clock select
    sel          : in  std_logic;
    -- MMCM clock and lock status
    lock         : out std_logic;
    stop         : out std_logic;
    -- IPBus
    ipb_in       : in  ipb_wbus;
    ipb_out      : out ipb_rbus;
    -- internal pseudo-40MHz clock
    clk40_in     : in  std_logic;
    clk40ish_in  : in  std_logic;
    -- clock outputs
    clk40        : out std_logic;
    -- clock domain reset outputs
    rst40        : out std_logic;
    clk_p        : out std_logic;
    rst_p        : out std_logic;
    clks_aux     : out std_logic_vector(2 downto 0);
    rsts_aux     : out std_logic_vector(2 downto 0);
    -- TTC protocol backplane signals
    ttc_in_p     : in  std_logic;
    ttc_in_n     : in  std_logic;
    -- TTC b command output
    ttc_cmd      : out ttc_cmd_t;
    ttc_cmd_dist : out ttc_cmd_t;
    -- L1A output
    ttc_l1a      : out std_logic;
    -- L1A qualifier output
    ttc_l1a_flag : out std_logic;
    ttc_l1a_dist : out std_logic;
    l1a_throttle : in  std_logic;
    dist_lock    : in  std_logic;
    bunch_ctr    : out bctr_t;
    evt_ctr      : in  eoctr_t;
    orb_ctr      : out eoctr_t;
    oc_flag      : out std_logic;
    ec_flag      : out std_logic;
    tmt_sync     : out tmt_sync_t;
    -- clock monitoring inputs from MGTs
    monclk       : in  std_logic_vector(2 downto 0)
    );

end emp_ttc;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
architecture rtl of emp_ttc is

  signal clk40_i, rst40_i, clk40s, clk40_div, rsti, clk40_a, rst40_a, clk_p_i, rst_p_i    : std_logic;
  signal clks_aux_i, rsts_aux_i                                                           : std_logic_vector(2 downto 0);
  signal l1a, l1a_ttc, l1a_int, l1a_del, l1a_pend, cmd_bx, cmd_pend, l1a_issue, cmd_issue : std_logic;
  signal psok, bc0_fr, ctr_clr, err_rst                                                   : std_logic;
  signal cmd, cmd_ttc, cmd_del                                                            : ttc_cmd_t;
  signal bunch_ctr_i                                                                      : bctr_t;
  signal req_bx                                                                           : unsigned(bctr_t'range);
  signal orb_ctr_i                                                                        : eoctr_t;
  signal sinerr_ctr, dberr_ctr                                                            : std_logic_vector(15 downto 0);
  signal stat                                                                             : ipb_reg_v(3 downto 0);
  signal ctrl                                                                             : ipb_reg_v(1 downto 0);
  signal stb                                                                              : std_logic_vector(1 downto 0);
  signal bc0_lock                                                                         : std_logic;
  signal ipbw                                                                             : ipb_wbus_array(N_SLAVES - 1 downto 0);
  signal ipbr                                                                             : ipb_rbus_array(N_SLAVES - 1 downto 0);
  signal tmt_ctrl                                                                         : ipb_reg_v(0 downto 0);
begin

-- ipbus address decode

  fabric : entity work.ipbus_fabric_sel
    generic map(
      NSLV      => N_SLAVES,
      SEL_WIDTH => IPBUS_SEL_WIDTH)
    port map(
      ipb_in          => ipb_in,
      ipb_out         => ipb_out,
      sel             => ipbus_sel_mp7_ttc(ipb_in.ipb_addr),
      ipb_to_slaves   => ipbw,
      ipb_from_slaves => ipbr
      );

-- TTC control registers

  reg : entity work.ipbus_syncreg_v
    generic map(
      N_CTRL => 2,
      N_STAT => 4
      )
    port map(
      clk     => clk,
      rst     => rst,
      ipb_in  => ipbw(N_SLV_CSR),
      ipb_out => ipbr(N_SLV_CSR),
      slv_clk => clk40_a,
      d       => stat,
      q       => ctrl,
      stb     => stb
      );

-- MMCM for clock multiplication / phase adjustment

  rsti <= rst or ctrl(0)(2);            -- CDC, unrelated clocks

  clocks : entity work.emp_ttc_clocks
    port map(
      clk_40    => clk40_in,
      clk_40pseudo => clk40ish_in,
      clko_40    => clk40_i,
      clko_p     => clk_p_i,
      clko_aux   => clks_aux_i,
      rsto_40    => rst40_i,
      rsto_p     => rst_p_i,
      rsto_aux   => rsts_aux_i,
      clko_40s   => clk40s,
      stopped    => stop,
      locked     => lock,
      rst_mmcm   => mmcm_rst,
      rsti       => rsti,
      clksel     => sel,
      psval      => ctrl(1)(11 downto 0),
      psok       => psok,
      psen       => ctrl(1)(12)
      );

  clk40_a  <= clk40_i;  -- Needed to make sure delta delays line up in simulation!
  rst40_a  <= rst40_i;
  clk40    <= clk40_i;
  rst40    <= rst40_i;
  clk_p    <= clk_p_i;
  rst_p    <= rst_p_i;
  clks_aux <= clks_aux_i;
  rsts_aux <= rsts_aux_i;

-- TTC protocol decoder

  err_rst <= ctrl(0)(1) and stb(0);

  ttccmd : entity work.emp_ttc_cmd
    generic map(
      LHC_BUNCH_COUNT => LHC_BUNCH_COUNT
      )
    port map(
      clk        => clk40_a,
      rst        => rst40_a,
      sclk       => clk40s,
      ttc_in_p   => ttc_in_p,
      ttc_in_n   => ttc_in_n,
      l1a        => l1a_ttc,
      cmd        => cmd_ttc,
      sinerr_ctr => sinerr_ctr,
      dberr_ctr  => dberr_ctr,
      c_delay    => ctrl(1)(20 downto 16),
      en_ttc     => ctrl(0)(0),
      err_rst    => err_rst
      );

-- L1A generation

  l1agen : entity work.l1a_gen
    port map(
      clk     => clk,
      rst     => rst,
      ipb_in  => ipbw(N_SLV_L1_GEN),
      ipb_out => ipbr(N_SLV_L1_GEN),
      tclk    => clk40_a,
      trst    => rst40_a,
      l1a     => l1a_int
      );

  l1a       <= l1a_ttc or (l1a_int and not (ctrl(0)(8) and l1a_throttle)) or (l1a_pend and (cmd_bx or not ctrl(0)(10)));  -- Note that internal throttle only applies to random trigger source
  l1a_issue <= l1a and not l1a_ttc and not l1a_int;

-- TTC command generation

  -- Pipelining: calculating req_bx is not time critical, can affort one clock cycle more.
  process(clk40_a)
  begin
    if rising_edge(clk40_a) then
      if (unsigned(ctrl(0)(23 downto 12)) > TTC_DEL) then
        req_bx <= unsigned(ctrl(0)(23 downto 12)) - TTC_DEL - 1;
      else
        req_bx <= LHC_BUNCH_COUNT + unsigned(ctrl(0)(23 downto 12)) - TTC_DEL - 1;
      end if;
    end if;
  end process;
  cmd_bx <= '1' when std_logic_vector(req_bx) = bunch_ctr_i    else '0';

  process(cmd_ttc, bc0_fr, cmd_pend, cmd_bx, ctrl(0)(10))
  begin
    cmd_issue <= '0';
    if cmd_ttc /= TTC_BCMD_NULL then
      cmd       <= cmd_ttc;
    elsif bc0_fr = '1' then
      cmd       <= TTC_BCMD_BC0;
    elsif cmd_pend = '1' and (cmd_bx = '1' or ctrl(0)(10) = '0') then
      cmd       <= ctrl(0)(31 downto 24);
      cmd_issue <= '1';
    else
      cmd <= TTC_BCMD_NULL;
    end if;
  end process;

  process(clk40_a)
  begin
    if rising_edge(clk40_a) then
      cmd_pend     <= (cmd_pend or (ctrl(0)(9) and stb(0))) and not (rst40_a or cmd_issue);
      l1a_pend     <= (l1a_pend or (ctrl(0)(7) and stb(0))) and not (rst40_a or l1a_issue);
      ttc_cmd_dist <= cmd;
    end if;
  end process;

  ttc_l1a_dist <= l1a;

-- Counters

  ctr_clr <= ctrl(0)(6) and stb(0);

  ttcctr : entity work.ttc_ctrs
    port map(
      clk         => clk40_a,
      rst         => rst40_a,
      ttc_cmd     => cmd,
      l1a         => l1a,
      clr         => '0',
      en_int_bc0  => ctrl(0)(3),
      bc0_lock    => bc0_lock,
      bc0_fr      => bc0_fr,
      ttc_cmd_out => cmd_del,
      l1a_out     => l1a_del,
      bunch_ctr   => bunch_ctr_i,
      orb_ctr     => orb_ctr_i
      );

  ttc_cmd   <= cmd_del;
  ttc_l1a   <= l1a_del;
  bunch_ctr <= bunch_ctr_i;
  orb_ctr   <= orb_ctr_i;
  oc_flag   <= '1' when orb_ctr_i(13 downto 0) = (13 downto 0 => '0') and bc0_lock = '1' else '0';
  ec_flag   <= '1' when evt_ctr(16 downto 0) = (16 downto 0   => '0')                    else '0';

-- Status reg

  stat(0) <= std_logic_vector(to_unsigned(LHC_BUNCH_COUNT, 12)) & (l1a_pend or cmd_pend) & psok & dist_lock & bc0_lock & X"0" & bunch_ctr_i;
  stat(1) <= evt_ctr;
  stat(2) <= orb_ctr_i;
  stat(3) <= dberr_ctr & sinerr_ctr;

-- clk40 frequency monitoring   

  div : entity work.freq_ctr_div
    port map(
      clk(0)    => clk40_a,
      clkdiv(0) => clk40_div
      );

-- Clock frequency monitor

  ctr : entity work.freq_ctr
    generic map(
      N_CLK => 4
      )
    port map(
      clk                => clk,
      rst                => rst,
      ipb_in             => ipbw(N_SLV_FREQ),
      ipb_out            => ipbr(N_SLV_FREQ),
      clkdiv(0)          => clk40_div,
      clkdiv(3 downto 1) => monclk
      );

-- TTC history buffer

  hist : entity work.ttc_history_new
    port map(
      clk     => clk,
      rst     => rst,
      ipb_in  => ipbw(N_SLV_HIST),
      ipb_out => ipbr(N_SLV_HIST),
      ttc_clk => clk40_a,
      ttc_rst => rst40_a,
      ttc_l1a => l1a_del,
      ttc_cmd => cmd_del,
      ttc_bx  => bunch_ctr_i,
      ttc_orb => orb_ctr_i,
      ttc_evt => evt_ctr
      );

-- Command counters

  cmdctrs : entity work.ttc_cmd_ctrs
    port map(
      clk     => clk,
      rst     => rst,
      ipb_in  => ipbw(N_SLV_CMD_CTRS),
      ipb_out => ipbr(N_SLV_CMD_CTRS),
      ttc_clk => clk40_a,
      clr     => ctr_clr,
      ttc_cmd => cmd_del
      );

-- TMT stuff

  tmt : entity work.tmt_sync
    port map(
      clk          => clk,
      rst          => rst,
      ipb_in       => ipbw(N_SLV_TMT),
      ipb_out      => ipbr(N_SLV_TMT),
      ttc_clk      => clk40_a,
      bctr         => bunch_ctr_i,
      tmt_l1a_sync => ttc_l1a_flag,
      tmt_pkt_sync => tmt_sync(0)
      );

end rtl;
-------------------------------------------------------------------------------
