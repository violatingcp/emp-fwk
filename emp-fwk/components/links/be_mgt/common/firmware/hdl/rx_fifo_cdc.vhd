
--------------------------------------------------------------------------------
--
-- Filename: rx_fifo_cdc.vhd

--
--------------------------------------------------------------------------------
-- Library Declarations
--------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.STD_LOGIC_1164.ALL;
USE ieee.STD_LOGIC_unsigned.ALL;
USE IEEE.STD_LOGIC_arith.ALL;
USE ieee.numeric_std.ALL;
USE ieee.STD_LOGIC_misc.ALL;

library unisim;
use unisim.vcomponents.all;

LIBRARY std;
USE std.textio.ALL;

LIBRARY work;
USE work.tx_fifo_pkg.ALL;

--------------------------------------------------------------------------------
-- Entity Declaration
--------------------------------------------------------------------------------
ENTITY rx_fifo_cdc IS
  GENERIC (DATA_WIDTH : integer := 64);
  PORT(
	ttc_clk         :  IN  STD_LOGIC := '0';
	link_clk        :  IN  STD_LOGIC := '0';
    reset           :  IN  STD_LOGIC := '0';
    init_done       :  IN  STD_LOGIC := '0';
    reset_crc_cnt   :  IN  STD_LOGIC := '0';
    rx_data_in      :  IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0'); 
    rx_header_in    :  IN STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0'); 
    rx_datavalid_in :  IN STD_LOGIC := '0';
    buf_rst_in      :  in  std_logic;
    buf_ptr_inc_in  :  in  std_logic;
    buf_ptr_dec_in  :  in  std_logic;
    ttc_data_out    :  OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    ttc_valid_out   :  OUT STD_LOGIC;
    crc_error       :  OUT STD_LOGIC
      );
END ENTITY;

ARCHITECTURE RTL OF rx_fifo_cdc IS

COMPONENT bram_rx_buffer
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC; --STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(64 DOWNTO 0);
    clkb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(64 DOWNTO 0)
  );
END COMPONENT;

  constant FIFO_DEPTH: integer := 128;
  
  signal wbuf_add :  integer range 0 to FIFO_DEPTH-1;
  signal rbuf_add :  integer range 0 to FIFO_DEPTH-1;
    
  signal wbuf_add_word, rbuf_add_word : STD_LOGIC_VECTOR(8 DOWNTO 0);
  signal bram_in_i                    : STD_LOGIC_VECTOR(DATA_WIDTH DOWNTO 0) := (OTHERS => '0');
  signal init_done_sync                    : std_logic;

    -- FIFO interface signal declarations
    SIGNAL wr_clk_i                       :   STD_LOGIC := '0';
    SIGNAL rd_clk_i                       :   STD_LOGIC := '0';
    SIGNAL almost_full_i                  :   STD_LOGIC := '0';
    SIGNAL almost_empty_i                 :   STD_LOGIC := '1';
    SIGNAL rst	                          :   STD_LOGIC := '0';
    SIGNAL wr_en_i                        :   STD_LOGIC := '0';
    SIGNAL rd_en_i                        :   STD_LOGIC := '0';
    SIGNAL fifo_in_i                      :   STD_LOGIC_VECTOR(DATA_WIDTH DOWNTO 0) := (OTHERS => '0');
    SIGNAL fifo_out_i                     :   STD_LOGIC_VECTOR(DATA_WIDTH DOWNTO 0) := (OTHERS => '0');
    SIGNAL full_i                         :   STD_LOGIC := '0';
    SIGNAL empty_i                        :   STD_LOGIC := '1';

    -- Read agent
    SIGNAL valid_bit                      :   STD_LOGIC := '0';  

    --Write agent
    SIGNAL rx_data_in_pad_flag_i          :   STD_LOGIC := '0';
    
    
   -- TB Signals
    SIGNAL rst_int_rd                     :   STD_LOGIC := '1';
    SIGNAL rst_int_wr                     :   STD_LOGIC := '1';
    SIGNAL fifo_reset                     :   STD_LOGIC := '1';
    SIGNAL txsequence_out_i               :   STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pause_read                     :   STD_LOGIC := '0';

    SIGNAL reset_crc_cnt_sync             :   STD_LOGIC := '0';
    SIGNAL reset_crc_cnt_wr_sync          :   STD_LOGIC := '0';
    SIGNAL buf_ptr_inc                    :   STD_LOGIC := '0';
    SIGNAL buf_ptr_dec                    :   STD_LOGIC := '0';
    SIGNAL buf_rst, buf_rst_i, buf_rst_w  :   STD_LOGIC := '0';
    SIGNAL buf_ptr_cntrl                  :   STD_LOGIC_VECTOR(1 downto 0) := "00";  
  
    attribute DONT_TOUCH : string;
    attribute DONT_TOUCH of fifo_out_i : signal is "true";
    attribute DONT_TOUCH of crc_check : label is "true";
