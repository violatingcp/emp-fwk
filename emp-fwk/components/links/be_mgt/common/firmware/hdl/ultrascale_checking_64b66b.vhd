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

entity ultrascale_checking_64b66b is
  Port (
        gtwiz_reset_all_in          : in STD_LOGIC;
        gtwiz_userclk_rx_usrclk2_in : in STD_LOGIC;
        gtwiz_userclk_rx_active_in  : in STD_LOGIC;
        rxdatavalid_in    : in  STD_LOGIC_VECTOR(1 DOWNTO 0);
        rxdata_in         : in  STD_LOGIC_VECTOR(63 DOWNTO 0);
        init_done_in      : in  STD_LOGIC;
        rxgearboxslip_out : out STD_LOGIC:='0';
        prbs_match_out    : out STD_LOGIC:='0';
        rx_latency_trigger_flag_out : out STD_LOGIC
);

end ultrascale_checking_64b66b;


architecture RTL of ultrascale_checking_64b66b is

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


signal example_checking_reset_int  : STD_LOGIC;
signal example_checking_reset_sync : STD_LOGIC;
signal rxdata_int : STD_LOGIC_VECTOR (63 DOWNTO 0);
signal prbs_any_chk_en_int : STD_LOGIC;
signal rxgearboxslip_ctr_int : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS=>'0');
signal prbs_any_chk_error_int : STD_LOGIC_VECTOR (63 DOWNTO 0);
signal prbs_match_out_i : STD_LOGIC;
signal padding_word_flag : STD_LOGIC;

BEGIN

-- attribute DONT_TOUCH : string;
-- attribute DONT_TOUCH of example_stimulus_reset_synchronizer_inst : label is "true";
-------------------------------------------------------------------------------------------------------------------
---- Reset synchronizer
-------------------------------------------------------------------------------------------------------------------

  -- Synchronize the example stimulus reset condition into the txusrclk2 domain
example_checking_reset_int <= gtwiz_reset_all_in OR (NOT gtwiz_userclk_rx_active_in);

example_checking_reset_synchronizer_inst: reset_synchronizer 
  PORT MAP(
    clk_in  => gtwiz_userclk_rx_usrclk2_in,
    rst_in  => example_checking_reset_int,
    rst_out => example_checking_reset_sync
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
process(gtwiz_userclk_rx_usrclk2_in, example_checking_reset_sync)
begin
    if example_checking_reset_sync = '1' then
        rxgearboxslip_ctr_int <= (OTHERS=>'0');
        rxgearboxslip_out     <= '0';
    elsif rising_edge(gtwiz_userclk_rx_usrclk2_in) then
        if (prbs_match_out_i='0' and init_done_in = '0') then
            rxgearboxslip_ctr_int <= rxgearboxslip_ctr_int + '1';
            rxgearboxslip_out     <= and_reduce(rxgearboxslip_ctr_int);
        else
            rxgearboxslip_out <= '0';
            if rxgearboxslip_ctr_int /= "0000" then
                rxgearboxslip_ctr_int <= rxgearboxslip_ctr_int - '1';
            end if;
        end if;  
    end if;
end process;

  
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
      RST      => example_checking_reset_sync,
      CLK      => gtwiz_userclk_rx_usrclk2_in,
      DATA_IN  => rxdata_int,
      EN       => prbs_any_chk_en_int,
      DATA_OUT => prbs_any_chk_error_int
  );


-- The prbs_any block indicates a match of the parallel PRBS data when all DATA_OUT bits are 0. Register the result
-- of the NOR function as the PRBS match indicator.
process(gtwiz_userclk_rx_usrclk2_in, example_checking_reset_sync)
    begin
        if example_checking_reset_sync = '1' then
            prbs_match_out_i <= '0';
        elsif rising_edge(gtwiz_userclk_rx_usrclk2_in) then
            prbs_match_out_i <= NOT(or_reduce(prbs_any_chk_error_int));
        end if;
end process;


-- disable the prbs checker when receiving an inserted paddding word or an invalid word
padding_word_flag <= '1' when rxdata_int = x"F7F7F7F7F7F7F7F7" else '0';
prbs_any_chk_en_int <= rxdatavalid_in(0) and not(padding_word_flag);
prbs_match_out <= prbs_match_out_i;

rx_latency_trigger_flag_out <= padding_word_flag;              



-- Generate code to receive user data (used for latency measurements for now)
-- gen_user: if SELECT_PATTERN = "SYNCH" generate 
--    process(gtwiz_userclk_rx_usrclk2_in, example_checking_reset_sync)
--        begin
--            if example_checking_reset_sync = '1' then
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
--    prbs_match_out <= prbs_match_out_i when prbs_any_chk_en_int = '1' else '1';--padding_word_flag = '0' else '1';
-- end generate;


-- Generate code to receive raw prbs data
--gen_prbs: if SELECT_PATTERN = "PRBS" generate
--            rx_latency_trigger_flag_out <= padding_word_flag;              
--            padding_word_flag <= '1' when rxdata_int = x"F7F7F7F7F7F7F7F7" else '0';
--            prbs_any_chk_en_int <= rxdatavalid_in(0) and not(padding_word_flag);
--            prbs_match_out <= prbs_match_out_i;  
--end generate;


end RTL;