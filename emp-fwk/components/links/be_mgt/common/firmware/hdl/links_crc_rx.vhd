
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ucrc_pkg.all;

entity links_crc_rx is
generic (
  CRC_METHOD: string := "ULTIMATE_CRC";
  TRAILER_EN: boolean := TRUE;
  POLYNOMIAL: std_logic_vector := "00000100110000010001110110110111";
  INIT_VALUE: std_logic_vector := "11111111111111111111111111111111";
  DATA_WIDTH: integer range 2 to 256 := 64;
  SYNC_RESET: integer range 0 to 1 := 1);
port (
      reset:                  in std_logic;
      clk:                    in std_logic;
      clken_in:               in std_logic;
      data_in:                in std_logic_vector(DATA_WIDTH-1 downto 0);
      data_valid_in:          in std_logic;
      data_out:               out std_logic_vector(DATA_WIDTH-1 downto 0);
      data_valid_out:         out std_logic;
      data_start_out:         out std_logic;
      reset_counters_in:      in std_logic;
      crc_checked_cnt_out:    out std_logic_vector(7 downto 0);
      crc_error_cnt_out:      out std_logic_vector(7 downto 0);
    --  trailer_out:            out std_logic_vector(DATA_WIDTH-1 downto 0);
      crc_error_out:          out std_logic
  );

end links_crc_rx;

architecture behave of links_crc_rx is

  signal data_start : std_logic;
  signal data_valid_shreg : std_logic_vector(3 downto 0);
  
  -- Assign default to zero to avoid unknown signals at startup in sim
  -- (i.e. looks like an error)
  signal crc_word : std_logic_vector(31 downto 0) := (others => '0');
  signal crc_valid, crc_error, crc_rst, crc_en : std_logic;
  signal crc_error_cnt, crc_checked_cnt: unsigned(7 downto 0);   
  signal trailer_valid: std_logic;
  
  attribute keep : string;
  attribute keep of crc_word : signal is "true";
  attribute keep of crc_error_cnt : signal is "true";
  attribute keep of crc_checked_cnt : signal is "true";
  

BEGIN

data_valid_shreg(0) <= data_valid_in;
 
 
process(clk)
  begin
    if rising_edge(clk) then
        if clken_in = '1' then
            data_valid_shreg(3 downto 1) <= data_valid_shreg(2 downto 0) ;
        end if;
    end if;
end process;


crc_rst <= '1' when data_valid_shreg(1 downto 0) = "00" else '0';
data_start <= '1' when data_valid_shreg(2 downto 0) = "001" else '0';
crc_valid <= '1' when data_valid_shreg(2 downto 0) = "100" else '0';

---------------------------------------------------------------------------
-- CRC methods
---------------------------------------------------------------------------

crc_en <= data_valid_in and clken_in;

ucrc_gen: if CRC_METHOD = "ULTIMATE_CRC" GENERATE

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
             crc_o => crc_word
            );

END GENERATE;

  
---------------------------------------------------------------------------
-- Error detection & counters
---------------------------------------------------------------------------

process(clk)
begin
    if rising_edge(clk) then
        if reset = '1' then
            crc_error <= '0';
        else
            if clken_in = '1' then
                if crc_valid = '0' then
                    crc_error <= '0';
                else
                -- check crc 
                    if crc_word /= data_in(31 DOWNTO 0) then
                        crc_error <= '1';
                    else
                        crc_error <= '0';
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;


status_counters: process(clk)
begin
    if rising_edge(clk) then
        if reset = '1' or reset_counters_in = '1' then
            crc_error_cnt <= (others => '0');
            crc_checked_cnt <= (others => '0');
        else
            if clken_in = '1' then
                if crc_error = '1' and crc_error_cnt /= X"ff" then
                    crc_error_cnt <= crc_error_cnt + 1;
                end if;
                if crc_valid = '1' and crc_checked_cnt /= X"ff" then
                    crc_checked_cnt <= crc_checked_cnt + 1;
                end if;
            end if;
        end if;
    end if;
end process;

  
crc_error_inst: process(clk)
begin
    if rising_edge(clk) then
        if reset_counters_in = '1' then
            crc_error_out <= '0';
        else
            if crc_error = '1' then
                crc_error_out <= '1';
            end if;
        end if;
    end if;
end process;
  
  ---------------------------------------------------------------------------
  -- Trailer
  ---------------------------------------------------------------------------
  
--  trailer_tgen: if TRAILER_EN = TRUE generate
--    trailer_valid <= '1' when data_valid_shreg = "1011" else '0';  
--    trailer: process(reset, clk)
--    begin
--      if rising_edge(clk) then
--        if reset = '1' then
--          trailer_out <= (others => '0');
--        else
--          if clken_in = '1' then
--            if trailer_valid = '1' then
--              trailer_out <= data_in;
--            end if;
--          end if;
--        end if;
--      end if;
--    end process;
--  end generate;

--  trailer_fgen: if TRAILER_EN = FALSE generate
--    trailer_valid <= '0';
--    trailer_out <= (others => '0');
--  end generate;
    
  ---------------------------------------------------------------------------
  -- Outputs
  ---------------------------------------------------------------------------  
  
  -- DMN: Altered to help with timing issues
  -- data_out <= data_in when crc_valid = '0' else x"00000000";
  
data_out <= data_in;
data_valid_out <= data_valid_in when crc_valid = '0' else '0';
data_start_out <= data_start;
 
crc_error_cnt_out <= std_logic_vector(crc_error_cnt);
crc_checked_cnt_out <= std_logic_vector(crc_checked_cnt);

end behave;
