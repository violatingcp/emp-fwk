-- emp_region
--
-- Wrapper for the MGTs and buffers belonging to one clock region
--
-- Dave Newbold, June 2014

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.mp7_ttc_decl.all;
--use work.mp7_readout_decl.all;
use work.ipbus_decode_emp_region.all;
use work.drp_decl.all;

use work.emp_data_types.all;
use work.emp_framework_decl.all;
use work.emp_project_decl.all;
use work.emp_device_decl.all;
use work.emp_device_types.all;

-------------------------------------------------------------------------------
entity emp_region is
  generic(
    INDEX : integer
    );
  port(
    clk          : in  std_logic;       -- ipbus clock, rst, bus
    rst          : in  std_logic;
    ipb_in       : in  ipb_wbus;
    ipb_out      : out ipb_rbus;
    board_id     : in  std_logic_vector(31 downto 0);
    csel         : in  std_logic_vector(2 downto 0);  -- MGT channel select
    clk_p        : in  std_logic;       -- parallel data clock & rst
    rst_in       : in  std_logic;       -- reset chain input
    rst_out      : out std_logic;       -- reset chain output
    ttc_cmd_in   : in  ttc_cmd_t;       -- TTC cmd chain
    ttc_cmd_out  : out ttc_cmd_t;
    ttc_l1a_in   : in  std_logic;
    ttc_l1a_out  : out std_logic;
    tmt_sync_in  : in  tmt_sync_t;      -- TMT sync
    tmt_sync_out : out tmt_sync_t;
    lock_in      : in  std_logic;       -- bunch counter lock chain
    lock_out     : out std_logic;
    ctrs_out     : out ttc_stuff_t;     -- TTC counters for use in logic
    rst_loc_out  : out std_logic;
    d            : in  ldata(3 downto 0);  -- parallel data to buffers
    q            : out ldata(3 downto 0);  -- parallel data from buffers
    refclk       : in  std_logic;       -- MGT refclk & IO
    refclk_alt   : in  std_logic;       -- MGT refclk & IO
    qplllock     : out std_logic;       -- QPLL lock flag from MGT
    txclk_mon    : out std_logic;  -- Divided monitoring clocks from selected MGT channel
    rxclk_mon    : out std_logic
    );

end emp_region;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
architecture rtl of emp_region is

  attribute DONT_TOUCH        : string;
  attribute DONT_TOUCH of rtl : architecture is "yes";

  signal ipbw   : ipb_wbus_array(N_SLAVES - 1 downto 0);
  signal ipbr   : ipb_rbus_array(N_SLAVES - 1 downto 0);
  signal ipbw_b : ipb_wbus_array(7 downto 0);
  signal ipbr_b : ipb_rbus_array(7 downto 0);
  signal ipbw_a : ipb_wbus_array(3 downto 0);
  signal ipbr_a : ipb_rbus_array(3 downto 0);

  signal ttc_cmd_i, ttc_cmd                                                    : ttc_cmd_t;
  signal tmt_sync_i, tmt_sync                                                  : tmt_sync_t;
  signal rst_i, rst_p, lock, bctr_lock, bc0, oc0, resync, go, bmax, l1a, l1a_i : std_logic;
  --signal cap_bus_i, cap_bus                                                    : daq_cap_bus;
  signal pctr                                                                  : pctr_t;
  signal bctr                                                                  : bctr_t;
  signal octr                                                                  : octr_t;

  signal mgt_d, mgt_q, mgt_d_r, q_r, q_payload, q_buf, d_r : ldata(3 downto 0);

  signal drp_out, drp_out_com : drp_rbus;
  signal drp_in, drp_in_com   : drp_wbus;
  signal drp_in_bus           : drp_wbus_array(3 downto 0);
  signal drp_out_bus          : drp_rbus_array(3 downto 0);

  signal buf_rst, buf_inc, buf_dec, align_marker : std_logic_vector(3 downto 0);
  signal rxclk_mon_q                             : std_logic_vector(3 downto 0);

  signal daq_act   : std_logic;
  --signal dbus_chan : daq_bus_array(8 downto 0);
  --signal dbus_out  : daq_bus;

begin

-- ipbus address decode

  fabric : entity work.ipbus_fabric_sel
    generic map(
      NSLV      => N_SLAVES,
      SEL_WIDTH => IPBUS_SEL_WIDTH)
    port map(
      ipb_in          => ipb_in,
      ipb_out         => ipb_out,
      sel             => ipbus_sel_emp_region(ipb_in.ipb_addr),
      ipb_to_slaves   => ipbw,
      ipb_from_slaves => ipbr
      );

