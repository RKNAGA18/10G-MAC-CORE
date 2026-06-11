SIM ?= icarus
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES += $(PWD)/rtl/crc32_d8.sv $(PWD)/rtl/mac_tx.sv
TOPLEVEL = mac_tx
export PYTHONPATH := $(PWD)/tb:$(PYTHONPATH)
MODULE = test_mac_tx
include $(shell cocotb-config --makefiles)/Makefile.sim
