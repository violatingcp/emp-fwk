-- emp_slim_top_decl
--
-- Defines constants for common top-level entity with minimal pinout
--
-- Tom Williams, June 2018

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.emp_framework_decl;

-------------------------------------------------------------------------------
package emp_slim_top_decl is

  constant OSC_CLK_FREQ : real := 300.0;

  constant PCIE_RST_ACTIVE_LEVEL : std_logic := '0';

end emp_slim_top_decl;
-------------------------------------------------------------------------------
