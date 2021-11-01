DESIGN ?=
VTOP ?= emu_top

DESIGN_BUILD_DIR := build/design/$(DESIGN)
VSRC := $(wildcard design/$(DESIGN)/*.v)

.PHONY: design
ifeq ($(DESIGN),)
design:
	$(error No design specified)
else
design:
	mkdir -p $(DESIGN_BUILD_DIR)
	$(YOSYS) -m transform -p "emu_transform -top $(VTOP) -cfg $(DESIGN_BUILD_DIR)/config.json -ldr $(DESIGN_BUILD_DIR)/loader.vh" -o $(DESIGN_BUILD_DIR)/output.v $(VSRC)
	iverilog -I$(DESIGN_BUILD_DIR) -s reconstruct -o $(DESIGN_BUILD_DIR)/reconstruct $(SIMSRCS) $(VSRC)
endif
