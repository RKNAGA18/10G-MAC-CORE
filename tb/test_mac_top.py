import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

async def physical_loopback(dut):
    """Simulates a fiber-optic cable plugged from the TX port directly into the RX port."""
    while True:
        await FallingEdge(dut.phy_clk)
        dut.phy_rx_tdata.value  = dut.phy_tx_tdata.value
        dut.phy_rx_tvalid.value = dut.phy_tx_tvalid.value
        dut.phy_rx_tlast.value  = dut.phy_tx_tlast.value
        dut.phy_tx_tready.value = dut.phy_rx_tready.value

@cocotb.test()
async def test_mac_top_loopback(dut):
    """Full System Test: Host -> TX FIFO -> MAC TX -> [LOOPBACK] -> MAC RX -> RX FIFO -> Host"""
    
    # 1. Start the Dual Clocks
    cocotb.start_soon(Clock(dut.host_clk, 4.0, units="ns").start()) # 250 MHz
    cocotb.start_soon(Clock(dut.phy_clk, 6.4, units="ns").start())  # 156.25 MHz
    
    # 2. Plug in the physical loopback cable
    cocotb.start_soon(physical_loopback(dut))

    # 3. Reset the entire chip
    dut.host_rst_n.value = 0
    dut.phy_rst_n.value = 0
    dut.host_tx_tvalid.value = 0
    dut.host_tx_tlast.value = 0
    dut.host_rx_tready.value = 1 # Host is always ready to read
    
    await Timer(40, units="ns")
    dut.host_rst_n.value = 1
    dut.phy_rst_n.value = 1
    await Timer(40, units="ns")

    dut._log.info("--- WAREHOUSE: SENDING PACKET (250 MHz) ---")
    
    # The Host sends a 4-byte payload
    payload = [0xAA, 0xBB, 0xCC, 0xDD]
    for i, byte in enumerate(payload):
        await FallingEdge(dut.host_clk)
        # Wait for FIFO to be ready
        while dut.host_tx_tready.value == 0:
            await FallingEdge(dut.host_clk)
            
        dut.host_tx_tvalid.value = 1
        dut.host_tx_tdata.value = byte
        dut.host_tx_tlast.value = 1 if (i == len(payload) - 1) else 0
        
    await FallingEdge(dut.host_clk)
    dut.host_tx_tvalid.value = 0
    dut.host_tx_tlast.value = 0
    
    dut._log.info("Packet sent to TX Core. Waiting for network transit...")
    
    # 4. Wait for the data to traverse the entire architecture
    received_payload = []
    
    dut._log.info("--- WAREHOUSE: RECEIVING PACKET (250 MHz) ---")
    
    # Wait up to 200 clock cycles for the packet to make the round trip
    for _ in range(200):
        await FallingEdge(dut.host_clk)
        if dut.host_rx_tvalid.value == 1:
            received_payload.append(int(dut.host_rx_tdata.value))
            if dut.host_rx_tlast.value == 1:
                break # End of packet detected!
                
    dut._log.info(f"Original Payload : {[hex(x) for x in payload]}")
    dut._log.info(f"Received Payload : {[hex(x) for x in received_payload]}")
    
    # 5. Check for errors
    assert dut.host_rx_error.value == 0, "MAC RX raised a CRC corruption error!"
    assert payload == received_payload, "Data was lost or corrupted during transit!"
    
    dut._log.info("🟢 FULL 10G MAC CORE LOOPBACK TEST PASSED! The chip is flawless.")
