# 10G Ethernet MAC Core

**Status:** In Development  
**Language:** SystemVerilog  
**Verification:** Cocotb (Python)  
**Goal:** Build a cycle-accurate, ultra-low latency 10G Ethernet MAC from scratch to master Clock Domain Crossing (CDC), IEEE 802.3 framing, and high-speed AXI-Stream data pipelines.

## Why This Project?
After successfully taping out an 8x8 INT4 AI Systolic Array, I am solving the "Feed the Beast" problem. High-performance accelerators require high-bandwidth data pipelines. This project is a deep dive into the physical and logical layers of network interconnects, building the hardware that bridges a host NPU/CPU to a 10Gbps fiber-optic physical layer (PHY).

## Development Roadmap & Curriculum

- [ ] **Level 1: The AXI4-Stream Handshake**
  - [x] Design cycle-accurate AXI-Stream pipeline register.
  - [x] Verify zero-data-loss under extreme backpressure (Cocotb).
- [ ] **Level 2: The TX Datapath (Framing & CRC)**
  - [ ] Implement IEEE 802.3 Preamble & SFD generation State Machine.
  - [ ] Design hardware combinatorial LFSR for real-time CRC-32 (FCS) calculation.
  - [ ] Append FCS and handle Inter-Packet Gap (IPG).
- [ ] **Level 3: The RX Datapath (Parsing & Validation)**
  - [ ] Detect SFD and strip Preamble from continuous XGMII stream.
  - [ ] Calculate incoming CRC-32 and validate against received FCS.
  - [ ] Assert error flags for corrupted frames and drop packets safely.
- [ ] **Level 4: Clock Domain Crossing (The Asynchronous FIFO)**
  - [ ] Design a dual-clock Asynchronous FIFO using Gray Code pointers.
  - [ ] Safely cross data from 200MHz Host domain to 156.25MHz Network domain.
- [ ] **Level 5: Full Duplex Loopback Verification**
  - [ ] Wire TX directly to RX in a closed-loop system.
  - [ ] Blast 10,000 randomized AXI-Stream packets through the pipeline and verify 100% integrity.

## Engineering Devlog
I am documenting every bug, timing violation, and architectural decision I make while building this core. You can read my raw engineering notes here: [Read the Devlog](devlog.md)

---
*Built with full custom RTL by R Naga Arjun*
