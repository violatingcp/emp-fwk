----------------------------------------------------------------------------------
-- Company: UOI - CERN
-- Engineer: Stavros Mallios
-- 
-- Create Date: 25/09/2017 01:21:46 PM
-- Design Name: 16G ultrascale links
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: KCU105 board
-- Tool Versions: Vivado 2016.4
-- Description: 

-- Additional Comments: 
--       INITIALIZATION : For the initialization to succeed the TX and RX should be initialized and the link must be up (data aligned). 
--                       The init_done_i signal indicates that the initialization was successful
-- BIT-ALIGN/MONITORING : We align the incoming data by checking the 2-bit header, the paddind words and the idles.
--                MODES : There are currently 2 options for the patterns being transmited. 
--                         1. PRBS : PRBS-31 data. Valid bit is manipulated by a counter (in tx_fifo_cdc.vhd) and is 0 for 80 clks every 1024 clks  
--                         2. USER : Incoming data. 
--           MONITORING : When the link is up, to check the link status we monitor the 2-bit header and the padding/idle words.
--                        I also added prbs checkers after crossing to the local clock domain (@240MHz). (but they are meaningful only when we are in "PRBS" mode)
--       CLOCK CROSSING : We are using FIFOs to cross from/to the link clk domain and by injecting/removing padding words (0x78F7F7F7F7F7F7F7) 
--                        For the 16G links we use 66b64b encoding and synchronous gearbox with the elastic buffer bypassed to reduce latency. 
--             HARDWARE : The design (only 16g GTH) was tested using a KCU105 developement board. For the GTH ref clock we use the Si570 clk of the KCU105 board.
--                        For the TTC clock the 300Mhz sysclk is connected to an MMCM 
--                  CRC : a 32-bit CRC is injected at the end of a data stream before the TX Fifo. The CRC checkers are placed after the RX fifo.


-- ====================================================================================================
-- || Engineer | Version |                 Changes                | Tested | Test Board |    Date    ||
-- ||----------|---------|----------------------------------------|--------|------------|------------||
-- || smallios |   1.0   | add initialization block               |   yes  |   KCU105   |            ||
-- || smallios |   1.0a  | changed some signal/port names         |   yes  |   KCU105   | 20.06.2018 ||
-- || smallios |   1.1   | add header checker                     |   yes  |   KCU105   | 21.06.2018 || 
-- || smallios |   1.2   | add prbs/user data mux                 |   yes  |   KCU105   | 23.06.2018 ||
-- || smallios |   1.2a  | remove external 40M clk 	        	  |   yes  |   KCU105   | 29.06.2018 ||
-- || smallios |   1.3   | diff clocks to top module              |    no  |            | 18.07.2018 ||
-- || smallios |   1.3a  | change tx,rx buses to ldata record     |    no  |            | 18.07.2018 ||
-- || smallios |   1.4   | add crc checksums                      |   yes  |   KCU105   | 18.11.2018 || 
-- || smallios |   1.4a  | rx fifo minimum latency                |   yes  |   KCU105   | 20.11.2018 ||
-- || smallios |   1.5	 | replace rx fifo with a dual port BRAM  |   yes  |   KCU105   | 28.11.2018 ||
-- || kadamidis|   1.6	 | add scrambler - descrambler            |   yes  |   KCU116   | 17.12.2018 ||
-- ====================================================================================================


-- ===============================
-- |LOOPBACK MODES (UG576 p.86)  |
-- |-----------------------------|
-- |000: Normal operation        |    
-- |001: Near-end PCS Loopback   |
-- |010: Near-end PMA Loopback   |
-- |011: Reserved                |
-- |100: Far-end PMA Loopback    |
-- |101: Reserved                |
-- |110: Far-end PCS Loopback    |
-- ===============================
-----------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

USE IEEE.std_logic_misc.all; -- OR_REDUCE & AND_REDUCE functions among others
use work.emp_data_types.all;



