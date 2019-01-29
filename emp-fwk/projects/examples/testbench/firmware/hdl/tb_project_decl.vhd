-- emp_project_decl for simulation
--
-- Defines constants for the whole device
--
-- Alessandro Thea, Apr 2018

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.emp_framework_decl.all;
use work.emp_device_types.all;

-------------------------------------------------------------------------------
package emp_project_decl is

  constant PAYLOAD_REV     : std_logic_vector(31 downto 0) := X"12345678";

  constant LHC_BUNCH_COUNT : integer             := 3564;
  constant LB_ADDR_WIDTH   : integer             := 10;
  constant CLOCK_RATIO     : integer             := 6;
  constant CLOCK_AUX_RATIO : clock_ratio_array_t := (2, 4, 6);
  constant PAYLOAD_LATENCY : integer             := 5;

  -- mgt -> chk -> buf -> fmt -> (algo) -> (fmt) -> buf -> chk -> mgt -> clk -> altclk
  constant REGION_CONF : region_conf_array_t := (
    -- Uncomment to trigger the gt
    0  => (no_mgt, u_crc32, buf, no_fmt, buf, u_crc32, no_mgt, -1, -1),  -- 0 / 118
    --1  => (gth_10g, u_crc32, buf, no_fmt, buf, u_crc32, gth_10g, 0, 0),  -- 0 / 118
    others => kDummyRegion
    );
    
end emp_project_decl;
-------------------------------------------------------------------------------
