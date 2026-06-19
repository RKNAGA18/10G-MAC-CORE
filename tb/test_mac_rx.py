import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

@cocotb.test()
async def test_mac_rx_hunt_logic(dut):
    """Test the MAC RX FSM's ability to filter noise and lock onto a packet."""
    
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    await FallingEdge(dut.clk)
    dut.rst_n.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tdata.value = 0
    dut.m_axis_tready.value = 1 
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1

    dut._log.info("--- TEST 1: IGNORING LINE NOISE ---")
    for byte in [0x12, 0xFF, 0x4A, 0x00]:
        dut.s_axis_tvalid.value = 1
        dut.s_axis_tdata.value = byte
        await FallingEdge(dut.clk)
        assert dut.m_axis_tvalid.value == 0, f"Failed: Passed noise {hex(byte)}"
    dut._log.info("Passed: FSM successfully ignored random noise.")

    dut._log.info("--- TEST 2: THE FALSE ALARM ---")
    dut.s_axis_tdata.value = 0x55 
    await FallingEdge(dut.clk)
    dut.s_axis_tdata.value = 0x55 
    await FallingEdge(dut.clk)
    dut.s_axis_tdata.value = 0xAA # GARBAGE!
    await FallingEdge(dut.clk)
    
    dut.s_axis_tdata.value = 0xD5 
    await FallingEdge(dut.clk)
    assert dut.m_axis_tvalid.value == 0, "Failed: Opened gates on fake SFD!"
    dut._log.info("Passed: FSM successfully aborted on corrupted preamble.")

    dut._log.info("--- TEST 3: THE GOLDEN PACKET ---")
    dut.s_axis_tdata.value = 0x55
    for _ in range(7):
        await FallingEdge(dut.clk)
        
    dut.s_axis_tdata.value = 0xD5
    await FallingEdge(dut.clk)
    
    dut.s_axis_tdata.value = 0xBB # Payload
    await FallingEdge(dut.clk)
    
    assert dut.m_axis_tvalid.value == 1
    assert dut.m_axis_tdata.value == 0xBB
    dut._log.info("Passed: FSM successfully locked onto the envelope and delivered the payload.")
    
    dut.s_axis_tlast.value = 1
    await FallingEdge(dut.clk)
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    dut._log.info("🟢 RX HUNTING TEST PASSED! The Mail Inspector is fully functional.")