entity async_mgt_wrapper is
generic( 
         INDEX      : integer;
         LINK       : string  := "ASYNC"; -- ASYNC or SYNCH (use ASYNCH for now)
         PATTERN    : string  := "USER";  -- PRBS or USER
         DATA_WIDTH : natural := 64; 
         N_CHANNELS : natural := 4;
         STABLE_CLOCK_PERIOD : real := 31.25
        );
    Port ( 
           ttc_clk_in       : in STD_LOGIC;
           ttc_rst_in       : in STD_LOGIC;
           stable_clk_in    : in STD_LOGIC;
           top_mgtrefclk0   : in STD_LOGIC;    
           -- top_mgtrefclk0 => refclk_alt,
             
           -- High Speed Serdes data ports (MGTs appear to work fine without ports wired up)
           rxn_in   : in STD_LOGIC_VECTOR(N_CHANNELS - 1 DOWNTO 0 );
           rxp_in   : in STD_LOGIC_VECTOR(N_CHANNELS - 1 DOWNTO 0 );
           txn_out  : out STD_LOGIC_VECTOR(N_CHANNELS - 1 DOWNTO 0 );
           txp_out  : out STD_LOGIC_VECTOR(N_CHANNELS - 1 DOWNTO 0 );
            
           -- Parallel interface data
           txdata_in    : in  ldata(N_CHANNELS - 1  downto 0);
           rxdata_out   : out ldata(N_CHANNELS  - 1  downto 0);
           buf_rst_in      :  in std_logic_vector(N_CHANNELS - 1 downto 0);
           buf_ptr_inc_in  :  in  std_logic_vector(N_CHANNELS - 1 downto 0);
           buf_ptr_dec_in  :  in  std_logic_vector(N_CHANNELS - 1 downto 0);              
           -- Control and debugg ports
           soft_reset_in            : in STD_LOGIC; 
           top_link_status          : out STD_LOGIC;
           top_initialization_done  : out STD_LOGIC;
           link_down_latched_out    : out STD_LOGIC;
           reset_tx_done_out        : out STD_LOGIC;
           reset_rx_done_out        : out STD_LOGIC;
           buffbypass_tx_done_out   : out STD_LOGIC;
           buffbypass_rx_done_out   : out STD_LOGIC;
           loopback_mode_in         : in std_logic_vector(3 * N_CHANNELS -1 downto 0)  :=  "010010010010";
           reset_error_counter_in   : in STD_LOGIC;
           qpll0lock_out            : OUT STD_LOGIC;
           crc_error_out            : out STD_LOGIC_VECTOR(3 DOWNTO 0);
           
            
           -- Latency measurement signals
           top_tx_latency_trigger_flag_out  : out STD_LOGIC; 
           top_rx_latency_trigger_flag_out  : out STD_LOGIC 
          );
end async_mgt_wrapper;


ARCHITECTURE RTL OF async_mgt_wrapper IS


component vio_bit_synchronizers
    PORT(   
          clk_freerun_in               : in STD_LOGIC;
          txprgdivresetdone_int        : in STD_LOGIC_VECTOR(3 DOWNTO 0);
          txpmaresetdone_int           : in STD_LOGIC_VECTOR(3 DOWNTO 0);
          rxpmaresetdone_int           : in STD_LOGIC_VECTOR(3 DOWNTO 0);
          reset_tx_done_int            : in STD_LOGIC;
          reset_rx_done_int            : in STD_LOGIC;
          buffbypass_tx_done_int       : in STD_LOGIC;
          buffbypass_rx_done_int       : in STD_LOGIC;
          buffbypass_tx_error_int      : in STD_LOGIC;
          buffbypass_rx_error_int      : in STD_LOGIC;
          link_status_at_local_int     : in STD_LOGIC_VECTOR(3 DOWNTO 0);
          channel_error_latched_int    : in STD_LOGIC_VECTOR(N_CHANNELS -1 DOWNTO 0);
          txprgdivresetdone_vio_sync   : out STD_LOGIC_VECTOR(3 DOWNTO 0);
          txpmaresetdone_vio_sync      : out STD_LOGIC_VECTOR(3 DOWNTO 0);
          rxpmaresetdone_vio_sync      : out STD_LOGIC_VECTOR(3 DOWNTO 0);
          reset_tx_done_vio_sync       : out STD_LOGIC;
          reset_rx_done_vio_sync       : out STD_LOGIC;
          buffbypass_tx_done_vio_sync  : out STD_LOGIC;
          buffbypass_rx_done_vio_sync  : out STD_LOGIC;
          buffbypass_tx_error_vio_sync : out STD_LOGIC;
          buffbypass_rx_error_vio_sync : out STD_LOGIC;
          qpll0lock_out_int            : in  STD_LOGIC;
          qpll0lock_out_vio            : out STD_LOGIC;
          link_status_at_local_sync    : out STD_LOGIC_VECTOR(3 DOWNTO 0);
          channel_error_latched_sync   : out STD_LOGIC_VECTOR(N_CHANNELS -1 DOWNTO 0)                
        );          
END component;
         

component gtwizard_ultrascale_0_vio_0  
   PORT(
         clk           : in STD_LOGIC;          
         probe_in0     : in STD_LOGIC; 
         probe_in1     : in STD_LOGIC;
         probe_in2     : in STD_LOGIC;
         probe_in3     : in STD_LOGIC_VECTOR(N_CHANNELS  -1 DOWNTO 0);
         probe_in4     : in STD_LOGIC_VECTOR(N_CHANNELS  -1 DOWNTO 0);
         probe_in5     : in STD_LOGIC_VECTOR(N_CHANNELS  -1 DOWNTO 0);
         probe_in6     : in STD_LOGIC_VECTOR(N_CHANNELS  -1 DOWNTO 0);
         probe_in7     : in STD_LOGIC; 
         probe_in8     : in STD_LOGIC; 
         probe_in9     : in STD_LOGIC; 
         probe_in10    : in STD_LOGIC; 
         probe_in11    : in STD_LOGIC; 
         probe_in12    : in STD_LOGIC; 
         probe_in13    : in STD_LOGIC_VECTOR(N_CHANNELS  -1 DOWNTO 0);
         probe_in14    : in STD_LOGIC_VECTOR(8*N_CHANNELS + N_CHANNELS -1 DOWNTO 8*N_CHANNELS);
         probe_out0    : out STD_LOGIC; 
         probe_out1    : out STD_LOGIC;
         probe_out2    : out STD_LOGIC;
         probe_out3    : out STD_LOGIC;
         probe_out4    : out STD_LOGIC;
         probe_out5    : out STD_LOGIC       
        );
