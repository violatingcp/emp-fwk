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

  constant BOARD_DESIGN_ID : std_logic_vector(7 downto 0) := X"FF";

  constant N_REGION        : integer := 2;

  constant N_REFCLK        : integer := 1;
  constant CROSS_REGION    : integer := 0;

  constant IO_GT_REGIONS : io_gt_array(0 to N_REGION - 1) := (
    0  => io_gt,
    1  => io_no_gt
  );


end emp_device_decl;
-------------------------------------------------------------------------------
