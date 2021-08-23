TRANSFORM_LIB ?= $(shell pwd)/../build/transform.so

OUTPUT_DIR := $(shell pwd)/output

VSRCS := test.v
VTOP := mips_cpu
INPUT_IL := $(OUTPUT_DIR)/input.il
OUTPUT_IL := $(OUTPUT_DIR)/output.il
OUTPUT_V := $(OUTPUT_DIR)/output.v

.PHONY: test
test: $(INPUT_IL)
	mkdir -p $(OUTPUT_DIR)
	yosys -m $(TRANSFORM_LIB) -p "read_rtlil $(INPUT_IL); insert_accessor; opt; write_rtlil $(OUTPUT_IL); write_verilog $(OUTPUT_V)"

$(INPUT_IL): $(VSRCS)
	mkdir -p $(OUTPUT_DIR)
	yosys -p "read_verilog $^; prep -top $(VTOP) -flatten; write_rtlil $(INPUT_IL)"

.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)