END component;


                    

----------------------------------------------------
----------------     SIGNALS     -------------------      
----------------------------------------------------

 
-- PRBS-31 based link status ports signals
   signal link_status_i : STD_LOGIC;
   signal link_down_latched_out_i : STD_LOGIC;
   signal link_down_latched_i   : STD_LOGIC;
   signal vio_reset_error_counter_i : STD_LOGIC;
 
   signal qpll_clk_out_i  : STD_LOGIC;

-- TX signals
   signal txusrclk2_i  : STD_LOGIC;
   signal txusrrst2_i  : STD_LOGIC; 
   signal txdata_i     : STD_LOGIC_VECTOR (N_CHANNELS*DATA_WIDTH - 1 DOWNTO 0);
   signal txheader_i, txheader_d   : STD_LOGIC_VECTOR (N_CHANNELS*6 - 1 DOWNTO 0);
   signal txsequence_i, txsequence_d : STD_LOGIC_VECTOR(N_CHANNELS*7 - 1 DOWNTO 0);
   signal userclk_rx_active_i : STD_LOGIC;  
   signal txdata_scrambled : STD_LOGIC_VECTOR (N_CHANNELS*DATA_WIDTH - 1 DOWNTO 0);
   
-- RX signals
   signal rxusrclk2_i : STD_LOGIC; 
   signal rxusrrst2_i : STD_LOGIC;   
   signal rxdata_i    : STD_LOGIC_VECTOR(N_CHANNELS*DATA_WIDTH - 1 DOWNTO 0);
   signal rxheader_out_i, rxheader_out_d  : STD_LOGIC_VECTOR(N_CHANNELS*6 - 1 DOWNTO 0);
   signal rx_datavalid_i , rx_datavalid_d : STD_LOGIC_VECTOR(N_CHANNELS*2 - 1 DOWNTO 0); 
   signal rxgearboxslip_i, rxgearboxslip_d : STD_LOGIC_VECTOR(N_CHANNELS   - 1 DOWNTO 0);
   signal userclk_tx_active_i : STD_LOGIC;
   signal unscrambled_data : STD_LOGIC_VECTOR (N_CHANNELS*DATA_WIDTH - 1 DOWNTO 0);
       
-- PRBS-31 64b66b stimulus & checking modules
   signal error_checker_reset_i : STD_LOGIC;
   signal reset_all_i   : STD_LOGIC;
   signal prbs_match_i : STD_LOGIC_VECTOR(N_CHANNELS-1 DOWNTO 0);
   signal data_good_i : STD_LOGIC_VECTOR(N_CHANNELS-1 DOWNTO 0);
   signal prbs_match_local_i : STD_LOGIC_VECTOR(N_CHANNELS-1 DOWNTO 0);

-- TTC clock signals      
   signal rst_240_i     : STD_LOGIC;

    
--INIT
   signal reset_all_vio_i : STD_LOGIC;
   signal reset_error_counter : STD_LOGIC;
   signal reset_tx_done_i : STD_LOGIC;
   signal reset_rx_done_i : STD_LOGIC;
   signal buffbypass_tx_done_i : STD_LOGIC;
   signal buffbypass_rx_done_i : STD_LOGIC;
   signal reset_init_module_i : STD_LOGIC;
   signal init_reset_out_i : STD_LOGIC;
   signal tx_init_done_i : STD_LOGIC;
   signal rx_init_done_i : STD_LOGIC;
   signal qpll0lock_out_int : STD_LOGIC;
   signal init_done_i : STD_LOGIC;
   signal retry_ctr_i : STD_LOGIC_VECTOR(N_CHANNELS-1 DOWNTO 0);
   signal reset_rx_datapath_init_i : STD_LOGIC;
  
-- TX usr resets
   signal txpmaresetdone_i : STD_LOGIC_VECTOR(N_CHANNELS-1 DOWNTO 0);
   signal txprgdivresetdone_i  : STD_LOGIC_VECTOR(N_CHANNELS-1 DOWNTO 0);
   signal rxpmaresetdone_i  : STD_LOGIC_VECTOR(N_CHANNELS-1 DOWNTO 0);

-- RX user resets
   signal reset_rx_datapath_i : STD_LOGIC; 
   signal reset_rx_datapath_vio_i : STD_LOGIC;
    
