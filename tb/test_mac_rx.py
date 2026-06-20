import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

@cocotb.test()
async def test_mac_rx_crc_check(dut):
    """Test the MAC RX FSM's ability to verify the CRC-32 Wax Seal."""
    
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    await FallingEdge(dut.clk)
    dut.rst_n.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tdata.value = 0
    dut.m_axis_tready.value = 1 
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1

    dut._log.info("--- TEST 1: THE PERFECT PACKET ---")
    # Preamble & SFD
    for _ in range(7):
        dut.s_axis_tvalid.value = 1
        dut.s_axis_tdata.value = 0x55
        await FallingEdge(dut.clk)
    dut.s_axis_tdata.value = 0xD5
    await FallingEdge(dut.clk)
    
    # Payload
    dut.s_axis_tdata.value = 0xAA
    dut.s_axis_tlast.value = 1
    await FallingEdge(dut.clk)
    dut.s_axis_tlast.value = 0
    
    correct_crc = [0x6f, 0x12, 0x66, 0x13]
    for byte in correct_crc:
        dut.s_axis_tdata.value = byte
        await FallingEdge(dut.clk)
        
    dut.s_axis_tvalid.value = 0
    await FallingEdge(dut.clk)
    
    # Check Verdict
    assert dut.rx_error.value == 0, "Hardware falsely flagged a perfect packet!"
    dut._log.info("Passed: Hardware accepted the perfect packet.")

    dut._log.info("--- TEST 2: THE SABOTAGED PACKET ---")
    # Preamble & SFD
    for _ in range(7):
        dut.s_axis_tvalid.value = 1
        dut.s_axis_tdata.value = 0x55
        await FallingEdge(dut.clk)
    dut.s_axis_tdata.value = 0xD5
    await FallingEdge(dut.clk)
    
    # Payload
    dut.s_axis_tdata.value = 0xAA
    dut.s_axis_tlast.value = 1
    await FallingEdge(dut.clk)
    dut.s_axis_tlast.value = 0
    
    
    corrupted_crc = [0x6f, 0x12, 0x66, 0xFF]
    for byte in corrupted_crc:
        dut.s_axis_tdata.value = byte
        await FallingEdge(dut.clk)
        
    dut.s_axis_tvalid.value = 0
    await FallingEdge(dut.clk)
    
    # Check Verdict
    assert dut.rx_error.value == 1, "SECURITY FAILURE: Hardware accepted a corrupted packet!"
    dut._log.info("Passed: Hardware caught the bad hash and asserted rx_error!")
    dut._log.info("🟢 RX SECURE VERIFICATION COMPLETE!")
