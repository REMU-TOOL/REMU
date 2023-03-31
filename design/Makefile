
.DEFAULT_GOAL := all

##### Design Compilation & Emulation #####

YOSYS ?= yosys
IVL ?= iverilog
VVP ?= vvp

DESIGN ?=

BUILD_ROOT := build
BUILD_DIR := $(BUILD_ROOT)/$(DESIGN)

SYSTEM_V     := $(BUILD_DIR)/emu_system.v
ELAB_V       := $(BUILD_DIR)/emu_elab.v
SYSINFO_FILE := $(BUILD_DIR)/sysinfo.json
CKPT_PATH    := $(BUILD_DIR)/ckpt
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

TICK ?= 0
DURATION ?=

REPLAY_PLUSARGS += -fst
REPLAY_PLUSARGS += -sysinfo $(SYSINFO_FILE)
REPLAY_PLUSARGS += -checkpoint $(CKPT_PATH)
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
all: $(SYSTEM_V) $(REPLAY_VVP)
endif

.PHONY: replay
ifeq ($(DESIGN),)
replay:
	$(error No design specified)
else
replay: $(REPLAY_VVP)
	$(VVP) $(VVP_FLAGS) $^ $(REPLAY_PLUSARGS)
endif

.PHONY: waveform
ifeq ($(DESIGN),)
waveform:
	$(error No design specified)
else
waveform:
	gtkwave $(REPLAY_DUMP)
endif

.PHONY: edit
ifeq ($(DESIGN),)
edit:
	$(error No design specified)
else
edit: $(SYSINFO_FILE)
	remu-cpedit $(SYSINFO_FILE) $(CKPT_PATH)
endif

.PHONY: cosim
ifeq ($(DESIGN),)
cosim:
	$(error No design specified)
else
cosim: $(COSIM_VVP)
	$(VVP) $(COSIM_VVP_FLAGS) $^ $(COSIM_PLUSARGS)
endif

.PHONY: waveform_cosim
ifeq ($(DESIGN),)
waveform_cosim:
	$(error No design specified)
else
waveform_cosim:
	gtkwave $(COSIM_DUMP)
endif

.PHONY: clean
ifeq ($(DESIGN),)
clean:
	rm -rf $(BUILD_ROOT)
else
clean:
	rm -rf $(BUILD_DIR)
endif

$(SYSTEM_V): $(VSRCS)
	mkdir -p $(BUILD_DIR)
	$(YOSYS) -m transform -p "read_verilog $^; emu_transform -top $(VTOP) -elab $(ELAB_V) -out $@ -sysinfo $(SYSINFO_FILE) -ckpt $(CKPT_PATH)"

$(ELAB_V): $(SYSTEM_V)
$(SYSINFO_FILE): $(SYSTEM_V)

$(REPLAY_VVP): $(ELAB_V) $(IVL_SRCS)
	mkdir -p $(BUILD_DIR)
	$(IVL) $(IVL_FLAGS) -o $@ $^

$(COSIM_VVP) : $(SYSTEM_V) $(COSIM_VSRCS) $(COSIM_IVL_SRCS)
	mkdir -p $(BUILD_DIR)
	$(IVL) $(COSIM_IVL_FLAGS) -o $@ $^
