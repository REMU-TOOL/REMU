TRANSFORM_LIB ?= $(shell pwd)/../build/transform.so

OUTPUT_DIR := $(shell pwd)/output

VSRCS := test.v
VTOP := sim_top
OUTPUT_IL := $(OUTPUT_DIR)/output.il
OUTPUT_V := $(OUTPUT_DIR)/output.v

.PHONY: test
test: $(VSRCS)
	mkdir -p $(OUTPUT_DIR)
	yosys -m $(TRANSFORM_LIB) -p "read_verilog $^; insert_accessor; opt; write_rtlil $(OUTPUT_IL); write_verilog $(OUTPUT_V)"

.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)
