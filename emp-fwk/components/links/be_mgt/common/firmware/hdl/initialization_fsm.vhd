----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/04/2018 06:15:59 PM
-- Design Name: 
-- Module Name: initialization_fsm - RTL
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

-- =====================================================================================================================
-- This example design initialization module provides a demonstration of how initialization logic can be constructed to
-- interact with and enhance the reset controller helper block in order to assist with successful system bring-up. This
-- example initialization logic monitors for timely reset completion, retrying resets as necessary to mitigate problems
-- with system bring-up such as clock or data connection readiness. This is an example and can be modified as necessary.
-- =====================================================================================================================


entity initialization_fsm is
generic (STABLE_CLOCK_PERIOD : real);
port ( 
 		clk_freerun_in 	: IN STD_LOGIC;
 		reset_all_in 	: IN STD_LOGIC;
 		tx_init_done_in	: IN STD_LOGIC;
 		rx_init_done_in	: IN STD_LOGIC;
 		rx_data_good_in	: IN STD_LOGIC;
 		reset_all_out  	: OUT STD_LOGIC;
 		reset_rx_out 	: OUT STD_LOGIC;
 		init_done_out 	: OUT STD_LOGIC;
 		retry_ctr_out 	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	 );
end initialization_fsm;




architecture RTL of initialization_fsm is

component reset_synchronizer
    port (
        clk_in : IN STD_LOGIC;
        rst_in  : IN STD_LOGIC;
        rst_out : OUT STD_LOGIC   
        );
end component;

component bit_synchronizer
    port (
        clk_in : IN STD_LOGIC;
        i_in  : IN STD_LOGIC;
        o_out : OUT STD_LOGIC   
        );
end component;


signal reset_all_sync 	 : STD_LOGIC;
signal tx_init_done_sync : STD_LOGIC;
signal rx_init_done_sync : STD_LOGIC;
signal rx_data_good_sync : STD_LOGIC;

signal timer_clr 	: STD_LOGIC;
signal tx_timer_sat : STD_LOGIC;
signal rx_timer_sat : STD_LOGIC;
signal timer_ctr 	: UNSIGNED(24 DOWNTO 0) := (others => '0');

constant P_FREERUN_FREQUENCY : real := STABLE_CLOCK_PERIOD;
constant P_TX_TIMER_DURATION_US : real := 30000.0;
constant P_RX_TIMER_DURATION_US : real := 130000.0;

constant p_tx_timer_term_cyc_int : real := P_TX_TIMER_DURATION_US * P_FREERUN_FREQUENCY;
constant p_rx_timer_term_cyc_int : real := P_RX_TIMER_DURATION_US * P_FREERUN_FREQUENCY;

signal retry_ctr_out_i : UNSIGNED(3 DOWNTO 0);
signal retry_ctr_incr : STD_LOGIC := '0';

type StateType is (ST_START,ST_TX_WAIT,ST_RX_WAIT,ST_MONITOR);
signal State : StateType;

signal sm_init_active  : STD_LOGIC := '0';

attribute DONT_TOUCH : string;
attribute DONT_TOUCH of reset_synchronizer_reset_all_inst  : label is "true";
attribute DONT_TOUCH of bit_synchronizer_tx_init_done_inst : label is "true";
attribute DONT_TOUCH of bit_synchronizer_rx_init_done_inst : label is "true";
attribute DONT_TOUCH of bit_synchronizer_rx_data_good_inst : label is "true";




BEGIN


---------------------------------------------------------------------------------------------------------------------
-- Synchronizers
---------------------------------------------------------------------------------------------------------------------

-- Synchronize the "reset all" input signal into the free-running clock domain
-- The reset_all_in input should be driven by the master "reset all" example design input
reset_synchronizer_reset_all_inst: reset_synchronizer  
    port map (
              clk_in  => clk_freerun_in,
              rst_in  => reset_all_in,
              rst_out => reset_all_sync
              );
              
-- Synchronize the TX initialization done indicator into the free-running clock domain
-- The tx_init_done_in input should be driven by the signal or logical combination of signals that represents a
-- completed TX initialization process; for example, the reset helper block gtwiz_reset_tx_done_out signal, or the
-- logical AND of gtwiz_reset_tx_done_out with gtwiz_buffbypass_tx_done_out if the TX buffer is bypassed.
bit_synchronizer_tx_init_done_inst: bit_synchronizer  
    port map (
              clk_in  => clk_freerun_in,
              i_in  => tx_init_done_in,
              o_out => tx_init_done_sync
              );
              
-- Synchronize the RX initialization done indicator into the free-running clock domain
-- The rx_init_done_in input should be driven by the signal or logical combination of signals that represents a
-- completed RX initialization process; for example, the reset helper block gtwiz_reset_rx_done_out signal, or the
-- logical AND of gtwiz_reset_rx_done_out with gtwiz_buffbypass_rx_done_out if the RX elastic buffer is bypassed.
bit_synchronizer_rx_init_done_inst: bit_synchronizer  
    port map (
              clk_in  => clk_freerun_in,
              i_in  => rx_init_done_in,
              o_out => rx_init_done_sync
              );              
 
-- Synchronize the RX data good indicator into the free-running clock domain
-- The rx_data_good_in input should be driven the user application's indication of continual good data reception.
-- The example design drives rx_data_good_in high when no PRBS checker errors are seen in the 8 most recent
-- consecutive clock cycles of data reception.              
bit_synchronizer_rx_data_good_inst: bit_synchronizer  
    port map (
              clk_in  => clk_freerun_in,
              i_in  => rx_data_good_in,
              o_out => rx_data_good_sync
              );


