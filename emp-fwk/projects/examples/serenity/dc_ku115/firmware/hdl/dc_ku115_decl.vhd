-- emp_project_decl
--
-- Defines constants for the whole device
--
-- Dave Newbold, June 2014

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.emp_framework_decl.all;
use work.emp_device_types.all;

-------------------------------------------------------------------------------
package emp_project_decl is

  constant PAYLOAD_REV         : std_logic_vector(31 downto 0) := X"12345678";


  -- Number of LHC bunches 
  constant LHC_BUNCH_COUNT    : integer             := 3564;
  -- Latency buffer size
  constant LB_ADDR_WIDTH      : integer             := 10;

  -- Clock setup
  constant CLOCK_COMMON_RATIO : integer             := 24;
  constant CLOCK_RATIO        : integer             := 6;
  constant CLOCK_AUX_RATIO    : clock_ratio_array_t := (2, 4, 6);
   
  -- Only used by nullalgo   
  constant PAYLOAD_LATENCY    : integer             := 5;

  -- mgt -> chk -> buf -> fmt -> (algo) -> (fmt) -> buf -> chk -> mgt -> clk -> altclk
  -- reserve 0 and 19 for infrastructure
  constant REGION_CONF : region_conf_array_t := ( 
    0  => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 225  -- Right Column
    1  => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 226
    2  => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 227
    3  => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 228  
    4  => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 229
    5  => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 230
    6  => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 231
    7  => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 232
    8  => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 233
--    -- Cross-chip
    9  => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 133  -- Left Column
    10 => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 132
    11 => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 131
    14 => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 128
    15 => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 127
    16 => (gth16, no_chk, buf, no_fmt, buf, no_chk, gth16),  -- Bank 126

    others => kDummyRegion
    );



end emp_project_decl;
-------------------------------------------------------------------------------
