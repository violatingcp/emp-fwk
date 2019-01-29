-- emp_device_decl
--
-- Defines constants for the whole device
--
-- Tom Williams, June 2018

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.emp_framework_decl.all;

-------------------------------------------------------------------------------
package emp_device_decl is

  constant BOARD_DESIGN_ID : std_logic_vector(7 downto 0) := X"03";

  constant N_REGION       : integer := 28;

  constant N_REFCLK     : integer := 0;
  constant CROSS_REGION : integer := 13;

  constant IO_GT_REGIONS : io_gt_array(0 to N_REGION - 1) := (
    others  => io_no_gt
  );

end emp_device_decl;
-------------------------------------------------------------------------------
