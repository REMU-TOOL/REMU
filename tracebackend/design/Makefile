TOP_NAME ?= batch
BUILD_DIR ?= ../obj_dir/$(TOP_NAME)

VTOP = $(BUILD_DIR)/V$(TOP_NAME)
VSRC = $(TOP_NAME).v
VXX_CLFAG += --cc --trace-fst -Mdir $(BUILD_DIR)
VXX_CLFAG += -Wno-style 
VXX_CLFAG += -Wno-lint 
VXX_CLFAG += -Wno-context 
VXX_CLFAG += -Wno-fatal 
VXX_CLFAG += -Wno-UNOPTFLAT

compile:
	mkdir -p $(BUILD_DIR)
	verilator $(VXX_CLFAG) $(VSRC)