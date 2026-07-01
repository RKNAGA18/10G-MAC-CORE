read_verilog -sv ../rtl/crc32_d8.sv
read_verilog -sv ../rtl/mac_tx.sv
read_verilog -sv ../rtl/mac_rx.sv
read_verilog -sv ../rtl/async_fifo.sv
read_verilog -sv ../rtl/mac_top.sv

hierarchy -check -top mac_top
synth -top mac_top

dfflibmap -liberty /home/arjun/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
abc -liberty /home/arjun/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
opt_clean
write_verilog mac_top_netlist.v
write_json mac_top_netlist.json
stat -liberty /home/arjun/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
