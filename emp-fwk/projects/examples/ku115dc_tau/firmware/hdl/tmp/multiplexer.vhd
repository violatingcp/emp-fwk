library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.emp_data_types.all;
use work.top_decl.all;
use work.emp_device_decl.all;

use work.pf_data_types.all;
use work.pf_constants.all;

entity multiplexer is
  port(
    --clk240 : in std_logic;
    --clk40 : in std_logic;
    clk : in std_logic;
    --rst : in std_logic;
    d : in ldata(N_IN_CHANS - 1 downto 0);
    start_pf : out std_logic_vector(PF_RESHAPE_FACTOR - 1 downto 0);
    q_pf : out pf_data_array(N_PF_IP_CORES - 1 downto 0)(N_PF_IP_CORE_IN_CHANS - 1 downto 0)
  );
end multiplexer;

architecture rtl of multiplexer is
  --type tSel is range 0 to PF_RESHAPE_FACTOR - 1;
  type tSelArray is array (natural range <>) of integer range 0 to PF_RESHAPE_FACTOR - 1;
  signal sel : tSelArray(N_PF_IP_CORES - 1 downto 0);
  signal start_pf_int : std_logic_vector(PF_RESHAPE_FACTOR - 1 downto 0) := (others => '0'); --(0 => '1', others => '0');
  signal d0ValidLast : std_logic; -- The valid bit of the 0th input from the previous cycle
  signal dPipe : ldata(N_IN_CHANS - 1 downto 0);

begin

  -- Record the valid bit from the previous cycle
  valid_pipe : process(clk)
  begin
    if rising_edge(clk) then
      d0ValidLast <= d(0).valid;
      dPipe <= d;
    end if;
  end process valid_pipe;
  
  gSel : for i in 0 to N_PF_IP_CORES - 1 generate
    set_select : process(clk)
    begin
      start_pf_int <= (others => '0');
      if rising_edge(clk) then
        -- Only count when the input is valid
        if d(0).valid = '1' then
          -- Reset the counter if it has reached the maximum, or if the incoming data is newly valid
          if (sel(i) = PF_RESHAPE_FACTOR - 1) or (d0ValidLast = '0') then
            sel(i) <= 0;
          else
            sel(i) <= sel(i) + 1;
          end if; 
          
          -- The start PF signal needs to go high after receiving 6 frames of valid data,
          -- then every 6th frame
          if sel(i) = PF_RESHAPE_FACTOR - 1 then
            start_pf_int(i) <= '1';
          end if;
          
        end if;       
      end if;
    end process set_select;
  end generate gSel;

  -- On the 0th count d inputs 0 to 11 map to q_pf inputs 0 to 11
  -- On the 1st count d inputs 0 to 11 map to q_pf inputs 12 to 23, etc...
  g0 : for i in N_PF_IP_CORES - 1 downto 0 generate
    g1 : for j in N_PF_IP_CORE_IN_CHANS - 1 downto 0 generate
      mux_process : process(clk, d)
      begin
        if rising_edge(clk) then
          if j / N_CHANS_PER_CORE = sel(i) then
            q_pf(i)(j) <= dPipe(i * N_CHANS_PER_CORE + j mod N_CHANS_PER_CORE).data(31 downto 0);
          end if;
        end if;
      end process;
    end generate g1;
  end generate g0;
  
  start_pf <= start_pf_int;  

end rtl;
