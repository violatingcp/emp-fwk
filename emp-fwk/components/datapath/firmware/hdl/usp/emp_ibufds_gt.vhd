-- emp_ibufds_gt
--
-- Wrapper for ultrascale clock buffers
-- 
-- Author: Alessandro Thea

library IEEE;
use IEEE.STD_LOGIC_1164.all;

library unisim;
use unisim.vcomponents.all;

entity emp_ibufds_gt is
  port (
    refclkp     : in  std_logic;
    refclkn     : in  std_logic;
    refclk      : out std_logic;
    refclk_buf  : out std_logic
  );
end emp_ibufds_gt;

architecture rtl of emp_ibufds_gt is
  signal refclk_odiv : std_logic;
begin
    ibuf : IBUFDS_GTE4
      port map(
        i     => refclkp,
        ib    => refclkn,
        o     => refclk,
        odiv2 => refclk_odiv,
        ceb   => '0'
        );

    bufg_refclk : BUFG_GT
      port map(
        i       => refclk_odiv,
        o       => refclk_buf,
        ce      => '1',
        clr     => '0',
        div     => "000",
        cemask  => '1',
        clrmask => '0'
        );
end rtl;
