-- emp_slim_top_decl
--
-- Defines constants for common top-level entity with minimal pinout
--
-- Tom Williams, May 2018

library IEEE;
use IEEE.STD_LOGIC_1164.all;

-------------------------------------------------------------------------------
package emp_slim_top_decl is

  constant OSC_CLK_FREQ : real := 100.0;

  constant PCIE_RST_ACTIVE_LEVEL : std_logic := '0';

end emp_slim_top_decl;
-------------------------------------------------------------------------------
