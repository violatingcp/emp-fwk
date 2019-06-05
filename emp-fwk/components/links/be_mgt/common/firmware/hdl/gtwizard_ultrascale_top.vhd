-- =====================================================================================================================
-- This example design top module instantiates the example design wrapper; slices vectored ports for per-channel assignment;
-- Author 	: Stavros Mallios
-- Date 	: 08/01/2018
-- =====================================================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.emp_framework_decl.all;
use work.emp_device_decl.all;
use work.emp_project_decl.all;
USE IEEE.std_logic_misc.all; -- contains OR_REDUCE & AND_REDUCE functions among others.

ENTITY gtwizard_ultrascale_top IS 
          Generic (INDEX : integer );
		  PORT (
        gtwiz_userclk_tx_reset_in : IN STD_LOGIC;
        gtwiz_userclk_tx_srcclk_out : OUT STD_LOGIC;
        gtwiz_userclk_tx_usrclk_out : OUT STD_LOGIC;
        gtwiz_userclk_tx_usrclk2_out : OUT STD_LOGIC;
        gtwiz_userclk_tx_active_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_reset_in : IN STD_LOGIC;
        gtwiz_userclk_rx_srcclk_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_usrclk_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_usrclk2_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_active_out : OUT STD_LOGIC;
        gtwiz_buffbypass_tx_reset_in : IN STD_LOGIC;
--        gtwiz_buffbypass_tx_start_user_in : IN STD_LOGIC;
        gtwiz_buffbypass_tx_done_out : OUT STD_LOGIC;
        gtwiz_buffbypass_tx_error_out : OUT STD_LOGIC;
        gtwiz_buffbypass_rx_reset_in : IN STD_LOGIC;
--        gtwiz_buffbypass_rx_start_user_in : IN STD_LOGIC;
        gtwiz_buffbypass_rx_done_out : OUT STD_LOGIC;
        gtwiz_buffbypass_rx_error_out : OUT STD_LOGIC;
        gtwiz_reset_clk_freerun_in : IN STD_LOGIC;
        gtwiz_reset_all_in : IN STD_LOGIC;
        gtwiz_reset_tx_pll_and_datapath_in : IN STD_LOGIC;
        gtwiz_reset_tx_datapath_in : IN STD_LOGIC;
        gtwiz_reset_rx_pll_and_datapath_in : IN STD_LOGIC;
        gtwiz_reset_rx_datapath_in : IN STD_LOGIC;
        gtwiz_reset_rx_cdr_stable_out : OUT STD_LOGIC;
        gtwiz_reset_tx_done_out : OUT STD_LOGIC;
        gtwiz_reset_rx_done_out : OUT STD_LOGIC;
        gtwiz_userdata_tx_in : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
        gtwiz_userdata_rx_out : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
        gtrefclk00_in : IN STD_LOGIC;
        qpll0outclk_out : OUT STD_LOGIC;
        qpll0outrefclk_out : OUT STD_LOGIC;
        qpll0lock_out : OUT STD_LOGIC;
        gtyrxn_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        gtyrxp_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        loopback_in : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        rxgearboxslip_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        txheader_in : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        txsequence_in : IN STD_LOGIC_VECTOR(27 DOWNTO 0);
--        gtpowergood_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        gtytxn_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        gtytxp_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        rxdatavalid_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        rxheader_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        rxheadervalid_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        rxpmaresetdone_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        rxstartofseq_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        txpmaresetdone_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        txprgdivresetdone_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
      );

END gtwizard_ultrascale_top;



ARCHITECTURE RTL OF gtwizard_ultrascale_top IS

