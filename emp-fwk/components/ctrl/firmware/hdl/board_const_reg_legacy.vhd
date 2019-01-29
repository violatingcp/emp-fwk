-- board_const_reg
--
-- Allows software to determine top level parameters of firmware
--
-- loc 0: magic word (X"DEADBEAF")
-- loc 1: FW_REV
-- loc 2: top level constants (see below)
-- loc 3: ALGO_REV
--
-- Dave Newbold, July 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.emp_project_decl.all;
use work.emp_framework_decl.all;
use work.emp_device_decl.all;

entity board_const_reg is
    port(
        ipb_in: in ipb_wbus;
        ipb_out: out ipb_rbus
    );

end board_const_reg;

architecture rtl of board_const_reg is

begin

    ipb_out.ipb_ack <= ipb_in.ipb_strobe;
    ipb_out.ipb_err <= '0';
    
    with ipb_in.ipb_addr(1 downto 0) select ipb_out.ipb_rdata <=
        X"DEADBEAF" when "00",
        BOARD_DESIGN_ID & FRAMEWORK_REV when "01",
        PAYLOAD_REV when "10",
        std_logic_vector(to_unsigned(CLOCK_RATIO, 4)) & std_logic_vector(to_unsigned(N_REGION, 6)) &
            std_logic_vector(to_unsigned(LB_ADDR_WIDTH, 4)) & std_logic_vector(to_unsigned(0, 6)) &
            std_logic_vector(to_unsigned(LHC_BUNCH_COUNT, 12)) when others;
        
end rtl;
