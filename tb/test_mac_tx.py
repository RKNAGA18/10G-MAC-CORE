import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

@cocotb.test()
async def test_mac_tx_fsm(dut):
    """Test the MAC TX Preamble and SFD generation."""
    
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    await FallingEdge(dut.clk)
    dut.rst_n.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    dut.s_axis_tdata.value = 0
    dut.m_axis_tready.value = 1 
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1

    dut._log.info("--- WAKING UP THE NETWORK ---")
    dut.s_axis_tvalid.value = 1
    dut.s_axis_tdata.value = 0xAA 
    
    await FallingEdge(dut.clk)

    for i in range(7):
        assert dut.m_axis_tvalid.value == 1, "MAC stopped transmitting early!"
        assert dut.m_axis_tdata.value == 0x55, f"Expected Preamble 0x55, got {hex(dut.m_axis_tdata.value)}"
        assert dut.s_axis_tready.value == 0, "MAC didn't hold the host in backpressure!"
        dut._log.info(f"Cycle {i+1}: Sent Preamble 0x55. Host is paused.")
        await FallingEdge(dut.clk)

    assert dut.m_axis_tdata.value == 0xD5, f"Expected SFD 0xD5, got {hex(dut.m_axis_tdata.value)}"
    dut._log.info("Cycle 8: Sent SFD 0xD5. Envelope sealed!")
    await FallingEdge(dut.clk)

    dut._log.info("--- OPENING THE GATES FOR DATA ---")
    assert dut.s_axis_tready.value == 1, "MAC didn't open the gates for the host!"
    assert dut.m_axis_tdata.value == 0xAA, "Host data didn't pass through!"
    dut._log.info("Cycle 9: Successfully transmitted payload byte 0xAA")
    
    dut.s_axis_tlast.value = 1
    await FallingEdge(dut.clk)
    
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0
    await FallingEdge(dut.clk)
    
    dut._log.info("FSM TEST PASSED! The Envelope was created perfectly.")
