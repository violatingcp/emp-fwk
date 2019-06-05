
--------------------------------------------------------------------------------
--
-- Filename: tx_fifo_exdes.vhd
--
-- Description:
--   This is the demo testbench for fifo_generator core.
--
--------------------------------------------------------------------------------
-- Library Declarations
--------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.STD_LOGIC_1164.ALL;
USE ieee.STD_LOGIC_unsigned.ALL;
--USE IEEE.STD_LOGIC_arith.ALL;
USE ieee.numeric_std.ALL;
USE ieee.STD_LOGIC_misc.ALL;

library unisim;
use unisim.vcomponents.all;
use work.emp_framework_decl.all;
use work.emp_device_decl.all;
use work.emp_project_decl.all;
LIBRARY std;
USE std.textio.ALL;

--LIBRARY work;
--USE work.tx_fifo_pkg.ALL;

--------------------------------------------------------------------------------
-- Entity Declaration
--------------------------------------------------------------------------------
ENTITY tx_fifo_cdc IS
    GENERIC ( DATA_WIDTH : integer := 64; 
              PATTERN : STRING := "USER";
              INDEX : integer
            );
    PORT(
	     ttc_clk        :  IN  STD_LOGIC := '0';
         link_clk       :  IN  STD_LOGIC := '0';
         reset          :  IN  STD_LOGIC := '0';
         tx_data_valid  :  IN  STD_LOGIC := '0';
         tx_data_in     :  IN  STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
         tx_data_out    :  OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
         tx_sequence_out :  OUT STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');
         tx_datavalid_i    : OUT STD_LOGIC;
         tx_header_out  :  OUT STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0')
        );
END ENTITY;

ARCHITECTURE RTL OF tx_fifo_cdc IS

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
    SIGNAL full_inv                       :   STD_LOGIC := '1';
    signal prbs_data_ttc_i                  :   STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    signal user_data_ttc_i                  :   STD_LOGIC_VECTOR(DATA_WIDTH DOWNTO 0) := (OTHERS => '0');
    signal user_data_ttc_crc_i                  :   STD_LOGIC_VECTOR(DATA_WIDTH DOWNTO 0) := (OTHERS => '0');

    --Write agent
    signal tx_data_link_i    : STD_LOGIC_VECTOR(DATA_WIDTH DOWNTO 0) := (OTHERS => '0');
    signal tx_header_link_i  : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');

   -- TB Signals
    SIGNAL rst_int_rd                     :   STD_LOGIC := '1';
    SIGNAL rst_int_wr                     :   STD_LOGIC := '1';
    SIGNAL reset_en                       :   STD_LOGIC := '0';
    SIGNAL txsequence_out_i               :   STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pause_read                     :   STD_LOGIC := '0';
    
    -- Initialization counter signals
    constant LOCAL_CLK_FREQUENCY : integer := 240;
    constant INIT_TIMER_DURATION_US : integer := 150000;
    constant init_timer_term_cyc_int : integer := INIT_TIMER_DURATION_US * LOCAL_CLK_FREQUENCY;
    SIGNAL init_timer_ctr : UNSIGNED(25 DOWNTO 0) := (OTHERS => '0');
    SIGNAL init_timer_sat : STD_LOGIC := '0';
    signal idles_timer_ctr : UNSIGNED(9 DOWNTO 0) := (OTHERS => '0');
    signal idles_timer_sat : STD_LOGIC := '0';
    signal txseq_cnt_en : std_logic := '1';

    attribute DONT_TOUCH : string;
    attribute DONT_TOUCH of insert_pad_prbs_words_inst : label is "true";
    attribute DONT_TOUCH of reset_synchronizer_read_inst : label is "true";
    attribute DONT_TOUCH of reset_synchronizer_write_inst : label is "true";


    FUNCTION bit_reverse(s1:std_logic_vector) return std_logic_vector is 
        variable rr : std_logic_vector(s1'high downto s1'low); 
     begin 
        for ii in s1'high downto s1'low loop 
            rr(ii) := s1(s1'high-ii); 
        end loop; 
        return rr; 
    END bit_reverse; 

    signal wd_data_count_i :  STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');
    attribute keep : string;
    attribute keep of wd_data_count_i : signal is "true";

BEGIN  
-----------------------------------------------------
--- Reset generation logic --------------------------
----------------------------------------------------- 
wr_clk_i    <= ttc_clk;
rd_clk_i    <= link_clk;

reset_synchronizer_read_inst:  entity work.reset_synchronizer  
    Port Map(
             clk_in  => rd_clk_i,
             rst_in  => reset,
             rst_out => rst_int_rd
            );  
        
reset_synchronizer_write_inst:  entity work.reset_synchronizer  
    Port Map(
             clk_in  => wr_clk_i,
             rst_in  => reset,
             rst_out => rst_int_wr
            );       


-- PRBS data gen
prbs_stimulus_inst: entity work.ultrascale_fifo_stimulus_64b66b
GENERIC MAP (SELECT_PATTERN => "PRBS" ) --PATTERN)
PORT MAP(
         reset  => rst_int_wr,
         clk    => wr_clk_i,
         enable => '1',
         txdata_out  => prbs_data_ttc_i
         );


