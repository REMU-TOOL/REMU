EMU_TOP := emu_top
SIM_TOP := sim_top

EMU_SRCS += $(DESIGN_DIR)/example_singlecycle/emu_top.v
EMU_SRCS += $(DESIGN_DIR)/example_singlecycle/mips_cpu.v
SIM_SRCS += $(ELAB_FILE)
SIM_SRCS += singlecycle_test.v

IVL_ARGS += -DINITMEM_FILE=\"$(DESIGN_DIR)/example_singlecycle/initmem.txt\"

PLAT_MAP := y

COCOTB_MODULE := testbench

include ../../common.mk
