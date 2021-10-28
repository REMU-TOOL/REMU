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

.PHONY: yosys
yosys:
	+make -C yosys all
	make -C yosys PREFIX=$(BUILD_DIR) install

.PHONY: transform
transform:
	+make -C transform

.PHONY: test
test:
	make -C tests

.PHONY: monitor
monitor:
	make -C monitor

.PHONY: run
run: $(VSRC) FORCE
	mkdir -p $(BUILD_DIR)
	$(YOSYS) -m transform -p "emu_transform -top $(VTOP) -cfg $(BUILD_DIR)/config.json -ldr $(BUILD_DIR)/loader.vh" -o $(OUTPUT_V) $(VSRC)

.PHONY: clean test_clean transform_clean build_clean yosys_clean monitor_clean

clean: build_clean yosys_clean transform_clean test_clean monitor_clean

build_clean:
	rm -rf $(BUILD_DIR)

yosys_clean:
	make -C yosys clean

transform_clean:
	make -C transform clean

test_clean:
	make -C tests clean

monitor_clean:
	make -C monitor clean
