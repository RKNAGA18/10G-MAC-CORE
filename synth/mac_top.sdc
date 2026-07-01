# =========================================================
# TIMING CONSTRAINTS FOR 10G MAC CORE (Sky130)
# =========================================================

# 1. Define the Fast Host Clock (250 MHz -> 4.0 ns period)
create_clock -name host_clk -period 4.0 [get_ports host_clk]

# 2. Define the Slow PHY Clock (156.25 MHz -> 6.4 ns period)
create_clock -name phy_clk -period 6.4 [get_ports phy_clk]

# 3. Clock Domain Crossing (CDC) Rules
# Tell the router these clocks are completely independent.
set_clock_groups -asynchronous -group {host_clk} -group {phy_clk}

# 4. Input/Output Delays
set_input_delay  -max 0.8 -clock host_clk [get_ports host_tx_*]
set_output_delay -max 0.8 -clock host_clk [get_ports host_rx_*]

set_input_delay  -max 1.2 -clock phy_clk  [get_ports phy_rx_*]
set_output_delay -max 1.2 -clock phy_clk  [get_ports phy_tx_*]
