-- emp_device_types
--
-- Defines design specific types and constants
--
-- Dave Newbold, June 2014

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.emp_device_decl.all;
use work.emp_framework_decl.all;

-------------------------------------------------------------------------------
package emp_device_types is

  -- Region configuration structure
  type region_conf_t is
  record
    mgt_i_kind : mgt_kind_t;
    chk_i_kind : chk_kind_t;
    buf_i_kind : buf_kind_t;
    fmt_kind   : fmt_kind_t;
    buf_o_kind : buf_kind_t;
    chk_o_kind : chk_kind_t;
    mgt_o_kind : mgt_kind_t; -- Currently unused
    refclk     : integer range -1 to N_REFCLK - 1;
    refclk_alt : integer range -1 to N_REFCLK - 1;
  end record;

  -- Dummy, empty region
  constant kDummyRegion : region_conf_t := (no_mgt, no_chk, no_buf, no_fmt, no_buf, no_chk, no_mgt, -1, -1);

  -- Region configuration array type
  type region_conf_array_t is array(0 to N_REGION - 1) of region_conf_t;

end emp_device_types;
-------------------------------------------------------------------------------
