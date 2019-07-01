-- null_algo
--
-- Do-nothing top level algo for testing
--
-- Dave Newbold, July 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.emp_data_types.all;
use work.top_decl.all;

use work.emp_data_types.all;
use work.emp_device_decl.all;
use work.mp7_ttc_decl.all;

--use work.pf_data_types.all;
use work.pf_constants.all;

entity emp_payload is
	port(
		clk: in std_logic; -- ipbus signals
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk_payload: in std_logic_vector(2 downto 0);
		rst_payload: in std_logic_vector(2 downto 0);
		clk_p: in std_logic; -- data clock
		rst_loc: in std_logic_vector(N_REGION - 1 downto 0);
		clken_loc: in std_logic_vector(N_REGION - 1 downto 0);
		ctrs: in ttc_stuff_array;
		bc0: out std_logic;
		d: in ldata(4 * N_REGION - 1 downto 0); -- data in
		q: out ldata(4 * N_REGION - 1 downto 0); -- data out
		gpio: out std_logic_vector(29 downto 0); -- IO to mezzanine connector
		gpio_en: out std_logic_vector(29 downto 0) -- IO to mezzanine connector (three-state enables)
	);
		
end emp_payload;

architecture rtl of emp_payload is
  signal rst_loc_reg : std_logic_vector(N_REGION - 1 downto 0);       
  constant N_FRAMES_USED : natural := 1;
  signal start_pf : std_logic_vector(0 downto 0) := (others => '1');                
  --signal d0ValidLast : std_logic; -- The valid bit of the 0th input from the previous cycle
  --shared variable sel : integer range 0 to 128;
  --signal dPipe : ldata(N_PF_IP_CORE_IN_CHANS  - 1 downto 0);
  
begin

   ipb_out <= IPB_RBUS_NULL;

   selector_gen : process (clk_p)
   begin  -- process selector_gen
     if clk_p'event and clk_p = '1' then  -- rising clock edge
       rst_loc_reg <= rst_loc;
      end if;
    end process selector_gen;

--  valid_pipe : process(clk)
--  begin
--    if rising_edge(clk) then
--      d0ValidLast <= d(0).valid;
--      dPipe <= d(N_IN_CHANS-1 downto 0);
--    end if;
--  end process valid_pipe;

  start_pf(0) <= '1';

--  selector_start : process (clk_p)
--  begin 
--    if rising_edge(clk) then
--      if d(0).valid = '1' then
--        if (sel = 50) or (d0ValidLast = '0') then
--          start_pf(0) <= '1';
--          sel := 0;  
--        else
--          sel := sel + 1;
--          start_pf(0) <= '0';
--        end if;       
--      end if;
--    end if;
--  end process selector_start;

  pf_algo : entity work.in_ip_wrapper
    PORT MAP (
      clk    => clk_p,
      rst    => rst_loc(0),
      start  => start_pf(0),
      input  => d(N_IN_CHANS-1 downto 0),
      done   => open,
      idle   => open,
      ready  => open,
      output => q(N_OUT_CHANS - 1 downto 0)
   );

  gMux : for i in N_PF_IP_CORE_OUT_CHANS - 1 downto 0 generate     
   selector_end : process (clk_p)
   begin 
    if rising_edge(clk) then
      q(i).strobe <= '1';
      q(i).valid  <= '1'; 
    end if;
   end process selector_end;
  end generate gMux;
   
  bc0 <= '0';
  gpio <= (others => '0');
  gpio_en <= (others => '0');

end rtl;
