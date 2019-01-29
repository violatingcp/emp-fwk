
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]

# PCIe connections
set_property PACKAGE_PIN AK10 [get_ports pcie_sys_clk_p]
set_property PACKAGE_PIN AE15 [get_ports pcie_sys_rst]
#set_property PULLUP true [get_ports pcie_sys_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_sys_rst]
set_false_path -from [get_ports pcie_sys_rst]

# EXTERNAL OSCILLATOR:
# - based on an ICS8N4Q001L clock generator,
#   hard-wired to use the first frequency setting, which defaults to 170
#   MHz according to datasheet, or 200 MHz according to user guide and
#   schematics.
# - 1.8V differential signal
# - connected to an HR bank (-> use LVDS_25 instead of LVDS)
set_property IOSTANDARD LVDS_25 [get_ports osc_clk_p]
set_property PACKAGE_PIN AL12 [get_ports osc_clk_p]
set_property PACKAGE_PIN AM12 [get_ports osc_clk_n]

# Heartbeat LED
set_property IOSTANDARD LVCMOS18 [get_ports heartbeat_led]
set_property PACKAGE_PIN J31 [get_ports heartbeat_led]