-- Buffer bypass resets 
   signal userclk_tx_active_n_i : STD_LOGIC;
   signal buffbypass_tx_reset_i : STD_LOGIC;
   signal buffbypass_rx_reset_i : STD_LOGIC;
   signal buffbypass_rx_reset_buffered_i : STD_LOGIC;
   
-- VIO FOR HARDWARE BRING-UP AND DEBUG signals synchronized into the free-running clk domain
   signal txprgdivresetdone_vio_sync : STD_LOGIC_VECTOR(N_CHANNELS-1 DOWNTO 0);
   signal txpmaresetdone_vio_sync : STD_LOGIC_VECTOR(N_CHANNELS-1 DOWNTO 0);
   signal rxpmaresetdone_vio_sync : STD_LOGIC_VECTOR(N_CHANNELS-1 DOWNTO 0);
   signal reset_tx_done_vio_sync : STD_LOGIC;
   signal reset_rx_done_vio_sync : STD_LOGIC;
   signal buffbypass_tx_done_vio_sync : STD_LOGIC;
   signal buffbypass_rx_done_vio_sync : STD_LOGIC;
   signal buffbypass_tx_error_vio_sync : STD_LOGIC;
   signal buffbypass_rx_error_vio_sync : STD_LOGIC;
   signal qpll0lock_out_vio     : STD_LOGIC;
   signal buffbypass_tx_error_i : STD_LOGIC;
   signal buffbypass_rx_error_i : STD_LOGIC;
   signal reset_tx_pll_and_datapath_vio_i : STD_LOGIC;
   signal reset_tx_datapath_vio_i : STD_LOGIC;
   signal reset_rx_pll_and_datapath_vio_i : STD_LOGIC;
   signal link_status_at_local_vio_sync : STD_LOGIC_VECTOR(N_CHANNELS-1 DOWNTO 0);
   signal tx_datavalid_i : STD_LOGIC_VECTOR(3 downto 0); 

   signal ttc_data_out_i : STD_LOGIC_VECTOR (N_CHANNELS*DATA_WIDTH - 1 DOWNTO 0);
   signal channel_error_latched_i      : STD_LOGIC_VECTOR(N_CHANNELS -1 DOWNTO 0);
   signal channel_error_latched_sync   : STD_LOGIC_VECTOR(N_CHANNELS -1 DOWNTO 0);

     
   attribute DONT_TOUCH : string;
   attribute DONT_TOUCH of reset_synchronizer_buffbypass_tx_reset_inst : label is "true";
   attribute DONT_TOUCH of reset_synchronizer_buffbypass_rx_reset_inst : label is "true";

       
BEGIN


---  ===================================================================================================================
---  RESETS
---  ===================================================================================================================

-- combined MGT general reset from initialization FSM or from Soft reset from IPBus
reset_all_i <= init_reset_out_i or reset_all_vio_i or soft_reset_in; --or reset_all_ipb;
reset_error_counter <= reset_error_counter_in or vio_reset_error_counter_i;

-- PRBS checker should be held in reset until the TX and RX are initialized. Also should reset when we issue an MGT general reset.  
error_checker_reset_i <= not(rx_init_done_i) or not(tx_init_done_i) or reset_all_i;

-- Combine the receiver reset signals form the initialization module and the VIO to drive the appropriate reset
-- controller helper block reset input
reset_rx_datapath_i <= reset_rx_datapath_init_i or reset_rx_datapath_vio_i;  

--   -- BUFFER BYPASS CONTROLLER RESETS --
--   The TX buffer bypass controller helper block should be held in reset until the TX user clocking network helper
--   block, which drives it, is active.It must be synchronous to the txusrclk2
userclk_tx_active_n_i <= not userclk_tx_active_i;
reset_synchronizer_buffbypass_tx_reset_inst:  entity work.reset_synchronizer  
    Port Map(
              clk_in  => txusrclk2_i,
              rst_in  => userclk_tx_active_n_i,
              rst_out => buffbypass_tx_reset_i
            );

--   The RX buffer bypass controller helper block should be held in reset until the RX user clocking network helper
--   block which drives it is active and the TX buffer bypass sequence has completed for this loopback configuration. It must be synchronous to the rxusrclk2
buffbypass_rx_reset_i  <= not userclk_rx_active_i or not buffbypass_tx_done_i; 
reset_synchronizer_buffbypass_rx_reset_inst:  entity work.reset_synchronizer 
    Port Map(
              clk_in  => rxusrclk2_i,
              rst_in  => buffbypass_rx_reset_i,
              rst_out => buffbypass_rx_reset_buffered_i
            );


   
   
---  ===================================================================================================================
---  SYNCHRONOUS LINKS PRBS STIMULUS, CHECKING, AND LINK MANAGEMENT
---  ===================================================================================================================

