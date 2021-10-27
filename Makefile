include common.mk

VSRC ?= tests/common/singlecycle_top.v tests/common/singlecycle.v
VTOP ?= emu_top

OUTPUT_V := $(BUILD_DIR)/output.v

.PHONY: FORCE

.PHONY: build
build: yosys transform
	mkdir -p $(BUILD_DIR)/share/yosys/plugins
	cp transform/transform.so $(BUILD_DIR)/share/yosys/plugins
	cp -r emulib $(BUILD_DIR)/share/yosys/

.PHONY: transform
transform:
	+make -C transform

.PHONY: yosys
yosys:
	+make -C yosys all
	make -C yosys PREFIX=$(BUILD_DIR) install

.PHONY: run
run: $(TRANSFORM_LIB) $(VSRC) FORCE
	mkdir -p $(BUILD_DIR)
	$(YOSYS) -m transform -p "emu_transform -top $(VTOP) -cfg $(BUILD_DIR)/config.json -ldr $(BUILD_DIR)/loader.vh" -o $(OUTPUT_V) $(VSRC)

.PHONY: test
test: $(TRANSFORM_LIB) FORCE
	make -C tests

.PHONY: clean clean-test clean-transform clean-build clean-yosys

clean: clean-test clean-transform clean-build clean-yosys

clean-test:
	make -C tests clean

clean-transform:
	make -C transform clean

clean-build:
	rm -rf $(BUILD_DIR)

clean-yosys:
	make -C yosys clean
