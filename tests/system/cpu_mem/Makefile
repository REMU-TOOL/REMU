EMU_TOP := emu_top
SIM_TOP := sim_top

EMU_SRCS += $(wildcard $(DESIGN_DIR)/picorv32/*.v)
SIM_SRCS += $(wildcard $(DESIGN_DIR)/picorv32/*.v)
SIM_SRCS += cpu_mem_test.v

PLAT_MAP := y

COCOTB_MODULE := testbench

include ../../common.mk