-- TTC signals

  process(clk_p)
  begin
    if rising_edge(clk_p) then
      ttc_cmd_i  <= ttc_cmd_in;
      tmt_sync_i <= tmt_sync_in;
      l1a_i      <= ttc_l1a_in;
      rst_i      <= rst_in;
      --cap_bus_i  <= cap_bus_in;
      lock       <= lock_in and bctr_lock;
    end if;
  end process;

  ttc_delay : entity work.del_array
    generic map(
      DWIDTH => ttc_cmd_t'length,
      DELAY  => ttc_chain_del(INDEX)
      )
    port map(
      clk => clk_p,
      d   => ttc_cmd_i,
      q   => ttc_cmd
      );

  l1a_delay : entity work.del_array
    generic map(
      DWIDTH => 1,
      DELAY  => ttc_chain_del(INDEX)
      )
    port map(
      clk  => clk_p,
      d(0) => l1a_i,
      q(0) => l1a
      );

  tmt_delay : entity work.del_array
    generic map(
      DWIDTH => tmt_sync_t'length,
      DELAY  => ttc_chain_del(INDEX)
      )
    port map(
      clk => clk_p,
      d   => tmt_sync_i,
      q   => tmt_sync
      );

  rst_delay : entity work.del_array
    generic map(
      DWIDTH => 1,
      DELAY  => ttc_chain_del(INDEX)
      )
    port map(
      clk  => clk_p,
      d(0) => rst_i,
      q(0) => rst_p
      );

  bc0    <= '1' when ttc_cmd = TTC_BCMD_BC0       else '0';
  oc0    <= '1' when ttc_cmd = TTC_BCMD_OC0       else '0';
  resync <= '1' when ttc_cmd = TTC_BCMD_RESYNC    else '0';
  go     <= '1' when ttc_cmd = TTC_BCMD_TEST_SYNC else '0';

-- Bunch counter

  bunch : entity work.bunch_ctr
    generic map(
      CLOCK_RATIO     => CLOCK_RATIO,
      CLK_DIV         => CLOCK_RATIO,
      OCTR_WIDTH      => octr'length,
      LHC_BUNCH_COUNT => LHC_BUNCH_COUNT,
      BC0_BX          => TTC_BC0_BX
      )
    port map(
      clk  => clk_p,
      rst  => rst_p,
      clr  => '0',
      bc0  => bc0,
      oc0  => oc0,
      bctr => bctr,
      pctr => pctr,
      bmax => bmax,
      octr => octr,
      lock => bctr_lock
      );

-- Outputs to local logic       

  ctrs_out.ttc_cmd <= ttc_cmd;
  ctrs_out.l1a     <= l1a;
  ctrs_out.bctr    <= bctr;
  ctrs_out.pctr    <= pctr;
  rst_loc_out      <= rst_p;

-- MGT DRP decode

  drp_gen : if REGION_CONF(INDEX).mgt_i_kind /= no_mgt generate

    drp : entity work.ipbus_drp_bridge
      port map(
        clk     => clk,
        rst     => rst,
        ipb_in  => ipbw(N_SLV_DRP),
        ipb_out => ipbr(N_SLV_DRP),
        drp_out => drp_in,
        drp_in  => drp_out
        );

    drp_mux : entity work.drp_mux
      generic map(
        N_DRP => 4
        )
      port map(
        sel         => csel(2 downto 1),
        drp_in      => drp_in,
        drp_out     => drp_out,
        slv_drp_in  => drp_out_bus,
        slv_drp_out => drp_in_bus
        );

    drp_com : entity work.ipbus_drp_bridge
      port map(
        clk     => clk,
        rst     => rst,
        ipb_in  => ipbw(N_SLV_DRP_COM),
        ipb_out => ipbr(N_SLV_DRP_COM),
        drp_out => drp_in_com,
        drp_in  => drp_out_com
        );

  end generate;

  assert 
    -- Either a tracnsciever-equipped region
    IO_GT_REGIONS(INDEX) = io_gt or (
      -- or both mgts need to be null
      REGION_CONF(INDEX).mgt_i_kind = no_mgt and
      REGION_CONF(INDEX).mgt_o_kind = no_mgt
    )
    report 
      "Region " & integer'image(INDEX) & " - " &
      "Cannot allocate MGTs in current region: no physical GT interface is present. " & lf &
      " - mgt_i_kind: '" & mgt_kind_t'image(REGION_CONF(INDEX).mgt_i_kind) & "', " & lf &
      " - mgt_o_kind: '" & mgt_kind_t'image(REGION_CONF(INDEX).mgt_o_kind) & "', " & lf &
      " - io_gt_kind: '" & io_gt_kind_t'image(IO_GT_REGIONS(INDEX)) & "'"
    severity failure;

