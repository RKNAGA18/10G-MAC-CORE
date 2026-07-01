# =========================================================
# OPENROAD PLACEMENT SCRIPT FOR 10G MAC CORE
# =========================================================

set pdk_base "/home/arjun/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd"

read_lef $pdk_base/techlef/sky130_fd_sc_hd__nom.tlef
read_lef $pdk_base/lef/sky130_fd_sc_hd.lef
read_liberty $pdk_base/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_def mac_top_floorplan.def
read_sdc mac_top.sdc

# 3. Global Placement (Increased density tolerance to 0.65)
global_placement -density 0.65

# 4. Detailed Placement
detailed_placement

# 5. Save the Placed Blueprint
write_def mac_top_placed.def
exit
