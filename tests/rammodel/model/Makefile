include ../../../common.mk

SIM ?= icarus
DUMP ?= n

TOPLEVEL_LANG := verilog

VERILOG_SOURCES += $(wildcard $(ROOT_DIR)/emulib/model/*.v)
VERILOG_SOURCES += $(PWD)/test.v

COMPILE_ARGS += -I$(ROOT_DIR)/emulib/include

TOPLEVEL = rammodel_test

MODULE = test_model

DUMPFILE := $(MODULE).fst
COMPILE_ARGS += -DDUMPFILE=\"$(DUMPFILE)\"
COMPILE_ARGS += -DSIM_LOG
#COMPILE_ARGS += -DSIM_LOG_FIFO
#COMPILE_ARGS += -DSIM_LOG_RAMMODEL_STATE_LSU_INS
#COMPILE_ARGS += -DSIM_LOG_RAMMODEL_STATE_LSU_MC_STATE

ifeq ($(DUMP),y)
PLUSARGS += -fst +DUMP
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -f $(DUMPFILE)
