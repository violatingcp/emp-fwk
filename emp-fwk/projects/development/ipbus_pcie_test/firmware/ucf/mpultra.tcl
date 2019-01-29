## MPUltra XDC
#
# Link Width   - x1
# Link Speed   - gen3
# Family       - kintexu
# Part         - xcku115
# Package      - flvb1760
# Speed grade  - -2
# PCIe Block   - X0Y5
## ---------------------------------------------------------------
#

set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]

#set_false_path -through [get_pins {infra/xdma_wrapper/xdma_0_i/xdma_0/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst/CFGMAX*}]
#set_false_path -through [get_nets {infra/xdma_wrapper/xdma_0_i/xdma_0/inst/cfg_max*}]



##### SYS RESET###########
#set_property LOC [get_package_pins -filter {PIN_FUNC == IO_T1U_N12_PERSTN1_65}] [get_ports pcie_sys_rst_n]
set_property PACKAGE_PIN AP28 [get_ports pcie_sys_rst_n]
set_property PULLUP true [get_ports pcie_sys_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_sys_rst_n]
set_false_path -from [get_ports pcie_sys_rst_n]


##### REFCLK_IBUF and PCIe block LOC ###########

set_property PACKAGE_PIN N36 [get_ports pcie_sys_clk_p]
create_clock -period 10.000 -name sys_clk [get_ports pcie_sys_clk_p]

set_property LOC GTHE3_CHANNEL_X0Y36 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[33].*gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]

