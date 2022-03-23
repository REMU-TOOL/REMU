ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
YOSYS_DIR := $(ROOT_DIR)/yosys

ifeq ($(DEBUG),y)
YOSYS := gdb --args yosys
else
YOSYS := yosys
endif

RTLSRCS := $(wildcard $(ROOT_DIR)/emulib/rtl/*.v)
SIMSRCS := $(wildcard $(ROOT_DIR)/emulib/sim/*.v $(ROOT_DIR)/emulib/stub/*.v)
