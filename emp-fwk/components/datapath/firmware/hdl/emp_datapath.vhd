-- emp_datapath
--
-- Wrapper for MGTs, buffers, TTC signals distribution
--
-- Alessandro Thea, March 2018, 
-- 
-- heavily inspired by the corresponding mp7 code from
-- Dave Newbold, February 2014

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.mp7_ttc_decl.all;
use work.ipbus_decode_emp_datapath.all;
use work.drp_decl.all;

use work.emp_data_types.all;
use work.emp_project_decl.all;
use work.emp_framework_decl.all;
use work.emp_device_decl.all;
use work.emp_datapath_utils.all;

entity emp_datapath is
  port(
    clk         : in  std_logic;        -- ipbus clock, rst, bus
    rst         : in  std_logic;
    ipb_in      : in  ipb_wbus;
    ipb_out     : out ipb_rbus;
    board_id    : in  std_logic_vector(31 downto 0);
    clk40       : in  std_logic;
    clk_p       : in  std_logic;        -- parallel data clock & rst
    rst_p       : in  std_logic;
    ttc_cmd     : in  ttc_cmd_t;        -- TTC command (clk40 domain)
    ttc_l1a     : in  std_logic;        -- TTC L1A (clk40 domain)
    lock        : out std_logic;  -- lock flag for distributed bunch counters
    ctrs_out    : out ttc_stuff_array(N_REGION - 1 downto 0);  -- TTC counters for local logic
    rst_out     : out std_logic_vector(N_REGION - 1 downto 0);  -- Resets for local logic;
    clken_out   : out std_logic_vector(N_REGION - 1 downto 0);  -- Clock enables for local logic;
    tmt_sync    : in  tmt_sync_t;       -- TMT sync signals
    payload_bc0 : in  std_logic;
    refclkp     : in  std_logic_vector(N_REFCLK - 1 downto 0);  -- MGT refclks & IO
    refclkn     : in  std_logic_vector(N_REFCLK - 1 downto 0);
    clkmon      : out std_logic_vector(2 downto 0);  -- clock frequency monitoring outputs
    d           : in  ldata(N_REGION * 4 - 1 downto 0);  -- parallel data from payload
    q           : out ldata(N_REGION * 4 - 1 downto 0)  -- parallel data to payload
    );

end emp_datapath;

architecture rtl of emp_datapath is

  signal ipbw  : ipb_wbus_array(N_SLAVES - 1 downto 0);
  signal ipbr  : ipb_rbus_array(N_SLAVES - 1 downto 0);
  signal ipbdc : ipbdc_bus_array(N_REGION downto 0);

  signal ctrl : ipb_reg_v(0 downto 0);

  signal rst_chain_a, lock_chain_a, l1a_chain_a : std_logic_vector(N_REGION downto 0);
  signal ttc_chain_a                            : ttc_cmd_array(N_REGION downto 0);
  signal tmt_chain_a                            : tmt_sync_array(N_REGION downto 0);
  --signal cap_chain_a                            : daq_cap_bus_array(N_REGION downto 0);
  --signal daq_chain_a                            : daq_bus_array(N_REGION downto 0);


  signal rst_chain_b, lock_chain_b, l1a_chain_b : std_logic_vector(N_REGION downto 0);
  signal ttc_chain_b                            : ttc_cmd_array(N_REGION downto 0);
  signal tmt_chain_b                            : tmt_sync_array(N_REGION downto 0);
  --signal cap_chain_b                            : daq_cap_bus_array(N_REGION downto 0);
  --signal daq_chain_b                            : daq_bus_array(N_REGION downto 0);

  --signal dbus_cross : daq_bus;

  signal refclk, refclk_odiv, refclk_buf : std_logic_vector(N_REFCLK - 1 downto 0);
  signal refclk_mon, refclk_mon_d        : std_logic_vector(N_REFCLK - 1 downto 0);
  signal rxclk_mon, txclk_mon, qplllock  : std_logic_vector(31 downto 0);  -- Match range of integer sel
  signal sel                             : integer range 0 to 31;
  signal qplllock_sel                    : std_logic;
  signal ctrs                            : ttc_stuff_array(N_REGION - 1 downto 0);


  signal ctrs_int  : ttc_stuff_array(N_REGION - 1 downto 0);  -- TTC counters for local logic
  signal rst_int   : std_logic_vector(N_REGION - 1 downto 0);  -- Resets for local logic;
  signal clken_int : std_logic_vector(N_REGION - 1 downto 0);  -- Clock enables for local logic;
  signal d_int     : ldata(N_REGION * 4 - 1 downto 0);  -- parallel data from payload
  signal q_int     : ldata(N_REGION * 4 - 1 downto 0);  -- parallel data to payload


begin