sync_links:IF LINK = "SYNC" GENERATE 
--  -- Loop over all channels
prbs_gen: for I in 0 to N_CHANNELS-1 generate

    attribute DONT_TOUCH : string;
    attribute DONT_TOUCH of prbs_stimulus_inst : label is "true";
    attribute DONT_TOUCH of prbs_check_inst    : label is "true";

    begin 
    
    --   PRBS stimulus -------------------------------------------------------------------------------------------------------------------         
    prbs_stimulus_inst: entity work.ultrascale_stimulus_64b66b -- gtwizard_ultrascale_0_example_stimulus_64b66b
        GENERIC MAP
        (SELECT_PATTERN => "PRBS") 
        PORT MAP(
                 gtwiz_reset_all_in          => reset_all_i,
                 gtwiz_userclk_tx_usrclk2_in => txusrclk2_i,
                 gtwiz_userclk_tx_active_in  => userclk_tx_active_i,
                 txheader_out                => txheader_i( 6*I + 5 DOWNTO 6*I ),
                 txsequence_out              => txsequence_i( 7*I + 6 DOWNTO 7*I ),
                 txdata_out                  => txdata_i( DATA_WIDTH*I + DATA_WIDTH-1 DOWNTO DATA_WIDTH*I ),
                 tx_latency_trigger_flag_out => open
                );    

    
    -- PRBS checking -------------------------------------------------------------------------------------------------------------------
    prbs_check_inst:  entity work.ultrascale_checking_64b66b --gtwizard_ultrascale_0_example_checking_64b66b
        PORT MAP(
                 gtwiz_reset_all_in          => error_checker_reset_i,
                 gtwiz_userclk_rx_usrclk2_in => rxusrclk2_i,
                 gtwiz_userclk_rx_active_in  => userclk_rx_active_i,
                 rxdatavalid_in              => rx_datavalid_i( 2*I+1 DOWNTO 2*I ),
                 rxdata_in                   => rxdata_i( DATA_WIDTH*I + DATA_WIDTH-1 DOWNTO DATA_WIDTH*I ),
                 init_done_in                => init_done_i,
                 rxgearboxslip_out           => rxgearboxslip_i( i ),
                 prbs_match_out              => prbs_match_i( i ), 
                 rx_latency_trigger_flag_out => open                
                );  


end generate prbs_gen;

end generate;


--  ===================================================================================================================
--  ASYNCHRONOUS PRBS STIMULUS, FIFO CDC, CHECKING, LINK MANAGEMENT
--    An MMCM primitive is used to source the 240MHz local clock
--    For every link :
--     - TX cdc uses a fifo and a padding word injecter to cross from local to link domain and a prbs data generator to bring the link up
--     - RX cdc uses a fifo to cross from link to local clock domain and 
--     - PRBS data checker is used to bring the link up at link domain
--     - PRBS data checker is used to check the clock crossing at fabric domain
--  ===================================================================================================================

async_links:IF LINK = "ASYNC" GENERATE 

---------------------------------
-- Loop over all (N_CHANNELS) channels
---------------------------------
cdc_and_stimulus_gen: for I in 0 to N_CHANNELS-1 GENERATE

    attribute DONT_TOUCH : string;
    attribute DONT_TOUCH of tx_fifo_inst : label is "true";
    attribute DONT_TOUCH of data_check_inst    : label is "true";

BEGIN

-----------------------------------------------------------------
-- Instantiate PRBS stimulus and CDC FIFO
-- Pattern selection : 
--           "PRBS" : for prbs only or 
--           "USER" : prbs to bring the link up, then user data
------------------------------------------------------------------
tx_fifo_inst: entity work.tx_fifo_cdc
        GENERIC MAP 
            (DATA_WIDTH => DATA_WIDTH, 
             PATTERN => PATTERN,
             INDEX => INDEX )
        PORT MAP(
                 ttc_clk          => ttc_clk_in,
                 link_clk         => txusrclk2_i,   
                 reset            => reset_all_i,
                 tx_data_in       => txdata_in(I).data,
                 tx_data_valid    => txdata_in(i).valid,
                 tx_data_out      => txdata_i( DATA_WIDTH*I + DATA_WIDTH-1 DOWNTO DATA_WIDTH*I ),
                 tx_datavalid_i   => tx_datavalid_i(i),
                 tx_sequence_out  => txsequence_i( 7*I + 6 DOWNTO 7*I ),
                 tx_header_out    => txheader_i( 6*I + 5 DOWNTO 6*I )
                );


scrambler: entity work.aurora_SCRAMBLER
        Port Map(
                 txdata_i        => txdata_i( DATA_WIDTH*I + DATA_WIDTH-1 DOWNTO DATA_WIDTH*I ),
                 scrambled_data  => txdata_scrambled( DATA_WIDTH*I + DATA_WIDTH-1 DOWNTO DATA_WIDTH*I ),
                 txusrclk2_i     => txusrclk2_i,
                 reset_all_i     => reset_all_i,
                 tx_datavalid_i  => tx_datavalid_i(i),
                 txheader_i      => txheader_i( 6*I + 5 DOWNTO 6*I ),
                 txheader_d      => txheader_d( 6*I + 5 DOWNTO 6*I ),
                 txsequence_i    => txsequence_i( 7*I + 6 DOWNTO 7*I ),
                 txsequence_d    => txsequence_d( 7*I + 6 DOWNTO 7*I )
                 ); 
      
         
