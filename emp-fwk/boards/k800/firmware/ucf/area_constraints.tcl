delete_pblocks -quiet infra ttc clocks payload
#-------------------------------------


# PCIe: Use X0Y0 hard block & lock the GTH in the bottom-right corner
set_property LOC GTHE3_CHANNEL_X1Y7 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[25].*gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST}]

# Constrain infra to the lowest row of clock regions, plus X5Y1 that contains the PCIe MGTs
create_pblock infra
resize_pblock [get_pblocks infra] -add {CLOCKREGION_X0Y0:CLOCKREGION_X5Y0}
resize_pblock [get_pblocks infra] -add CLOCKREGION_X5Y1
add_cells_to_pblock [get_pblocks infra] [get_cells -quiet [list infra info ctrl]] 


# Constrain TTC to a sub-area of infra
create_pblock ttc -parent [get_pblocks infra]
resize_pblock [get_pblocks ttc] -add CLOCKREGION_X2Y0
add_cells_to_pblock [get_pblocks ttc] [get_cells -quiet ttc] 


# Except for the clocks, that require a 3 row vertical slice to accommodate 3 MMCMs and the corresponding BUFGs.
create_pblock clocks
resize_pblock [get_pblocks clocks] -add {CLOCKREGION_X4Y0:CLOCKREGION_X4Y3}
add_cells_to_pblock [get_pblocks clocks] [get_cells infra/us_clocks/*]
add_cells_to_pblock [get_pblocks clocks] [get_cells infra/osc_clock/*]
add_cells_to_pblock [get_pblocks clocks] [get_cells ttc/clocks/*]

# # TTC MMC assignment
# # TODO - check the code below
# create_pblock mmcm_ttc
# resize_pblock [get_pblocks mmcm_ttc] -add CLOCKREGION_X5Y9

# add_cells_to_pblock [get_pblocks mmcm_ttc] [get_cells ttc/clocks/mmcm]
# set bufgs { bufg_40 bufg_p bufr_40s cgen\[0\].bufg_aux cgen\[1\].bufg_aux cgen\[2\].bufg_aux }
# foreach i $bufgs {
#     add_cells_to_pblock [get_pblocks mmcm_ttc] [get_cells -quiet ttc/clocks/${i} ]
# }
# # -------------------

# Parameters
set lSitePatterns [list SLICE DSP* RAM*]
set lLeftQuadWidth 500
set lRightQuadWidth 381

set lClkBounds [get_XY_bounds [get_clock_regions]]
puts "Clock region boundaries ${lClkBounds}"

lassign [create_quad_pblocks $lLeftQuadWidth $lRightQuadWidth $lSitePatterns] lNumQuads lLeftBoundary lRightBoundary

# Create the quad p-blocks and store the number of blocks created
puts "Created $lNumQuads quads"

for {set i 0} {$i < 9} {incr i} {
    set q [expr 1 + $i]
    set lQuadBlock [get_pblocks quad_R$q]
    puts "Populating $lQuadBlock with region $i" 
     
    add_cells_to_pblock $lQuadBlock datapath/rgen\[$i\].region
}
 
for {set i 9} {$i < 18} {incr i} {
    set q [expr 18 - $i]
    set lQuadBlock [get_pblocks quad_L$q]
    puts "Populating $lQuadBlock with region $i"

    add_cells_to_pblock $lQuadBlock datapath/rgen\[$i\].region
}


# Payload Area assignment

set lPayload [create_pblock payload]
set lPayloadRect [find_rects [get_sites -of [get_clock_regions -f {ROW_INDEX>0}] -f "RPM_X >= $lLeftBoundary && RPM_X <= $lRightBoundary"]]
add_rects_to_pblock $lPayload $lPayloadRect $lSitePatterns

add_cells_to_pblock [get_pblocks payload] [get_cells -quiet datapath/rgen[*].pgen.*]