COMPONENT gtwizard_ultrascale_gth16g
PORT (
        gtwiz_userclk_tx_reset_in : IN STD_LOGIC;
        gtwiz_userclk_tx_srcclk_out : OUT STD_LOGIC;
        gtwiz_userclk_tx_usrclk_out : OUT STD_LOGIC;
        gtwiz_userclk_tx_usrclk2_out : OUT STD_LOGIC;
        gtwiz_userclk_tx_active_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_reset_in : IN STD_LOGIC;
        gtwiz_userclk_rx_srcclk_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_usrclk_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_usrclk2_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_active_out : OUT STD_LOGIC;
        gtwiz_buffbypass_tx_reset_in : IN STD_LOGIC;
        gtwiz_buffbypass_tx_start_user_in : IN STD_LOGIC;
        gtwiz_buffbypass_tx_done_out : OUT STD_LOGIC;
        gtwiz_buffbypass_tx_error_out : OUT STD_LOGIC;
        gtwiz_buffbypass_rx_reset_in : IN STD_LOGIC;
        gtwiz_buffbypass_rx_start_user_in : IN STD_LOGIC;
        gtwiz_buffbypass_rx_done_out : OUT STD_LOGIC;
        gtwiz_buffbypass_rx_error_out : OUT STD_LOGIC;
        gtwiz_reset_clk_freerun_in : IN STD_LOGIC;
        gtwiz_reset_all_in : IN STD_LOGIC;
        gtwiz_reset_tx_pll_and_datapath_in : IN STD_LOGIC;
        gtwiz_reset_tx_datapath_in : IN STD_LOGIC;
        gtwiz_reset_rx_pll_and_datapath_in : IN STD_LOGIC;
        gtwiz_reset_rx_datapath_in : IN STD_LOGIC;
        gtwiz_reset_rx_cdr_stable_out : OUT STD_LOGIC;
        gtwiz_reset_tx_done_out : OUT STD_LOGIC;
        gtwiz_reset_rx_done_out : OUT STD_LOGIC;
        gtwiz_userdata_tx_in : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
        gtwiz_userdata_rx_out : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
        gtrefclk00_in : IN STD_LOGIC;
        qpll0outclk_out : OUT STD_LOGIC;
        qpll0outrefclk_out : OUT STD_LOGIC;
        qpll0lock_out : OUT STD_LOGIC;
        gthrxn_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        gthrxp_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        loopback_in : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        rxgearboxslip_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        txheader_in : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        txsequence_in : IN STD_LOGIC_VECTOR(27 DOWNTO 0);
--        gtpowergood_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        gthtxn_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        gthtxp_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        rxdatavalid_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        rxheader_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        rxheadervalid_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        rxpmaresetdone_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        rxstartofseq_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        txpmaresetdone_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        txprgdivresetdone_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
      );
END COMPONENT;

COMPONENT gtwizard_ultrascale_gty16g
PORT (
        gtwiz_userclk_tx_reset_in : IN STD_LOGIC;
        gtwiz_userclk_tx_srcclk_out : OUT STD_LOGIC;
        gtwiz_userclk_tx_usrclk_out : OUT STD_LOGIC;
        gtwiz_userclk_tx_usrclk2_out : OUT STD_LOGIC;
        gtwiz_userclk_tx_active_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_reset_in : IN STD_LOGIC;
        gtwiz_userclk_rx_srcclk_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_usrclk_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_usrclk2_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_active_out : OUT STD_LOGIC;
        gtwiz_buffbypass_tx_reset_in : IN STD_LOGIC;
        gtwiz_buffbypass_tx_start_user_in : IN STD_LOGIC;
        gtwiz_buffbypass_tx_done_out : OUT STD_LOGIC;
        gtwiz_buffbypass_tx_error_out : OUT STD_LOGIC;
        gtwiz_buffbypass_rx_reset_in : IN STD_LOGIC;
        gtwiz_buffbypass_rx_start_user_in : IN STD_LOGIC;
        gtwiz_buffbypass_rx_done_out : OUT STD_LOGIC;
        gtwiz_buffbypass_rx_error_out : OUT STD_LOGIC;
        gtwiz_reset_clk_freerun_in : IN STD_LOGIC;
        gtwiz_reset_all_in : IN STD_LOGIC;
        gtwiz_reset_tx_pll_and_datapath_in : IN STD_LOGIC;
        gtwiz_reset_tx_datapath_in : IN STD_LOGIC;
        gtwiz_reset_rx_pll_and_datapath_in : IN STD_LOGIC;
        gtwiz_reset_rx_datapath_in : IN STD_LOGIC;
        gtwiz_reset_rx_cdr_stable_out : OUT STD_LOGIC;
        gtwiz_reset_tx_done_out : OUT STD_LOGIC;
        gtwiz_reset_rx_done_out : OUT STD_LOGIC;
        gtwiz_userdata_tx_in : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
        gtwiz_userdata_rx_out : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
        gtrefclk00_in : IN STD_LOGIC;
        qpll0outclk_out : OUT STD_LOGIC;
        qpll0outrefclk_out : OUT STD_LOGIC;
        qpll0lock_out : OUT STD_LOGIC;
        gtyrxn_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        gtyrxp_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        loopback_in : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        rxgearboxslip_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        txheader_in : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        txsequence_in : IN STD_LOGIC_VECTOR(27 DOWNTO 0);
--        gtpowergood_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        gtytxn_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        gtytxp_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        rxdatavalid_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        rxheader_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        rxheadervalid_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        rxpmaresetdone_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        rxstartofseq_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        txpmaresetdone_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        txprgdivresetdone_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
      );
