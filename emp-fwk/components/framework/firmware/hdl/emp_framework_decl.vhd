-- fwtop_decl
--
-- Defines constants for the whole device
--
-- Dave Newbold, June 2014

library IEEE;
use IEEE.STD_LOGIC_1164.all;

-------------------------------------------------------------------------------
package emp_framework_decl is

  constant FRAMEWORK_REV : std_logic_vector(23 downto 0) := X"000101";

  type clock_ratio_array_t is array(2 downto 0) of integer;

  -- Move it to fwk decl
  type io_gt_kind_t is (io_no_gt, io_gt);
  type io_gt_array is array(natural range <>) of io_gt_kind_t;

  type mgt_kind_t is (no_mgt);
  type buf_kind_t is (no_buf, buf);
  type chk_kind_t is (no_chk, ologic_crc32, gct, f64, u_crc32);
  type fmt_kind_t is (no_fmt, tdr, s1, demux, m_pkt);

end emp_framework_decl;
-------------------------------------------------------------------------------
