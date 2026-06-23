import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

@cocotb.test()
async def test_async_fifo_cdc(dut):
    """Test safely passing data between 250 MHz (Host) and 156.25 MHz (MAC) clocks."""
    
    cocotb.start_soon(Clock(dut.wr_clk, 4.0, units="ns").start())
    cocotb.start_soon(Clock(dut.rd_clk, 6.4, units="ns").start())

    dut.wr_rst_n.value = 0
    dut.rd_rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.wdata.value = 0
    
    await Timer(20, units="ns")
    dut.wr_rst_n.value = 1
    dut.rd_rst_n.value = 1
    await Timer(20, units="ns")

    dut._log.info("FILLING THE FIFO (250 MHz)")
    
    test_data = [0x11, 0x22, 0x33, 0x44, 0x55]
    for byte in test_data:
        await FallingEdge(dut.wr_clk)
        dut.wr_en.value = 1
        dut.wdata.value = byte
        
    await FallingEdge(dut.wr_clk)
    dut.wr_en.value = 0 
    
    dut._log.info("READING THE FIFO (156.25 MHz)")
    
    received_data = []
    for _ in range(50):
        await FallingEdge(dut.rd_clk) 
        if dut.empty.value == 0:
            dut.rd_en.value = 1
            received_data.append(int(dut.rdata.value))
            if len(received_data) == len(test_data):
                break 
        else:
            dut.rd_en.value = 0
            
    await FallingEdge(dut.rd_clk)
    dut.rd_en.value = 0
    
    dut._log.info(f"Sent Data: {[hex(x) for x in test_data]}")
    dut._log.info(f"Received : {[hex(x) for x in received_data]}")
    
    assert test_data == received_data, "Data corruption across clock domains!"
    dut._log.info("ASYNC FIFO METASTABILITY TEST PASSED")
