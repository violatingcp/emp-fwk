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

  constant BOARD_DESIGN_ID : std_logic_vector(7 downto 0) := X"40";

  constant N_REGION       : integer := 18;

  constant N_REFCLK     : integer := 10;
  constant CROSS_REGION : integer := 8;

  constant IO_REGION_SPEC : io_region_spec_array_t(0 to N_REGION - 1) := (
    0  => (io_gth, 0, -1), -- Bank 225 -- Right Column
    1  => (io_gth, 0, -1), -- Bank 226 
    2  => (io_gth, 1, -1), -- Bank 227 
    3  => (io_gth, 1, -1), -- Bank 228 -- refclk only from bank 226 (0 or 1)
    4  => (io_gth, 3, -1), -- Bank 229  
    5  => (io_gth, 2, -1), -- Bank 230 
    6  => (io_gth, 4, -1), -- Bank 231 
    7  => (io_gth, 5, -1), -- Bank 232 
    8  => (io_gth, 5, -1), -- Bank 233 
--    -- Cross-chip
    9  => (io_gth,   6, -1), -- Bank 133 -- Left Column
    10 => (io_gth,   6, -1), -- Bank 132
    11 => (io_gth,   7, -1), -- Bank 131
    12 => (io_nogt, -1, -1), -- No MGT
    13 => (io_nogt, -1, -1), -- No MGT
    14 => (io_gth,   8, -1), -- Bank 128
    15 => (io_gth,   8, -1), -- Bank 127
    16 => (io_gth,   9, -1), -- Bank 126
    17 => (io_nogt, -1, -1), -- No MGT
    others  => kIONoGTRegion
  );

end emp_device_decl;
-------------------------------------------------------------------------------
