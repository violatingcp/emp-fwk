# Post-upgrade XDMA core customisation
# Update the core constraints to locate the PCIe block and the surrounding logic 
# in the appropriate area of the ku115 FPGA and to the appropriate quad.
# 
# Note: Although this ultimately changes the core constraints it is 
# a setup file, and for this reason is located in the cfg folder.
set_property -dict [list CONFIG.pcie_blk_locn {X1Y0} CONFIG.select_quad {GTH_Quad_224}] [get_ips xdma_0]
