-- emp device declaration
--
-- Defines constants for the whole device
--
-- Alessandro Thea, April 2018

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.emp_framework_decl.all;

-------------------------------------------------------------------------------
package emp_device_decl is

  constant BOARD_DESIGN_ID : std_logic_vector(7 downto 0) := X"01";

  constant N_REGION       : integer := 18;

  constant N_REFCLK     : integer := 10;
  constant CROSS_REGION : integer := 8;

  constant IO_GT_REGIONS : io_gt_array(0 to N_REGION - 1) := (
    0  => io_gt,
    1  => io_gt,
    2  => io_gt,
    --3  => io_gt,
    4  => io_gt,
    5  => io_gt,
    6  => io_gt,
    7  => io_gt,
    8  => io_gt,
    --11  => io_gt,
    --12  => io_gt,
    13 => io_gt,
    16 => io_gt,
    17 => io_gt,
    others  => io_no_gt
  );

end emp_device_decl;
-------------------------------------------------------------------------------
