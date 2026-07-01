set pdk_base "/home/arjun/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd"

read_lef $pdk_base/techlef/sky130_fd_sc_hd__nom.tlef
read_lef $pdk_base/lef/sky130_fd_sc_hd.lef
read_liberty $pdk_base/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog mac_top_netlist.v
link_design mac_top
read_sdc mac_top.sdc

initialize_floorplan -utilization 60 \
                     -aspect_ratio 1.0 \
                     -core_space 5.0 \
                     -site unithd
tapcell -distance 14
write_def mac_top_floorplan.def
