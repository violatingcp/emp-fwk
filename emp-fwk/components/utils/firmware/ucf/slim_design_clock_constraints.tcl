# 100 Mhz PCIe system clock
create_clock -period 10.000 -name pcie_sys_clk [get_ports pcie_sys_clk_p]


# IPbus clock. Derived from xdma user clock.
create_generated_clock -name ipbus_clk -source [get_pins infra/us_clocks/mmcm_user_clk/CLKIN1] [get_pins infra/us_clocks/mmcm_user_clk/CLKOUT1]

# 40 MHz from external oscillator
create_generated_clock -name clk_40_extern_i [get_pins infra/osc_clock/mmcm_osc_clk/CLKOUT1]
create_generated_clock -name clk_40_extern   -source [get_pins ttc/clocks/mmcm/CLKIN1] [get_pins ttc/clocks/mmcm/CLKOUT1]
# Approx 40MHz clock derived from AXI clock (for tests without external clock source)
create_generated_clock -name clk_40_pseudo_i [get_pins infra/us_clocks/mmcm_user_clk/CLKOUT2]
create_generated_clock -name clk_40_pseudo   -source [get_pins ttc/clocks/mmcm/CLKIN2] [get_pins ttc/clocks/mmcm/CLKOUT1]
# Payload I/O clock derived from external oscillator
create_generated_clock -name clk_payload_extern -source [get_pins ttc/clocks/mmcm/CLKIN1] [get_pins ttc/clocks/mmcm/CLKOUT3]
# Payload I/O clock derived from AXI clock (for tests without external clock source)
create_generated_clock -name clk_payload_pseudo -source [get_pins ttc/clocks/mmcm/CLKIN2] [get_pins ttc/clocks/mmcm/CLKOUT3]


# Clock groups: Asynchronous
set_clock_groups -asynch -group [get_clocks -include_generated_clocks ipbus_clk] -group {clk_40_pseudo clk_payload_pseudo}
set_clock_groups -asynch -group [get_clocks -include_generated_clocks ipbus_clk] -group [get_clocks -include_generated_clocks osc_clk]

# Clock groups: Logically exclusive
set_clock_groups -logically_exclusive -group [get_clocks -filter {MASTER_CLOCK == clk_40_extern_i}] -group [get_clocks -filter {MASTER_CLOCK == clk_40_pseudo_i}]
