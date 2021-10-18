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
FPGA_DIR := $(ROOT_DIR)/fpga
SIM_DIR := $(ROOT_DIR)/sim

TRANSFORM_LIB := $(ROOT_DIR)/transform/transform.so
TRANSFORM_TCL := $(ROOT_DIR)/scripts/transform.tcl

EMULIBS := $(wildcard $(LIB_DIR)/*.v)
