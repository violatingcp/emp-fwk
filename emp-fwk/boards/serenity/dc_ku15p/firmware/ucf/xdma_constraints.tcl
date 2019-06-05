# PCIe clock root optimisation
set_property USER_CLOCK_ROOT X3Y0 [get_nets -of_objects [get_pins -hierarchical -filter NAME=~infra/dma/*bufg_gt_sysclk/O]]
set_property USER_CLOCK_ROOT X3Y0 [get_nets -of_objects [get_pins -hierarchical -filter NAME=~infra/dma/*/phy_clk_i/bufg_gt_intclk/O]]
set_property USER_CLOCK_ROOT X3Y0 [get_nets -of_objects [get_pins -hierarchical -filter NAME=~infra/dma/*/phy_clk_i/bufg_gt_coreclk/O]]
set_property USER_CLOCK_ROOT X3Y0 [get_nets -of_objects [get_pins -hierarchical -filter NAME=~infra/dma/*/phy_clk_i/bufg_gt_userclk/O]]


