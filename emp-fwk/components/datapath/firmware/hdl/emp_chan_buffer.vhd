-- emp_chan_buffer
--
-- Latency / cap / playback & derandomiser buffers for one serdes channel (tx or tx)
--
-- Note that there is one stage of data pipelining in this block
--
-- ctrl(1 downto 0): buffer mode: 0: latency buf; 1: capture; 2: play once; 3: play repeat
-- ctrl(3 downto 2): data source: 0: input data; 1: buffer playback; 2: pattern gen; 3: zeroes
-- data_ctrl(1 downto 0): playback strobe source: 0: input data; 1: buffer; 2: pattern gen; 3: always '1'
--
-- Dave Newbold, March 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.emp_data_types.all;
--use work.mp7_readout_decl.all;
use work.mp7_ttc_decl.all;
use work.ipbus_decode_emp_chan_buffer.all;
use work.top_decl.all;

entity emp_chan_buffer is
	generic(
		INDEX: integer
	);
	port(
		clk: in std_logic; -- ipbus control signals
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk_p: in std_logic; -- parallel data clock & reset
		rst_p: in std_logic;
		orb: in std_logic_vector(11 downto 0); -- orbit counter
		bctr: in std_logic_vector(11 downto 0); -- bunch counter signals
		pctr: in std_logic_vector(2 downto 0);
		bmax: in std_logic;
		go: in std_logic; -- synchronisation signals from TTC
		resync: in std_logic;
		d: in lword; -- input & output data
		q: out lword
	);

end emp_chan_buffer;

architecture rtl of emp_chan_buffer is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	
	signal mode, datasrc, stbsrc: std_logic_vector(1 downto 0);

	signal ctrl: ipb_reg_v(1 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal bsel: integer range DAQ_N_BANKS - 1 downto 0;
	
	signal buf_rst, last_word, trig_word, trig_word_d, v_play, v_cap, buf_zero: std_logic;
	signal actr: unsigned(LB_ADDR_WIDTH - 1 downto 0);
	signal buf_addr: std_logic_vector(LB_ADDR_WIDTH - 1 downto 0);
	signal buf_we, buf_re_adv, buf_re, go_pend, cap_done, cap_orb: std_logic;
	
	signal qs: lword;
	signal buf_d, buf_q:std_logic_vector(71 downto 0);
	signal q_valid_i, q_valid_d: std_logic;
	
	signal dr_we: std_logic;
	signal dr_raddr, dr_waddr: std_logic_vector(DR_ADDR_WIDTH - 1 downto 0);
	signal dr_data: lword;
	 
begin

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
    generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH)
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_emp_chan_buffer(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- Control register

	ctrlreg: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 2,
			N_STAT => 1
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl,
			qmask => (X"0FFFFFFF", X"000F3FFF")
		);

	stat(0)(0) <= '0';
	stat(0)(1) <= cap_done;
	stat(0)(31 downto 2) <= (others => '0');
	
	mode <= ctrl(0)(1 downto 0);
	datasrc <= ctrl(0)(3 downto 2);
	stbsrc <= ctrl(0)(5 downto 4);

-- Buffer sync logic

	trig_word <= '1' when bctr = ctrl(1)(15 downto 4) and pctr = ctrl(1)(2 downto 0) else '0';
	last_word <= '1' when actr = unsigned(ctrl(1)(27 downto 16)) else '0';

	buf_rst <= resync or rst_p;

	process(clk_p)
	begin
		if rising_edge(clk_p) then
			trig_word_d <= trig_word;
			v_play <= ((v_play and not last_word) or trig_word) and not buf_rst;
			v_cap <= ((v_cap and not last_word) or trig_word_d) and not buf_rst;
		end if;
	end process;
	
-- Address counter

	with mode select buf_zero <=
		buf_rst when "00", -- latency mode
		trig_word_d when "01", -- capture mode
		trig_word when others; -- playback modes
		
	process(clk_p)
	begin
		if rising_edge(clk_p) then
			if buf_zero = '1' or last_word = '1' then
				actr <= (others => '0');
			elsif (buf_re_adv or buf_we) = '1' then
				actr <= actr + 1;
			end if;
		end if;
	end process;
	
	buf_addr <= std_logic_vector(actr);
	
-- Read / write enable

	process(clk_p)
	begin
		if rising_edge(clk_p) then
			go_pend <= (go_pend or go) and not (cap_orb or buf_rst);
			cap_done <= (cap_done or (cap_orb and last_word)) and not (go or buf_rst);
			buf_re <= buf_re_adv;

			if buf_rst = '1' then
				cap_orb <= '0';
			elsif trig_word = '1' then
				cap_orb <= (cap_orb or go_pend) and not cap_done;
			end if;
		end if;
	end process;

	-- Buffer write enable
	buf_we <= ((cap_orb and v_cap) or not mode(0)) and not mode(1) and (d.strobe or ctrl(0)(7));
	-- Buffer read enable-precursor. Precedes buf_re by once clock cycle and drives the buffer address counter
	buf_re_adv <= (v_play or mode(0)) and mode(1);
		
	buf_d <= d.strobe & d.valid & d.data(63 downto 48) & "00" & d.data(47 downto 32) & "00" & d.data(31 downto 16) & "00" & d.data(15 downto 0);

	rxbuf: entity work.ipbus_ported_dpram72
		generic map(
			ADDR_WIDTH => LB_ADDR_WIDTH
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_BUFFER),
			ipb_out => ipbr(N_SLV_BUFFER),
			rclk => clk_p,
			we => buf_we,
			d => buf_d,
			q => buf_q,
			addr => buf_addr
		);

 	qs.data <= buf_q(69 downto 54) & buf_q(51 downto 36) & buf_q(33 downto 18) & buf_q(15 downto 0);
	qs.valid <= buf_q(70);
	qs.strobe <= buf_q(71);
	qs.start <= '0';
	
-- Data source select
	
	with datasrc select q.data <=
		d.data when "00", -- input data source
		qs.data when "01", -- buffer source
		orb & bctr & std_logic_vector(to_unsigned(INDEX, 40)) when "10", -- pattern source
		(others => '0') when others; -- zeroes source
	
	with datasrc select q_valid_i <=
		d.valid when "00", -- input data source
		qs.valid and buf_re when "01", -- buffer source
		buf_re and not ctrl(0)(6) when others; -- other sources

	with stbsrc select q.strobe <=
		d.strobe when "00", -- input data strobe
		qs.strobe and buf_re when "01", -- strobe from buffer content
		ctrl(0)(8 + to_integer(unsigned(pctr))) when "10", -- pattern strobe
		'1' when others;
		
	q.valid <= q_valid_i;
	q.start <= q_valid_i and not q_valid_d;
	
	process(clk_p)
	begin
		if rising_edge(clk_p) then
			q_valid_d <= q_valid_i;
		end if;
	end process;

end rtl;
