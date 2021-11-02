include common.mk

-include .config

.DEFAULT_GOAL := design

##### Configuration #####

PLAT ?=
VENDOR ?=

ifeq ($(PLAT),ultraz)
VENDOR := xilinx
endif

.PHONY: config-clean
config-clean:
	rm -f .config

.PHONY: config-platform
config-platform:
	echo 'VENDOR := $(VENDOR)' >> .config
	echo 'PLAT := $(PLAT)' >> .config

##### Design Compilation #####

DESIGN ?=
VTOP ?= emu_top

DESIGN_BUILD_DIR := build/design/$(DESIGN)
VSRC := $(wildcard design/$(DESIGN)/*.v)

DESIGN_OUTPUT_V := $(DESIGN_BUILD_DIR)/output.v
DESIGN_SIM_BIN := $(DESIGN_BUILD_DIR)/sim

.PHONY: design
ifeq ($(DESIGN),)
design:
	$(error No design specified)
design_clean:
	$(error No design specified)
else
design: $(DESIGN_SIM_BIN) .platform-flow
design_clean:
	rm -rf $(DESIGN_BUILD_DIR)
endif

$(DESIGN_OUTPUT_V): $(VSRC)
	mkdir -p $(DESIGN_BUILD_DIR)
	$(YOSYS) -m transform -p "emu_transform -top $(VTOP) -cfg $(DESIGN_BUILD_DIR)/config.json -ldr $(DESIGN_BUILD_DIR)/loader.vh" -o $@ $^

$(DESIGN_SIM_BIN): $(SIMSRCS) $(VSRC) | $(DESIGN_OUTPUT_V)
	iverilog -I$(DESIGN_BUILD_DIR) -s reconstruct -o $@ $^

.PHONY: .platform-flow
.platform-flow: $(DESIGN_OUTPUT_V)
	make -C platform/$(VENDOR) PLAT=$(PLAT)

##### Framework Compilation #####

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
	make -C monitor VENDOR=$(VENDOR) PLAT=$(PLAT)

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
	make -C monitor clean VENDOR=$(VENDOR) PLAT=$(PLAT)
