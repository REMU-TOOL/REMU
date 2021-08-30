TRANSFORM_LIB ?= $(shell pwd)/../build/transform.so

OUTPUT_DIR := $(shell pwd)/output
FPGA_DIR := $(shell pwd)/../fpga

VSRCS := test.v
VTOP := mips_cpu
INPUT_IL := $(OUTPUT_DIR)/input.il
OUTPUT_IL := $(OUTPUT_DIR)/output.il
OUTPUT_V := $(OUTPUT_DIR)/output.v
VSRCS_SIM := $(OUTPUT_V) $(wildcard $(FPGA_DIR)/ip/*.v) $(FPGA_DIR)/emu_top.v sim.v
OUTPUT_SIM := $(OUTPUT_DIR)/sim

.PHONY: test
test: $(OUTPUT_SIM)
	$(OUTPUT_SIM)

$(OUTPUT_SIM): $(VSRCS_SIM)
	iverilog -o $@ $^

$(OUTPUT_V): $(INPUT_IL) $(TRANSFORM_LIB)
	yosys -m $(TRANSFORM_LIB) -p "read_rtlil $(INPUT_IL); insert_accessor -cfg output/cfg.txt; opt; write_rtlil $(OUTPUT_IL); write_verilog $@"

$(INPUT_IL): $(VSRCS)
	mkdir -p $(OUTPUT_DIR)
	yosys -p "read_verilog $^; prep -top $(VTOP) -flatten; write_rtlil $@"

.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)