END COMPONENT;

COMPONENT gtwizard_ultrascale_gty25g
PORT (
        gtwiz_userclk_tx_reset_in : IN STD_LOGIC;
        gtwiz_userclk_tx_srcclk_out : OUT STD_LOGIC;
        gtwiz_userclk_tx_usrclk_out : OUT STD_LOGIC;
        gtwiz_userclk_tx_usrclk2_out : OUT STD_LOGIC;
        gtwiz_userclk_tx_active_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_reset_in : IN STD_LOGIC;
        gtwiz_userclk_rx_srcclk_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_usrclk_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_usrclk2_out : OUT STD_LOGIC;
        gtwiz_userclk_rx_active_out : OUT STD_LOGIC;
        gtwiz_buffbypass_tx_reset_in : IN STD_LOGIC;
        gtwiz_buffbypass_tx_start_user_in : IN STD_LOGIC;
        gtwiz_buffbypass_tx_done_out : OUT STD_LOGIC;
        gtwiz_buffbypass_tx_error_out : OUT STD_LOGIC;
        gtwiz_buffbypass_rx_reset_in : IN STD_LOGIC;
        gtwiz_buffbypass_rx_start_user_in : IN STD_LOGIC;
        gtwiz_buffbypass_rx_done_out : OUT STD_LOGIC;
        gtwiz_buffbypass_rx_error_out : OUT STD_LOGIC;
        gtwiz_reset_clk_freerun_in : IN STD_LOGIC;
        gtwiz_reset_all_in : IN STD_LOGIC;
        gtwiz_reset_tx_pll_and_datapath_in : IN STD_LOGIC;
        gtwiz_reset_tx_datapath_in : IN STD_LOGIC;
        gtwiz_reset_rx_pll_and_datapath_in : IN STD_LOGIC;
        gtwiz_reset_rx_datapath_in : IN STD_LOGIC;
        gtwiz_reset_rx_cdr_stable_out : OUT STD_LOGIC;
        gtwiz_reset_tx_done_out : OUT STD_LOGIC;
        gtwiz_reset_rx_done_out : OUT STD_LOGIC;
        gtwiz_userdata_tx_in : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
        gtwiz_userdata_rx_out : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
        gtrefclk00_in : IN STD_LOGIC;
        qpll0outclk_out : OUT STD_LOGIC;
        qpll0outrefclk_out : OUT STD_LOGIC;
        qpll0lock_out : OUT STD_LOGIC;
        gtyrxn_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        gtyrxp_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        loopback_in : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        rxgearboxslip_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        txheader_in : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        txsequence_in : IN STD_LOGIC_VECTOR(27 DOWNTO 0);
--        gtpowergood_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        gtytxn_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        gtytxp_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        rxdatavalid_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        rxheader_out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        rxheadervalid_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        rxpmaresetdone_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        rxstartofseq_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        txpmaresetdone_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        txprgdivresetdone_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
      );
END COMPONENT;

signal gtwiz_buffbypass_tx_start_user_i, gtwiz_buffbypass_rx_start_user_i : std_logic := '0';