data_check_inst: entity work.data_quality_with_idle
  Port map(
            reset_all_in                => error_checker_reset_i,
            rx_usrclk2_in               => rxusrclk2_i,
            rx_active_in                => userclk_rx_active_i,
            rxdatavalid_in              => rx_datavalid_d( 2*I + 1 DOWNTO 2*I ),
            rxdata_in                   => unscrambled_data( DATA_WIDTH*I+DATA_WIDTH-1 DOWNTO DATA_WIDTH*I ), --rxdata_i( DATA_WIDTH*I+DATA_WIDTH-1 DOWNTO DATA_WIDTH*I ),                
            rxdata_header_in            => rxheader_out_d( 6*I + 5 DOWNTO 6*I ),
            rxgearboxslip_out           => rxgearboxslip_i( i ),
            prbs_match_out              => open, --prbs_match_i( i ), 
            data_good                   => data_good_i( i )
           );

-----------------------------------------------------------------------------------------------------
-- Simple FIFO-based clock crossing logic. Data are stripped from padding words and fed to the FIFO 
-----------------------------------------------------------------------------------------------------
rx_fifo_inst: entity work.rx_fifo_cdc
        GENERIC MAP 
            (DATA_WIDTH => DATA_WIDTH)
        PORT MAP(
                 ttc_clk         =>  ttc_clk_in,
                 link_clk        =>  rxusrclk2_i,   
                 reset           =>  reset_all_i,
                 init_done       =>  init_done_i,
                 reset_crc_cnt   =>  reset_error_counter, 
                 rx_data_in      =>  unscrambled_data( DATA_WIDTH*I+DATA_WIDTH-1 DOWNTO DATA_WIDTH*I ),
                 rx_header_in    =>  rxheader_out_d( 6*I + 5 DOWNTO 6*I ),
                 buf_rst_in      =>  buf_rst_in(i),
                 buf_ptr_inc_in  =>  buf_ptr_inc_in(i),
                 buf_ptr_dec_in  =>  buf_ptr_dec_in(i),
                 rx_datavalid_in =>  rx_datavalid_d( 2*i ),
                 ttc_data_out    =>  ttc_data_out_i( DATA_WIDTH*I+DATA_WIDTH-1 DOWNTO DATA_WIDTH*I ),
                 ttc_valid_out   =>  rxdata_out(I).valid,
                 crc_error       =>  crc_error_out(i)
               );

    rxdata_out(I).data   <= ttc_data_out_i( DATA_WIDTH*I+DATA_WIDTH-1 DOWNTO DATA_WIDTH*I );
    rxdata_out(I).strobe <= '1';
    rxdata_out(I).start  <= '0';
 
descrambler : entity work.aurora_DESCRAMBLER
        Port Map(
                 rxdata_i         => rxdata_i( DATA_WIDTH*I+DATA_WIDTH-1 DOWNTO DATA_WIDTH*I ),
                 unscrambled_data => unscrambled_data( DATA_WIDTH*I+DATA_WIDTH-1 DOWNTO DATA_WIDTH*I ),
                 rxusrclk2_i      => rxusrclk2_i,
                 reset_all_i      => reset_all_i,
                 rxheader_out_i   => rxheader_out_i( 6*I + 5 DOWNTO 6*I ),
                 rxheader_out_d   => rxheader_out_d( 6*I + 5 DOWNTO 6*I ),
                 rx_datavalid_i   => rx_datavalid_i( 2*i ),
                 rx_datavalid_d   => rx_datavalid_d( 2*i ),
                 rxgearboxslip_i  => rxgearboxslip_i(i),
                 rxgearboxslip_d  => rxgearboxslip_d(i)
                 );

--------------------------------------------------------------------------------------------
-- Check PRBS data received after crossing to fabric clock domain. Used for data validation at fabric clock domain. Latched error indicator is included. 
--------------------------------------------------------------------------------------------
ttc_prbs_checker_inst: entity work.ttc_prbs_checker
        GENERIC MAP
            (SELECT_PATTERN => "PRBS") 
        PORT MAP(
                  reset                  => error_checker_reset_i,
                  clk                    => ttc_clk_in,
                  rx_active              => userclk_rx_active_i,
                  rxdatavalid_in         => "11",
                  data_in                => ttc_data_out_i( DATA_WIDTH*I+DATA_WIDTH-1 DOWNTO DATA_WIDTH*I ),
                  reset_error_latched    => reset_error_counter, 
                  prbs_match_out         => prbs_match_local_i( i ),
                  channel_error_latched  =>  channel_error_latched_i( i )
                );
 
END GENERATE cdc_and_stimulus_gen;

END GENERATE;

