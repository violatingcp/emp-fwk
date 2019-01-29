set script_path [ file dirname [ file normalize [ info script ] ] ]
source "$script_path/emp_colors.tcl"
puts $gColors

proc apply_emp_cell_highlights_leg {} {
    global gColors
    set lColors [dict create]

    dict set lColors infra* [dict get $gColors LightGreen300]
    dict set lColors infra/dma* [dict get $gColors LightGreen600]
    dict set lColors ctrl* [dict get $gColors Teal200]
    dict set lColors ttc* [dict get $gColors Amber500]
    dict set lColors datapath* [dict get $gColors LightBlue200]
    dict set lColors payload* [dict get $gColors Pink600]

    puts $lColors

    dict for {patt color} $lColors {
        puts "$patt $color"       
        highlight_objects -rgb $color [get_cell -hier -f "NAME=~$patt"]
    }
}


apply_emp_cell_highlights
