# Custom ku15p clock constraint to circumvent a rouding issue in the ku15p serenity daughtercard V1.
# The oscillator clock is routed to non-GC pins. To be fixed in v2. 
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets infra/osc_clock/ibufds_osc/O]
