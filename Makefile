BUILD_DIR := $(shell pwd)/build
TRANSFORM_LIB := $(BUILD_DIR)/transform.so

CXXSRCS := transform.cc emuutil.cc
CXXDEPS := transform.cc emuutil.cc emuutil.h

OUTPUT_DIR := $(shell pwd)/output
FPGA_DIR := $(shell pwd)/fpga

VSRC ?= test/test.v
VTOP ?= mips_cpu

INPUT_IL := $(OUTPUT_DIR)/input.il
OUTPUT_IL := $(OUTPUT_DIR)/output.il
OUTPUT_V := $(OUTPUT_DIR)/output.v
VSRC_SIM := $(OUTPUT_V) $(wildcard $(FPGA_DIR)/ip/*.v) $(FPGA_DIR)/emu_top.v test/sim.v
SIM_BIN := $(OUTPUT_DIR)/sim

.PHONY: build
build: $(TRANSFORM_LIB)

$(TRANSFORM_LIB): $(CXXDEPS)
	mkdir -p $(BUILD_DIR)
	yosys-config --exec --cxx --cxxflags --ldflags -o $(TRANSFORM_LIB) --shared $(CXXSRCS) --ldlibs

.PHONY: transform
transform: $(OUTPUT_V)

$(OUTPUT_V): $(INPUT_IL) $(TRANSFORM_LIB)
	yosys -m $(TRANSFORM_LIB) -p "read_rtlil $(INPUT_IL); insert_accessor -cfg output/cfg.txt -ldr output/loader.vh; opt; write_rtlil $(OUTPUT_IL); write_verilog $@"

$(INPUT_IL): $(VSRC)
	mkdir -p $(OUTPUT_DIR)
	yosys -p "read_verilog $^; prep -top $(VTOP) -flatten; write_rtlil $@"

.PHONY: transform_clean
transform_clean:
	rm -rf $(OUTPUT_DIR)

.PHONY: test
test: $(SIM_BIN)
	$(SIM_BIN)

$(SIM_BIN): $(VSRC_SIM)
	iverilog -o $@ -I$(FPGA_DIR) $^

.PHONY: clean
clean: transform_clean
	rm -rf $(BUILD_DIR)