-- Send PRBS31 data to initialise the link. After the init_timer_sat is asserted send user data
user_gen:if PATTERN = "USER" GENERATE
   
  -- Increment the init_timer_ctr counter until its value reaches init_timer_term_cyc_int terminal count and assert init_timer_sat. 
  -- Clear the timer and remove assertions when the timer is reset from the user or the initialization state machine.
--  process (wr_clk_i)
--  begin
--      if rising_edge(wr_clk_i) then
--          if rst_int_wr = '1' then
--              init_timer_ctr    <= (others => '0');
--              init_timer_sat <= '0';
--          else
--              if (to_integer(unsigned(init_timer_ctr)) = init_timer_term_cyc_int ) then
--                 init_timer_sat <= '1';
--              else 
--                  init_timer_ctr <= init_timer_ctr + 1;
--              end if;
--          end if;
--      end if;
--  end process;


--   Send xx IDLES every 1024 cycles -- TO BE REPLACED by valid bit ctrl
  process (wr_clk_i)
  begin
      if rising_edge(wr_clk_i) then
          if rst_int_wr = '1' then
              idles_timer_ctr    <= (others => '0');
              idles_timer_sat <= '0';
          else
              if (to_integer(unsigned(idles_timer_ctr)) >= 80 ) then
                 idles_timer_sat <= '1';
              else 
                 idles_timer_sat <= '0';
              end if;
              idles_timer_ctr <= idles_timer_ctr + 1;              
          end if;
      end if;
  end process; 


--idles_timer_sat <= data_valid_bit;


user_data_ttc_i <= idles_timer_sat & prbs_data_ttc_i(DATA_WIDTH/2 - 1 DOWNTO 0) & prbs_data_ttc_i(DATA_WIDTH - 1 DOWNTO DATA_WIDTH/2);
    
    
-- CRC generator 
crc_gen: entity work.links_crc_tx
generic map(
            CRC_METHOD => "ULTIMATE_CRC",
            TRAILER_EN =>  TRUE,
            POLYNOMIAL =>  "00000100110000010001110110110111", -- aurora poly (ethernet)
            INIT_VALUE =>  "11111111111111111111111111111111",
            DATA_WIDTH =>  64,
            SYNC_RESET => 1)
port map(
          clk              => wr_clk_i,
          clken_in         => '1',
          data_in          => tx_data_in, -- user_data_ttc_i(63 DOWNTO 0), 
          data_valid_in    => tx_data_valid, --user_data_ttc_i(64), ,
          data_out         => user_data_ttc_crc_i(DATA_WIDTH - 1 DOWNTO 0),
          data_valid_out   => user_data_ttc_crc_i (DATA_WIDTH)
        );    
    
                          
fifo_in_i <= user_data_ttc_crc_i;

   
-- prbs/user data MUX for initialization
--WITH init_timer_sat SELECT
--      fifo_in_i <= '0' & prbs_data_ttc_i        WHEN '0',
--                         user_data_ttc_crc_i    WHEN '1',
--                   '0' & prbs_data_ttc_i        WHEN OTHERS;

END GENERATE;


-- Send only PRBS
prbs_gen:if PATTERN = "PRBS" GENERATE 
    fifo_in_i <= '0' & prbs_data_ttc_i;
