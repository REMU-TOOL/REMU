ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
YOSYS_DIR := $(ROOT_DIR)/yosys

ifeq ($(DEBUG),y)
YOSYS := gdb --args $(YOSYS_DIR)/yosys
else
YOSYS := $(YOSYS_DIR)/yosys
endif

RTLSRCS := $(wildcard $(ROOT_DIR)/rtl/ip/*.v $(ROOT_DIR)/rtl/system/*.v)
SIMSRCS := $(wildcard $(ROOT_DIR)/sim/*.v $(ROOT_DIR)/emulib/stub/*.v)
