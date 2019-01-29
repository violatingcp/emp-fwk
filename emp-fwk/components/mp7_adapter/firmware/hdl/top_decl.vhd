-- top_decl
--
-- Defines constants for the whole device
--
-- Dave Newbold, June 2014

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.emp_framework_decl.all;
use work.emp_device_types.all;
use work.emp_project_decl;

-------------------------------------------------------------------------------
package top_decl is

  constant PAYLOAD_REV       : std_logic_vector(31 downto 0) := work.emp_project_decl.PAYLOAD_REV;
 
  constant LHC_BUNCH_COUNT   : integer             := work.emp_project_decl.LHC_BUNCH_COUNT;
  constant LB_ADDR_WIDTH     : integer             := work.emp_project_decl.LB_ADDR_WIDTH;
  constant CLOCK_RATIO       : integer             := work.emp_project_decl.CLOCK_RATIO;
  constant CLOCK_AUX_RATIO   : clock_ratio_array_t := work.emp_project_decl.CLOCK_AUX_RATIO;
  constant PAYLOAD_LATENCY   : integer             := work.emp_project_decl.PAYLOAD_LATENCY;
  
  -- mgt -> chk -> buf -> fmt -> (algo) -> (fmt) -> buf -> chk -> mgt -> clk -> altclk
  constant REGION_CONF       : region_conf_array_t := work.emp_project_decl.REGION_CONF;
    

  -- Legacy MP7 constants  
  constant DR_ADDR_WIDTH     : integer             := 9;
  constant DAQ_N_BANKS       : integer             := 1;  -- Number of readout banks
  constant DAQ_TRIGGER_MODES : integer             := 1; -- Number of trigger modes for readout

end top_decl;
-------------------------------------------------------------------------------
