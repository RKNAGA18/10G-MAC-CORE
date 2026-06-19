SIM ?= icarus
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES += $(PWD)/rtl/mac_rx.sv
TOPLEVEL = mac_rx
export PYTHONPATH := $(PWD)/tb:$(PYTHONPATH)
MODULE = test_mac_rx
include $(shell cocotb-config --makefiles)/Makefile.sim
