# 100 MHz external oscillator from Artix
create_clock -period 10.000 -name osc_clk [get_ports osc_clk_p]
