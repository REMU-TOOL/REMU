EMU_TOP := emu_top
SIM_TOP := test

EMU_SRCS += emu_top.v
SIM_SRCS += test.v
SIM_SRCS += $(find $(EMULIB_DIR)/model/rammodel -type f -name "*.v")

COCOTB_MODULE := testbench

include ../../common.mk
