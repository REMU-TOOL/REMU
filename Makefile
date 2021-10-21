include common.mk

VSRC ?= tests/common/singlecycle_top.v tests/common/singlecycle.v
VTOP ?= emu_top

OUTPUT_V := $(OUTPUT_DIR)/output.v

.PHONY: FORCE

.PHONY: build
build: $(TRANSFORM_LIB)

$(TRANSFORM_LIB): FORCE
	make -C transform

.PHONY: transform
transform: $(TRANSFORM_LIB) $(VSRC) FORCE
	mkdir -p $(OUTPUT_DIR)
	$(YOSYS) -m $(TRANSFORM_LIB) -p "tcl $(TRANSFORM_TCL) -top $(VTOP) -cfg $(OUTPUT_DIR)/cfg.txt -ldr $(OUTPUT_DIR)/loader.vh" -o $(OUTPUT_V) $(EMULIBS) $(VSRC)

.PHONY: test
test: $(TRANSFORM_LIB) FORCE
	make -C tests

.PHONY: clean clean-test clean-transform
clean: clean-test clean-transform
	rm -rf $(OUTPUT_DIR)

clean-test:
	make -C tests clean

 clean-transform:
	make -C transform clean
