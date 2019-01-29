-- null_algo
--
-- Do-nothing top level algo for testing
--
-- Dave Newbold, July 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.emp_data_types.all;
use work.top_decl.all;

use work.emp_device_decl.all;
use work.mp7_ttc_decl.all;

entity emp_payload is
	port(
		clk: in std_logic; -- ipbus signals
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk_payload: in std_logic_vector(2 downto 0);
		rst_payload: in std_logic_vector(2 downto 0);
		clk_p: in std_logic; -- data clock
		rst_loc: in std_logic_vector(N_REGION - 1 downto 0);
		clken_loc: in std_logic_vector(N_REGION - 1 downto 0);
		ctrs: in ttc_stuff_array;
		bc0: out std_logic;
		d: in ldata(4 * N_REGION - 1 downto 0); -- data in
		q: out ldata(4 * N_REGION - 1 downto 0); -- data out
		gpio: out std_logic_vector(29 downto 0); -- IO to mezzanine connector
		gpio_en: out std_logic_vector(29 downto 0) -- IO to mezzanine connector (three-state enables)
	);
		
end emp_payload;

architecture rtl of emp_payload is
	
	type dr_t is array(PAYLOAD_LATENCY downto 0) of ldata(3 downto 0);

begin

	ipb_out <= IPB_RBUS_NULL;

	gen: for i in N_REGION - 1 downto 0 generate
	
		constant ich: integer := i * 4 + 3;
		constant icl: integer := i * 4;
		signal dr: dr_t;
		
		attribute SHREG_EXTRACT: string;
		attribute SHREG_EXTRACT of dr: signal is "no"; -- Don't absorb FFs into shreg

	begin
	
		dr(0) <= d(ich downto icl);
	
		process(clk_p) -- Mother of all shift registers
		begin
			if rising_edge(clk_p) then
				dr(PAYLOAD_LATENCY downto 1) <= dr(PAYLOAD_LATENCY - 1 downto 0);
			end if;
		end process;

		q(ich downto icl) <= dr(PAYLOAD_LATENCY);
	
	end generate;
	
	bc0 <= '0';
	
	gpio <= (others => '0');
	gpio_en <= (others => '0');

end rtl;
