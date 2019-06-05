----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/22/2018 02:29:29 PM
-- Design Name: 
-- Module Name: bit_synchronizer - Behavioral
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


-- Asynchronous Input Synchronization
--
-- The following code is an example of synchronizing an asynchronous input
-- of a design to reduce the probability of metastability affecting a circuit.
--
-- The following synthesis and implementation attributes are added to the code
-- in order improve the MTBF characteristics of the implementation:
--
--  ASYNC_REG="TRUE" - Specifies registers will be receiving asynchronous data
--                     input to allow tools to report and improve metastability
--
-- The following constants are available for customization:
--
--   SYNC_STAGES     - Integer value for number of synchronizing registers, must be 2 or higher
--   PIPELINE_STAGES - Integer value for number of registers on the output of the
--                     synchronizer for the purpose of improveing performance.
--                     Particularly useful for high-fanout nets.
--   INIT            - Initial value of synchronizer registers upon startup, 1'b0 or 1'b1.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bit_synchronizer is
    Port ( clk_in : in STD_LOGIC;
           i_in : in STD_LOGIC;
           o_out : out STD_LOGIC);
end bit_synchronizer;

ARCHITECTURE Behavioral OF bit_synchronizer IS

-- Insert the following before begin keyword of architecture
constant SYNC_STAGES : integer := 3;
constant PIPELINE_STAGES : integer := 0;
constant INIT : std_logic := '0';

--signal o_out : std_logic;  -- Synchronized output

signal sreg : std_logic_vector(SYNC_STAGES-1 downto 0) := (others => INIT);
attribute async_reg : string;
attribute async_reg of sreg : signal is "true";

signal sreg_pipe : std_logic_vector(PIPELINE_STAGES-1 downto 0) := (others => INIT);
attribute shreg_extract : string;
attribute shreg_extract of sreg_pipe : signal is "false";


begin 


-- Insert the following in the architecture after the begin keyword
   process(clk_in)
   begin
    if(clk_in'event and clk_in='1')then
       sreg <= sreg(SYNC_STAGES-2 downto 0) & i_in;  -- Async Input <async_in>
    end if;
   end process;

   no_pipeline : if PIPELINE_STAGES = 0 generate
   begin
      o_out <= sreg(SYNC_STAGES-1);
   end generate;

   one_pipeline : if PIPELINE_STAGES = 1 generate
   begin
    process(clk_in)
    begin
      if(clk_in'event and clk_in='1') then
        o_out <= sreg(SYNC_STAGES-1);
      end if;
    end process;
   end generate;

   multiple_pipeline : if PIPELINE_STAGES > 1 generate
   begin
    process(clk_in)
    begin
      if(clk_in'event and clk_in='1') then
        sreg_pipe <= sreg_pipe(PIPELINE_STAGES-2 downto 0) & sreg(SYNC_STAGES-1);
      end if;
    end process;
    o_out <= sreg_pipe(PIPELINE_STAGES-1);
   end generate;


END Behavioral;


--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;

---- Uncomment the following library declaration if using
---- arithmetic functions with Signed or Unsigned values
----use IEEE.NUMERIC_STD.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx leaf cells in this code.
----library UNISIM;
----use UNISIM.VComponents.all;

--entity bit_synchronizer is
--    Port ( clk_in : in STD_LOGIC;
--           i_in : in STD_LOGIC;
--           o_out : out STD_LOGIC);
--end bit_synchronizer;


--ARCHITECTURE Behavioral OF bit_synchronizer IS

--signal i_in_meta : STD_LOGIC;
--signal i_in_sync1 : STD_LOGIC;
--signal i_in_sync2 : STD_LOGIC;
--signal i_in_sync3 : STD_LOGIC;
--signal i_in_out : STD_LOGIC;

--attribute ASYNC_REG : string;
--attribute ASYNC_REG of i_in_meta : signal is "TRUE";
--attribute ASYNC_REG of i_in_sync1 : signal is "TRUE";
--attribute ASYNC_REG of i_in_sync2 : signal is "TRUE";
--attribute ASYNC_REG of i_in_sync3 : signal is "TRUE";


--BEGIN

--process(clk_in)
--begin
--    if rising_edge(clk_in) then     
--        i_in_meta  <= i_in;
--        i_in_sync1 <= i_in_meta;
--        i_in_sync2 <= i_in_sync1;
--        i_in_sync3 <= i_in_sync2;
--        i_in_out   <= i_in_sync3;
--    end if;
--end process;

--o_out <= i_in_out;

--END Behavioral;

