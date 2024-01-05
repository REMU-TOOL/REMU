TEST_DIR   := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
EMULIB_DIR := $(realpath $(TEST_DIR)/../emulib)
DESIGN_DIR := $(realpath $(TEST_DIR)/../design)


DUMP ?= n
YOSYS ?= yosys

EMU_INCLUDE := $(EMULIB_DIR)/include
EMU_MODEL   := $(EMULIB_DIR)/model
EMU_FPGA    := $(EMULIB_DIR)/fpga

BUILD_DIR   := .build
OUTPUT_FILE := $(BUILD_DIR)/output.v
ELAB_FILE   := $(BUILD_DIR)/elab.v
SYSINFO_FILE := $(BUILD_DIR)/sysinfo.json
LOADER_FILE := $(BUILD_DIR)/loader.vh
SIM_BIN     := $(BUILD_DIR)/sim
DUMP_FILE   := $(BUILD_DIR)/dump.fst
RESULTS_XML := $(BUILD_DIR)/results.xml

SIMCTRL_V   := $(BUILD_DIR)/simctrl.v

SIM_SRCS += $(wildcard $(EMULIB_DIR)/common/*.v)
SIM_SRCS += $(shell find $(EMULIB_DIR)/model -type f -name "*.v")
SIM_SRCS += $(wildcard $(EMULIB_DIR)/fpga/*.v)
SIM_SRCS += $(wildcard $(EMULIB_DIR)/system/*.v)
SIM_SRCS += $(wildcard $(EMULIB_DIR)/platform/sim/*.v)
SIM_SRCS += $(SIMCTRL_V)
SIM_TOP += _simctrl

TRANSFORM_ARGS += -top $(EMU_TOP)
TRANSFORM_ARGS += -sysinfo $(SYSINFO_FILE)
TRANSFORM_ARGS += -loader $(LOADER_FILE)
TRANSFORM_ARGS += -elab $(ELAB_FILE)
ifneq ($(PLAT_MAP),y)
TRANSFORM_ARGS += -nosystem
endif

ifeq ($(TIMEOUT),)
TIMEOUT = 10000000
endif

ifneq ($(EMU_TOP),)
SIM_SRCS += $(OUTPUT_FILE)
endif

ifneq ($(COCOTB_MODULE),)
VVP_ARGS += -M $(shell cocotb-config --lib-dir) -m $(shell cocotb-config --lib-name vpi icarus)
sim: export MODULE = $(COCOTB_MODULE)
sim: export COCOTB_RESULTS_FILE = $(RESULTS_XML)
sim: export LIBPYTHON_LOC = $(shell cocotb-config --libpython)
endif

IVL_ARGS += -I$(EMU_INCLUDE) -I$(BUILD_DIR)
IVL_ARGS += $(foreach top,$(SIM_TOP),-s $(top))

PLUSARGS += -fst

ifeq ($(DUMP),y)
PLUSARGS += +dump
endif

.DEFAULT_GOAL := sim

$(SIMCTRL_V):
	@mkdir -p $(BUILD_DIR)
	@echo "\`timescale 1ns/1ps" > $@
	@echo "module _simctrl;" >> $@
	@echo "initial begin" >> $@
	@echo "if (\$$test\$$plusargs(\"dump\")) begin" >> $@
	@echo "\$$dumpfile(\"$(DUMP_FILE)\");" >> $@
	@echo "\$$dumpvars;" >> $@
	@echo "end" >> $@
	@echo "#$(TIMEOUT) \$$display(\"timeout\");" >> $@
	@echo "\$$fatal;" >> $@
	@echo "end" >> $@
	@echo "endmodule" >> $@

$(OUTPUT_FILE): $(EMU_SRCS)
	@mkdir -p $(BUILD_DIR)
	$(YOSYS) -m transform -p "read_verilog $^; emu_transform $(TRANSFORM_ARGS); write_verilog $@"

$(ELAB_FILE): $(OUTPUT_FILE)

$(SIM_BIN): $(SIM_SRCS)
	@mkdir -p $(BUILD_DIR)
	iverilog $(IVL_ARGS) -o $@ $^

.PHONY: sim
sim: $(SIM_BIN)
	vvp $(VVP_ARGS) $^ $(PLUSARGS)
ifneq ($(COCOTB_MODULE),)
	@$(TEST_DIR)/check_cocotb_result.py $(RESULTS_XML)
endif

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf __pycache__
