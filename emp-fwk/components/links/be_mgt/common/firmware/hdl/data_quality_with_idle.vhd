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

USE IEEE.std_logic_misc.all; -- contains OR_REDUCE & AND_REDUCE functions among others!!!!

entity data_quality_with_idle is
  Port (
         reset_all_in : in STD_LOGIC;
         rx_usrclk2_in : in STD_LOGIC;
         rx_active_in  : in STD_LOGIC;
         rxdatavalid_in    : in  STD_LOGIC_VECTOR(1 DOWNTO 0);
         rxdata_in         : in  STD_LOGIC_VECTOR(63 DOWNTO 0);
         rxdata_header_in  : in STD_LOGIC_VECTOR(5 DOWNTO 0);
         rxgearboxslip_out : out STD_LOGIC:='0';
         prbs_match_out    : out STD_LOGIC:='0';
         data_good         : out STD_LOGIC:='0'
       );

end data_quality_with_idle;


architecture RTL of data_quality_with_idle is

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


signal reset  : STD_LOGIC;
signal reset_sync : STD_LOGIC;
signal rxdata_int : STD_LOGIC_VECTOR (63 DOWNTO 0);
signal prbs_checker_enable : STD_LOGIC;
signal rxgearboxslip_ctr_int : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS=>'0');
signal prbs_error_vector : STD_LOGIC_VECTOR (63 DOWNTO 0);
signal prbs_match_out_i : STD_LOGIC;
signal padding_word_flag : STD_LOGIC;

signal header_match_i : STD_LOGIC;
signal rxdata_header_i : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal data_good_i : STD_LOGIC;

signal prbs_error_vector_test : STD_LOGIC_VECTOR (63 DOWNTO 0);

signal rxdata_header_i_l1 : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal rxdata_header_i_l2 : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal rxdata_header_i_l3 : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal rxdata_header_i_l4 : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal rxdatavalid_in_l1 : STD_LOGIC;

signal data_check : STD_LOGIC;
signal crc_en : STD_LOGIC;

BEGIN

-- attribute DONT_TOUCH : string;
-- attribute DONT_TOUCH of example_stimulus_reset_synchronizer_inst : label is "true";
-------------------------------------------------------------------------------------------------------------------
---- Reset synchronizer
-------------------------------------------------------------------------------------------------------------------

  -- Synchronize the example stimulus reset condition into the txusrclk2 domain
reset <= reset_all_in OR (NOT rx_active_in);
rxdata_header_i <= rxdata_header_in;

example_checking_reset_synchronizer_inst: reset_synchronizer 
  PORT MAP(
    clk_in  => rx_usrclk2_in,
    rst_in  => reset,
    rst_out => reset_sync
  );


 -------------------------------------------------------------------------------------------------------------
 --Data reception declarations and assignments
 -------------------------------------------------------------------------------------------------------------
 --Bit-reverse the txdata_out assignment to accomodate any differences between transmitter and receiver user interface data widths, since gearbox modes transmit data MSb first.
rxdata_int <= bit_reverse(rxdata_in);
 

 -----------------------------------------------------------------------------------------------------------------
 -- PRBS generator output enable and sideband control generation
 -----------------------------------------------------------------------------------------------------------------
 
-- Use the PRBS checker lock indicator as feedback, periodically pulsing the rxgearboxslip until initialization is achieved
process(rx_usrclk2_in, reset_sync)
begin
    if reset_sync = '1' then
        rxgearboxslip_ctr_int <= (OTHERS=>'0');
        rxgearboxslip_out     <= '0';
    elsif rising_edge(rx_usrclk2_in) then
        if data_check = '1' then
            if data_good_i = '0' then 
                rxgearboxslip_ctr_int <= rxgearboxslip_ctr_int + '1';
                rxgearboxslip_out     <= and_reduce(rxgearboxslip_ctr_int);
            else
                if rxgearboxslip_ctr_int /= "0000" then
                    rxgearboxslip_ctr_int <= rxgearboxslip_ctr_int - '1';     
                end if;
                rxgearboxslip_out <= '0';
            end if;
        end if;  
    end if;
end process;


process(rx_usrclk2_in, reset_sync)
    begin
        if reset_sync = '1' then
            data_good_i <= '0';
            data_check  <= '0';
            crc_en      <= '0';
        elsif rising_edge(rx_usrclk2_in) then
            if rxdata_header_i(1 DOWNTO 0) = "01" then
                data_check <= '0';
                data_good_i <= '0';
            elsif rxdata_header_i = "10" then
                data_check <= '1';
                if rxdata_int = x"78F7F7F7F7F7F7F7" then -- Padding
                    data_good_i <= '1';
                elsif rxdata_int = x"5555555555BCBCBC" then -- IDLE
                    data_good_i <= '1';
                elsif rxdata_int(63 downto 32) = x"99000000" then -- CRC
                    data_good_i <= '1';
                    crc_en <= '1';
                else 
                    data_good_i <= '0';
                    crc_en <= '0';
                end if;
            else 
                data_check <= '1';
                data_good_i <= '0';
            end if;
        end if;
end process;

    ---------------------------------------------------------------------------------------------------------------------
  -- PRBS gen block
  ---------------------------------------------------------------------------------------------------------------------

   --The prbs_any block, described in Xilinx Application Note 884 (XAPP884), "An Attribute-Programmable PRBS Generator
   --and Checker", generates or checks a parameterizable PRBS sequence. Instantiate and parameterize a prbs_any block
   --to generate a PRBS31 sequence with parallel data sized to the transmitter user data width.
