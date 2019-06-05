----------------------------------------------------------------------------------
-- Project - emp_fwk
-- Component - links
-- Description
--    Rev. 0.1 - Integrate mgt16 from Stavros MALLIOUS to emp - Krerk PIROMSOPA , Pitchaya SITTI-AMORN 
--    Rev. 0.2 - Integrate MGTs (gth16, gty16, gty25) - kadamidis
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.emp_framework_decl.all;
use work.emp_device_decl.all;
use work.emp_project_decl.all;
use work.emp_data_types.all;

entity emp_be_mgt is
  generic (
     INDEX      : integer;
     N_CHANNELS : integer := 4
     ); 
  port(
    clk             : in std_logic;
    rst             : in std_logic;
    ipb_in          : in ipb_wbus;
    ipb_out         : out ipb_rbus;

    ttc_clk_in      : in  std_logic;       
    stable_clk_in   : in std_logic; 
    top_mgtrefclk0  : in std_logic;          
    
    rxn_in          : in   std_logic_vector(N_CHANNELS - 1 DOWNTO 0);
    rxp_in          : in   std_logic_vector(N_CHANNELS - 1 DOWNTO 0);
    txn_out         : out  std_logic_vector(N_CHANNELS - 1 DOWNTO 0);
    txp_out         : out  std_logic_vector(N_CHANNELS - 1 DOWNTO 0);         
    buf_rst_in      : in   std_logic_vector(N_CHANNELS - 1 downto 0);
    buf_ptr_inc_in  : in   std_logic_vector(N_CHANNELS - 1 downto 0);
    buf_ptr_dec_in  : in   std_logic_vector(N_CHANNELS - 1 downto 0);
    qplllock        : out  std_logic;
    -- Parallel interface data
    txdata_in  : in  ldata(N_CHANNELS - 1 DOWNTO 0);
    rxdata_out : out ldata(N_CHANNELS - 1 DOWNTO 0)          
 
);
end emp_be_mgt;

architecture behavioral of emp_be_mgt is
    signal ctrl     : ipb_reg_v(0 downto 0);
    signal status   : ipb_reg_v(0 downto 0);
    
-- in    
    signal mgt_rst               : std_logic;
    signal mgt_loopback          : std_logic := '0';
    signal mgt_error_counter_rst : std_logic;
    signal loopback_mode         : std_logic_vector(3 * N_CHANNELS - 1 downto 0) :="010010010010";
-- out  
    signal link_status           : std_logic;
    signal link_down_latched     : std_logic;
    signal init_done             : std_logic;
    signal reset_tx_done         : std_logic;
    signal reset_rx_done         : std_logic;
    signal bufferbypass_tx_done  : std_logic;
    signal bufferbypass_rx_done  : std_logic;
    signal qpll0lock_out         : std_logic;
    signal crc_error_out         : std_logic_vector(N_CHANNELS - 1 downto 0);
begin



async_mgt_inst : entity work.async_mgt_wrapper
    generic map(
            INDEX               => INDEX,            
            LINK                => "ASYNC",
            PATTERN             => "USER",
            DATA_WIDTH          => 64,
            N_CHANNELS          => 4,
            STABLE_CLOCK_PERIOD => 31.25)    
    port map(
            ttc_clk_in              => ttc_clk_in,      -- 240 MHz or 360 MHz
            ttc_rst_in              => rst,
            stable_clk_in           => stable_clk_in,   -- 31.25 MHz
            top_mgtrefclk0          => top_mgtrefclk0,   -- 250 MHz            
            -- High Speed Serdes data ports 
            rxn_in                  => rxn_in,  
            rxp_in                  => rxp_in ,
            txn_out                 => txn_out,
             txp_out                => txp_out,
             -- Parallel interface data
            txdata_in               => txdata_in,
            rxdata_out              => rxdata_out,
            -- Control and debugg ports
            buf_rst_in              => buf_rst_in,
            buf_ptr_inc_in          => buf_ptr_inc_in,
            buf_ptr_dec_in          => buf_ptr_dec_in,
            soft_reset_in           => mgt_rst,  
            top_link_status         => link_status,
            link_down_latched_out   => link_down_latched,
            top_initialization_done => init_done,
            reset_tx_done_out       => reset_tx_done,
            reset_rx_done_out       => reset_rx_done,
            buffbypass_tx_done_out  => bufferbypass_tx_done,
            buffbypass_rx_done_out  => bufferbypass_rx_done,
            crc_error_out           => crc_error_out,
            qpll0lock_out           => qpll0lock_out,
            loopback_mode_in        => loopback_mode,
            reset_error_counter_in  => mgt_error_counter_rst,
            -- Latency measurement signals
            top_tx_latency_trigger_flag_out => open,
            top_rx_latency_trigger_flag_out => open
            );      
      
 -- IPbus Slave    
 csr: entity work.ipbus_ctrlreg_v
     generic map(
            N_CTRL => 1,
            N_STAT => 1
            )
     port map(
            clk       => clk,
            reset     => rst,
            ipbus_in  => ipb_in,
            ipbus_out => ipb_out,
            d         => status,
            q         => ctrl
            );
 
    status(0)(0) <= link_status;
    status(0)(1) <= init_done;
    status(0)(2) <= qpll0lock_out;
    status(0)(3) <= link_down_latched;
    status(0)(4) <= reset_tx_done;
    status(0)(5) <= reset_rx_done;
    status(0)(6) <= bufferbypass_tx_done;
    status(0)(7) <= bufferbypass_rx_done;
    status(0)(11 downto 8) <= crc_error_out;
    status(0)(31 downto 12)<=x"ABCDE";
 
    mgt_rst <= ctrl(0)(0);
    mgt_loopback <= ctrl(0)(1); 
    mgt_error_counter_rst <= ctrl(0)(2);
    loopback_mode <= "000000000000" when mgt_loopback = '1' else "010010010010" ;


end behavioral;






