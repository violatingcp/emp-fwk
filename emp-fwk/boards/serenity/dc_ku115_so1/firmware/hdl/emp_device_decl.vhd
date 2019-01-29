-- mpultra_brd_decl
--
-- Defines constants for the whole device
--
-- Dave Newbold, June 2014

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.emp_framework_decl.all;

-------------------------------------------------------------------------------
package emp_device_decl is

  constant BOARD_DESIGN_ID : std_logic_vector(7 downto 0) := X"02";

  constant N_REGION       : integer := 18;

  constant N_REFCLK     : integer := 10;
  constant CROSS_REGION : integer := 8;

  constant IO_GT_REGIONS : io_gt_array(0 to N_REGION - 1) := (
    others  => io_no_gt
  );

end emp_device_decl;
-------------------------------------------------------------------------------
