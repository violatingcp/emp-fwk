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

  constant BOARD_DESIGN_ID : std_logic_vector(7 downto 0) := X"41";

  constant N_REGION       : integer := 18;

  constant N_REFCLK     : integer := 12;
  constant CROSS_REGION : integer := 9;

  constant IO_REGION_SPEC : io_region_spec_array_t(0 to N_REGION - 1) := (
    0 => (io_gth,  0, -1),   --Bank 225 -- 
    1 => (io_gth,  0, -1),   --Bank 226
    2 => (io_gth,  1, -1),   --Bank 227
    3 => (io_gth,  2, -1),   --Bank 228
    4 => (io_gth,  3, -1),   --Bank 229
    5 => (io_gth,  3, -1),   --Bank 230
    6 => (io_gth,  4, -1),   --Bank 231
    7 => (io_gth,  5, -1),   --Bank 232
    8 => (io_gth,  5, -1),   --Bank 233
    9 => (io_gth,  6, -1),   --Bank 234
    -- Cross-chip
    10 => (io_gty,  7, -1),  --Bank 134 -
    11 => (io_gty,  8, -1),  --Bank 133
    12 => (io_gty,  8, -1),  --Bank 132
    13 => (io_gty,  9, -1),  --Bank 131
    14 => (io_gty,  9, -1),  --Bank 130
    15 => (io_gty, 10, -1),  --Bank 129
    16 => (io_gty, 11, -1),  --Bank 128
    17 => (io_gty, 11, -1),  --Bank 127
    others  => kIONoGTRegion
  );

end emp_device_decl;
-------------------------------------------------------------------------------
