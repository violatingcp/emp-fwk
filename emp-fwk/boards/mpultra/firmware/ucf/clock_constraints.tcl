
# 100 MHz external oscillator
create_clock -period 10.000 -name osc_clk [get_ports osc_clk_p]

# Clock rate setting for refclks (kind of arbitrary, 250MHz here) - external
set lRefClkSize [llength [get_ports {refclkn[*]}]]
for {set i 0} {$i < $lRefClkSize} {incr i} {
    create_clock -name refclk_$i -period 4.000 [get_ports refclkn[$i]]
}

set_clock_groups -asynch -group [get_clocks -regexp refclk_[0-9]+]