-- When the timer is enabled by the initialization state machine, increment the timer_ctr counter until its value
-- reaches p_rx_timer_term_cyc_int RX terminal count and rx_timer_sat is asserted. Assert tx_timer_sat when the
-- counter value reaches the p_tx_timer_term_cyc_int TX terminal count. Clear the timer and remove assertions when the
-- timer is disabled by the initialization state machine.
process (clk_freerun_in)
  begin
    if rising_edge(clk_freerun_in) then
    	if timer_clr = '1' then
    		timer_ctr    <= (others => '0');
      		tx_timer_sat <= '0';
      		rx_timer_sat <= '0';
      	else
      		if (to_integer(unsigned(timer_ctr)) = integer(p_tx_timer_term_cyc_int)) then
      			tx_timer_sat <= '1';
      		end if;
      		if (to_integer(unsigned(timer_ctr)) = integer(p_rx_timer_term_cyc_int)) then
		        rx_timer_sat <= '1';
		    else 
		    	timer_ctr <= timer_ctr + 1;
		    end if;
		end if;
	end if;
end process;



-- -------------------------------------------------------------------------------------------------------------------
-- Retry counter
-- ----------------------------------------------------------------------------------------------------------------- 
-- Increment the retry_ctr_out register for each TX or RX reset asserted by the initialization state machine until the
-- register saturates at 4'd15. This value, which is initialized on device programming and is never reset, could be
-- useful for debugging purposes. The initialization state machine will continue to retry as needed beyond the retry
-- register saturation point indicated, so 4'd15 should be interpreted as "15 or more attempts since programming."
process (clk_freerun_in)
  begin 
    if rising_edge(clk_freerun_in) then
        if ((retry_ctr_incr = '1') and (retry_ctr_out_i /= "1111")) then
            retry_ctr_out_i <= retry_ctr_out_i + 1;
        end if;
   	end if;
end process;

retry_ctr_out <= STD_LOGIC_VECTOR(retry_ctr_out_i);


-- -------------------------------------------------------------------------------------------------------------------
-- Initialization state machine
-- -------------------------------------------------------------------------------------------------------------------

-- Implement the initialization state machine control and its outputs as a single sequential process. The state
-- machine is reset by the synchronized reset_all_in input, and does not begin operating until its first use. Note
-- that this state machine is designed to interact with and enhance the reset controller helper block.
process (clk_freerun_in) 
  begin
  	if rising_edge(clk_freerun_in) then
  	     if reset_all_sync = '1' then
            timer_clr      	<= '1';
            reset_all_out  	<= '0';
            reset_rx_out   	<= '0';
            retry_ctr_incr 	<= '0';
            init_done_out  	<= '0';
            sm_init_active 	<= '1';
  		    State 		   	<= ST_START;
	      else
              case State is 
                -- When starting the initialization procedure, clear the timer and remove reset outputs, then proceed to wait
                -- for completion of TX initialization
                when ST_START =>  
                    if (sm_init_active = '1') then
                        timer_clr      	<= '1';
                        reset_all_out  	<= '0';
                        reset_rx_out   	<= '0';
                        retry_ctr_incr 	<= '0';
                        State          	<= ST_TX_WAIT;
                    end if;
                
                -- Enable the timer. If TX initialization completes before the counter's TX terminal count, clear the timer and
                -- proceed to wait for RX initialization. If the TX terminal count is reached, clear the timer, assert the
                -- reset_all_out output (which in this example causes a master reset_all assertion), and increment the retry
                -- counter. Completion conditions for TX initialization are described above.	  
                when ST_TX_WAIT =>
                    if (tx_init_done_sync = '1') then
                        timer_clr 	<= '1';
                        State   	<= ST_RX_WAIT;
                    else
                        if (tx_timer_sat = '1') then
                            timer_clr      	<= '1';
                            reset_all_out  	<= '1';
                            retry_ctr_incr 	<= '1';
                            State        	<= ST_START;
                        else
                            timer_clr 		<= '0';
                        end if;
                    end if;
        
                -- Enable the timer. When the RX terminal count is reached, check whether RX initialization has completed and
                -- whether the data good indicator is high. If both conditions are met, transition to the MONITOR state. If
                -- either condition is not met, then clear the timer, assert the reset_rx_out output (which in this example
                -- either drives gtwiz_reset_rx_pll_and_datapath_in or gtwiz_reset_rx_datapath_in, depending on PLL sharing),
                when ST_RX_WAIT => 
                    if (rx_timer_sat = '1') then 
                        if (rx_init_done_sync = '1' and rx_data_good_sync = '1') then -- 
                            init_done_out 	<= '1';
                            State       	<= ST_MONITOR;
                        else 
                            timer_clr      	<= '1';
                            reset_rx_out   	<= '1';
                            retry_ctr_incr 	<= '1';
                            State        	<= ST_START;
                        end if;
                    else
                        timer_clr <= '0';
                    end if;
        
                    -- In this MONITOR state, assert the init_done_out output for use as desired. If RX initialization or the data
                    -- good indicator is lost while in this state, reset the RX components as described in the ST_RX_WAIT state.
                when ST_MONITOR =>
                        if (rx_init_done_sync = '0' ) then -- or rx_data_good_sync = '0'
                            init_done_out      <= '0';
                            timer_clr          <= '1';
                            reset_rx_out       <= '1';
                            retry_ctr_incr     <= '1';
                            State            <= ST_START;
                        end if; 
              end case;
            end if;    
    end if;
end process;

end RTL;