BEGIN

  gth16g_int:  if REGION_CONF(INDEX).mgt_i_kind = gth16 generate   

  example_wrapper_inst: gtwizard_ultrascale_gth16g
  	PORT MAP(
		    gthrxn_in                            => gtyrxn_in
		   ,gthrxp_in                            => gtyrxp_in
		   ,gthtxn_out                           => gtytxn_out
		   ,gthtxp_out                           => gtytxp_out
		   ,gtwiz_userclk_tx_reset_in            => gtwiz_userclk_tx_reset_in
		   ,gtwiz_userclk_tx_srcclk_out          => gtwiz_userclk_tx_srcclk_out
		   ,gtwiz_userclk_tx_usrclk_out          => gtwiz_userclk_tx_usrclk_out
		   ,gtwiz_userclk_tx_usrclk2_out         => gtwiz_userclk_tx_usrclk2_out
		   ,gtwiz_userclk_tx_active_out          => gtwiz_userclk_tx_active_out
		   ,gtwiz_userclk_rx_reset_in            => gtwiz_userclk_rx_reset_in
		   ,gtwiz_userclk_rx_srcclk_out          => gtwiz_userclk_rx_srcclk_out
		   ,gtwiz_userclk_rx_usrclk_out          => gtwiz_userclk_rx_usrclk_out
		   ,gtwiz_userclk_rx_usrclk2_out         => gtwiz_userclk_rx_usrclk2_out
		   ,gtwiz_userclk_rx_active_out          => gtwiz_userclk_rx_active_out
		   ,gtwiz_buffbypass_tx_reset_in         => gtwiz_buffbypass_tx_reset_in
		   ,gtwiz_buffbypass_tx_start_user_in    => gtwiz_buffbypass_tx_start_user_i
		   ,gtwiz_buffbypass_tx_done_out         => gtwiz_buffbypass_tx_done_out
		   ,gtwiz_buffbypass_tx_error_out        => gtwiz_buffbypass_tx_error_out
		   ,gtwiz_buffbypass_rx_reset_in         => gtwiz_buffbypass_rx_reset_in
		   ,gtwiz_buffbypass_rx_start_user_in    => gtwiz_buffbypass_rx_start_user_i
		   ,gtwiz_buffbypass_rx_done_out         => gtwiz_buffbypass_rx_done_out
		   ,gtwiz_buffbypass_rx_error_out        => gtwiz_buffbypass_rx_error_out
		   ,gtwiz_reset_clk_freerun_in           => gtwiz_reset_clk_freerun_in
		   ,gtwiz_reset_all_in                   => gtwiz_reset_all_in
		   ,gtwiz_reset_tx_pll_and_datapath_in   => gtwiz_reset_tx_pll_and_datapath_in
		   ,gtwiz_reset_tx_datapath_in           => gtwiz_reset_tx_datapath_in
		   ,gtwiz_reset_rx_pll_and_datapath_in   => gtwiz_reset_rx_pll_and_datapath_in
		   ,gtwiz_reset_rx_datapath_in           => gtwiz_reset_rx_datapath_in
		   ,gtwiz_reset_rx_cdr_stable_out        => gtwiz_reset_rx_cdr_stable_out
		   ,gtwiz_reset_tx_done_out              => gtwiz_reset_tx_done_out
		   ,gtwiz_reset_rx_done_out              => gtwiz_reset_rx_done_out
		   ,gtwiz_userdata_tx_in                 => gtwiz_userdata_tx_in
		   ,gtwiz_userdata_rx_out                => gtwiz_userdata_rx_out
		   ,gtrefclk00_in                        => gtrefclk00_in
		   ,qpll0outclk_out                      => qpll0outclk_out
		   ,qpll0outrefclk_out                   => qpll0outrefclk_out
		   ,rxgearboxslip_in                     => rxgearboxslip_in
		   ,txheader_in                          => txheader_in
		   ,txsequence_in                        => txsequence_in
--		   ,gtpowergood_out => open
		   ,rxdatavalid_out                      => rxdatavalid_out
		   ,rxheader_out                         => rxheader_out
		   ,rxheadervalid_out                    => rxheadervalid_out
		   ,rxpmaresetdone_out                   => rxpmaresetdone_out
		   ,rxstartofseq_out                     => rxstartofseq_out
		   ,txpmaresetdone_out                   => txpmaresetdone_out
		   ,txprgdivresetdone_out                => txprgdivresetdone_out
		   ,loopback_in                          => loopback_in,
		    qpll0lock_out                         => qpll0lock_out
		);
