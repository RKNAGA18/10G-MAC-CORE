import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

@cocotb.test()
async def axi_handshake_test(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await FallingEdge(dut.clk)
    dut.rst_n.value = 0
    dut.s_axis_tvalid.value = 0
    dut.m_axis_tready.value = 0
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1

    dut._log.info("--- TEST 1: SMOOTH FLOW ---")
    dut.m_axis_tready.value = 1 
    dut.s_axis_tvalid.value = 1
    dut.s_axis_tdata.value = 0xAA
    await FallingEdge(dut.clk)
    dut.s_axis_tvalid.value = 0
    await FallingEdge(dut.clk)
    
    assert dut.m_axis_tdata.value == 0xAA, "Data corrupted in smooth flow!"
    dut._log.info("Smooth flow passed! 0xAA transferred.")

    dut._log.info("--- TEST 2: THE TRAFFIC JAM (BACKPRESSURE) ---")
    dut.m_axis_tready.value = 0 
    dut.s_axis_tvalid.value = 1
    dut.s_axis_tdata.value = 0xBB
    
    for _ in range(5):
        await FallingEdge(dut.clk)
        
    dut._log.info("Traffic jam held for 5 cycles. Now opening the gates...")
    
    dut.s_axis_tvalid.value = 0
    dut.m_axis_tready.value = 1
    await FallingEdge(dut.clk)
    
    assert dut.m_axis_tdata.value == 0xBB, "Data was lost during backpressure!"
    dut._log.info("Traffic jam survived! 0xBB successfully held and transferred.")
    dut._log.info("LEVEL 1 COMPLETE")
