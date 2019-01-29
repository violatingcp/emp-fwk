-- sim_infra
--
-- Simulation wrapper for ethernet, ipbus, MMC link and associated clock / system reset
--
-- Dave Newbold, June 2013

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.ipbus.all;

entity sim_infra is
  generic(
    MAC_ADDR : std_logic_vector(47 downto 0);
    IP_ADDR  : std_logic_vector(31 downto 0)
    );
  port(
    -- IPbus clock and reset (out)
    ipb_clk  : out std_logic;
    ipb_rst  : out std_logic;
    -- IPbus (from / to slaves)
    ipb_in   : in  ipb_rbus;
    ipb_out  : out ipb_wbus;
    -- External resets
    soft_rst : in  std_logic            -- The signal of lesser doom
    );

end sim_infra;

architecture rtl of sim_infra is

  signal clk125_g, ipb_clk_g, clk40_g, rst_g, rst_ctrl, clk125_fr, clk125, ipb_clk_i                    : std_logic;
  signal mac_tx_data, mac_rx_data                                                                       : std_logic_vector(7 downto 0);
  signal mac_tx_valid, mac_tx_last, mac_tx_error, mac_tx_ready, mac_rx_valid, mac_rx_last, mac_rx_error : std_logic;
  --signal ipb_out_m                                                                                      : ipb_wbus;
  --signal ipb_in_m                                                                                       : ipb_rbus;

begin

-- Clock generation for ipbus, ethernet, POR

  clocks : entity work.clock_sim
    generic map(
      CLK_AUX_FREQ => 40.0
      )
    port map(
      clko125   => clk125_g,
      clko25    => ipb_clk_g,
      clko_aux  => clk40_g,
      soft_rst  => soft_rst,
      nuke      => '0', -- no doom today
      rsto      => rst_g,
      rsto_ctrl => rst_ctrl
      );

-- Clocks for rest of logic

  clk125    <= clk125_g;
  ipb_clk_i <= ipb_clk_g;
  ipb_clk   <= ipb_clk_g;
  ipb_rst   <= rst_g;

--  Ethernet MAC core and PHY interface

  eth : entity work.eth_mac_sim
    generic map(
      MULTI_PACKET => true
      )
    port map(
      clk      => clk125,
      rst      => rst_ctrl,
      tx_data  => mac_tx_data,
      tx_valid => mac_tx_valid,
      tx_last  => mac_tx_last,
      tx_error => mac_tx_error,
      tx_ready => mac_tx_ready,
      rx_data  => mac_rx_data,
      rx_valid => mac_rx_valid,
      rx_last  => mac_rx_last,
      rx_error => mac_rx_error
      );

-- ipbus control logic

  ipbus : entity work.ipbus_ctrl
    port map(
      mac_clk      => clk125,
      rst_macclk   => rst_ctrl,
      ipb_clk      => ipb_clk_i,
      rst_ipb      => rst_ctrl,
      mac_rx_data  => mac_rx_data,
      mac_rx_valid => mac_rx_valid,
      mac_rx_last  => mac_rx_last,
      mac_rx_error => mac_rx_error,
      mac_tx_data  => mac_tx_data,
      mac_tx_valid => mac_tx_valid,
      mac_tx_last  => mac_tx_last,
      mac_tx_error => mac_tx_error,
      mac_tx_ready => mac_tx_ready,
      ipb_out      => ipb_out,
      ipb_in       => ipb_in,
      mac_addr     => MAC_ADDR,
      ip_addr      => IP_ADDR
      );

end rtl;