end generate gth16g_int;

  gty16g_int:  if REGION_CONF(INDEX).mgt_i_kind = gty16 generate   

  example_wrapper_inst: gtwizard_ultrascale_gty16g  
  	PORT MAP(
		    gtyrxn_in                            => gtyrxn_in
		   ,gtyrxp_in                            => gtyrxp_in
		   ,gtytxn_out                           => gtytxn_out
		   ,gtytxp_out                           => gtytxp_out
		   ,gtwiz_userclk_tx_reset_in            => gtwiz_userclk_tx_reset_in
		   ,gtwiz_userclk_tx_srcclk_out          => gtwiz_userclk_tx_srcclk_out
		   ,gtwiz_userclk_tx_usrclk_out          => gtwiz_userclk_tx_usrclk_out
		   ,gtwiz_userclk_tx_usrclk2_out         => gtwiz_userclk_tx_usrclk2_out
		   ,gtwiz_userclk_tx_active_out          => gtwiz_userclk_tx_active_out
		   ,gtwiz_userclk_rx_reset_in            => gtwiz_userclk_rx_reset_in
		   ,gtwiz_userclk_rx_srcclk_out          => gtwiz_userclk_rx_srcclk_out
		   ,gtwiz_userclk_rx_usrclk_out          => gtwiz_userclk_rx_usrclk_out
		   ,gtwiz_userclk_rx_usrclk2_out         => gtwiz_userclk_rx_usrclk2_out
		   ,gtwiz_userclk_rx_active_out          => gtwiz_userclk_rx_active_out
		   ,gtwiz_buffbypass_tx_reset_in         => gtwiz_buffbypass_tx_reset_in
		   ,gtwiz_buffbypass_tx_start_user_in    => gtwiz_buffbypass_tx_start_user_i
		   ,gtwiz_buffbypass_tx_done_out         => gtwiz_buffbypass_tx_done_out
		   ,gtwiz_buffbypass_tx_error_out        => gtwiz_buffbypass_tx_error_out
		   ,gtwiz_buffbypass_rx_reset_in         => gtwiz_buffbypass_rx_reset_in
		   ,gtwiz_buffbypass_rx_start_user_in    => gtwiz_buffbypass_rx_start_user_i
		   ,gtwiz_buffbypass_rx_done_out         => gtwiz_buffbypass_rx_done_out
		   ,gtwiz_buffbypass_rx_error_out        => gtwiz_buffbypass_rx_error_out
		   ,gtwiz_reset_clk_freerun_in           => gtwiz_reset_clk_freerun_in
		   ,gtwiz_reset_all_in                   => gtwiz_reset_all_in
		   ,gtwiz_reset_tx_pll_and_datapath_in   => gtwiz_reset_tx_pll_and_datapath_in
		   ,gtwiz_reset_tx_datapath_in           => gtwiz_reset_tx_datapath_in
		   ,gtwiz_reset_rx_pll_and_datapath_in   => gtwiz_reset_rx_pll_and_datapath_in
		   ,gtwiz_reset_rx_datapath_in           => gtwiz_reset_rx_datapath_in
		   ,gtwiz_reset_rx_cdr_stable_out        => gtwiz_reset_rx_cdr_stable_out
		   ,gtwiz_reset_tx_done_out              => gtwiz_reset_tx_done_out
		   ,gtwiz_reset_rx_done_out              => gtwiz_reset_rx_done_out
		   ,gtwiz_userdata_tx_in                 => gtwiz_userdata_tx_in
		   ,gtwiz_userdata_rx_out                => gtwiz_userdata_rx_out
		   ,gtrefclk00_in                        => gtrefclk00_in
		   ,qpll0outclk_out                      => qpll0outclk_out
		   ,qpll0outrefclk_out                   => qpll0outrefclk_out
		   ,rxgearboxslip_in                     => rxgearboxslip_in
		   ,txheader_in                          => txheader_in
		   ,txsequence_in                        => txsequence_in
--		   ,gtpowergood_out => open
		   ,rxdatavalid_out                      => rxdatavalid_out
		   ,rxheader_out                         => rxheader_out
		   ,rxheadervalid_out                    => rxheadervalid_out
		   ,rxpmaresetdone_out                   => rxpmaresetdone_out
		   ,rxstartofseq_out                     => rxstartofseq_out
		   ,txpmaresetdone_out                   => txpmaresetdone_out
		   ,txprgdivresetdone_out                => txprgdivresetdone_out
		   ,loopback_in                          => loopback_in,
		    qpll0lock_out                         => qpll0lock_out
		);
