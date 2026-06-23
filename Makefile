SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/rtl/async_fifo.sv

TOPLEVEL = async_fifo
export PYTHONPATH := $(PWD)/tb:$(PYTHONPATH)
MODULE = test_async_fifo

include $(shell cocotb-config --makefiles)/Makefile.sim
