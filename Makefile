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

##### Design Compilation & Emulation #####

DESIGN ?=
VTOP ?= emu_top

DESIGN_BUILD_ROOT := design/build
DESIGN_BUILD_DIR := $(DESIGN_BUILD_ROOT)/$(DESIGN)
VSRC := $(wildcard design/$(DESIGN)/*.v)

DESIGN_OUTPUT_V := $(DESIGN_BUILD_DIR)/output.v
DESIGN_SIM_BIN := $(DESIGN_BUILD_DIR)/sim

-include design/$(DESIGN)/include.mk

.PHONY: design design_clean launch
ifeq ($(DESIGN),)
design:
	$(error No design specified)
design_clean:
	rm -rf $(DESIGN_BUILD_ROOT)
else
design: .platform-flow
design_clean:
	rm -rf $(DESIGN_BUILD_DIR)
endif

launch:
	$(if $(DESIGN),,$(error DESIGN is not specified))
	$(if $(HOST),,$(error HOST is not specified))
	$(if $(PORT),,$(error PORT is not specified))
	rm -rf /tmp/ckpt
	python3 -m host $(LOADMEM) $(DESIGN_BUILD_DIR)/config.json $(HOST) $(PORT) /tmp/ckpt

reconstruct: $(DESIGN_SIM_BIN)
	$(if $(DESIGN),,$(error DESIGN is not specified))
	$(if $(HOST),,$(error HOST is not specified))
	$(if $(PORT),,$(error PORT is not specified))
	$(if $(STARTCYCLE),,$(error STARTCYCLE is not specified))
	$(if $(RUNCYCLE),,$(error RUNCYCLE is not specified))
	python3 -m host --dump $(STARTCYCLE) --dumpfile $(DESIGN_BUILD_DIR)/$(STARTCYCLE).hex $(DESIGN_BUILD_DIR)/config.json $(HOST) $(PORT) /tmp/ckpt
	$(DESIGN_SIM_BIN) +startcycle=$(STARTCYCLE) +runcycle=$(RUNCYCLE) +checkpoint=$(DESIGN_BUILD_DIR)/$(STARTCYCLE).hex +dumpfile=$(DESIGN_BUILD_DIR)/dump.vcd

viewvcd:
	$(if $(DESIGN),,$(error DESIGN is not specified))
	gtkwave $(DESIGN_BUILD_DIR)/dump.vcd

$(DESIGN_OUTPUT_V): $(VSRC)
	mkdir -p $(DESIGN_BUILD_DIR)
	$(YOSYS) -m transform -p "emu_transform -top $(VTOP) -cfg $(DESIGN_BUILD_DIR)/config.json -ldr $(DESIGN_BUILD_DIR)/loader.vh" -o $@ $^

$(DESIGN_SIM_BIN): $(SIMSRCS) $(VSRC) | $(DESIGN_OUTPUT_V)
	iverilog -I$(DESIGN_BUILD_DIR) -DRECONSTRUCT -s reconstruct -o $@ $^

.PHONY: .platform-flow
.platform-flow: $(DESIGN_OUTPUT_V)
	make -C platform/$(VENDOR) PLAT=$(PLAT)

##### Framework Compilation #####

.PHONY: build
build: yosys transform
	mkdir -p $(YOSYS_DIR)/share/plugins
	cp -f transform/transform.so $(YOSYS_DIR)/share/plugins
	rm -rf $(YOSYS_DIR)/share/emulib
	cp -rf emulib $(YOSYS_DIR)/share/

.PHONY: yosys
yosys:
	+make -C yosys all

.PHONY: transform
transform: yosys
	+make -C transform

.PHONY: test
test:
	make -C tests

.PHONY: monitor
monitor:
	make -C monitor VENDOR=$(VENDOR) PLAT=$(PLAT)

.PHONY: clean test_clean transform_clean yosys_clean monitor_clean

clean: yosys_clean transform_clean test_clean monitor_clean

yosys_clean:
	make -C yosys clean

transform_clean:
	make -C transform clean

test_clean:
	make -C tests clean

monitor_clean:
	make -C monitor clean VENDOR=$(VENDOR) PLAT=$(PLAT)
