set script_path [ file dirname [ file normalize [ info script ] ] ]
source "$script_path/emp_colors.tcl"

proc apply_emp_mgt_highlights {} {
    global gColors

    set lNumReg [llength [get_cells datapath/rgen[*].region]]

    lassign [dict get $gColors LightBlue100]  aR aG aB
    lassign [dict get $gColors LightBlue900] bR bG bB

    for {set i 0} {$i < $lNumReg} {incr i} {
	set r [expr $aR + $i * ($bR - $aR)/($lNumReg-1)]
	set g [expr $aG + $i * ($bG - $aG)/($lNumReg-1)]
	set b [expr $aB + $i * ($bB - $aB)/($lNumReg-1)]
	set lCol "$r $g $b"
	
        highlight_objects -rgb $lCol [get_cells -hier -f "NAME=~datapath/rgen[$i]*"]
    }

}


apply_emp_mgt_highlights

