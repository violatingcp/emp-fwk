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

package ipbus_decode_sim is

  constant IPBUS_SEL_WIDTH: positive := 5; -- Should be enough for now?
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_sim(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Fri Feb  9 11:46:21 2018 
  constant N_SLV_INFO: integer := 0;
  constant N_SLV_CTRL: integer := 1;
  constant N_SLV_TTC: integer := 2;
  constant N_SLV_DATAPATH: integer := 3;
  constant N_SLV_PAYLOAD: integer := 4;
  constant N_SLAVES: integer := 5;
-- END automatically generated VHDL

    
end ipbus_decode_sim;

package body ipbus_decode_sim is

  function ipbus_sel_sim(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Fri Feb  9 11:46:21 2018 
    if    std_match(addr, "0------------------0-----0--0---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_INFO, IPBUS_SEL_WIDTH)); -- info / base 0x00000000 / mask 0x80001048
    elsif std_match(addr, "0------------------0-----0--1---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CTRL, IPBUS_SEL_WIDTH)); -- ctrl / base 0x00000008 / mask 0x80001048
    elsif std_match(addr, "0------------------0-----1------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TTC, IPBUS_SEL_WIDTH)); -- ttc / base 0x00000040 / mask 0x80001040
    elsif std_match(addr, "0------------------1------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_DATAPATH, IPBUS_SEL_WIDTH)); -- datapath / base 0x00001000 / mask 0x80001000
    elsif std_match(addr, "1-------------------------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_PAYLOAD, IPBUS_SEL_WIDTH)); -- payload / base 0x80000000 / mask 0x80000000
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_sim;

end ipbus_decode_sim;

