NAME := $(patsubst %.mk,%,$(notdir $(lastword $(MAKEFILE_LIST))))
ROOT_DIR := ../..

YOSYS ?= $(ROOT_DIR)/yosys/yosys

SIM_FLAGS ?=

BUILD_SRCS :=
SIM_SRCS :=
SIM_INCLUDE_PATH :=

# Test-specific parameters
BUILD_TOP 	:= ff
BUILD_SRCS 	+= ff.v
SIM_TOP 	:= sim_top
SIM_SRCS 	+= fftest.v

BUILD_DIR 	:= $(NAME).build
OUTPUT_FILE := $(BUILD_DIR)/output.v
CONFIG_FILE	:= $(BUILD_DIR)/config.json
LOADER_FILE := $(BUILD_DIR)/loader.vh
SIM_BIN 	:= $(BUILD_DIR)/sim
DUMP_FILE 	:= $(BUILD_DIR)/dump.vcd

SIM_SRCS	+= $(OUTPUT_FILE)
SIM_SRCS 	+= $(wildcard $(ROOT_DIR)/sim/*.v $(ROOT_DIR)/emulib/*.v)

run:
	mkdir -p $(BUILD_DIR)
	$(YOSYS) -m transform -p "emu_transform -top $(BUILD_TOP) -cfg $(CONFIG_FILE) -ldr $(LOADER_FILE)" -o $(OUTPUT_FILE) $(BUILD_SRCS)
	iverilog -I$(BUILD_DIR) -I../common $(EXTRA_IVFLAGS) -DDUMP_FILE=\"$(DUMP_FILE)\" -s $(SIM_TOP) -o $(SIM_BIN) $(SIM_SRCS)
	$(SIM_BIN) $(SIM_FLAGS)

clean:
	rm -rf $(BUILD_DIR)
