----------------------------------------------------------------------------------
-- Project - emp_fwk
-- Description - Dummy BE MGT inteface
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
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

    ttc_clk_in      : in std_logic;       
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

    signal rxdata   : ldata(N_CHANNELS - 1 DOWNTO 0);
    
begin

	ipb_out.ipb_rdata <= (others => '0');
	ipb_out.ipb_ack <= ipb_in.ipb_strobe;
	ipb_out.ipb_err <= '0';

    process(stable_clk_in)
    begin
        if rising_edge(stable_clk_in) then
            rxdata <= txdata_in;
        end if;
    end process;

    rxdata_out <= txdata_in;
    qplllock <= '1';
    
end behavioral;

