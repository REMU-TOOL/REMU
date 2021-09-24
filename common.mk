ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

TRANSFORM_LIB := $(ROOT_DIR)/transform/transform.so
TRANSFORM_TCL := $(ROOT_DIR)/scripts/transform.tcl
