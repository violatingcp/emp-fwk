----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/22/2018 01:02:58 PM
-- Design Name: 
-- Module Name: reset_synchronizer - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity reset_synchronizer is
    Port ( clk_in : in STD_LOGIC;
           rst_in : in STD_LOGIC;
           rst_out : out STD_LOGIC);
end reset_synchronizer;


ARCHITECTURE Behavioral OF reset_synchronizer IS

signal rst_in_meta : STD_LOGIC;
signal rst_in_sync1 : STD_LOGIC;
signal rst_in_sync2 : STD_LOGIC;
signal rst_in_sync3 : STD_LOGIC;
signal rst_in_out : STD_LOGIC;

attribute ASYNC_REG : string;
attribute ASYNC_REG of rst_in_meta : signal is "TRUE";
attribute ASYNC_REG of rst_in_sync1 : signal is "TRUE";
attribute ASYNC_REG of rst_in_sync2 : signal is "TRUE";
attribute ASYNC_REG of rst_in_sync3 : signal is "TRUE";


BEGIN


process(clk_in)
     begin
        if rising_edge(clk_in) then
            if (rst_in = '1') then
                rst_in_meta  <= '1';
                rst_in_sync1 <= '1';
                rst_in_sync2 <= '1';
                rst_in_sync3 <= '1';
                rst_in_out   <= '1';        
            else
                rst_in_meta  <= '0';
                rst_in_sync1 <= rst_in_meta;
                rst_in_sync2 <= rst_in_sync1;
                rst_in_sync3 <= rst_in_sync2;
                rst_in_out   <= rst_in_sync3;
            end if;
        end if;
end process;

rst_out <= rst_in_out;

end Behavioral;


