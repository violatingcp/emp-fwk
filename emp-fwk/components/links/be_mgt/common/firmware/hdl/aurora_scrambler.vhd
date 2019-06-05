----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/13/2018 06:11:55 PM
-- Design Name: 
-- Module Name: aurora_scrambler - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity aurora_scrambler is
        Generic( DATA_WIDTH : natural := 64 );
        Port (
         txdata_i       : IN STD_LOGIC_VECTOR(0 to DATA_WIDTH - 1);
         tx_datavalid_i : IN STD_LOGIC;
         scrambled_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
         txusrclk2_i    : IN STD_LOGIC;
         reset_all_i    : IN STD_LOGIC;
         txheader_d     : out STD_LOGIC_VECTOR(5 DOWNTO 0);
         txheader_i     : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
         txsequence_d   : out std_logic_vector(6 downto 0);
         txsequence_i   : in std_logic_vector(6 downto 0)   
         );
 
end aurora_scrambler;

architecture Behavioral of aurora_scrambler is

Component aurora_64b66b_0_SCRAMBLER_64B66B
    Port (
             UNSCRAMBLED_DATA_IN : IN STD_LOGIC_VECTOR(0 to DATA_WIDTH - 1);
             DATA_VALID_IN       : IN STD_LOGIC;
             SCRAMBLED_DATA_OUT  : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
             USER_CLK            : IN STD_LOGIC;
             SYSTEM_RESET        : IN STD_LOGIC
             );
End Component;

begin

    process(txusrclk2_i,reset_all_i)
    begin
        if rising_edge(txusrclk2_i) then
            txheader_d   <= txheader_i;
            txsequence_d <= txsequence_i;
        end if;
    end process;


scrambler: aurora_64b66b_0_SCRAMBLER_64B66B
        Port Map(
                 UNSCRAMBLED_DATA_IN => txdata_i,
                 DATA_VALID_IN       => tx_datavalid_i,
                 SCRAMBLED_DATA_OUT  => scrambled_data,
                 USER_CLK            => txusrclk2_i,
                 SYSTEM_RESET        => reset_all_i
                 ); 

end Behavioral;
