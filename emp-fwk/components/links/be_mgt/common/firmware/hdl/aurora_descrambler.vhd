----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/13/2018 06:17:16 PM
-- Design Name: 
-- Module Name: aurora_descrambler - Behavioral
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


entity aurora_descrambler is
        Generic( DATA_WIDTH : natural := 64 );
        Port (
              rxdata_i         : IN  STD_LOGIC_VECTOR(0 to DATA_WIDTH - 1);
              rx_datavalid_i   : IN  STD_LOGIC;
              unscrambled_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
              rxusrclk2_i      : IN  STD_LOGIC;
              reset_all_i      : IN  STD_LOGIC;
              rxheader_out_i   : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
              rxheader_out_d   : out STD_LOGIC_VECTOR(5 DOWNTO 0);
              rx_datavalid_d   : out STD_LOGIC;
              rxgearboxslip_i  : in  STD_LOGIC;
              rxgearboxslip_d  : out STD_LOGIC
              );
 end aurora_descrambler;

architecture Behavioral of aurora_descrambler is
    
    Component aurora_64b66b_0_DESCRAMBLER_64B66B
        Port (
                 SCRAMBLED_DATA_IN    : IN  STD_LOGIC_VECTOR(0 to DATA_WIDTH - 1);
                 DATA_VALID_IN        : IN  STD_LOGIC;
                 UNSCRAMBLED_DATA_OUT : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
                 USER_CLK             : IN  STD_LOGIC;
                 SYSTEM_RESET         : IN  STD_LOGIC
                 );
    End Component;
    
    signal reset_all_s : std_logic;
    attribute DONT_TOUCH : string;
    attribute DONT_TOUCH of reset_synchronizer_dscreset_inst : label is "true";
    
begin


 reset_synchronizer_dscreset_inst:  entity work.reset_synchronizer  
    Port Map(
             clk_in  => rxusrclk2_i,
             rst_in  => reset_all_i,
             rst_out => reset_all_s
            );

    process(rxusrclk2_i,reset_all_s)
    begin
        if rising_edge(rxusrclk2_i) then
            rxheader_out_d <= rxheader_out_i;
            rx_datavalid_d <= rx_datavalid_i;
            rxgearboxslip_d <= rxgearboxslip_i;
        end if;
   end process;


descrambler : aurora_64b66b_0_DESCRAMBLER_64B66B
        Port Map(
                 SCRAMBLED_DATA_IN    => rxdata_i,
                 DATA_VALID_IN        => rx_datavalid_i,
                 UNSCRAMBLED_DATA_OUT => unscrambled_data,
                 USER_CLK             => rxusrclk2_i,
                 SYSTEM_RESET         => reset_all_s
                 );

end Behavioral;
