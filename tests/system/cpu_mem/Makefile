EMU_TOP := emu_top
SIM_TOP := sim_top

EMU_SRCS += $(DESIGN_DIR)/picorv32/emu_top.v
EMU_SRCS += $(DESIGN_DIR)/picorv32/picorv32.v
SIM_SRCS += $(DESIGN_DIR)/picorv32/emu_top.v
SIM_SRCS += $(DESIGN_DIR)/picorv32/picorv32.v
SIM_SRCS += cpu_mem_test.v

PLAT_MAP := y

COCOTB_MODULE := testbench

include ../../common.mk
