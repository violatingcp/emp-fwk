set script_path [ file dirname [ file normalize [ info script ] ] ]
source "$script_path/emp_colors.tcl"
puts $gColors

# proc apply_emp_site_highlights_leg {} {

#     set lColors [dict create]
#     dict lappend lColors GTH* 67 181 245
#     dict lappend lColors GTY* 67 181 245
#     dict lappend lColors DSP* 64 163 63
#     dict lappend lColors MMCM* 255 185 0
#     dict lappend lColors SLICE* 43 51 155
#     dict lappend lColors URAM* 153 43 174 
#     dict lappend lColors RAM* 233 71 128
#     puts $lColors

#     dict for {patt color} $lColors {
#         puts "$patt $color"       
#         highlight_objects -quiet -rgb $color [get_sites -f "NAME=~$patt"]
#     }
# }


proc apply_emp_site_highlights {} {
    global gColors
    dict set lColors GTH* [dict get $gColors Teal500]
    dict set lColors GTY* [dict get $gColors Teal300]
    dict set lColors DSP* [dict get $gColors LightGreen600]
    dict set lColors MMCM* [dict get $gColors Amber500]
    dict set lColors SLICE* [dict get $gColors LightBlue800]
    dict set lColors URAM* [dict get $gColors Pink400]
    dict set lColors RAM* [dict get $gColors Pink600]
    puts "aaa [dict get $lColors URAM*]"
    puts $lColors

    dict for {patt color} $lColors {
        puts "$patt $color"       
        highlight_objects -quiet -rgb $color [get_sites -f "NAME=~$patt"]
    }
}

apply_emp_site_highlights

