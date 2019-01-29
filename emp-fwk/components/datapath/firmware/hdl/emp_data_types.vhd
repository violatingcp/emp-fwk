-- Defines the fundamental data type for the MP7 parallel data path
--
-- Dave Newbold, 2013

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package emp_data_types is

	constant LWORD_WIDTH: integer := 64;

	type lword is
		record
			data: std_logic_vector(LWORD_WIDTH - 1 downto 0);
			valid: std_logic;
			start: std_logic;
			strobe: std_logic;
		end record;
		
	type ldata is array(natural range <>) of lword;
	
	constant LWORD_NULL: lword := ((others => '0'), '0', '0', '0');
	constant LDATA_NULL: ldata(0 downto 0) := (0 => LWORD_NULL);
	
end emp_data_types;

