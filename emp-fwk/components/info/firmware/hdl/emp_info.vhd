-- Simple block that exposes info registers to IPbus
--
-- Tom Williams (RAL)
-- based on code from mp7_ctrl's "board_const_reg" entity

library IEEE;
use IEEE.std_logic_1164.all;

use work.ipbus.all;
use work.emp_framework_decl.all;
use work.emp_device_decl.all;
use work.emp_project_decl.all;


entity emp_info is
  port(
    ipb_in: in ipb_wbus;
    ipb_out: out ipb_rbus
  );

end emp_info;


architecture rtl of emp_info is

begin

  ipb_out.ipb_ack <= ipb_in.ipb_strobe;
  ipb_out.ipb_err <= ipb_in.ipb_write when ipb_in.ipb_strobe = '1' else '0';

  with ipb_in.ipb_addr(1 downto 0) select ipb_out.ipb_rdata <=
    X"DEADBEEF"   when "00",
    BOARD_DESIGN_ID & FRAMEWORK_REV when "01",
    PAYLOAD_REV   when "10",
    X"00000000"   when others;

end rtl;
