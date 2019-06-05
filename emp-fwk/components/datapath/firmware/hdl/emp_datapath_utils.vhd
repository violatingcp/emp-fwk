-- emp datapath utilities
--
--
--
-- Alessandro Thea, Febbraio


library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.emp_device_decl.all;
use work.emp_framework_decl.all;
use work.emp_project_decl.all;


-------------------------------------------------------------------------------
package emp_datapath_utils is


-- reflclock functions
function is_refclk_used(refclk_i : in integer range 0 to N_REGION) return boolean;
function is_refclk_used_by(refclk_i : in integer range 0 to N_REGION; gt_kind : in io_gt_kind_t) return boolean;

function reg_has_refclk(reg_i : in integer range 0 to N_REGION) return boolean;
function reg_has_refclk_alt(reg_i : in integer range 0 to N_REGION) return boolean;

function is_mgt_symmetric(reg_i : in integer range 0 to N_REGION) return boolean;
function is_chksum_symmetric(reg_i : in integer range 0 to N_REGION) return boolean;

function is_mgt_compatible_with_site(reg_i : in integer range 0 to N_REGION) return boolean;

end package emp_datapath_utils;
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
package body emp_datapath_utils is

  ---------------------------------------------------------
  function is_refclk_used(refclk_i : in integer range 0 to N_REGION) return boolean is
    variable lIsRefClkUsed : boolean := false;
  begin

    for i in 0 to N_REGION - 1 loop
        if (
            IO_REGION_SPEC(i).io_refclk = refclk_i or
            IO_REGION_SPEC(i).io_refclk_alt = refclk_i
          ) and (
            REGION_CONF(i).mgt_i_kind /= no_mgt or
            REGION_CONF(i).mgt_o_kind /= no_mgt
          ) then
            lIsRefClkUsed := true;
        end if;
    end loop;

    return lIsRefClkUsed;

  end function is_refclk_used;
  ---------------------------------------------------------


  ---------------------------------------------------------
  function is_refclk_used_by(refclk_i : in integer range 0 to N_REGION; gt_kind : in io_gt_kind_t) return boolean is
    variable lIsRefClkUsed : boolean := false;
  begin

    for i in 0 to N_REGION - 1 loop
        if (
            IO_REGION_SPEC(i).io_refclk = refclk_i or
            IO_REGION_SPEC(i).io_refclk_alt = refclk_i
          ) and (
            IO_REGION_SPEC(i).io_gt_kind = gt_kind
          ) and (
            REGION_CONF(i).mgt_i_kind /= no_mgt or
            REGION_CONF(i).mgt_o_kind /= no_mgt
          ) then
            lIsRefClkUsed := true;
        end if;
    end loop;

    return lIsRefClkUsed;
  end function is_refclk_used_by;
  ---------------------------------------------------------


  ---------------------------------------------------------
  function reg_has_refclk(reg_i : in integer range 0 to N_REGION) return boolean is
  begin
    return IO_REGION_SPEC(reg_i).io_refclk = -1;
  end function reg_has_refclk;
  ---------------------------------------------------------


  ---------------------------------------------------------
  function reg_has_refclk_alt(reg_i : in integer range 0 to N_REGION) return boolean is
  begin
    return IO_REGION_SPEC(reg_i).io_refclk_alt = -1;
  end function reg_has_refclk_alt;
  ---------------------------------------------------------


  ---------------------------------------------------------
  function is_mgt_symmetric(reg_i : in integer range 0 to N_REGION) return boolean is
  begin
    return REGION_CONF(reg_i).mgt_i_kind = REGION_CONF(reg_i).mgt_o_kind;
  end function is_mgt_symmetric;
  ---------------------------------------------------------

  ---------------------------------------------------------
  function is_mgt_compatible_with_site(reg_i : in integer range 0 to N_REGION) return boolean is
  begin

    return 
      -- No mgts, no further checks
      (REGION_CONF(reg_i).mgt_i_kind = no_mgt and REGION_CONF(reg_i).mgt_o_kind = no_mgt) or

      -- Maybe redundant?
      (IO_REGION_SPEC(reg_i).io_gt_kind = io_nogt and 
        (REGION_CONF(reg_i).mgt_i_kind = no_mgt and REGION_CONF(reg_i).mgt_o_kind = no_mgt)
        ) or

      -- GTHs
      (IO_REGION_SPEC(reg_i).io_gt_kind = io_gth and 
        (REGION_CONF(reg_i).mgt_i_kind = gth16 and REGION_CONF(reg_i).mgt_o_kind = gth16)
        ) or

      -- GTYs
      (IO_REGION_SPEC(reg_i).io_gt_kind = io_gty and 
        (
          (REGION_CONF(reg_i).mgt_i_kind = gty16 and REGION_CONF(reg_i).mgt_o_kind = gty16) or
          (REGION_CONF(reg_i).mgt_i_kind = gty25 and REGION_CONF(reg_i).mgt_o_kind = gty25)
          )
        );

  end function is_mgt_compatible_with_site;
  ---------------------------------------------------------

  ---------------------------------------------------------
  function is_chksum_symmetric(reg_i : in integer range 0 to N_REGION) return boolean is
  begin
    return REGION_CONF(reg_i).chk_i_kind = REGION_CONF(reg_i).chk_o_kind;
  end function is_chksum_symmetric;
  ---------------------------------------------------------


end  package body emp_datapath_utils ;
-------------------------------------------------------------------------------
