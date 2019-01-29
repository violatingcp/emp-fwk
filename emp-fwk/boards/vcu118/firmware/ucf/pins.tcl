
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CONFIG_MODE SPIx8 [current_design]

# Bitstream config options
set_property BITSTREAM.CONFIG.CONFIGRATE 51.0 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pulldown [current_design]

# PCIe connections
set_property PACKAGE_PIN AC9 [get_ports pcie_sys_clk_p]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_sys_rst]
set_property PACKAGE_PIN AM17 [get_ports pcie_sys_rst]
set_property PULLUP true [get_ports pcie_sys_rst]
set_false_path -from [get_ports pcie_sys_rst]

# External 300 MHz oscillator
set_property PACKAGE_PIN F31      [get_ports osc_clk_n] ;# Bank  47 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_47
set_property IOSTANDARD  DIFF_SSTL12 [get_ports osc_clk_n] ;# Bank  47 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_47
set_property PACKAGE_PIN G31      [get_ports osc_clk_p] ;# Bank  47 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_47
set_property IOSTANDARD  DIFF_SSTL12 [get_ports osc_clk_p] ;# Bank  47 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_47

# Heartbeat LED
set_property IOSTANDARD  LVCMOS12 [get_ports heartbeat_led] ;# Bank  40 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_40
set_property PACKAGE_PIN AT32     [get_ports heartbeat_led] ;# Bank  40 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_40
