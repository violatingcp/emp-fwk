-- =====================================================================================================================
 --This example design checking module checks PRBS31 data at the appropriate parallel data width from the receiver,
 --along with performing any data manipulation or sideband signaling necessary for the selected data decoding. This
 --module instance checks data from a single transceiver channel for data reception demonstration purposes.
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

USE IEEE.std_logic_misc.all; -- contains OR_REDUCE & AND_REDUCE functions among others


entity ttc_prbs_checker is
  GENERIC (SELECT_PATTERN : STRING);
  Port (
        reset          : in STD_LOGIC;
        clk            : in STD_LOGIC;
        rx_active      : in STD_LOGIC;
        reset_error_latched : in STD_LOGIC;
        rxdatavalid_in : in  STD_LOGIC_VECTOR(1 DOWNTO 0);
        data_in        : in  STD_LOGIC_VECTOR(63 DOWNTO 0);
        prbs_match_out : out STD_LOGIC:='0';
        channel_error_latched  : out STD_LOGIC:='0' 
);

end ttc_prbs_checker;



architecture RTL of ttc_prbs_checker is

component reset_synchronizer
  Port(
        clk_in  : in STD_LOGIC;
        rst_in  : in STD_LOGIC;
        rst_out : out STD_LOGIC
    );
end component;

component gtwizard_ultrascale_0_prbs_any
  generic (
        CHK_MODE    : INTEGER := 1;
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


signal checker_reset_int  : STD_LOGIC;
signal checker_reset_sync : STD_LOGIC;
signal data_int : STD_LOGIC_VECTOR (63 DOWNTO 0);
--signal prbs_any_chk_en_int : STD_LOGIC;
signal prbs_any_chk_error_int : STD_LOGIC_VECTOR (63 DOWNTO 0);
signal prbs_match_out_i       : STD_LOGIC;
--signal user_pattern_flag_i : STD_LOGIC;

-- error latched indicator :
signal channel_error_latched_i : STD_LOGIC;
signal reset_error_latched_int : STD_LOGIC;
signal reset_error_latched_sync : STD_LOGIC;


BEGIN

  -----------------------------------------------------------------------------------------------------------------
  -- Reset synchronizer
  -----------------------------------------------------------------------------------------------------------------
checker_reset_int <= reset OR (NOT rx_active);
reset_error_latched_int <= reset_error_latched;


-- Synchronize the reset condition into the local clock domain
example_checking_reset_synchronizer_inst: reset_synchronizer 
  PORT MAP(
    clk_in  => clk,
    rst_in  => checker_reset_int,
    rst_out => checker_reset_sync
  );


example_error_reset_synchronizer_inst: reset_synchronizer 
  PORT MAP(
    clk_in  => clk,
    rst_in  => reset_error_latched_int,
    rst_out => reset_error_latched_sync
  );



  ---------------------------------------------------------------------------------------------------------------------
  -- PRBS checker block
  ---------------------------------------------------------------------------------------------------------------------
data_int <= data_in;

   --The prbs_any block, described in Xilinx Application Note 884 (XAPP884), "An Attribute-Programmable PRBS Generator
   --and Checker", generates or checks a parameterizable PRBS sequence. Instantiate and parameterize a prbs_any block
   --to generate a PRBS31 sequence with parallel data sized to the transmitter user data width.
prbs_any_gen_inst : gtwizard_ultrascale_0_prbs_any
    generic map (
      CHK_MODE    => 1,
      INV_PATTERN => 1,
      POLY_LENGHT => 31,
      POLY_TAP    => 28,
      NBITS       => 64 ) 
    port map (
      RST      => checker_reset_sync,
      CLK      => clk,
      DATA_IN  => data_int,
      EN       => rxdatavalid_in(0),
      DATA_OUT => prbs_any_chk_error_int
  );



  -- PRBS data match when all DATA_OUT bits are 0. Register the result
  -- of the NOR function as the PRBS match indicator.
process(clk, checker_reset_sync)
    begin
        if checker_reset_sync = '1' then
            prbs_match_out_i <= '0';
        elsif rising_edge(clk) then
            prbs_match_out_i <= NOT(or_reduce(prbs_any_chk_error_int));
        end if;
end process;



  -- Channel error counters
  
process (clk,reset_error_latched_sync)
begin
    if reset_error_latched_sync = '1' then
        channel_error_latched_i <= '0';
    elsif rising_edge(clk) then  
        if (prbs_match_out_i = '0') then
            channel_error_latched_i <= '1';                     
        end if;
    end if;
end process;



prbs_match_out <= prbs_match_out_i;  
channel_error_latched <= channel_error_latched_i;

---- Generate code to receive user data (used for latency measurements for now)
--gen_user: if SELECT_PATTERN = "SYNCH" generate 
--    process(clk, example_checking_reset_sync)
--        begin
--            if example_checking_reset_sync = '1' then
--                user_pattern_flag_i <= '0';
--            else
--                if rxdata_int = x"F7F7F7F7F7F7F7F7" then
--                     user_pattern_flag_i <= '1';
--                else 
--                    user_pattern_flag_i <= '0';
--                end if;
--            end if;
--    end process;
    
--    rx_latency_trigger_flag_out <= user_pattern_flag_i;
--    prbs_match_out <= prbs_match_out_i when prbs_any_chk_en_int = '1' else '1';--user_pattern_flag_i = '0' else '1';
--end generate;


-- Generate code to receive raw prbs data
--gen_prbs: if SELECT_PATTERN = "PRBS" generate
--        user_pattern_flag_i <= '1' when data_int = x"F7F7F7F7F7F7F7F7" else '0';
--        prbs_any_chk_en_int <= rxdatavalid_in(0) and not(user_pattern_flag_i);
--        prbs_match_out <= prbs_match_out_i;  
--end generate;



end RTL;