-- mp7_counters_decl
--
-- Defines the array subtypes for distributed counters
--
-- Dave Newbold, September 2013

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.top_decl.all;
use work.mp7_brd_decl.all;

package mp7_ttc_decl is

	subtype ttc_cmd_t is std_logic_vector(7 downto 0);
	subtype bctr_t is std_logic_vector(11 downto 0);
	subtype pctr_t is std_logic_vector(2 downto 0);
	subtype octr_t is std_logic_vector(11 downto 0);
	subtype eoctr_t is std_logic_vector(31 downto 0);

	type ttc_cmd_array is array(natural range <>) of ttc_cmd_t;

	type ttc_stuff_t is
		record
			ttc_cmd: ttc_cmd_t;
			l1a: std_logic;
			bctr: bctr_t;
			pctr: pctr_t;
		end record;

	type ttc_stuff_array is array(natural range <>) of ttc_stuff_t;
	
	constant TTC_DEL: integer := 5;
	constant TTC_BC0_OFFSET: integer := 24; -- Do not screw with this unless you like wasting time
	constant TTC_BC0_BX: integer := LHC_BUNCH_COUNT-TTC_BC0_OFFSET-1; -- Do not screw with this unless you like wasting time
	constant TTC_N_BCMD: integer := 9;
	constant TTC_BCMD_BC0: ttc_cmd_t := X"01";
	constant TTC_BCMD_EC0: ttc_cmd_t := X"02";
	constant TTC_BCMD_RESYNC: ttc_cmd_t := X"04";
	constant TTC_BCMD_OC0: ttc_cmd_t := X"08";
	constant TTC_BCMD_TEST_SYNC: ttc_cmd_t := X"0c";
	constant TTC_BCMD_START: ttc_cmd_t := X"10";
	constant TTC_BCMD_STOP: ttc_cmd_t := X"14";
	constant TTC_BCMD_TEST_ENABLE: ttc_cmd_t := X"24";
	constant TTC_BCMD_HARD_RESET: ttc_cmd_t := X"4c";	
	constant TTC_BCMD_NULL: ttc_cmd_t := X"00";
	constant TTC_STUFF_NULL: ttc_stuff_t := ((others => '0'), '0', (others => '0'), (others => '0'));

	constant N_RULES: integer := 4;
	
	type trig_rule is
		record
			window_del: integer;
			maxtrig: integer;
		end record;
		
	type trig_rules_t is array(0 to N_RULES - 1) of trig_rule;
	
	constant TRIG_RULES: trig_rules_t := (
		(2, 1), -- window size 3
		(22, 2), -- window size 25
		(75, 3), -- window size 100
		(140, 4) -- window size 240
	);
	
	function ttc_chain_del(i: integer) return integer;
	
	subtype tmt_sync_t is std_logic_vector(0 downto 0);
	type tmt_sync_array is array(natural range <>) of tmt_sync_t;
	
end mp7_ttc_decl;

package body mp7_ttc_decl is

	function ttc_chain_del(i: integer) return integer is
		variable delay: integer;
	begin
		delay := (TTC_DEL * CLOCK_RATIO) - 2 - i; -- 2 compensates for pipeline registers between TTC block and first region
		if i > CROSS_REGION then
			return(delay - 1);
		else
			return(delay);
		end if;
	end function ttc_chain_del;
	
end package body mp7_ttc_decl;
