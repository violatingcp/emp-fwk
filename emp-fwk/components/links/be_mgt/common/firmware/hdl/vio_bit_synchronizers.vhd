----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/19/2018 10:10:13 AM
-- Design Name: 
-- Module Name: vio_bit_synchronizer - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vio_bit_synchronizers is
    Port (
          clk_freerun_in                : IN STD_LOGIC;
          txprgdivresetdone_int         : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
          txpmaresetdone_int            : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
          rxpmaresetdone_int            : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
          reset_tx_done_int             : IN STD_LOGIC;
          reset_rx_done_int             : IN STD_LOGIC;
          buffbypass_tx_done_int        : IN STD_LOGIC;
          buffbypass_rx_done_int        : IN STD_LOGIC;
          buffbypass_tx_error_int       : IN STD_LOGIC;
          buffbypass_rx_error_int       : IN STD_LOGIC;
          qpll0lock_out_int             : IN STD_LOGIC;
          link_status_at_local_int      : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
          channel_error_latched_int     : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
          
          txprgdivresetdone_vio_sync    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
          txpmaresetdone_vio_sync       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
          rxpmaresetdone_vio_sync       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
          reset_tx_done_vio_sync        : OUT STD_LOGIC;
          reset_rx_done_vio_sync        : OUT STD_LOGIC;
          buffbypass_tx_done_vio_sync   : OUT STD_LOGIC;
          buffbypass_rx_done_vio_sync   : OUT STD_LOGIC;
          buffbypass_tx_error_vio_sync  : OUT STD_LOGIC;
          buffbypass_rx_error_vio_sync  : OUT STD_LOGIC;
          qpll0lock_out_vio             : OUT STD_LOGIC;
          link_status_at_local_sync     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
          channel_error_latched_sync    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
          );
end vio_bit_synchronizers;

architecture Behavioral of vio_bit_synchronizers is

   attribute DONT_TOUCH : string;
   attribute DONT_TOUCH of bit_synchronizer_vio_txprgdivresetdone_0_inst : label is "true";
   attribute DONT_TOUCH of bit_synchronizer_vio_txprgdivresetdone_1_inst : label is "true";
   attribute DONT_TOUCH of bit_synchronizer_vio_txprgdivresetdone_2_inst : label is "true";
   attribute DONT_TOUCH of bit_synchronizer_vio_txprgdivresetdone_3_inst : label is "true";
   attribute DONT_TOUCH of bit_synchronizer_vio_txpmaresetdone_0_inst : label is "true";
   attribute DONT_TOUCH of bit_synchronizer_vio_txpmaresetdone_1_inst : label is "true";
   attribute DONT_TOUCH of bit_synchronizer_vio_txpmaresetdone_2_inst : label is "true";
   attribute DONT_TOUCH of bit_synchronizer_vio_txpmaresetdone_3_inst : label is "true";
   attribute DONT_TOUCH of bit_synchronizer_vio_rxpmaresetdone_0_inst : label is "true";
   attribute DONT_TOUCH of bit_synchronizer_vio_rxpmaresetdone_1_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_vio_rxpmaresetdone_2_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_vio_rxpmaresetdone_3_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_vio_reset_tx_done_0_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_vio_reset_rx_done_0_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_vio_buffbypass_tx_done_0_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_vio_buffbypass_rx_done_0_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_vio_buffbypass_tx_error_0_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_vio_buffbypass_rx_error_0_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_link_status_local_0_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_link_status_local_1_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_link_status_local_2_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_link_status_local_3_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_channel_error_latched_0_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_channel_error_latched_1_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_channel_error_latched_2_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_channel_error_latched_3_inst : label is "true";   
   attribute DONT_TOUCH of bit_synchronizer_vio_qpll0lock_out_int_inst : label is "true";   

   
begin

    bit_synchronizer_vio_qpll0lock_out_int_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => qpll0lock_out_int,
                 o_out   => qpll0lock_out_vio 
                 );

    bit_synchronizer_vio_txprgdivresetdone_0_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => txprgdivresetdone_int(0),
                 o_out   => txprgdivresetdone_vio_sync(0) 
                 );

    bit_synchronizer_vio_txprgdivresetdone_1_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => txprgdivresetdone_int(1),
                 o_out   => txprgdivresetdone_vio_sync(1) 
                 );

    bit_synchronizer_vio_txprgdivresetdone_2_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => txprgdivresetdone_int(2),
                 o_out   => txprgdivresetdone_vio_sync(2) 
                 );

    bit_synchronizer_vio_txprgdivresetdone_3_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => txprgdivresetdone_int(3),
                 o_out   => txprgdivresetdone_vio_sync(3) 
                 );                 

