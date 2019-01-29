-- Address decode logic for ipbus fabric
-- 
-- This file has been AUTOGENERATED from the address table - do not hand edit
-- 
-- We assume the synthesis tool is clever enough to recognise exclusive conditions
-- in the if statement.
-- 
-- Dave Newbold, February 2011

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package ipbus_decode_emp_ctrl is

  constant IPBUS_SEL_WIDTH: positive := 2;
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_emp_ctrl(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Tue Oct 16 10:38:37 2018 
  constant N_SLV_CSR: integer := 0;
  constant N_SLV_BOARD_ID: integer := 1;
  constant N_SLV_ID: integer := 2;
  constant N_SLAVES: integer := 3;
-- END automatically generated VHDL

    
end ipbus_decode_emp_ctrl;

package body ipbus_decode_emp_ctrl is

  function ipbus_sel_emp_ctrl(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Tue Oct 16 10:38:37 2018 
    if    std_match(addr, "-----------------------------00-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CSR, IPBUS_SEL_WIDTH)); -- csr / base 0x00000000 / mask 0x00000006
    elsif std_match(addr, "-----------------------------01-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_BOARD_ID, IPBUS_SEL_WIDTH)); -- board_id / base 0x00000002 / mask 0x00000006
    elsif std_match(addr, "-----------------------------1--") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_ID, IPBUS_SEL_WIDTH)); -- id / base 0x00000004 / mask 0x00000004
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_emp_ctrl;

end ipbus_decode_emp_ctrl;

