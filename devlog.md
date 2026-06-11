# 10G Ethernet MAC Core: Engineering Devlog

This log tracks the chronological journey, structural micro-architecture choices, and debugging victories during the design of a cycle-accurate 10G Ethernet Media Access Control (MAC) Core in SystemVerilog.

---

##  Log Entry: June 11, 2026
###  Milestone: Level 2 Mastered — The Parallel CRC-32 Math Integration

#### 1. The Architectural Challenge: The 800-Picosecond Deadline
At a 10 Gigabit line rate using an 8-bit datapath interface, the hardware has to process an incoming or outgoing byte every single clock cycle. This leaves a timing budget of roughly **800 picoseconds to 1 nanosecond** depending on the targeted implementation frequency. 

A traditional bit-serial Cyclic Redundancy Check (CRC) engine shifts data out one bit at a time, requiring 8 clock cycles per byte. In a high-throughput network pipeline, this sequential method creates severe backpressure bottlenecks, rendering the system too slow for line-rate data processing.

#### 2. The VLSI Solution: Unrolling Loops into Hardware (LFSR)
To hit the line-rate target, the sequential loops were transformed into a completely unrolled, parallel network of combinational logic gates. By implementing a parallel **Linear-Feedback Shift Register (LFSR)** configured for an 8-bit data width (`crc32_d8`), the 32-bit internal CRC state updates instantly as the data stream propagates through the physical wire matrix. 

The mathematical equations utilize deep tree networks of exclusive-OR (XOR) gates, calculating the complex IEEE 802.3 Ethernet generator polynomial (`0x04C11DB7`) in zero clock cycles.

#### 3. FSM Upgrades & Hardware Interleaving
The `mac_tx` Finite State Machine (FSM) was modified to orchestrate and step through the full frame transmission pipeline:

* **`IDLE` State:** Initializes the internal 32-bit CRC register to `32'hFFFFFFFF` (the Ethernet standard starting seed).
* **`PREAMBLE` & `SFD` States:** Asserts `s_axis_tready = 0` to block the host data from entering while streaming the 7-byte alternating pattern (`0x55`) and the 1-byte anchor (`0xD5`).
* **`DATA` State:** Opens the host interface. As bytes stream from the host to the network layer, they are routed through the combinational XOR matrix to compute the running hash on the fly.
* **`FCS` (Frame Check Sequence) State:** Triggered immediately when the host asserts `s_axis_tlast`. The FSM holds the host back for 4 cycles while it partitions the final 32-bit CRC register into 4 sequential bytes, inverts them (1's complement), and drives them onto the network output bus (`m_axis_tdata`).

```text
                    +-------------------+
                    |    crc32_d8.sv    |
                    |                   |
 s_axis_tdata ------> [Data]   [CRC Out] ----+
                    |  [8]       [32]   |    |
                    |                   |    | (next_crc)
     +--------------> [CRC In]          |    |
     |              |  [32]             |    |
     |              +-------------------+    |
     |                                       |
  [crc_reg] <================================+
  (Updates in DATA state on clk edge)
