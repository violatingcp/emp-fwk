----------------------------------------------------------------------------------
-- Company: UOI - CERN
-- Engineer: Stavros Mallios
-- Create Date: 17/07/2017
-- Target Devices: KCU105 
-- Tool Versions: Vivado 2016.2
-- Description: based on the example design provided by xilinx 

-- =====================================================================================================================
-- This example design stimulus module generates PRBS31 data at the appropriate parallel data width for the transmitter,
-- along with any sideband signaling necessary for the selected data encoding. The stimulus provided by this module
-- instance drives a single transceiver channel for data transmission demonstration purposes.
-- =====================================================================================================================
-- =====================================================================================================================
-- |  Author  |   Date   |           Comments          |
-- | smallios | 19/07/17 | Add flag to measure latency |
-- |          |          |                             |
-- =====================================================================================================================


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;



entity ultrascale_fifo_stimulus_64b66b is
    GENERIC (SELECT_PATTERN : STRING);
	Port (
  			reset 	   : in STD_LOGIC;
  			clk        : in STD_LOGIC;
  			enable 	   : in STD_LOGIC;
  			txdata_out : out STD_LOGIC_VECTOR(63 DOWNTO 0)
          );

end ultrascale_fifo_stimulus_64b66b;


architecture RTL of ultrascale_fifo_stimulus_64b66b is

component reset_synchronizer
	Port(
			clk_in  : in STD_LOGIC;
    		rst_in  : in STD_LOGIC;
    		rst_out : out STD_LOGIC
		);
end component;

component gtwizard_ultrascale_0_prbs_any
	generic (
            CHK_MODE    : INTEGER := 0;
    		INV_PATTERN : INTEGER := 1;
    		POLY_LENGHT : INTEGER := 31;
    		POLY_TAP    : INTEGER := 28;
    		NBITS       : INTEGER := 64 
		);
	port (
    		RST      : in  STD_LOGIC;
    		CLK      : in  STD_LOGIC;
    		DATA_IN  : in  STD_LOGIC_VECTOR(63 DOWNTO 0);
    		EN       : in  STD_LOGIC; 
    		DATA_OUT : out STD_LOGIC_VECTOR(63 DOWNTO 0)
		);
end component;


FUNCTION bit_reverse(s1:std_logic_vector) return std_logic_vector is 
	variable rr : std_logic_vector(s1'high downto s1'low); 
begin 
	for ii in s1'high downto s1'low loop 
  		rr(ii) := s1(s1'high-ii); 
	end loop; 
	return rr; 
end bit_reverse; 

signal reset_int  : STD_LOGIC;
signal reset_sync : STD_LOGIC;
signal txdata_int : STD_LOGIC_VECTOR (63 DOWNTO 0);
signal prbs_gen_enable_int : STD_LOGIC;
signal counter : STD_LOGIC_VECTOR (7 DOWNTO 0);
signal txsequence_out_i : STD_LOGIC_VECTOR (6 DOWNTO 0);
signal txdata_int_i : STD_LOGIC_VECTOR (63 DOWNTO 0);



BEGIN

-- attribute DONT_TOUCH : string;
-- attribute DONT_TOUCH of example_stimulus_reset_synchronizer_inst : label is "true";
-------------------------------------------------------------------------------------------------------------------
---- Reset synchronizer
-------------------------------------------------------------------------------------------------------------------

  -- Synchronize the example stimulus reset condition into the txusrclk2 domain
reset_int <= reset OR (NOT enable);

example_stimulus_reset_synchronizer_inst: reset_synchronizer 
	PORT MAP(
    clk_in 	=> clk,
    rst_in 	=> reset_int,
    rst_out	=> reset_sync
  );


 -------------------------------------------------------------------------------------------------------------
 --Data transmission declarations and assignments
 -------------------------------------------------------------------------------------------------------------

   --Bit-reverse the txdata_out assignment to accomodate any differences between transmitter and receiver user interface
   --data widths, since gearbox modes transmit data MSb first.
txdata_out <= txdata_int;--bit_reverse(txdata_int);


-- Generate user pattern data
gen_user: if SELECT_PATTERN = "USER" generate 
    process(clk,reset_sync,enable)
       begin
          if(rising_edge(clk)) then
            if reset_sync='1' then
                counter <= x"00";
            else
                if enable = '0' then
                -- do nothing
                else 
                   counter <= counter + 1;
                end if;
            end if;
          end if;
       end process;
    -- trigger pattern
    txdata_int <=  x"55555555555555" & counter; --when user_pattern_flag_i = '1' else txdata_int_i; counter & x"AAAAAAAAAAAAAA";  
end generate;


-- Generate code to send raw prbs data
gen_prbs: if SELECT_PATTERN = "PRBS" generate 
  ---------------------------------------------------------------------------------------------------------------------
-- PRBS generator block
---------------------------------------------------------------------------------------------------------------------

 --The prbs_any block, described in Xilinx Application Note 884 (XAPP884), "An Attribute-Programmable PRBS Generator
 --and Checker", generates or checks a parameterizable PRBS sequence. Instantiate and parameterize a prbs_any block
 --to generate a PRBS31 sequence with parallel data sized to the transmitter user data width.
prbs_any_gen_inst : gtwizard_ultrascale_0_prbs_any
  generic map (
      CHK_MODE    => 0,
      INV_PATTERN => 1,
      POLY_LENGHT => 31,
      POLY_TAP    => 28,
      NBITS       => 64 ) 
  port map (
      RST      => reset_sync,
      CLK      => clk,
      DATA_IN  => (OTHERS=>'0'),
      EN       => enable,
      DATA_OUT => txdata_int_i
);

txdata_int <= txdata_int_i;

end generate; 
 
end RTL;