end generate gty16g_int;

 gty25g_int:  if REGION_CONF(INDEX).mgt_i_kind = gty25 generate   

  example_wrapper_inst: gtwizard_ultrascale_gty25g  
  	PORT MAP(
		    gtyrxn_in                            => gtyrxn_in
		   ,gtyrxp_in                            => gtyrxp_in
		   ,gtytxn_out                           => gtytxn_out
		   ,gtytxp_out                           => gtytxp_out
		   ,gtwiz_userclk_tx_reset_in            => gtwiz_userclk_tx_reset_in
		   ,gtwiz_userclk_tx_srcclk_out          => gtwiz_userclk_tx_srcclk_out
		   ,gtwiz_userclk_tx_usrclk_out          => gtwiz_userclk_tx_usrclk_out
		   ,gtwiz_userclk_tx_usrclk2_out         => gtwiz_userclk_tx_usrclk2_out
		   ,gtwiz_userclk_tx_active_out          => gtwiz_userclk_tx_active_out
		   ,gtwiz_userclk_rx_reset_in            => gtwiz_userclk_rx_reset_in
		   ,gtwiz_userclk_rx_srcclk_out          => gtwiz_userclk_rx_srcclk_out
		   ,gtwiz_userclk_rx_usrclk_out          => gtwiz_userclk_rx_usrclk_out
		   ,gtwiz_userclk_rx_usrclk2_out         => gtwiz_userclk_rx_usrclk2_out
		   ,gtwiz_userclk_rx_active_out          => gtwiz_userclk_rx_active_out
		   ,gtwiz_buffbypass_tx_reset_in         => gtwiz_buffbypass_tx_reset_in
		   ,gtwiz_buffbypass_tx_start_user_in    => gtwiz_buffbypass_tx_start_user_i
		   ,gtwiz_buffbypass_tx_done_out         => gtwiz_buffbypass_tx_done_out
		   ,gtwiz_buffbypass_tx_error_out        => gtwiz_buffbypass_tx_error_out
		   ,gtwiz_buffbypass_rx_reset_in         => gtwiz_buffbypass_rx_reset_in
		   ,gtwiz_buffbypass_rx_start_user_in    => gtwiz_buffbypass_rx_start_user_i
		   ,gtwiz_buffbypass_rx_done_out         => gtwiz_buffbypass_rx_done_out
		   ,gtwiz_buffbypass_rx_error_out        => gtwiz_buffbypass_rx_error_out
		   ,gtwiz_reset_clk_freerun_in           => gtwiz_reset_clk_freerun_in
		   ,gtwiz_reset_all_in                   => gtwiz_reset_all_in
		   ,gtwiz_reset_tx_pll_and_datapath_in   => gtwiz_reset_tx_pll_and_datapath_in
		   ,gtwiz_reset_tx_datapath_in           => gtwiz_reset_tx_datapath_in
		   ,gtwiz_reset_rx_pll_and_datapath_in   => gtwiz_reset_rx_pll_and_datapath_in
		   ,gtwiz_reset_rx_datapath_in           => gtwiz_reset_rx_datapath_in
		   ,gtwiz_reset_rx_cdr_stable_out        => gtwiz_reset_rx_cdr_stable_out
		   ,gtwiz_reset_tx_done_out              => gtwiz_reset_tx_done_out
		   ,gtwiz_reset_rx_done_out              => gtwiz_reset_rx_done_out
		   ,gtwiz_userdata_tx_in                 => gtwiz_userdata_tx_in
		   ,gtwiz_userdata_rx_out                => gtwiz_userdata_rx_out
		   ,gtrefclk00_in                        => gtrefclk00_in
		   ,qpll0outclk_out                      => qpll0outclk_out
		   ,qpll0outrefclk_out                   => qpll0outrefclk_out
		   ,rxgearboxslip_in                     => rxgearboxslip_in
		   ,txheader_in                          => txheader_in
		   ,txsequence_in                        => txsequence_in
--		   ,gtpowergood_out => open
		   ,rxdatavalid_out                      => rxdatavalid_out
		   ,rxheader_out                         => rxheader_out
		   ,rxheadervalid_out                    => rxheadervalid_out
		   ,rxpmaresetdone_out                   => rxpmaresetdone_out
		   ,rxstartofseq_out                     => rxstartofseq_out
		   ,txpmaresetdone_out                   => txpmaresetdone_out
		   ,txprgdivresetdone_out                => txprgdivresetdone_out
		   ,loopback_in                          => loopback_in,
		    qpll0lock_out                         => qpll0lock_out
		);
end generate gty25g_int;

END RTL;
