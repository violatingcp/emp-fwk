-- emp_project_decl for the VCU118 minimal example design
--
-- Defines constants for the whole project
--


library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.emp_framework_decl.all;
use work.emp_device_types.all;

-------------------------------------------------------------------------------
package emp_project_decl is

  constant PAYLOAD_REV        : std_logic_vector(31 downto 0) := X"12345678";
  
  -- Number of LHC bunches 
  constant LHC_BUNCH_COUNT    : integer             := 3564;
  -- Latency buffer size
  constant LB_ADDR_WIDTH      : integer             := 10;

  -- Clock setup
  constant CLOCK_COMMON_RATIO : integer             := 24;
  constant CLOCK_RATIO        : integer             := 6;
  constant CLOCK_AUX_RATIO    : clock_ratio_array_t := (2, 4, 6);

  -- Only used by nullalgo
  constant PAYLOAD_LATENCY : integer             := 5;

  -- mgt -> chk -> buf -> fmt -> (algo) -> (fmt) -> buf -> chk -> mgt
  constant REGION_CONF : region_conf_array_t := (
    0  => (no_mgt, u_crc32, buf, no_fmt, buf, u_crc32, no_mgt),
    ---- Cross-chip
    others => kDummyRegion
    );

end emp_project_decl;
-------------------------------------------------------------------------------