-- ipbus address decode

  fabric : entity work.ipbus_fabric_sel
    generic map(
      NSLV      => N_SLAVES,
      SEL_WIDTH => IPBUS_SEL_WIDTH)
    port map(
      ipb_in          => ipb_in,
      ipb_out         => ipb_out,
      sel             => ipbus_sel_emp_datapath(ipb_in.ipb_addr),
      ipb_to_slaves   => ipbw,
      ipb_from_slaves => ipbr
      );

-- Control reg

  loc : entity work.ipbus_reg_v
    generic map(
      N_REG => 1
      )
    port map(
      clk       => clk,
      reset     => rst,
      ipbus_in  => ipbw(N_SLV_CTRL),
      ipbus_out => ipbr(N_SLV_CTRL),
      q         => ctrl,
      qmask     => (0 => X"000000ff")
      );

-- Region info

  id : entity work.region_info
    port map(
      ipb_in  => ipbw(N_SLV_REGION_INFO),
      ipb_out => ipbr(N_SLV_REGION_INFO),
      qsel    => ctrl(0)(7 downto 3)
      );

-- Payload BC0 monitoring

  --bc0_mon : entity work.align_mon
  --  port map(
  --    clk     => clk,
  --    rst     => rst,
  --    ipb_in  => ipbw(N_SLV_BC0_MON),
  --    ipb_out => ipbr(N_SLV_BC0_MON),
  --    clk_p   => clk_p,
  --    rst_p   => rst_p,
  --    bctr    => ctrs(ALIGN_REGION).bctr,
  --    pctr    => ctrs(ALIGN_REGION).pctr,
  --    sig     => payload_bc0
  --    );

-- Regions

  fabric_q : entity work.ipbus_dc_fabric_sel
    generic map(
      SEL_WIDTH => 5
      )
    port map(
      clk       => clk,
      rst       => rst,
      sel       => ctrl(0)(7 downto 3),
      ipb_in    => ipbw(N_SLV_REGION),
      ipb_out   => ipbr(N_SLV_REGION),
      ipbdc_out => ipbdc(0),
      ipbdc_in  => ipbdc(N_REGION)
      );



  -----------------------------------------------------------------------------
  -- Refclks

  -- Each clock to a GT clock buffer
  clk_gen : for i in N_REFCLK - 1 downto 0 generate

      ibufds_gen : if is_refclk_used(i) generate
        ibuf : entity work.emp_ibufds_gt
        port map(
            refclkp  => refclkp(i),
            refclkn  => refclkn(i),
            refclk   => refclk(i),
            refclk_buf => refclk_buf(i)
        );
      end generate ibufds_gen;

      ibufds_ngen : if not is_refclk_used(i) generate
        refclk(i)      <= '0';
        refclk_odiv(i) <= '0';
        refclk_buf(i)  <= '0';
      end generate ibufds_ngen;

    end generate clk_gen;
    -----------------------------------------------------------------------------

    -----------------------------------------------------------------------------
    -- Monitoring 
    refclk_div_gen : if N_REFCLK /= 0 generate
      div : entity work.freq_ctr_div
        generic map(
          N_CLK => N_REFCLK
          )
        port map(
          clk    => refclk_buf,
          clkdiv => refclk_mon
          );
    end generate;

    refclk_div_ngen : if N_REFCLK = 0 generate
      refclk_mon <= (others => '0');
    end generate;

    -----------------------------------------------------------------------------


    -- Clock monitoring

    sel <= to_integer(unsigned(ctrl(0)(7 downto 3)));

    qplllock(31 downto N_REGION)  <= (others => '0');
    txclk_mon(31 downto N_REGION) <= (others => '0');
    rxclk_mon(31 downto N_REGION) <= (others => '0');

    clkmon(0)    <= '0' when (sel >= N_REFCLK or IO_REGION_SPEC(sel).io_refclk = -1) else refclk_mon(IO_REGION_SPEC(sel).io_refclk);
    clkmon(1)    <= txclk_mon(sel);
    clkmon(2)    <= rxclk_mon(sel);
    qplllock_sel <= qplllock(sel);

-- Inter-region chained signals

    process(clk_p)
    begin
      if rising_edge(clk_p) then
        rst_chain_a(0) <= rst_p;
        ttc_chain_a(0) <= ttc_cmd;
        l1a_chain_a(0) <= ttc_l1a;
        tmt_chain_a(0) <= tmt_sync;
      --cap_chain_a(0) <= cap_bus;
      end if;
    end process;

    process(clk40)
    begin
      if rising_edge(clk40) then
        lock <= lock_chain_b(N_REGION);
      end if;
    end process;

    lock_chain_a(0) <= '1';

