
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.ucrc_pkg.all;


entity links_crc_tx is
    generic (
      CRC_METHOD: string := "ULTIMATE_CRC";
      TRAILER_EN: boolean := TRUE;
      POLYNOMIAL: std_logic_vector := "00000100110000010001110110110111"; -- aurora poly (ethernet)
      INIT_VALUE: std_logic_vector := "11111111111111111111111111111111";
      DATA_WIDTH: integer range 2 to 256 := 64;
      SYNC_RESET: integer range 0 to 1 := 1);
    port (
          clk:                    in std_logic := '0';
          clken_in:               in std_logic := '0';
          data_in:                in std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
          data_valid_in:          in std_logic := '0';
          data_out:               out std_logic_vector(DATA_WIDTH-1 downto 0);
          data_valid_out:         out std_logic
         );
end links_crc_tx;

architecture behave of links_crc_tx is

  signal data_valid_shreg : std_logic_vector(3 downto 0);
  
  signal crc_word : std_logic_vector(31 downto 0);
  signal crc_valid, crc_rst, crc_en : std_logic;
  signal trailer_valid : std_logic;

begin

  data_valid_shreg(0) <= data_valid_in;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if clken_in = '1' then
        data_valid_shreg(3 downto 1)  <= data_valid_shreg(2 downto 0) ;
      end if;
    end if;
  end process;

  crc_rst <= '1' when data_valid_shreg(3 downto 0) = "0000" else '0';
  crc_valid <= '1' when data_valid_shreg = "1100" else '0';

  ---------------------------------------------------------------------------
  -- CRC methods
  ---------------------------------------------------------------------------

  crc_en <= data_valid_in and clken_in;
    
  ucrc_gen: if CRC_METHOD = "ULTIMATE_CRC" generate
    ucrc_inst: ucrc_par
    generic map (
      POLYNOMIAL => POLYNOMIAL,
      INIT_VALUE => INIT_VALUE,
      DATA_WIDTH => DATA_WIDTH,
      SYNC_RESET => SYNC_RESET)
    port map(
      clk_i => clk,
      rst_i => crc_rst,
      clken_i => crc_en,
      data_i => data_in,
      match_o => open,
      crc_o => crc_word);
  end generate;


  ---------------------------------------------------------------------------
  -- Trailer
  ---------------------------------------------------------------------------
  
  trailer_tgen: if TRAILER_EN = TRUE generate
    trailer_valid <= '1' when data_valid_shreg = "1000" else '0';
  end generate;

  trailer_fgen: if TRAILER_EN = FALSE generate
    trailer_valid <= '0';
  end generate;

  ---------------------------------------------------------------------------
  -- Outputs
  ---------------------------------------------------------------------------

--------------------- PACKETS ------------------------------------------------------  
--  |  data_valid_shreg | valid-bit | code |  Zeroes   |      CRC      |
----|------------------------------------------------------------------|
--  |       1111        |     1     |            DATA_IN               | 
--  |       1111        |     1     |            DATA_IN               | 
--  |       1111        |     1     |            DATA_IN               | 
--  |       1110        |     0     |            DATA_IN               | CRC disabled
--  |       1100        |     0     | 0x99 | 0x000000  |   32-bit CRC  | CRC PACKET
--  |       1000        |     0     |  ??  |     ?     |       ?       | Trailer (?)
-------------------------------------------------------------------------------------
 
 
  
  data_out <= x"99" & x"000000" & crc_word when crc_valid = '1' else
              --trailer_in when trailer_valid = '1' else 
              data_in;
          
  data_valid_out <=  data_valid_in; --or crc_valid or trailer_valid;
   
end behave;