-- Check Rx & Tx MGT & CRC type match. 
  assert 
    REGION_CONF(INDEX).mgt_i_kind = REGION_CONF(INDEX).mgt_o_kind 
    report 
      "Region " & integer'image(INDEX) & " - " &
      "The use of different Tx & Rx MGTs is not supported yet"
    severity failure;
  assert 
    REGION_CONF(INDEX).chk_i_kind = REGION_CONF(INDEX).chk_o_kind 
    report 
      "Region " & integer'image(INDEX) & " - " &
      "The use of different Tx & Rx CRCs/Checksums is not supported yet" 
    severity failure;


  ndrp_gen : if REGION_CONF(INDEX).mgt_i_kind = no_mgt generate

    ipbr(N_SLV_DRP)     <= IPB_RBUS_NULL;
    ipbr(N_SLV_DRP_COM) <= IPB_RBUS_NULL;

  end generate;


-- No MGT

  mgt_gen_null : if REGION_CONF(INDEX).mgt_i_kind = no_mgt generate

    mgt_q           <= (others => LWORD_NULL);
    ipbr(N_SLV_MGT) <= IPB_RBUS_NULL;
    qplllock        <= '0';
    align_marker    <= (others => '1');
    txclk_mon       <= '0';
    rxclk_mon       <= '0';

  end generate;

-- Buffers

  bgen : if REGION_CONF(INDEX).buf_i_kind = buf or REGION_CONF(INDEX).buf_o_kind = buf generate

-- ipbus decode

    fabric_buf : entity work.ipbus_fabric_sel
      generic map(
        NSLV      => 8,
        SEL_WIDTH => 3
        )
      port map(
        sel             => csel,
        ipb_in          => ipbw(N_SLV_BUFFER),
        ipb_out         => ipbr(N_SLV_BUFFER),
        ipb_to_slaves   => ipbw_b,
        ipb_from_slaves => ipbr_b
        );

-- Channel buffers

    buf_gen : for j in 0 to 7 generate

      constant id                                             : integer := 8 * INDEX + j;
      constant iw                                             : integer := j / 2;
      --signal rx_dbus_in, rx_dbus_out, tx_dbus_in, tx_dbus_out : daq_bus;
      signal db, qb                                           : lword;
      --signal dbus_in, dbus_out                                : daq_bus;

    begin

      cbuf_gen : if (REGION_CONF(INDEX).buf_i_kind = buf and j rem 2 = 0) or (REGION_CONF(INDEX).buf_o_kind = buf and j rem 2 = 1) generate

        buf : entity work.emp_chan_buffer
          generic map (
            INDEX => id
            )
          port map(
            clk         => clk,
            rst         => rst,
            ipb_in      => ipbw_b(j),
            ipb_out     => ipbr_b(j),
            clk_p       => clk_p,
            rst_p       => rst_p,
            orb         => octr,
            bctr        => bctr,
            pctr        => pctr,
            bmax        => bmax,
            go          => go,
            resync      => resync,
            d           => db,
            q           => qb
            );

      end generate;

      cbuf_ngen : if (REGION_CONF(INDEX).buf_i_kind = no_buf and j rem 2 = 0) or (REGION_CONF(INDEX).buf_o_kind = no_buf and j rem 2 = 1) generate

        ipbr_b(j) <= IPB_RBUS_NULL;
        qb        <= LWORD_NULL;

      end generate;


      rxgen : if j rem 2 = 0 generate   -- rx buffer

        db      <= mgt_q(iw);
        q_r(iw) <= qb;

      end generate;

      txgen : if j rem 2 = 1 generate   -- tx buffer

        db          <= q_buf(iw);
        mgt_d_r(iw) <= qb;

      end generate;

    end generate;

  end generate;

  nbgen : if REGION_CONF(INDEX).buf_i_kind = no_buf and REGION_CONF(INDEX).buf_o_kind = no_buf generate

    ipbr(N_SLV_BUFFER) <= IPB_RBUS_NULL;

    -- Bypass buffers.  Not sure MP7 will function in this manner.
    q_r     <= mgt_q;
    mgt_d_r <= q_buf;

  end generate;

  ttc_cmd_out  <= ttc_cmd_i;
  ttc_l1a_out  <= l1a_i;
  tmt_sync_out <= tmt_sync_i;
  rst_out      <= rst_i;
  lock_out     <= lock;

