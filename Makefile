SIM ?= icarus
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES += $(PWD)/rtl/axi_stream_register.sv
TOPLEVEL = axi_stream_register
export PYTHONPATH := $(PWD)/tb:$(PYTHONPATH)
MODULE = test_axi
include $(shell cocotb-config --makefiles)/Makefile.sim
