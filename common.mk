ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
YOSYS_DIR := $(ROOT_DIR)/yosys

OUTPUT_DIR := $(ROOT_DIR)/output
FPGA_DIR := $(ROOT_DIR)/fpga
SIM_DIR := $(ROOT_DIR)/sim

TRANSFORM_LIB := $(ROOT_DIR)/transform/transform.so
TRANSFORM_TCL := $(ROOT_DIR)/scripts/transform.tcl