--    attribute DONT_TOUCH of reset_synchronizer_crc_cnt_inst : label is "true";
    attribute DONT_TOUCH of reset_synchronizer_read_inst : label is "true";
    attribute DONT_TOUCH of reset_synchronizer_write_inst : label is "true";
--    attribute DONT_TOUCH of reset_synchronizer_crc_cnt_wr_inst : label is "true";

    -- Debugging signals
    signal rd_data_count_i :  STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');

    attribute keep : string;
    attribute keep of full_i : signal is "true";
    attribute keep of empty_i : signal is "true";
    attribute keep of almost_full_i : signal is "true";
    attribute keep of almost_empty_i : signal is "true";
    attribute keep of rd_data_count_i : signal is "true";


    FUNCTION bit_reverse(s1:std_logic_vector) return std_logic_vector is 
        variable rr : std_logic_vector(s1'high downto s1'low); 
    begin 
        for ii in s1'high downto s1'low loop 
              rr(ii) := s1(s1'high-ii); 
        end loop; 
        return rr; 
    end bit_reverse; 


 BEGIN  
-----------------------------------------------------
--- Reset generation logic --------------------------
----------------------------------------------------- 
wr_clk_i    <= link_clk;
rd_clk_i    <= ttc_clk;

fifo_reset <= reset;

bit_synchronizer_initdone_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => wr_clk_i,
                 i_in    => init_done,
                 o_out   => init_done_sync 
                 );

bit_synchronizer_bufptrinc_in_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => rd_clk_i,
                 i_in    => buf_ptr_inc_in,
                 o_out   => buf_ptr_inc 
                 );

bit_synchronizer_bufptrdec_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => rd_clk_i,
                 i_in    => buf_ptr_dec_in,
                 o_out   => buf_ptr_dec 
                 );

reset_synchronizer_bufrst_inst:  entity work.reset_synchronizer  
    Port Map(
             clk_in  => rd_clk_i,
             rst_in  => buf_rst_in,
             rst_out => buf_rst_i
            );

reset_synchronizer_bufrstw_inst:  entity work.reset_synchronizer  
    Port Map(
             clk_in  => wr_clk_i,
             rst_in  => buf_rst_in,
             rst_out => buf_rst_w
            );
            
reset_synchronizer_read_inst:  entity work.reset_synchronizer  
    Port Map(
             clk_in  => rd_clk_i,
             rst_in  => fifo_reset,
             rst_out => rst_int_rd
            );  
        
reset_synchronizer_write_inst:  entity work.reset_synchronizer  
    Port Map(
             clk_in  => wr_clk_i,
             rst_in  => fifo_reset,
             rst_out => rst_int_wr
            );          

reset_synchronizer_crc_cnt_inst:  entity work.reset_synchronizer  
    Port Map(
             clk_in  => rd_clk_i,
             rst_in  => reset_crc_cnt,
             rst_out => reset_crc_cnt_sync
            );      

reset_synchronizer_crc_cnt_wr_inst:  entity work.reset_synchronizer  
    Port Map(
             clk_in  => wr_clk_i,
             rst_in  => reset_crc_cnt,
             rst_out => reset_crc_cnt_wr_sync
            );   

rx_data_in_pad_flag_i <= '1' when bit_reverse(rx_data_in) = x"78F7F7F7F7F7F7F7" else '0';
--rx_data_in_pad_flag_i <= '1' when rx_data_in = x"78F7F7F7F7F7F7F7" else '0';

valid_bit   <= not rx_header_in(1) and rx_header_in(0); -- valid bit = 1 when rxheader= "01"