END GENERATE;



-----------------------------------------------------
-- SYNCHRONIZERS B/W WRITE AND READ DOMAINS
-----------------------------------------------------
PROCESS(wr_clk_i,rst_int_wr)
BEGIN
    IF(rst_int_wr = '1') THEN
        wr_en_i          <= '0';
    ELSIF (wr_clk_i'event AND wr_clk_i='1') THEN
        wr_en_i <= '1';
    END IF;
END PROCESS;


  txgb_32b:  if REGION_CONF(INDEX).mgt_i_kind = gth16 generate   
    --  Control txsequence as required for 64B/66B gearbox data transmission at the selected user data width
    --  For 32bit internal data rd_en_i shoulb be low for one user clocks every 64 cycles
    process(rd_clk_i,rst_int_rd)
    begin
        if rising_edge(rd_clk_i) then
            if rst_int_rd='1' then
                txsequence_out_i <= "0000000";
                rd_en_i <= '0';
            else
                if txsequence_out_i = "0011111" then
                    rd_en_i <= '0';
                    txsequence_out_i <= txsequence_out_i + '1';
                elsif txsequence_out_i = "0100000" then
                    txsequence_out_i <= "0000000";
                    rd_en_i <= '1';
                else
                    txsequence_out_i <= txsequence_out_i + '1';
                    rd_en_i <= '1';
                end if;
              end if;
            end if;
    end process;
  end generate txgb_32b;

  txgb_64b:  if REGION_CONF(INDEX).mgt_i_kind = gty16 or REGION_CONF(INDEX).mgt_i_kind = gty25 generate   
    --  Control txsequence as required for 64B/66B gearbox data transmission at the selected user data width
    --  For 64bit internal data rd_en_i shoulb be low for two user clocks every 64 cycles
    process(rd_clk_i,rst_int_rd)
    begin
        if rising_edge(rd_clk_i) then
            if rst_int_rd='1' then
                txsequence_out_i <= "0000000";
                rd_en_i <= '0';
                txseq_cnt_en <= '1';
            else
              if txseq_cnt_en = '1' then 
                if txsequence_out_i = "0011111" then
                    rd_en_i <= '0';
                    txsequence_out_i <= txsequence_out_i + '1';
                elsif txsequence_out_i = "0100000" then
                    txsequence_out_i <= "0000000";
                    rd_en_i <= '1';
                else
                    txsequence_out_i <= txsequence_out_i + '1';
                    rd_en_i <= '1';
                end if;
              end if;
              txseq_cnt_en <= not txseq_cnt_en;
            end if;
        end if;
    end process;
  end generate txgb_64b;

tx_datavalid_i <= rd_en_i;

-- Asynchronous FIFO 
tx_fifo_inst: entity work.tx_fifo_top 
PORT MAP (
           RST                => rst,
           -- Write ports     
           WR_CLK             => wr_clk_i,
           WR_EN 		      => wr_en_i,
           DIN                => fifo_in_i,
           ALMOST_FULL        => almost_full_i,                      
           FULL               => full_i, 
           -- Read ports      
           RD_CLK             => rd_clk_i, 
           RD_EN              => rd_en_i,                     
           DOUT               => fifo_out_i,
           ALMOST_EMPTY       => almost_empty_i,           
           EMPTY              => empty_i,
           rd_data_count      => open,
           wr_data_count      => wd_data_count_i,
           prog_full          => open,
           prog_empty         => open 
         );


pause_read <= not rd_en_i;



-- Insert padding word and prbs characters
insert_pad_prbs_words_inst: entity work.add_padding_and_prbs_data
GENERIC MAP(BYTE_WIDTH => 8)
PORT MAP(
         clk            => rd_clk_i,
         data_in        => fifo_out_i,
         pad_in         => empty_i,
         pause_read_in  => pause_read,
         data_out       => tx_data_link_i,
         header_out     => tx_header_link_i
         );


-- GTH ports
tx_data_out     <= bit_reverse(tx_data_link_i(DATA_WIDTH - 1 DOWNTO 0));
tx_header_out   <= tx_header_link_i;
tx_sequence_out <= txsequence_out_i;


END ARCHITECTURE;