--prbs_any_gen_inst_gen : gtwizard_ultrascale_0_prbs_any
--    generic map (
--      CHK_MODE    => 0,
--      INV_PATTERN => 1,
--      POLY_LENGHT => 31,
--      POLY_TAP    => 28,
--      NBITS       => 64 ) 
--    port map (
--      RST      => reset_sync,
--      CLK      => rx_usrclk2_in,
--      DATA_IN  => rxdata_in,--(OTHERS=>'0'),
--      EN       => '1',
--      DATA_OUT => prbs_error_vector_test
--  );
  
  
  
  ---------------------------------------------------------------------------------------------------------------------
  -- PRBS checker block
  ---------------------------------------------------------------------------------------------------------------------

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
      RST      => reset_sync,
      CLK      => rx_usrclk2_in,
      DATA_IN  => rxdata_int, -- prbs_error_vector_test,
      EN       => prbs_checker_enable,
      DATA_OUT => prbs_error_vector
  );


-- The prbs_any block indicates a match of the parallel PRBS data when all DATA_OUT bits are 0. Register the result
-- of the NOR function as the PRBS match indicator.
process(rx_usrclk2_in, reset_sync)
    begin
        if reset_sync = '1' then
            prbs_match_out_i <= '0';
        elsif rising_edge(rx_usrclk2_in) then
            prbs_match_out_i <= NOT(or_reduce(prbs_error_vector));
        end if;
end process;


---- Data quality chack based on the header
--process(rx_usrclk2_in, reset_sync)
--    begin
--        if reset_sync = '1' then
--            header_match_i <= '0';
--        elsif rising_edge(rx_usrclk2_in) then
--            header_match_i <= rxdata_header_i(0) XOR rxdata_header_i(1);
--        end if;
--end process;

--process (rx_usrclk2_in) 
--    begin
--        if rising_edge(rx_usrclk2_in) then
--             rxdata_header_i_l1 <=  rxdata_header_i;
--             rxdata_header_i_l2 <=  rxdata_header_i_l1;
--             rxdata_header_i_l3 <=  rxdata_header_i_l2;
--             rxdata_header_i_l4 <=  rxdata_header_i_l3;

--        end if;
--end process;

process (rx_usrclk2_in) 
    begin
        if rising_edge(rx_usrclk2_in) then
             rxdatavalid_in_l1 <=  rxdatavalid_in(0);
        end if;
end process;

---- When rx header is '10' we receive prbs data and data quality is defined by the prbs checker
---- else we receive user data and the data quality is defind by the rx header value. 
--data_good_i <=  prbs_match_out_i when rxdata_header_i_l3(1 DOWNTO 0) & rxdata_header_i_l2(1 DOWNTO 0) = "1010" else
--             '1'   when rxdata_header_i_l4(1 DOWNTO 0) & rxdata_header_i_l3(1 DOWNTO 0)= "0101" else
--             '0';
          
--process(rx_usrclk2_in, reset_sync)
--    begin
--        if reset_sync = '1' then
--            data_good_i <= '0';
--        elsif rising_edge(rx_usrclk2_in) then
--           if (rxdata_header_i_l1(1 DOWNTO 0) & rxdata_header_i(1 DOWNTO 0) = "1001" or rxdata_header_i_l1(1 DOWNTO 0) & rxdata_header_i(1 DOWNTO 0) = "0101") then       
--               data_good_i <= '1';
--           elsif (rxdata_header_i_l3(1 DOWNTO 0) & rxdata_header_i_l2(1 DOWNTO 0) = "0110" or rxdata_header_i_l3(1 DOWNTO 0) & rxdata_header_i_l2(1 DOWNTO 0) = "1010") then 
--               data_good_i <= NOT(or_reduce(prbs_error_vector));
--           else
--               data_good_i <= rxdata_header_i(0) xor rxdata_header_i(1);
--           end if;
--        end if;
--end process;



data_good <= data_good_i or not(data_check) or not(rxdatavalid_in_l1);
             

-- Disable the prbs checker when receiving an inserted paddding word or an invalid word
padding_word_flag <= '1' when rxdata_int = x"78F7F7F7F7F7F7F7" else '0';
prbs_checker_enable <= rxdatavalid_in(0) and not(padding_word_flag);
prbs_match_out <= prbs_match_out_i;


-- Generate code to receive user data (used for latency measurements for now)
-- gen_user: if SELECT_PATTERN = "SYNCH" generate 
--    process(rx_usrclk2_in, reset_sync)
--        begin
--            if reset_sync = '1' then
--                padding_word_flag <= '0';
--            else
--                if rxdata_int = x"F7F7F7F7F7F7F7F7" then
--                     padding_word_flag <= '1';
--                else 
--                    padding_word_flag <= '0';
--                end if;
--            end if;
--    end process;

--    rx_latency_trigger_flag_out <= padding_word_flag;
--    prbs_match_out <= prbs_match_out_i when prbs_checker_enable = '1' else '1';--padding_word_flag = '0' else '1';
-- end generate;


-- Generate code to receive raw prbs data
-- gen_prbs: if SELECT_PATTERN = "PRBS" generate
--            rx_latency_trigger_flag_out <= padding_word_flag;              
--            padding_word_flag <= '1' when rxdata_int = x"F7F7F7F7F7F7F7F7" else '0';
--            prbs_checker_enable <= rxdatavalid_in(0) and not(padding_word_flag);
--            prbs_match_out <= prbs_match_out_i;  
-- end generate;


end RTL;