set script_path [ file dirname [ file normalize [ info script ] ] ]
source "$script_path/emp_colors.tcl"

proc apply_emp_site_highlights {} {
    global gColors
    dict set lColors PCI* [dict get $gColors Yellow500]
    dict set lColors GTH* [dict get $gColors Teal500]
    dict set lColors GTY* [dict get $gColors Teal300]
    dict set lColors DSP* [dict get $gColors LightGreen600]
    dict set lColors MMCM* [dict get $gColors Amber500]
    dict set lColors SLICE* [dict get $gColors LightBlue900]
    dict set lColors URAM* [dict get $gColors Pink200]
    dict set lColors RAM* [dict get $gColors Pink600]

    dict for {patt color} $lColors {
        puts "$patt $color"       
        highlight_objects -quiet -rgb $color [get_sites -f "NAME=~$patt"]
    }
}

apply_emp_site_highlights

