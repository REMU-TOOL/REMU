ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
YOSYS_DIR := $(ROOT_DIR)/yosys

TRANSFORM_LIB := $(ROOT_DIR)/transform/transform.so
TRANSFORM_TCL := $(ROOT_DIR)/scripts/transform.tcl
