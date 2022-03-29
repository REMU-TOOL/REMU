EMU_TOP := emu_top
SIM_TOP := sim_top

EMU_SRCS += $(DESIGN_DIR)/example_singlecycle/emu_top.v
EMU_SRCS += $(DESIGN_DIR)/example_singlecycle/mips_cpu.v
SIM_SRCS += $(DESIGN_DIR)/example_singlecycle/emu_top.v
SIM_SRCS += $(DESIGN_DIR)/example_singlecycle/mips_cpu.v
SIM_SRCS += singlecycle_test.v

IVL_ARGS += -DINITMEM_FILE=\"$(DESIGN_DIR)/example_singlecycle/initmem.txt\"

include ../../common.mk
