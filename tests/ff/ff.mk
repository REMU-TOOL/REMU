NAME := $(patsubst %.mk,%,$(notdir $(lastword $(MAKEFILE_LIST))))

include ../../common.mk

SIM_FLAGS ?=

# Test-specific parameters
BUILD_TOP 	:= ff
BUILD_SRCS 	+= ff.v
SIM_TOP 	:= sim_top
SIM_SRCS 	+= fftest.v

BUILD_DIR 	:= $(NAME).build
OUTPUT_FILE := $(BUILD_DIR)/output.v
SC_YML_FILE := $(BUILD_DIR)/scanchain.yml
LOADER_FILE := $(BUILD_DIR)/loader.vh
SIM_BIN 	:= $(BUILD_DIR)/sim
DUMP_FILE 	:= $(BUILD_DIR)/dump.vcd

SIM_SRCS	+= $(OUTPUT_FILE)
SIM_SRCS 	+= $(SIMSRCS)

EXTRA_IVFLAGS += -DEMULIB_TEST

run:
	mkdir -p $(BUILD_DIR)
	$(YOSYS) -m transform -p "emu_transform -top $(BUILD_TOP) -sc_yaml $(SC_YML_FILE) -loader $(LOADER_FILE)" -o $(OUTPUT_FILE) $(BUILD_SRCS)
	iverilog -I$(BUILD_DIR) -I../common $(EXTRA_IVFLAGS) -DDUMP_FILE=\"$(DUMP_FILE)\" -s $(SIM_TOP) -o $(SIM_BIN) $(SIM_SRCS)
	$(SIM_BIN) $(SIM_FLAGS)

clean:
	rm -rf $(BUILD_DIR)