--  ===================================================================================================================
--  LINK STATUS AND ERROR FLAGS AND COUNTERS
--      Links status indicates if link is UP or DOWN. 
--      Link indicator is monitored by the initialization FSM. 
--      Includes a latched link indicator (for single errors). 
--  ===================================================================================================================
link_status_inst: entity work.link_status
    GENERIC MAP
              (PATTERN => PATTERN) 
    port map( 
              -- Differential reference clock inputs
              clk_freerun_buf_int => stable_clk_in,
              clk_rx_in           => rxusrclk2_i, 
              reset               => reset_error_counter,
              data_good_in        => data_good_i,
              link_status         => link_status_i,
              error_counter       => open,
              link_down_latched   => link_down_latched_i
            );

--  ===================================================================================================================
--  INITIALIZATION : 
--  The initialization module interacts with the reset controller helper block and other design logic to retry
--     failed reset attempts in order to mitigate bring-up issues such as initially-unavailable reference clocks
--     or data connections.
--  It also resets the receiver in the event of link loss in an attempt to regain link, so please note the 
--    possibility that this behavior can have the effect of overriding or disturbing user-provided inputs that
--    destabilize the data stream.
--  The INIT FSM :
--    - Waits for TX initialization
--    - Waits for RX initialization
--    - Monitors the link status (prbs checker or 2-bit header value). If down it tries to re-initialize the link
--  ===================================================================================================================

tx_init_done_i <= reset_tx_done_i and buffbypass_tx_done_i; -- tx ready indicator
rx_init_done_i <= reset_rx_done_i and buffbypass_rx_done_i; -- rx ready indicator

initialization_fsm_init:  entity work.initialization_fsm
    generic map ( STABLE_CLOCK_PERIOD => STABLE_CLOCK_PERIOD)
    port map(
              clk_freerun_in   =>  stable_clk_in,
              reset_all_in     =>  reset_all_i,
              tx_init_done_in  =>  tx_init_done_i, 
              rx_init_done_in  =>  rx_init_done_i, 
              rx_data_good_in  =>  link_status_i,
              reset_all_out    =>  init_reset_out_i, 
              reset_rx_out     =>  reset_rx_datapath_init_i,
              init_done_out    =>  init_done_i,
              retry_ctr_out    =>  retry_ctr_i 
            );

--  ===================================================================================================================
--  VIO FOR HARDWARE BRING-UP AND DEBUG
--      Debug and analysis signals are synchronised to the freerunning clock.
--      A VIO core is used to monitor link status signals and apply resets.
--      For usage, refer to Vivado Design Suite.
--   User Guide: Programming and Debugging (UG908).
--  ===================================================================================================================

-----------------------------------------------------------------
-- Signals which are synchronous to clocks other than the 
-- free-running clock will require synchronization.
-----------------------------------------------------------------
vio_bit_synchronizers_inst: vio_bit_synchronizers
    PORT MAP(
              clk_freerun_in               => stable_clk_in,
              txprgdivresetdone_int        => txprgdivresetdone_i, 
              txpmaresetdone_int           => txpmaresetdone_i, 
              rxpmaresetdone_int           => rxpmaresetdone_i, 
              reset_tx_done_int            => reset_tx_done_i, 
              reset_rx_done_int            => reset_rx_done_i, 
              buffbypass_tx_done_int       => buffbypass_tx_done_i, 
              buffbypass_rx_done_int       => buffbypass_rx_done_i, 
              buffbypass_tx_error_int      => buffbypass_tx_error_i,  
              buffbypass_rx_error_int      => buffbypass_rx_error_i,
              link_status_at_local_int     => prbs_match_local_i,
              channel_error_latched_int    => channel_error_latched_i,
              txprgdivresetdone_vio_sync   => txprgdivresetdone_vio_sync, 
              txpmaresetdone_vio_sync      => txpmaresetdone_vio_sync, 
              rxpmaresetdone_vio_sync      => rxpmaresetdone_vio_sync, 
              reset_tx_done_vio_sync       => reset_tx_done_vio_sync, 
              reset_rx_done_vio_sync       => reset_rx_done_vio_sync, 
              buffbypass_tx_done_vio_sync  => buffbypass_tx_done_vio_sync, 
              buffbypass_rx_done_vio_sync  => buffbypass_rx_done_vio_sync, 
              buffbypass_tx_error_vio_sync => buffbypass_tx_error_vio_sync, 
              buffbypass_rx_error_vio_sync => buffbypass_rx_error_vio_sync,
              link_status_at_local_sync    => link_status_at_local_vio_sync, 
              channel_error_latched_sync   => channel_error_latched_sync ,
              qpll0lock_out_int            => qpll0lock_out_int,
              qpll0lock_out_vio            => qpll0lock_out_vio
            );
            
            
  
--IPBus interface for control and debugg signals :
top_link_status          <= link_status_i; 
top_initialization_done  <= init_done_i;
reset_tx_done_out        <= reset_tx_done_vio_sync;
reset_rx_done_out        <= reset_rx_done_vio_sync;
buffbypass_tx_done_out   <= buffbypass_tx_done_vio_sync;
buffbypass_rx_done_out   <= buffbypass_rx_done_vio_sync;
qpll0lock_out            <= qpll0lock_out_vio;
link_down_latched_out    <= link_down_latched_i;

