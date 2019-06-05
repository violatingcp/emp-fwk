# 100 MHz external oscillator from Artix
create_clock -period 10.000 -name osc_clk [get_ports osc_clk_p]

# set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets infra/osc_clock/ibufds_osc/O]

# MGT refclks
set lRefClkSize [llength [get_ports {refclkn[*]}]]
for {set i 0} {$i < $lRefClkSize} {incr i} {
    create_clock -name refclk_$i -period 10.0 [get_ports refclkn[$i]]
}