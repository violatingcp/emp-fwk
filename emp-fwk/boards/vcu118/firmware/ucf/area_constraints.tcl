delete_pblocks -quiet infra ttc clocks payload
#-------------------------------------


# PCIe location constraints.  Not sure what is best Clock Root: X5Y5 through to X5Y8
set_property LOC GTYE4_CHANNEL_X1Y35 [get_cells -hierarchical -filter {NAME =~infra/dma/*GTYE4_CHANNEL_PRIM_INST}]
set_property LOC PCIE40E4_X1Y0 [get_cells -hierarchical -filter {NAME =~infra/dma/*pcie_4_0_pipe_inst/pcie_4_0_e4_inst}]
set_property USER_CLOCK_ROOT X5Y0 [get_nets -of_objects [get_pins -hierarchical -filter NAME=~infra/dma/*bufg_gt_sysclk/O]]
set_property USER_CLOCK_ROOT X5Y0 [get_nets -of_objects [get_pins -hierarchical -filter NAME=~infra/dma/*/phy_clk_i/bufg_gt_intclk/O]]
set_property USER_CLOCK_ROOT X5Y0 [get_nets -of_objects [get_pins -hierarchical -filter NAME=~infra/dma/*/phy_clk_i/bufg_gt_coreclk/O]]
set_property USER_CLOCK_ROOT X5Y0 [get_nets -of_objects [get_pins -hierarchical -filter NAME=~infra/dma/*/phy_clk_i/bufg_gt_userclk/O]]


# Parameters
set lSitePatterns [list SLICE DSP* RAM*]
set lLeftQuadWidth 401
set lRightQuadWidth 401

set lClkBounds [get_XY_bounds [get_clock_regions]]
puts "Clock region boundaries ${lClkBounds}"

lassign [create_quad_pblocks $lLeftQuadWidth $lRightQuadWidth $lSitePatterns] lNumQuads lLeftBoundary lRightBoundary

# Create the quad p-blocks and store the number of blocks created
puts "Created $lNumQuads quads"

for {set i 0} {$i < 14} {incr i} {
    set q [expr 1 + $i]
    set lQuadBlock [get_pblocks quad_R$q] 
    puts "Populating $lQuadBlock with region $i" 
    
    add_cells_to_pblock $lQuadBlock datapath/rgen\[$i\].region
}

for {set i 14} {$i < 28} {incr i} {
    set q [expr 28 - $i]
    set lQuadBlock [get_pblocks quad_L$q]
    puts "Populating $lQuadBlock with region $i"

    add_cells_to_pblock $lQuadBlock datapath/rgen\[$i\].region
}


# Payload Area assignment

set lPayload [create_pblock payload]
set lPayloadRect [find_rects [get_sites -of [get_clock_regions -f {ROW_INDEX>0}] -f "RPM_X >= $lLeftBoundary && RPM_X <= $lRightBoundary"]]
add_rects_to_pblock $lPayload $lPayloadRect $lSitePatterns

add_cells_to_pblock [get_pblocks payload] [get_cells -quiet datapath/rgen[*].pgen.*]