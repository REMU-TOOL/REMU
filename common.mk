ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
YOSYS_DIR := $(ROOT_DIR)/yosys
BUILD_DIR := $(ROOT_DIR)/build

ifeq ($(DEBUG),y)
YOSYS := gdb --args $(BUILD_DIR)/bin/yosys-debug
else
YOSYS := $(BUILD_DIR)/bin/yosys
endif

RTLSRCS := $(wildcard $(ROOT_DIR)/rtl/ip/*.v $(ROOT_DIR)/rtl/system/*.v)
SIMSRCS := $(wildcard $(ROOT_DIR)/sim/*.v $(ROOT_DIR)/emulib/*.v)
