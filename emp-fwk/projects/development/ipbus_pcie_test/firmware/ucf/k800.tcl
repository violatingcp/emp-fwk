## K800 XDC
#
# Link Width   - x1
# Link Speed   - gen3
# Family       - kintexu
# Part         - xcku115
# Package      - flva1517
# Speed grade  - -2
# PCIe Block   - X0Y0
## ---------------------------------------------------------------
#

set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]


##### SYS RESET###########
set_property IOSTANDARD LVCMOS18 [get_ports pcie_sys_rst]
set_property LOC PCIE_3_1_X0Y0 [get_cells infra/dma/xdma_0_i/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst]
set_property PACKAGE_PIN AE15 [get_ports pcie_sys_rst]
set_false_path -from [get_ports pcie_sys_rst]


##### REFCLK_IBUF and PCIe block LOC ###########

create_clock -period 10.000 -name sys_clk [get_ports pcie_sys_clk_p]
set_property PACKAGE_PIN AK10 [get_ports pcie_sys_clk_p]
