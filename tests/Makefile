include ../common.mk

SUITE ?= ff
TEST ?= ff
DUMP ?= n

SIM_FLAGS :=

ifeq ($(DUMP),y)
	SIM_FLAGS += +DUMP
endif

include $(SUITE)/include.mk

OUTPUT_DIR := output

SIM := $(OUTPUT_DIR)/$(SUITE)-$(TEST).out
OUT_V := $(OUTPUT_DIR)/$(SUITE)-$(TEST).out.v
CFG := $(OUTPUT_DIR)/$(SUITE)-$(TEST).cfg.txt
VCD := $(OUTPUT_DIR)/$(SUITE)-$(TEST).vcd

test: $(SIM)
	$(abspath $(SIM)) $(SIM_FLAGS)

$(SIM): $(foreach n,$(VSIM-$(TEST)),$(SUITE)/$(n)) $(OUT_V)
	iverilog -Icommon -DDUMP_FILE=\"$(VCD)\" -o $@ $^

$(OUT_V): $(foreach n,$(VSRC-$(TEST)),$(SUITE)/$(n))
	mkdir -p $(OUTPUT_DIR)
	yosys -m $(TRANSFORM_LIB) -p "tcl $(TRANSFORM_TCL) -top $(VTOP-$(TEST)) -cfg $(CFG)" -o $@ $^

clean:
	rm -rf $(OUTPUT_DIR)