wr_en_i     <= rx_datavalid_in and not(rx_data_in_pad_flag_i) and init_done_sync;


  PROCESS(rd_clk_i,rst_int_rd)
  BEGIN
    IF(rst_int_rd = '1') THEN
        rd_en_i           <= '0';
    ELSIF (rd_clk_i'event AND rd_clk_i='1') THEN
        rd_en_i <= '1';
    END IF;
  END PROCESS;

--============================= BRAM ==================================================

--process (wr_clk_i) 
--begin
--    if rising_edge(wr_clk_i) then
--        bram_in_i   <= valid_bit & bit_reverse(rx_data_in);
--    end if;
--end process;

bram_in_i   <= valid_bit & bit_reverse(rx_data_in);
--bram_in_i   <= valid_bit & rx_data_in;

wbuf_sm: process (wr_clk_i) 
begin
    if rising_edge(wr_clk_i) then
        if (rst_int_wr = '1') then
            wbuf_add <= 100; 
        else
            if reset_crc_cnt_wr_sync = '1' or buf_rst_w ='1' then
                wbuf_add <= 14; 
            else
                if wr_en_i = '0' then  
                  -- Padding word.  Do not place in FIFO.
                    wbuf_add <= wbuf_add;
                else
                    if wbuf_add < FIFO_DEPTH-1 then
                        wbuf_add <= wbuf_add + 1;
                    else
                        wbuf_add <= 0;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process wbuf_sm;

-----------------------------------------------------------------------------
-- Stage 2: Dual port RAM
-----------------------------------------------------------------------------


  wbuf_add_word <= "00" & std_logic_vector(to_unsigned(wbuf_add,7));


---- Simple DUAL Port RAM RX cdc buffer
rx_buffer : bram_rx_buffer
  PORT MAP (
    clka => wr_clk_i,
    wea => wr_en_i,
    addra => wbuf_add_word,
    dina => bram_in_i,
    clkb => rd_clk_i,
    enb => '1',
    addrb => rbuf_add_word,
    doutb => fifo_out_i
  );



  -----------------------------------------------------------------------------
  -- Stage 3: Read data out of dual port RAM - RBUF -- Adopted from the mp7-fwk
  -----------------------------------------------------------------------------

  buf_ptr_cntrl <= buf_ptr_inc & buf_ptr_dec;
  buf_rst <= buf_rst_i or reset_crc_cnt_sync;

  rbuf_sm: process (rd_clk_i) 
  begin
    if rising_edge(rd_clk_i) then
      if (rst_int_rd = '1') then
        rbuf_add <= 0;
      else
          if (buf_rst = '1') then 
              rbuf_add <= 10;  
          else
            case buf_ptr_cntrl is
                when "01" =>           -- Subtract 1 ptr location
                  rbuf_add <= rbuf_add;
                when "10" =>           -- Add 1 ptr location
                  case rbuf_add is
                    when FIFO_DEPTH-2 =>
                      rbuf_add <= 0;
                    when FIFO_DEPTH-1 =>
                      rbuf_add <= 1;
                    when others => 
                      rbuf_add <= rbuf_add + 2;
                  end case;
                when others =>          -- Behave normally.
                  case rbuf_add is
                    when FIFO_DEPTH-1 =>
                      rbuf_add <= 0;
                    when others => 
                      rbuf_add <= rbuf_add + 1;
                  end case;
            end case;
          end if;
        end if;
      end if;
  end process rbuf_sm;

rbuf_add_word <= "00" & std_logic_vector(to_unsigned(rbuf_add,7));


--process (rd_clk_i) 
--begin
--    if rising_edge(rd_clk_i) then
--        if (rst_int_rd = '1') then
--            rbuf_add <= 0; 
--        else
--            if reset_crc_cnt_sync ='1' then
--                rbuf_add <= 10; 
--            else
--                if rbuf_add < FIFO_DEPTH-1 then
--                    rbuf_add <= rbuf_add + 1;
--                else
--                    rbuf_add <= 0;
--                end if;
--            end if;
--        end if;
--    end if;
--end process wbuf_sm;





--Ultimate CRC is a CRC generator/checker. Using generics the core can be fully customized. 
--It creates a function of the data input and the CRC register using XOR-logic. 
--Although the levels of logic gets very high for wide data inputs, the throughput still benefits from this architecture.
crc_check: entity work.links_crc_rx
    generic map(
              CRC_METHOD => "ULTIMATE_CRC",
              TRAILER_EN => FALSE,
              POLYNOMIAL => "00000100110000010001110110110111",
              INIT_VALUE => "11111111111111111111111111111111",
              DATA_WIDTH => 64,
              SYNC_RESET => 1
              )
    port map(
            reset               => rst_int_rd,
            clk                 => rd_clk_i,
            clken_in            => '1',
            data_in             => fifo_out_i(DATA_WIDTH - 1 DOWNTO 0),
            data_valid_in       => fifo_out_i(DATA_WIDTH),
            data_out            => open,
            data_valid_out      => open,
            data_start_out      => open,
            reset_counters_in   => reset_crc_cnt_sync,
            crc_checked_cnt_out => open,
            crc_error_cnt_out   => open,
--            trailer_out         => open,
            crc_error_out       => crc_error 
);


--    -- PRBS checking -------------------------------------------------------------------------------------------------------------
--    prbs_check_inst:  ultrascale_checking_64b66b
--        GENERIC MAP
--        (SELECT_PATTERN => "PRBS")     
--        PORT MAP(
--                gtwiz_reset_all_in          => rst,
--                gtwiz_userclk_rx_usrclk2_in => rd_en_i,
--                gtwiz_userclk_rx_active_in  => '1',
--                rxdatavalid_in              => "11",
--                rxdata_in                   => fifo_out_i(DATA_WIDTH - 1 DOWNTO 0),                
--                rxgearboxslip_out           => open,
--                prbs_match_out              => open, 
--                rx_latency_trigger_flag_out => open                
--                );  


-- GTH ports
ttc_data_out <= fifo_out_i(DATA_WIDTH - 1 DOWNTO 0);
ttc_valid_out <= fifo_out_i(DATA_WIDTH);


END ARCHITECTURE;
