TRANSFORM_LIB := transform/transform.so

OUTPUT_DIR := $(shell pwd)/output
FPGA_DIR := $(shell pwd)/fpga
SIM_DIR := $(shell pwd)/sim

VSRC ?= test/test.v
VTOP ?= mips_cpu

INPUT_IL := $(OUTPUT_DIR)/input.il
OUTPUT_IL := $(OUTPUT_DIR)/output.il
OUTPUT_V := $(OUTPUT_DIR)/output.v

VSRC_SIM := $(VSRC) $(SIM_DIR)/top.v
SIM_BIN := $(OUTPUT_DIR)/sim

VSRC_TEST := $(OUTPUT_V) $(wildcard $(FPGA_DIR)/ip/*.v) $(FPGA_DIR)/emu_top.v test/sim.v
TEST_BIN := $(OUTPUT_DIR)/test

.PHONY: FORCE

.PHONY: build
build: $(TRANSFORM_LIB)

$(TRANSFORM_LIB): FORCE
	make -C transform

.PHONY: transform
transform: $(OUTPUT_V)

$(OUTPUT_V): $(TRANSFORM_LIB) $(VSRC)
	mkdir -p $(OUTPUT_DIR)
	yosys -m $(TRANSFORM_LIB) -p "tcl scripts/transform.tcl -top $(VTOP) -cfg $(OUTPUT_DIR)/cfg.txt -ldr $(OUTPUT_DIR)/loader.vh" -o $@ $(VSRC)

.PHONY: sim
sim: $(SIM_BIN)
	STARTCYCLE=$$(((`cat checkpoint/cyclehi.txt`<<32)|`cat checkpoint/cyclelo.txt`)); \
	$(SIM_BIN) +startcycle=$$STARTCYCLE +runcycle=1000

$(SIM_BIN): $(VSRC_SIM)
	iverilog -o $@ -I$(OUTPUT_DIR) $^

.PHONY: test
test: $(TEST_BIN)
	$(TEST_BIN)

$(TEST_BIN): $(VSRC_TEST)
	iverilog -o $@ -I$(FPGA_DIR) $^

.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)
	make -C transform clean
