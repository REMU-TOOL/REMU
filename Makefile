include common.mk

VSRC ?= tests/mips_cpu/singlecycle_top.v tests/mips_cpu/singlecycle.v
VTOP ?= emu_top

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
transform: $(TRANSFORM_LIB) $(VSRC) FORCE
	mkdir -p $(OUTPUT_DIR)
	$(YOSYS) -m $(TRANSFORM_LIB) -p "tcl $(TRANSFORM_TCL) -top $(VTOP) -cfg $(OUTPUT_DIR)/cfg.txt -ldr $(OUTPUT_DIR)/loader.vh" -o $(OUTPUT_V) $(EMULIBS) $(VSRC)

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
