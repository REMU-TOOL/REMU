SIM ?= icarus
DUMP ?= n

TOPLEVEL_LANG := verilog

EMULIB_DIR := $(PWD)/../../../emulib

VERILOG_SOURCES += $(EMULIB_DIR)/rammodel/axi_txn_gate.v
VERILOG_SOURCES += $(EMULIB_DIR)/rammodel/ready_valid_stall.v
VERILOG_SOURCES += $(PWD)/axi_txn_gate_test.v

COMPILE_ARGS += -I$(EMULIB_DIR)/rammodel

TOPLEVEL = rammodel_axi_txn_gate_sim_wrapper

MODULE = test_axi_txn_gate

DUMPFILE := $(MODULE).vcd
COMPILE_ARGS += -DDUMPFILE=\"$(DUMPFILE)\"

ifeq ($(DUMP),y)
PLUSARGS += +DUMP
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -f $(DUMPFILE)
