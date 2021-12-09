include ../../../common.mk

SIM ?= icarus
DUMP ?= n

TOPLEVEL_LANG := verilog

VERILOG_SOURCES += $(wildcard $(ROOT_DIR)/emulib/model/rammodel/*.v)
VERILOG_SOURCES += $(PWD)/test.v

COMPILE_ARGS += -I$(ROOT_DIR)/emulib/include

TOPLEVEL = rammodel_test

MODULE = test_model

DUMPFILE := $(MODULE).vcd
COMPILE_ARGS += -DDUMPFILE=\"$(DUMPFILE)\"

ifeq ($(DUMP),y)
PLUSARGS += +DUMP
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -f $(DUMPFILE)
