generate_target synthesis [get_files tx_fifo.xci]
set_property used_in_synthesis false [get_files -of_object [get_files tx_fifo.xci] -filter {FILE_TYPE == XDC}]
set_property used_in_implementation false [get_files -of_object [get_files tx_fifo.xci] -filter {FILE_TYPE == XDC}]
