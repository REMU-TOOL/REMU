
.DEFAULT_GOAL := all

##### Design Compilation & Emulation #####

DESIGN ?=

BUILD_ROOT := build
BUILD_DIR := $(BUILD_ROOT)/$(DESIGN)
VSRC := $(wildcard $(DESIGN)/*.v)
VTOP := emu_top

OUTPUT_V := $(BUILD_DIR)/output.v
SIM_VVP := $(BUILD_DIR)/sim.vvp
SC_YML := $(BUILD_DIR)/scanchain.yml

-include $(DESIGN)/include.mk

.PHONY: all clean
ifeq ($(DESIGN),)
all:
	$(error No design specified)
clean:
	rm -rf $(BUILD_ROOT)
else
all: $(OUTPUT_V) $(SIM_VVP)
clean:
	rm -rf $(BUILD_DIR)
endif

$(OUTPUT_V): $(VSRC)
	mkdir -p $(BUILD_DIR)
	yosys -m transform -p "emu_transform -top $(VTOP) -yaml $(SC_YML)" -o $@ $^

$(SIM_VVP): $(VSRC) $(shell recheck --iv-srcs)
	mkdir -p $(BUILD_DIR)
	iverilog $(shell recheck --iv-flags) -s $(VTOP) -o $@ $^