-- Regions

    rgen : for i in 0 to N_REGION - 1 generate

      constant ih     : integer := 4 * i + 3;
      constant il     : integer := 4 * i;
      --signal dbus_out : daq_bus;
      signal ipbw_loc : ipb_wbus;
      signal ipbr_loc : ipb_rbus;

      signal ref_clk, alt_ref_clk : std_logic;

    begin

      dc : entity work.ipbus_dc_node
        generic map(
          I_SLV     => i,
          SEL_WIDTH => 5,
          PIPELINE  => (i = CROSS_REGION or i = N_REGION - 1)
          )
        port map(
          clk       => clk,
          rst       => rst,
          ipb_out   => ipbw_loc,
          ipb_in    => ipbr_loc,
          ipbdc_in  => ipbdc(i),
          ipbdc_out => ipbdc(i + 1)
          );

      clken_int(i) <= '1';


      -- Refclk association
      no_refclk_gen : if reg_has_refclk(i) generate
        ref_clk <= '0';
      end generate;

      refclk_gen : if not reg_has_refclk(i) generate
        ref_clk <= refclk(IO_REGION_SPEC(i).io_refclk);
      end generate;

      -- Alternate refclk association
      no_refclk_alt_gen : if reg_has_refclk_alt(i) generate
        alt_ref_clk <= '0';
      end generate;

      refclk_alt_gen : if not reg_has_refclk_alt(i) generate
        alt_ref_clk <= refclk(IO_REGION_SPEC(i).io_refclk_alt);
      end generate;

      region : entity work.emp_region
        generic map(
          INDEX => i
          )
        port map(
          clk          => clk,
          rst          => rst,
          ipb_in       => ipbw_loc,
          ipb_out      => ipbr_loc,
          board_id     => board_id,
          csel         => ctrl(0)(2 downto 0),
          clk_p        => clk_p,
          rst_in       => rst_chain_a(i),
          rst_out      => rst_chain_b(i + 1),
          ttc_cmd_in   => ttc_chain_a(i),
          ttc_cmd_out  => ttc_chain_b(i + 1),
          ttc_l1a_in   => l1a_chain_a(i),
          ttc_l1a_out  => l1a_chain_b(i + 1),
          tmt_sync_in  => tmt_chain_a(i),
          tmt_sync_out => tmt_chain_b(i + 1),
          lock_in      => lock_chain_a(i),
          lock_out     => lock_chain_b(i + 1),
          ctrs_out     => ctrs_int(i),
          rst_loc_out  => rst_int(i),
          --clken_out => clken_out(i),
          d            => d_int(ih downto il),
          q            => q_int(ih downto il),
          refclk       => ref_clk,
          refclk_alt   => alt_ref_clk,
          qplllock     => qplllock(i),
          txclk_mon    => txclk_mon(i),
          rxclk_mon    => rxclk_mon(i)
          );

      --end generate;

-- MAP X_b(x + 1) to X_a(x + 1)

      --rgen1 : for i in 0 to N_REGION - 1 generate
      -- Timing / DAQ signals routing
      pgen : if i = CROSS_REGION generate
        process(clk_p)
        begin
          if rising_edge(clk_p) then
            rst_chain_a(i + 1)  <= rst_chain_b(i + 1);
            ttc_chain_a(i + 1)  <= ttc_chain_b(i + 1);
            l1a_chain_a(i + 1)  <= l1a_chain_b(i + 1);
            tmt_chain_a(i + 1)  <= tmt_chain_b(i + 1);
            --cap_chain_a(i + 1)  <= cap_chain_b(i + 1);
            --daq_chain_a(i + 1)  <= daq_chain_b(i + 1);
            lock_chain_a(i + 1) <= lock_chain_b(i + 1);
          end if;
        end process;
      end generate;

      npgen : if i /= CROSS_REGION generate
        rst_chain_a(i + 1)  <= rst_chain_b(i + 1);
        ttc_chain_a(i + 1)  <= ttc_chain_b(i + 1);
        l1a_chain_a(i + 1)  <= l1a_chain_b(i + 1);
        tmt_chain_a(i + 1)  <= tmt_chain_b(i + 1);
        --cap_chain_a(i + 1)  <= cap_chain_b(i + 1);
        --daq_chain_a(i + 1)  <= daq_chain_b(i + 1);
        lock_chain_a(i + 1) <= lock_chain_b(i + 1);
      end generate;
      --end generate;


      --rgen2 : for i in 0 to N_REGION - 1 generate

      --  constant il : integer := 4 * i;
      --  constant ih : integer := il + 3;

      --begin
      d_int(ih downto il) <= d(ih downto il);
      q(ih downto il)     <= q_int(ih downto il);
      ctrs_out(i)         <= ctrs_int(i);
      rst_out(i)          <= rst_int(i);
      clken_out(i)        <= clken_int(i);
    end generate;

end rtl;
