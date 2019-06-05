# Sequence of actions to apply mgt area constraints
# 1. Discover what kind of MGTs used in the region
#       Using a regex similar to {datapath/rgen\[0\].*inst\[\d\].(GT.*_CHANNEL).*}
#       Return the GT channel kind (GTHE3, GTHE4, GTYE4,... or none)
# 2. Depending on 1., match pblock content with region elements. Apply loc constraints to channels
# 3. Depending on 1., apply timing constraints
# 4. Apply common timing constraints (probably merge with 3?)

# -----------------------------------------------------------------------------
proc re_in_region {aRegId aSubRegex} {
    # set lRegex {}
    # append lRegex {datapath/rgen\[} $aRegId {\]} $aSubRegex
    return [format {datapath/rgen\[%s\]%s} $aRegId $aSubRegex]
}

# -----------------------------------------------------------------------------
# Utility function
# Find cells in a region according to a regex
proc get_cells_in_region {aRegId aSubRegex} {
    return [get_cells -quiet -hier -regex [re_in_region $aRegId $aSubRegex]]
}


# -----------------------------------------------------------------------------
# Utility function
# Assemble the regular expression to match gt instance cells in a region
proc re_gtinstcell_in_region {aRegId aGTFamilyRegex} {
    return [re_in_region $aRegId [format {.*inst\[\d\].%s_CHANNEL.*_INST$} $aGTFamilyRegex]]
}


# -----------------------------------------------------------------------------
# Utility function
# Identifies the type of mgts used in a region
proc detect_region_gt_types {aRegId} {
    set lGTRegex [re_gtinstcell_in_region $aRegId {(GT.E\d)}]
    # puts ">>> $lGTRegex"
    set lGTInstCells [get_cells -hier -regex -quiet $lGTRegex]
    # puts "->> $lGTInstCells"

    set lKinds [list]
    foreach c $lGTInstCells {
        if {[regexp $lGTRegex [lindex $c 0] match lGTType] == 0} {
            continue
        }
        lappend lKinds $lGTType
    }

    set lUniqueKinds [lsort -unique $lKinds]
    return $lUniqueKinds
}


# -----------------------------------------------------------------------------
# All that is needed is a function that give a pBlock, finds the GTH-Channels in it and binds them to the cells for a region
#
# Arguments: 
#  - pBlock
#  - Region (datapath/rgen[x])
# 
proc match_gtcells_to_sites {aRegId aPblock aGTKind aIncreasing} {
    set lNumChanPerQuad 4

    # To find all GT channels in a region and sort them in increasing 
    set lChanSites [get_sites -of $aPblock -filter NAME=~*GT*CHANNEL*]

    if {$aIncreasing} {
        set lChanSites [lsort -increasing -dictionary $lChanSites ]
    } else {
        set lChanSites [lsort -decreasing -dictionary $lChanSites ]
    }

    set lChanBounds [get_XY_bounds $lChanSites]
    puts "PBlock $aPblock, XY channel bounds $lChanBounds"

    if {[llength $lChanSites] != $lNumChanPerQuad} {
        puts "ERROR: Expected 4 channels sites in this quad pBlock, found [llength $lChanSites]"
        # TODO: Throw instead of returning
        return -code error "ERROR: Expected $lNumChanPerQuad channels sites in this quad pBlock, found [llength $lChanSites]"
    }

    if {[lindex $lChanBounds 0 0] != [lindex $lChanBounds 1 0]} {
        puts "ERROR: PBlock channels not aligned $lChanBounds"
        # TODO: Throw instead of returning
        return
    }

    set lChanCells [lsort [get_cells -hier -regex [re_gtinstcell_in_region $aRegId $aGTKind]]]
    if {[llength $lChanCells] != $lNumChanPerQuad} {
        puts "ERROR: Expected $lNumChanPerQuad channels cells in this region $aRegId, found [llength $lChanCells]"
        # TODO: Throw instead of returning
        return -code error "ERROR: Expected $lNumChanPerQuad channels cells in this region $aRegId, found [llength $lChanCells]: $lChanCells"
    }

    puts "pblock $aPblock:"
    foreach c $lChanSites {
        puts " - $c"
    }

    # Check that the channel has been instantiated
    puts "reg $aRegId:"
    foreach c $lChanCells {
        puts " - $c"
    }


    set zipped {}
    foreach lC $lChanCells lS $lChanSites {
        lappend zipped [list $lC $lS]
    }

    return $zipped

}

