EMU_TOP := emu_top
SIM_TOP := test

EMU_SRCS += $(wildcard $(DESIGN_DIR)/picorv32/*.v)
SIM_SRCS += test.v

COCOTB_MODULE := testbench
TIMEOUT := 5000000

include ../../common.mk
