include ../../../common.mk

SIM ?= icarus
DUMP ?= n

TOPLEVEL_LANG := verilog

EMULIB_DIR := $(PWD)/../../../emulib

VERILOG_SOURCES += $(ROOT_DIR)/emulib/model/rammodel/*.v
VERILOG_SOURCES += $(PWD)/axi_txn_gate_test.v

COMPILE_ARGS += -I$(ROOT_DIR)/emulib/include

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
