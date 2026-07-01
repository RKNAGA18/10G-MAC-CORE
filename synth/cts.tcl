set pdk_base "/home/arjun/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd"

read_lef $pdk_base/techlef/sky130_fd_sc_hd__nom.tlef
read_lef $pdk_base/lef/sky130_fd_sc_hd.lef
read_liberty $pdk_base/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_def mac_top_placed.def
read_sdc mac_top.sdc

# Grow the Clock Tree
clock_tree_synthesis -buf_list "sky130_fd_sc_hd__clkbuf_2 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8"

# THE FIX: Snap the newly added clock buffers into the legal silicon rows!
detailed_placement

write_def mac_top_cts.def
exit
