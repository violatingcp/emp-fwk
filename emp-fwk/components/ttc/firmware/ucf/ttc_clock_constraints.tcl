# Remove clock constraints on the paths to the ttc clock frequency measurement block
set_false_path -to [get_pins ttc/ctr/t_in_reg/D]