--gtwizard_ultrascale_0_vio_0_inst: gtwizard_ultrascale_0_vio_0  
--    PORT MAP(
--             clk          =>  stable_clk_in, 
--             probe_in0    =>  link_status_i, 
--             probe_in1    =>  link_down_latched_i, 
--             probe_in2    =>  init_done_i,  
--             probe_in3    =>  retry_ctr_i,  
--             probe_in4    =>  txprgdivresetdone_vio_sync,  
--             probe_in5    =>  txpmaresetdone_vio_sync,  
--             probe_in6    =>  rxpmaresetdone_vio_sync,  
--             probe_in7    =>  reset_tx_done_vio_sync,  
--             probe_in8    =>  reset_rx_done_vio_sync,  
--             probe_in9    =>  buffbypass_tx_done_vio_sync,  
--             probe_in10   =>  buffbypass_rx_done_vio_sync,  
--             probe_in11   =>  qpll0lock_out_vio,  
--             probe_in12   =>  buffbypass_rx_error_vio_sync,
--             probe_in13   =>  "1111",
--             probe_in14   =>  channel_error_latched_sync,   
--             probe_out0   =>  reset_all_vio_i, 
--             probe_out1   =>  reset_tx_pll_and_datapath_vio_i,   
--             probe_out2   =>  reset_tx_datapath_vio_i,   
--             probe_out3   =>  reset_rx_pll_and_datapath_vio_i,   
--             probe_out4   =>  reset_rx_datapath_vio_i, 
--             probe_out5   =>  vio_reset_error_counter_i 
--            );


--  ===================================================================================================================
--  GTY QUAD INSTANTIATION
--  ===================================================================================================================

-- GTY quad -------------------------------------------------------------------------------                            
mgt_ultrascale_top_inst: entity work.gtwizard_ultrascale_top 
    Generic Map ( INDEX => INDEX )
    PORT MAP(
           -- Reference clock inputs
          gtrefclk00_in         => top_mgtrefclk0,
           -- Serial data ports for transceiver channels 
          gtyrxp_in             => rxp_in,
          gtyrxn_in             => rxn_in,
          gtytxn_out            => txn_out,
          gtytxp_out            => txp_out,
           -- User-provided ports for reset helper block(s)
          gtwiz_reset_clk_freerun_in    => stable_clk_in,        
          -- MP7 design specific ports ------------------------------------
          qpll0outclk_out               =>  qpll_clk_out_i,
          -- TX ports
          gtwiz_userclk_tx_usrclk2_out  => txusrclk2_i,
          gtwiz_userclk_tx_reset_in     => txusrrst2_i,
          gtwiz_userdata_tx_in          => txdata_scrambled,
          txheader_in                   => txheader_d,
          txsequence_in                 => txsequence_d,    
          -- RX ports    
          gtwiz_userclk_rx_usrclk2_out  => rxusrclk2_i,
          gtwiz_userclk_rx_reset_in     => rxusrrst2_i,
          gtwiz_userdata_rx_out         => rxdata_i,
          rxheader_out                  => rxheader_out_i,
          rxdatavalid_out               => rx_datavalid_i,
          rxgearboxslip_in              => rxgearboxslip_d,  
          -- PRBS-31 64b66b stimulus & checking ports
          gtwiz_userclk_tx_active_out   => userclk_tx_active_i,
          gtwiz_userclk_rx_active_out   => userclk_rx_active_i,
          gtwiz_reset_all_in            => reset_all_i,                
          -- Initialization
          gtwiz_reset_tx_done_out       => reset_tx_done_i,
          gtwiz_reset_rx_done_out       => reset_rx_done_i,
          gtwiz_buffbypass_tx_done_out  => buffbypass_tx_done_i,
          gtwiz_buffbypass_rx_done_out  => buffbypass_rx_done_i,
          gtwiz_reset_rx_datapath_in    => reset_rx_datapath_init_i,
          txpmaresetdone_out            => txpmaresetdone_i,
          txprgdivresetdone_out         => txprgdivresetdone_i,
          rxpmaresetdone_out            => rxpmaresetdone_i,
          gtwiz_buffbypass_tx_reset_in  => buffbypass_tx_reset_i,
          gtwiz_buffbypass_rx_reset_in  => buffbypass_rx_reset_buffered_i,
          gtwiz_buffbypass_tx_error_out => buffbypass_tx_error_i,
          gtwiz_buffbypass_rx_error_out => buffbypass_rx_error_i,
          gtwiz_reset_tx_pll_and_datapath_in => reset_tx_pll_and_datapath_vio_i,
          gtwiz_reset_tx_datapath_in         => reset_tx_datapath_vio_i,
          gtwiz_reset_rx_pll_and_datapath_in => reset_rx_pll_and_datapath_vio_i,
          qpll0lock_out => qpll0lock_out_int,
          loopback_in   => loopback_mode_in --"010010010010" -- Near-end PMA Loopback -- loopback_mode
         );

    

END RTL;



