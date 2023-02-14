
.DEFAULT_GOAL := all

##### Design Compilation & Emulation #####

DESIGN ?=

BUILD_ROOT := build
BUILD_DIR := $(BUILD_ROOT)/$(DESIGN)

OUTPUT_V     := $(BUILD_DIR)/output.v
ELAB_V       := $(BUILD_DIR)/elab.v
SYSINFO_FILE := $(BUILD_DIR)/sysinfo.json
REPLAY_VVP   := $(BUILD_DIR)/replay.vvp
REPLAY_DUMP  := $(BUILD_DIR)/replay.fst
COSIM_VVP    := $(BUILD_DIR)/cosim.vvp
COSIM_DUMP 	 := $(BUILD_DIR)/cosim.fst

IVL_SRCS        := $(shell remu-config --ivl-srcs)
IVL_FLAGS       := $(shell remu-config --ivl-flags)
VVP_FLAGS       := $(shell remu-config --vvp-flags)
COSIM_IVL_SRCS  := $(shell remu-config --cosim-ivl-srcs)
COSIM_IVL_FLAGS := $(shell remu-config --cosim-ivl-flags)
COSIM_VVP_FLAGS := $(shell remu-config --cosim-vvp-flags)

CKPT ?= /tmp/ckpt
TICK ?= 0
DURATION ?=

REPLAY_PLUSARGS += -fst
REPLAY_PLUSARGS += -sysinfo $(SYSINFO_FILE)
REPLAY_PLUSARGS += -checkpoint $(CKPT)
REPLAY_PLUSARGS += -tick $(TICK)
REPLAY_PLUSARGS += +dumpfile=$(REPLAY_DUMP)
ifneq ($(DURATION),)
REPLAY_PLUSARGS += +duration=$(DURATION)
endif

COSIM_PLUSARGS  += -fst
COSIM_PLUSARGS  += +dumpfile="$(COSIM_DUMP)"

-include $(DESIGN)/include.mk

.PHONY: all
ifeq ($(DESIGN),)
all:
	$(error No design specified)
else
all: $(OUTPUT_V) $(REPLAY_VVP)
endif

.PHONY: replay
ifeq ($(DESIGN),)
replay:
	$(error No design specified)
else
replay: $(REPLAY_VVP)
	vvp $(VVP_FLAGS) $^ $(REPLAY_PLUSARGS)
endif

.PHONY: cosim
ifeq ($(DESIGN),)
cosim:
	$(error No design specified)
else
cosim: $(COSIM_VVP)
	vvp $(COSIM_VVP_FLAGS) $^ $(COSIM_PLUSARGS)
endif

.PHONY: cosim-kill
cosim-kill:
	for id in `ipcs -q | grep "^0x" | cut -d' ' -f 2`; do ipcrm -q ${id}; done

.PHONY: clean
ifeq ($(DESIGN),)
clean:
	rm -rf $(BUILD_ROOT)
else
clean:
	rm -rf $(BUILD_DIR)
endif

$(OUTPUT_V): $(VSRCS)
	mkdir -p $(BUILD_DIR)
	yosys -m transform -p "read_verilog $^; emu_transform -top $(VTOP) -elab $(ELAB_V) -sysinfo $(SYSINFO_FILE); write_verilog $@"

$(ELAB_V): $(OUTPUT_V)

$(REPLAY_VVP): $(ELAB_V) $(IVL_SRCS)
	mkdir -p $(BUILD_DIR)
	iverilog $(IVL_FLAGS) -o $@ $^

$(COSIM_VVP) : $(OUTPUT_V) $(COSIM_VSRCS) $(COSIM_IVL_SRCS)
	mkdir -p $(BUILD_DIR)
	iverilog $(COSIM_IVL_FLAGS) -o $@ $^
