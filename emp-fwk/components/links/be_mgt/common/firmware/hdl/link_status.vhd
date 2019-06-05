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

USE IEEE.std_logic_misc.all; -- contains OR_REDUCE, AND_REDUCE

--use work.package_mp7_links.all;  
library work;
use work.all;


entity link_status is
    GENERIC ( 
             PATTERN : STRING := "PRBS"
            );
    Port ( 
          -- Differential reference clock inputs
           clk_freerun_buf_int : in STD_LOGIC;
           clk_rx_in       : in STD_LOGIC;
           reset           : in STD_LOGIC;
           data_good_in    : in STD_LOGIC_VECTOR( 3 DOWNTO 0);
           link_status     : out STD_LOGIC;
           error_counter   : out STD_LOGIC_VECTOR(11 DOWNTO 0) := (others=>'0');
           link_down_latched : out STD_LOGIC
           );
end link_status;


architecture RTL of link_status is



  signal sm_link  : std_logic := '0';
  signal link_ctr : std_logic_vector(6 DOWNTO 0);  
  signal link_error_async : std_logic;
  signal header_error_any_async : std_logic;
  signal link_error_sync : std_logic;
  signal header_error_any_sync : std_logic;
  signal error_counter_i : std_logic_vector(11 DOWNTO 0);
  signal link_down_latched_i : std_logic;
  signal link_error : std_logic;
--  signal reset_sync : std_logic;
  

  attribute keep : string;
  attribute keep of link_error_async : signal is "true";
  attribute keep of link_error_sync : signal is "true";


  attribute DONT_TOUCH : string;
  attribute DONT_TOUCH of bit_synchronizer_prbserror_inst : label is "true";
--  attribute DONT_TOUCH of reset_synchronizer_latchedsynch_inst : label is "true";


BEGIN

process(clk_rx_in)
  begin
    if rising_edge(clk_rx_in) then
        link_error_async <= not and_reduce(data_good_in(3 DOWNTO 0)); -- check any channel for error (prbs)
    end if;
end process;

--  Synchronize the PRBS mismatch indicator the free-running clock domain, using a reset synchronizer with asynchronous
--  reset and synchronous removal
bit_synchronizer_prbserror_inst: entity work.bit_synchronizer 
    port map(
             clk_in => clk_freerun_buf_int,
             i_in => link_error_async,
             o_out => link_error_sync
            );

--reset_synchronizer_latchedsynch_inst: entity work.reset_synchronizer 
--    Port Map(
--             clk_in  => clk_freerun_buf_int,
--             rst_in  => reset,
--             rst_out => reset_sync
--            );  


process(clk_freerun_buf_int)
begin
    if rising_edge(clk_freerun_buf_int) then
        
        if (sm_link = '0') then
        -- The link is considered to be down when the link counter initially has a value less than 67. When the link is
        -- down, the counter is incremented on each cycle where all PRBS bits match, but reset whenever any PRBS mismatch
        -- occurs. When the link counter reaches 67, transition to the link up state.
            if(link_error_sync = '1') then --prbs_error_any_sync = '1' or 
                link_ctr <= "0000000";
            else
                if (to_integer(unsigned(link_ctr)) < 67) then
                    link_ctr <= link_ctr + '1';
                else
                    sm_link <= '1';
            end if;
        end if;
      
    else 

        -- When the link is up, the link counter is decreased by 34 whenever any inavalid header appear (or PRBS mismatch) occurs, but is increased by
        -- only 1 on each cycle where all PRBS bits match, up to its saturation point of 67. If the link counter reaches
        -- 0 (including rollover protection), transition to the link down state.
        if(link_error_sync = '1') then -- prbs_error_any_sync = '1'
            if (to_integer(unsigned(link_ctr)) > 33) then
                link_ctr <= link_ctr - "100010";
                if (to_integer(unsigned(link_ctr)) = 34) then
                    sm_link  <= '0';
                end if;
            else
                link_ctr <= "0000000";
                sm_link  <= '0';
            end if;
        else
            if (to_integer(unsigned(link_ctr)) < 67) then
                link_ctr <= link_ctr + '1';
            end if;
        end if;       
      
      end if;
    end if;  
  end process;


-- Error counter 
  process (clk_freerun_buf_int)
  begin
    if rising_edge(clk_freerun_buf_int) then 
       if (reset = '1') then
         error_counter_i <= (OTHERS => '0');
       elsif link_error_sync = '1' then 
         error_counter_i <= error_counter_i + '1';                    
      end if;
    end if;  
  end process;

  -- Reset the latched link down indicator when the synchronized latched link down reset signal is high. Otherwise, set
  -- the latched link down indicator upon losing link. This indicator is available for user reference.
  process (clk_freerun_buf_int)
  begin
    if rising_edge(clk_freerun_buf_int) then  
        if (reset = '1') then
            link_down_latched_i <= '0';
        elsif (sm_link = '0') then
            link_down_latched_i <= '1';
        end if;
    end if;
  end process;

  link_status <= sm_link;
  error_counter <= error_counter_i;
  link_down_latched <= link_down_latched_i;

 end RTL; 




