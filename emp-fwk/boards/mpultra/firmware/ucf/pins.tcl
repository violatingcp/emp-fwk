
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]

# PCIe connections
set_property PACKAGE_PIN N36 [get_ports pcie_sys_clk_p]
set_property PACKAGE_PIN AP28 [get_ports pcie_sys_rst]
set_property PULLUP true [get_ports pcie_sys_rst]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_sys_rst]
set_false_path -from [get_ports pcie_sys_rst]

# External 100 MHz oscillator
set_property PACKAGE_PIN E26 [get_ports osc_clk_p]
set_property PACKAGE_PIN D26 [get_ports osc_clk_n]
set_property IOSTANDARD LVDS [get_ports osc_clk_n]

# MGT Ref Clocks

# Check the assignment in ug575-ultrascale-pkg-pinout, page 201 and 76
# Top Back A - 225 (0) n
set_property PACKAGE_PIN AR9 [get_ports {refclkn[0]}] 
# Bottom Back A - 225 (1) n
set_property PACKAGE_PIN AM7 [get_ports {refclkn[1]}] 
# Top Back B - 228 (0) n
set_property PACKAGE_PIN AB7 [get_ports {refclkn[2]}]
# Bottom Back B - 228 (1) n
set_property PACKAGE_PIN Y7 [get_ports {refclkn[3]}]
# Top Back C 232 (0) n
set_property PACKAGE_PIN K7 [get_ports {refclkn[4]}]
# Bottom Back C 232 (1) n
set_property PACKAGE_PIN G9 [get_ports {refclkn[5]}]
# Top Front B 131 (0) n
set_property PACKAGE_PIN AA37 [get_ports {refclkn[6]}]
# Bottom Front A 131 (1)
set_property PACKAGE_PIN W37 [get_ports {refclkn[7]}]
# Top Front A 128 (0) n
set_property PACKAGE_PIN AE37 [get_ports {refclkn[8]}]
# Bottom Front B 128 (1) n
set_property PACKAGE_PIN AC37 [get_ports {refclkn[9]}]

# Heartbeat LED
set_property IOSTANDARD LVCMOS18 [get_ports heartbeat_led]
set_property PACKAGE_PIN AT22 [get_ports heartbeat_led]