# -----------------------------------------------------------------------------
# Applies timing constraints to gths
proc apply_gt_timing_constraints {aRegId aGTKind} {

    # Power-On-FSM false path constraint (Should apply to Ultrascale Only)
    set lPwrOnFSMCells [get_cells_in_region $aRegId [format {.*gen_gtwizard_%s.gen_pwrgood_delay_inst.*pwr_on_fsm.*} [string tolower $aGTKind]]]
    if {$lPwrOnFSMCells != ""} {
        set_false_path -through [get_pins -filter {REF_PIN_NAME=~*Q} -of $lPwrOnFSMCells ]
        set_case_analysis 1     [get_pins -filter {REF_PIN_NAME=~*Q} -of $lPwrOnFSMCells ]
    } 

    set_false_path -to [get_cells_in_region $aRegId {.*bit_synchronizer.*inst/sreg_reg\[0\]}]
    set_false_path -to [get_cells_in_region $aRegId {.*bit_synchronizers_inst/.*bit_synchronizer.*inst/sreg_reg\[0\]}]

    set_false_path -to [get_cells_in_region $aRegId {.*reset_synchronizer.*inst/rst_in_.*_reg}]
    set_false_path -to [get_cells_in_region $aRegId {.*bit_synchronizer.*inst/i_in_meta_reg}]


    set_false_path -to [get_pins -filter {REF_PIN_NAME=~*D}   -of [get_cells_in_region $aRegId {.*reset_synchronizer.*inst/rst_in_meta.*}]]
    set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of [get_cells_in_region $aRegId {.*reset_synchronizer.*inst/rst_in_meta.*}]]
    set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of [get_cells_in_region $aRegId {.*reset_synchronizer.*inst/rst_in_sync1.*}]]
    set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of [get_cells_in_region $aRegId {.*reset_synchronizer.*inst/rst_in_sync2.*}]]
    set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of [get_cells_in_region $aRegId {.*reset_synchronizer.*inst/rst_in_sync3.*}]]
    set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of [get_cells_in_region $aRegId {.*reset_synchronizer.*inst/rst_in_out.*}]]
    set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of [get_cells_in_region $aRegId {.*reset_synchronizer.*inst/rst_in_meta.*}]]
    set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of [get_cells_in_region $aRegId {.*reset_synchronizer.*inst/rst_in_sync1.*}]]
    set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of [get_cells_in_region $aRegId {.*reset_synchronizer.*inst/rst_in_sync2.*}]]
    set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of [get_cells_in_region $aRegId {.*reset_synchronizer.*inst/rst_in_sync3.*}]]
    set_false_path -to [get_pins -filter {REF_PIN_NAME=~*CLR} -of [get_cells_in_region $aRegId {.*reset_synchronizer.*inst/rst_in_out.*}]]
    
    set_false_path -to [get_cells_in_region $aRegId {.*gtwiz_userclk_tx_inst/.*gtwiz_userclk_tx_active_.*_reg}]
    set_false_path -to [get_cells_in_region $aRegId {.*gtwiz_userclk_rx_inst/.*gtwiz_userclk_rx_active_.*_reg}]

}



# -----------------------------------------------------------------------------
proc constrain_mgts {aRegId aPblock aIncreasing} {

    # puts "------>"
    set lGTKinds [detect_region_gt_types $aRegId]
    # puts "-----.>"

    if {[llength $lGTKinds] > 1} {
        puts "ERROR: Expected 1 kind of GT channels in cell, found [llength $lGTlKinds]: $lGTlKinds"
        # TODO: Throw instead of returning
        return -code error "ERROR: Expected 1 kind of GT channels in cell, found [llength $lGTlKinds]: $lGTlKinds"
    } elseif { [llength $lGTKinds] == 0 } {
        # No MGTs here, carry on
        return
    }

    # puts "----->>"
    set lGTKind [lindex $lGTKinds 0]

    puts "Region $aRegId, detected $lGTKind"

    set lCellSiteMap [match_gtcells_to_sites $aRegId $aPblock $lGTKind $aIncreasing]
    puts "Region $aRegId, [llength $lCellSiteMap] cell-sites matches found."
    # puts "---->>>"

    foreach item $lCellSiteMap {
        lassign $item cell site
        set_property LOC $site $cell
    }
    # puts "--->>>>"

    apply_gt_timing_constraints $aRegId $lGTKind
}


