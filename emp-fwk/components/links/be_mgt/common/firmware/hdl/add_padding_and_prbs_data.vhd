----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/20/2018 12:12:58 PM
-- Design Name: 
-- Module Name: add_padding_and_prbs_data - Behavioral
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

entity add_padding_and_prbs_data is
  generic(
  BYTE_WIDTH : natural := 8);
 port(
    clk                             : in  std_logic;
    data_in                         : in  std_logic_vector(8*BYTE_WIDTH downto 0);
    pad_in                          : in  std_logic;
    pause_read_in                   : in  std_logic;
    data_out                        : out std_logic_vector(8*BYTE_WIDTH downto 0);
    header_out                      : out std_logic_vector(5 downto 0)
    );
end add_padding_and_prbs_data;


architecture behavioral of add_padding_and_prbs_data is

    signal sel : std_logic_vector(2 downto 0);
    signal data_valid_shreg : std_logic_vector(3 downto 0);
    signal crc_valid : std_logic;

begin

  data_valid_shreg(0) <= data_in(8*BYTE_WIDTH);
  
process(clk)
  begin
    if rising_edge(clk) then
        if pause_read_in = '0' and pad_in = '0' then 
            data_valid_shreg(3 downto 1)  <= data_valid_shreg(2 downto 0) ;
        end if;
    end if;
end process;

crc_valid <= '1' when data_valid_shreg = "1100" else '0';
  
  
-- when pad_in is 1 we inject a padding word for clock compensation 
--  else when data valid bit is 0 we send IDLEs
--  and  when data valid bit is 1 we send DATA
sel <= data_in(8*BYTE_WIDTH) & pad_in & crc_valid;

process(sel)
--    variable txkcontrol: std_logic_vector(1 downto 0);
begin
    case sel is
        when "000" => -- send IDLEs
            header_out <= "000010";
            data_out(8*BYTE_WIDTH-1 DOWNTO 0)<= x"5555555555BCBCBC"; 
        when "001" => -- send CRC 
            header_out <= "000010";
            data_out(8*BYTE_WIDTH-1 DOWNTO 0) <= data_in(8*BYTE_WIDTH-1 DOWNTO 0);
        when "100" => -- send DATA
            header_out <= "000001";
            data_out(8*BYTE_WIDTH-1 DOWNTO 0) <= data_in(8*BYTE_WIDTH-1 DOWNTO 0);
        when others => -- send PADding words
            header_out <= "000010";
            data_out(8*BYTE_WIDTH-1 DOWNTO 0) <= x"78F7F7F7F7F7F7F7";
    end case;
end process;

data_out(8*BYTE_WIDTH) <= data_in(8*BYTE_WIDTH);

end behavioral;