--   Synchronize txpmaresetdone into the free-running clock domain for VIO usage


    bit_synchronizer_vio_txpmaresetdone_0_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => txpmaresetdone_int(0),
                 o_out   => txpmaresetdone_vio_sync(0) 
                 );

    bit_synchronizer_vio_txpmaresetdone_1_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => txpmaresetdone_int(1),
                 o_out   => txpmaresetdone_vio_sync(1) 
                 );

    bit_synchronizer_vio_txpmaresetdone_2_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => txpmaresetdone_int(2),
                 o_out   => txpmaresetdone_vio_sync(2) 
                 );

    bit_synchronizer_vio_txpmaresetdone_3_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => txpmaresetdone_int(3),
                 o_out   => txpmaresetdone_vio_sync(3) 
                 );

--   Synchronize rxpmaresetdone into the free-running clock domain for VIO usage


    bit_synchronizer_vio_rxpmaresetdone_0_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => rxpmaresetdone_int(0),
                 o_out   => rxpmaresetdone_vio_sync(0) 
                 );

    bit_synchronizer_vio_rxpmaresetdone_1_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => rxpmaresetdone_int(1),
                 o_out   => rxpmaresetdone_vio_sync(1) 
                 );

    bit_synchronizer_vio_rxpmaresetdone_2_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => rxpmaresetdone_int(2),
                 o_out   => rxpmaresetdone_vio_sync(2) 
                 );

    bit_synchronizer_vio_rxpmaresetdone_3_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => rxpmaresetdone_int(3),
                 o_out   => rxpmaresetdone_vio_sync(3) 
                 );

--  Synchronize reset_tx_done into the free-running clock domain for VIO usage

    bit_synchronizer_vio_reset_tx_done_0_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => reset_tx_done_int,
                 o_out   => reset_tx_done_vio_sync 
                 );

--   Synchronize reset_rx_done into the free-running clock domain for VIO usage

    bit_synchronizer_vio_reset_rx_done_0_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => reset_rx_done_int,
                 o_out   => reset_rx_done_vio_sync 
                 );

--   Synchronize buffbypass_tx_done into the free-running clock domain for VIO usage

    bit_synchronizer_vio_buffbypass_tx_done_0_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => buffbypass_tx_done_int,
                 o_out   => buffbypass_tx_done_vio_sync 
                 );

--   Synchronize buffbypass_rx_done into the free-running clock domain for VIO usage

    bit_synchronizer_vio_buffbypass_rx_done_0_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => buffbypass_rx_done_int,
                 o_out   => buffbypass_rx_done_vio_sync 
                 );

--   Synchronize buffbypass_tx_error into the free-running clock domain for VIO usage

    bit_synchronizer_vio_buffbypass_tx_error_0_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => buffbypass_tx_error_int,
                 o_out   => buffbypass_tx_error_vio_sync 
                 );

--   Synchronize buffbypass_rx_error into the free-running clock domain for VIO usage

    bit_synchronizer_vio_buffbypass_rx_error_0_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => buffbypass_rx_error_int,
                 o_out   => buffbypass_rx_error_vio_sync 
                 );

--   Synchronize rxpmaresetdone into the free-running clock domain for VIO usage

    bit_synchronizer_link_status_local_0_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => link_status_at_local_int(0),
                 o_out   => link_status_at_local_sync(0) 
                 );

    bit_synchronizer_link_status_local_1_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => link_status_at_local_int(1),
                 o_out   => link_status_at_local_sync(1) 
                 );

    bit_synchronizer_link_status_local_2_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => link_status_at_local_int(2),
                 o_out   => link_status_at_local_sync(2) 
                 );

    bit_synchronizer_link_status_local_3_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => link_status_at_local_int(3),
                 o_out   => link_status_at_local_sync(3) 
                 );

    bit_synchronizer_channel_error_latched_0_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => channel_error_latched_int(0),
                 o_out   => channel_error_latched_sync(0) 
                 );

    bit_synchronizer_channel_error_latched_1_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => channel_error_latched_int(1),
                 o_out   => channel_error_latched_sync(1) 
                 );

    bit_synchronizer_channel_error_latched_2_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => channel_error_latched_int(2),
                 o_out   => channel_error_latched_sync(2) 
                 );

    bit_synchronizer_channel_error_latched_3_inst : entity work.bit_synchronizer
        Port Map(
                 clk_in  => clk_freerun_in,
                 i_in    => channel_error_latched_int(3),
                 o_out   => channel_error_latched_sync(3) 
                 );
end Behavioral;

