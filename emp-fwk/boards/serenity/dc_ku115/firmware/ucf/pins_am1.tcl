
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]

# PCIe connections
set_property PACKAGE_PIN AL8 [get_ports pcie_sys_clk_p]
set_property PACKAGE_PIN AE19 [get_ports pcie_sys_rst]
set_property PULLUP true [get_ports pcie_sys_rst]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_sys_rst]
set_false_path -from [get_ports pcie_sys_rst]

set_property PACKAGE_PIN AV10 [get_ports {pcie_rxp[0]}]
set_property PACKAGE_PIN AU12 [get_ports {pcie_txp[0]}]

# EXTERNAL OSCILLATOR (tbd):
set_property IOSTANDARD LVDS_25 [get_ports osc_clk_p]
set_property PACKAGE_PIN AL15 [get_ports osc_clk_p]
set_property PACKAGE_PIN AL14 [get_ports osc_clk_n]

# MGT Ref Clocks

# Check the assignment in ug575-ultrascale-pkg-pinout, page 201 and 76
# Top Back A - 226 (0) n
set_property PACKAGE_PIN AG7 [get_ports {refclkn[0]}] 
# Bottom Back A - 226 (1) n
set_property PACKAGE_PIN AF9 [get_ports {refclkn[1]}] 
# Top Back B - 229 (0) n
set_property PACKAGE_PIN W7 [get_ports {refclkn[2]}]
# Bottom Back B - 229 (1) n
set_property PACKAGE_PIN U7 [get_ports {refclkn[3]}]
# Top Back C 232 (0) n
set_property PACKAGE_PIN M9 [get_ports {refclkn[4]}]
# Bottom Back C 232 (1) n
set_property PACKAGE_PIN L7 [get_ports {refclkn[5]}]
# Top Front B 132 (0) n
set_property PACKAGE_PIN M34 [get_ports {refclkn[6]}]
# Bottom Front A 132 (1)
set_property PACKAGE_PIN K34 [get_ports {refclkn[7]}]
# Top Front A 127 (0) n
set_property PACKAGE_PIN AF34 [get_ports {refclkn[8]}]
# Bottom Front B 127 (1) n
set_property PACKAGE_PIN AD34 [get_ports {refclkn[9]}]

# Heartbeat LED
set_property IOSTANDARD LVCMOS18 [get_ports heartbeat_led]
set_property PACKAGE_PIN K26 [get_ports heartbeat_led]
