VIVADO_VERSION ?= 2019.1
VIVADO_ROOT ?= /opt/Xilinx_$(VIVADO_VERSION)
VIVADO ?= $(VIVADO_ROOT)/Vivado/$(VIVADO_VERSION)/bin/vivado
VIVADO_FLAGS ?= -nolog -nojournal -notrace -mode batch

PLAT ?=
DESIGN ?=

ifeq ($(PLAT),)
$(error PLAT is not specified)
endif

ifeq ($(DESIGN),)
$(error No design specified)
endif

.PHONY: build
build:
	mkdir -p ../../build/design/$(DESIGN)/vivado_out
	$(VIVADO) $(VIVADO_FLAGS) -source common/scripts/mk.tcl -tclargs "$(PLAT)" "$(DESIGN)"
