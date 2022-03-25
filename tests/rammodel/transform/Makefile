include ../../../common.mk

# Test-specific parameters
BUILD_TOP 	:= emu_top
BUILD_SRCS 	+= emu_top.v

BUILD_DIR 	:= .build
OUTPUT_FILE := $(BUILD_DIR)/output.v
SC_YML_FILE := $(BUILD_DIR)/scanchain.yml
LOADER_FILE := $(BUILD_DIR)/loader.vh

SIM ?= icarus
DUMP ?= n

TOPLEVEL_LANG := verilog

VERILOG_SOURCES += $(OUTPUT_FILE)
VERILOG_SOURCES += $(SIMSRCS)
VERILOG_SOURCES += $(PWD)/test.v

COMPILE_ARGS += -I$(ROOT_DIR)/emulib/include -I$(BUILD_DIR)

TOPLEVEL = test

MODULE = test_model

DUMPFILE := $(MODULE).vcd
COMPILE_ARGS += -DDUMPFILE=\"$(DUMPFILE)\"

ifeq ($(DUMP),y)
PLUSARGS += +DUMP
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

$(OUTPUT_FILE): $(BUILD_SRCS)
	mkdir -p $(BUILD_DIR)
	$(YOSYS) -m transform -p "emu_transform -top $(BUILD_TOP) -sc_yaml $(SC_YML_FILE) -loader $(LOADER_FILE)" -o $@ $^

sim: $(OUTPUT_FILE)

clean::
	rm -f $(DUMPFILE)
	rm -rf $(BUILD_DIR)
