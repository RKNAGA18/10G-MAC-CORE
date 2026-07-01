set pdk_base "/home/arjun/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd"

read_lef $pdk_base/techlef/sky130_fd_sc_hd__nom.tlef
read_lef $pdk_base/lef/sky130_fd_sc_hd.lef
read_liberty $pdk_base/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_def mac_top_cts.def
read_sdc mac_top.sdc

# THE FIX: Restrict the global highway to M1-M5 as the foundry intended
set_routing_layers -signal met1-met5

global_route
detailed_route
write_def mac_top_routed.def
exit
