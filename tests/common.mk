TEST_DIR   := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
EMULIB_DIR := $(realpath $(TEST_DIR)/../emulib)
DESIGN_DIR := $(realpath $(TEST_DIR)/../design)

DUMP ?= n

EMU_INCLUDE := $(EMULIB_DIR)/include

BUILD_DIR   := .build
OUTPUT_FILE := $(BUILD_DIR)/output.v
SC_YML_FILE := $(BUILD_DIR)/scanchain.yml
LOADER_FILE := $(BUILD_DIR)/loader.vh
SIM_BIN     := $(BUILD_DIR)/sim
DUMP_FILE   := $(BUILD_DIR)/dump.fst
RESULTS_XML := $(BUILD_DIR)/results.xml

DUMP_V      := $(BUILD_DIR)/_dump.v

SIM_SRCS += $(wildcard $(EMULIB_DIR)/common/*.v)
SIM_SRCS += $(wildcard $(EMULIB_DIR)/fpga/*.v)
SIM_SRCS += $(wildcard $(EMULIB_DIR)/platform/*.v)
SIM_SRCS += $(wildcard $(TEST_DIR)/../platform/sim/common/sources/*.v)

ifeq ($(DUMP),y)
SIM_SRCS += $(DUMP_V)
SIM_TOP += _dump
endif

ifeq ($(EMU_TOP),)
else
SIM_SRCS += $(OUTPUT_FILE)
endif

ifeq ($(COCOTB_MODULE),)
else
VVP_ARGS += -M $(shell cocotb-config --lib-dir) -m $(shell cocotb-config --lib-name vpi icarus)
sim: export MODULE = $(COCOTB_MODULE)
sim: export COCOTB_RESULTS_FILE = $(RESULTS_XML)
sim: export LIBPYTHON_LOC = $(shell cocotb-config --libpython)
endif

IVL_ARGS += -I$(EMU_INCLUDE) -I$(BUILD_DIR)
IVL_ARGS += $(foreach top,$(SIM_TOP),-s $(top))

PLUSARGS += -fst

.DEFAULT_GOAL := sim

$(DUMP_V):
	mkdir -p $(BUILD_DIR)
	echo "module _dump(); initial begin \$$dumpfile(\"$(DUMP_FILE)\"); \$$dumpvars(); end endmodule" > $(DUMP_V)

$(OUTPUT_FILE): $(EMU_SRCS)
	mkdir -p $(BUILD_DIR)
	yosys -m transform -p "emu_transform -top $(EMU_TOP) -yaml $(SC_YML_FILE) -loader $(LOADER_FILE) -raw_plat" -o $@ $^

$(SIM_BIN): $(SIM_SRCS)
	mkdir -p $(BUILD_DIR)
	iverilog $(IVL_ARGS) -o $@ $^

.PHONY: sim
sim: $(SIM_BIN)
	vvp $(VVP_ARGS) $^ $(PLUSARGS)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf __pycache__
