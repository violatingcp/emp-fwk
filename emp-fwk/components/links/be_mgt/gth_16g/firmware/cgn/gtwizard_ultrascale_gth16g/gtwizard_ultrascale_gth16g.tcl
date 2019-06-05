generate_target synthesis [get_files gtwizard_ultrascale_gth16g.xci]
set_property used_in_synthesis false [get_files -of_object [get_files gtwizard_ultrascale_gth16g.xci] -filter {FILE_TYPE == XDC}]
set_property used_in_implementation false [get_files -of_object [get_files gtwizard_ultrascale_gth16g.xci] -filter {FILE_TYPE == XDC}]
