SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/rtl/crc32_d8.sv 
VERILOG_SOURCES += $(PWD)/rtl/mac_tx.sv 
VERILOG_SOURCES += $(PWD)/rtl/mac_rx.sv 
VERILOG_SOURCES += $(PWD)/rtl/async_fifo.sv 
VERILOG_SOURCES += $(PWD)/rtl/mac_top.sv

TOPLEVEL = mac_top
export PYTHONPATH := $(PWD)/tb:$(PYTHONPATH)
# Point to the NEW Loopback Test
MODULE = test_mac_top 

include $(shell cocotb-config --makefiles)/Makefile.sim
