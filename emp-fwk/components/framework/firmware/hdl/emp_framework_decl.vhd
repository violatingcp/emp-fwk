-- emp_framework_decl
--
-- Defines the enumerators for the whole framework
--
-- Alessandro Thea, Tom Williams 2018

library IEEE;
use IEEE.STD_LOGIC_1164.all;

-------------------------------------------------------------------------------
package emp_framework_decl is

  constant FRAMEWORK_REV : std_logic_vector(23 downto 0) := X"000203";

  type clock_ratio_array_t is array(2 downto 0) of integer;

  type io_gt_kind_t is (io_nogt, io_gth, io_gty);

  -- Region specification
  type io_region_spec_t is
  record
    io_gt_kind     : io_gt_kind_t;
    io_refclk      : integer;
    io_refclk_alt  : integer;
  end record;

  -- Empty region
  constant kIONoGTRegion : io_region_spec_t := (io_nogt, -1, -1);

    -- Region configuration array type
  type io_region_spec_array_t is array (integer range <>) of io_region_spec_t;

  type mgt_kind_t is (no_mgt, gth16, gty16, gty25);
  type buf_kind_t is (no_buf, buf);
  type chk_kind_t is (no_chk, ologic_crc32, gct, f64, u_crc32);
  type fmt_kind_t is (no_fmt, tdr, s1, demux, m_pkt);

end emp_framework_decl;
-------------------------------------------------------------------------------
