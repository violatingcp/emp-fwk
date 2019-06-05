
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
# Bank 224
set_property PACKAGE_PIN AL12 [get_ports pcie_sys_clk_p]   
#set_property PACKAGE_PIN V10 [get_ports pcie_sys_clk_p]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_sys_rst]
set_property PACKAGE_PIN AN27 [get_ports pcie_sys_rst]
set_property PULLUP true [get_ports pcie_sys_rst]
set_false_path -from [get_ports pcie_sys_rst]

set_property PACKAGE_PIN BB6 [get_ports {pcie_rxp[0]}]
set_property PACKAGE_PIN AW8 [get_ports {pcie_txp[0]}]

# External 100 MHz oscillator from artix
# Ku15p revision 1.
# Bank  66 VCCO - VCC1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_66
set_property PACKAGE_PIN AR12      [get_ports osc_clk_n] ;
set_property IOSTANDARD  DIFF_SSTL18_I [get_ports osc_clk_n] ;
# Bank  66 VCCO - VCC1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_66
set_property PACKAGE_PIN AR13      [get_ports osc_clk_p] ;
set_property IOSTANDARD  DIFF_SSTL18_I [get_ports osc_clk_p] ;

# set_property PACKAGE_PIN AU16      [get_ports osc_clk_n] ;
# set_property IOSTANDARD  DIFF_SSTL18_I [get_ports osc_clk_n] ;
# set_property PACKAGE_PIN AT16      [get_ports osc_clk_p] ;
# set_property IOSTANDARD  DIFF_SSTL18_I [get_ports osc_clk_p] ;

# Heartbeat LED
# Bank  65 VCCO - VCC1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_D10_65
set_property IOSTANDARD  LVCMOS18 [get_ports heartbeat_led] ;
set_property PACKAGE_PIN AM23     [get_ports heartbeat_led] ;


#MGT Ref clks - Taken from ku150 Schematics
# Bank 225 refclk0
set_property PACKAGE_PIN AJ12 [get_ports {refclkp[0]}]
# Bank 227 refclk0
set_property PACKAGE_PIN AE12 [get_ports {refclkp[1]}]
# Bank 227 refclk1
set_property PACKAGE_PIN AD10 [get_ports {refclkp[2]}]
# Bank 230 refclk0
set_property PACKAGE_PIN W12 [get_ports {refclkp[3]}]
# Bank 230 refclk1
set_property PACKAGE_PIN V10 [get_ports {refclkp[4]}]
# Bank 233 refclk0
set_property PACKAGE_PIN N12 [get_ports {refclkp[5]}]
# Bank 233 refclk1
set_property PACKAGE_PIN M10 [get_ports {refclkp[6]}]

# Bank 133 refclk1
set_property PACKAGE_PIN N30 [get_ports {refclkp[7]}]
# Bank 133 refclk0
set_property PACKAGE_PIN P32 [get_ports {refclkp[8]}]
# Bank 130 refclk1
set_property PACKAGE_PIN Y32 [get_ports {refclkp[9]}]
# Bank 130 refclk0
set_property PACKAGE_PIN W30 [get_ports {refclkp[10]}]
# Bank 128 refclk0
set_property PACKAGE_PIN AD32 [get_ports {refclkp[11]}]




