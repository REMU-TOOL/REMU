ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
YOSYS_DIR := $(ROOT_DIR)/yosys

DEBUG ?= n

ifeq ($(DEBUG),y)
YOSYS := gdb --args $(YOSYS_DIR)/yosys
else
YOSYS := yosys
endif

OUTPUT_DIR := $(ROOT_DIR)/output
LIB_DIR := $(ROOT_DIR)/lib
RTL_DIR := $(ROOT_DIR)/rtl
SIM_DIR := $(ROOT_DIR)/sim

TRANSFORM_LIB := $(ROOT_DIR)/transform/transform.so

EMULIBS := $(wildcard $(LIB_DIR)/*.v)
RTLSRCS := $(wildcard $(RTL_DIR)/ip/*.v $(RTL_DIR)/system/*.v)