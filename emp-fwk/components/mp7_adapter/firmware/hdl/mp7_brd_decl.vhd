-- mpultra_brd_decl
--
-- Defines constants for the whole device
--
-- Dave Newbold, June 2014

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.emp_device_decl;

-------------------------------------------------------------------------------
package mp7_brd_decl is

  constant BOARD_DESIGN_ID : std_logic_vector(7 downto 0) := work.emp_device_decl.BOARD_DESIGN_ID;

  constant N_REGION : integer := work.emp_device_decl.N_REGION;
  constant N_LINKS  : integer := N_REGION * 4;

  constant N_REFCLK     : integer := work.emp_device_decl.N_REFCLK;
  constant CROSS_REGION : integer := work.emp_device_decl.CROSS_REGION;

end mp7_brd_decl;
-------------------------------------------------------------------------------