-- Formatter

  --fgen_tdr : if REGION_CONF(INDEX).fmt_kind = tdr generate

  --  formatter : entity work.mp7_formatter_tdrproto
  --    port map(
  --      clk       => clk,
  --      rst       => rst,
  --      ipb_in    => ipbw(N_SLV_FORMATTER_CSR),
  --      ipb_out   => ipbr(N_SLV_FORMATTER_CSR),
  --      board_id  => board_id(7 downto 0),
  --      clk_p     => clk_p,
  --      rst_p     => rst_p,
  --      bctr      => bctr,
  --      tmt_sync  => tmt_sync,
  --      d_buf     => q_r,
  --      q_payload => q_payload,
  --      d_payload => d_r,
  --      q_buf     => q_buf
  --      );

  --end generate;

  --fgen_demux : if REGION_CONF(INDEX).fmt_kind = demux generate

  --  formatter : entity work.mp7_formatter_demux
  --    port map(
  --      clk       => clk,
  --      rst       => rst,
  --      ipb_in    => ipbw(N_SLV_FORMATTER_CSR),
  --      ipb_out   => ipbr(N_SLV_FORMATTER_CSR),
  --      board_id  => board_id(7 downto 0),
  --      clk_p     => clk_p,
  --      rst_p     => rst_p,
  --      bctr      => bctr,
  --      pctr      => pctr,
  --      d_buf     => q_r,
  --      q_payload => q_payload,
  --      d_payload => d_r,
  --      q_buf     => q_buf
  --      );

  --end generate;

  --fgen_s1 : if REGION_CONF(INDEX).fmt_kind = s1 generate

  --  formatter : entity work.mp7_formatter_s1proto
  --    port map(
  --      clk       => clk,
  --      rst       => rst,
  --      ipb_in    => ipbw(N_SLV_FORMATTER_CSR),
  --      ipb_out   => ipbr(N_SLV_FORMATTER_CSR),
  --      board_id  => board_id(7 downto 0),
  --      clk_p     => clk_p,
  --      rst_p     => rst_p,
  --      bctr      => bctr,
  --      d_buf     => q_r,
  --      q_payload => q_payload,
  --      d_payload => d_r,
  --      q_buf     => q_buf
  --      );

  --end generate;

  --fgen_m_pkt : if REGION_CONF(INDEX).fmt_kind = m_pkt generate

  --  formatter : entity work.mp7_formatter_multi_pkt
  --    port map(
  --      clk       => clk,
  --      rst       => rst,
  --      ipb_in    => ipbw(N_SLV_FORMATTER_CSR),
  --      ipb_out   => ipbr(N_SLV_FORMATTER_CSR),
  --      board_id  => board_id(7 downto 0),
  --      clk_p     => clk_p,
  --      rst_p     => rst_p,
  --      bctr      => bctr,
  --      d_buf     => q_r,
  --      q_payload => q_payload,
  --      d_payload => d_r,
  --      q_buf     => q_buf
  --      );

  --end generate;

  nfgen : if REGION_CONF(INDEX).fmt_kind = no_fmt generate

    ipbr(N_SLV_FORMATTER_CSR) <= IPB_RBUS_NULL;
    q_payload                 <= q_r;
    q_buf                     <= d_r;

  end generate;

-- Data path pipelining

  process(clk_p)
  begin
    if rising_edge(clk_p) then
      mgt_d <= mgt_d_r;
      q     <= q_payload;
      d_r   <= d;
    end if;
  end process;

-- Alignment monitor

  mon_gen : if REGION_CONF(INDEX).mgt_i_kind /= no_mgt generate

    fabric_align : entity work.ipbus_fabric_sel
      generic map(
        NSLV      => 4,
        SEL_WIDTH => 2
        )
      port map(
        sel             => csel(2 downto 1),
        ipb_in          => ipbw(N_SLV_ALIGN),
        ipb_out         => ipbr(N_SLV_ALIGN),
        ipb_to_slaves   => ipbw_a,
        ipb_from_slaves => ipbr_a
        );

    align_gen : for i in 3 downto 0 generate

      signal align_ctrl : std_logic_vector(3 downto 0);

    begin

      align_mon : entity work.align_mon
        port map(
          clk        => clk,
          rst        => rst,
          ipb_in     => ipbw_a(i),
          ipb_out    => ipbr_a(i),
          clk_p      => clk_p,
          rst_p      => rst_p,
          bctr       => bctr,
          pctr       => pctr,
          sig        => align_marker(i),
          align_ctrl => align_ctrl
          );

      process(clk_p)
      begin
        if rising_edge(clk_p) then
          buf_rst(i) <= align_ctrl(0);
          buf_inc(i) <= align_ctrl(1);
          buf_dec(i) <= align_ctrl(2);
        end if;
      end process;

    end generate;

  end generate;

  mon_ngen : if REGION_CONF(INDEX).mgt_i_kind = no_mgt generate

    ipbr(N_SLV_ALIGN) <= IPB_RBUS_NULL;

  end generate;

end rtl;
-------------------------------------------------------------------------------

