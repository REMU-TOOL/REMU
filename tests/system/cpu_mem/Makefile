EMU_TOP := emu_top
SIM_TOP := sim_top

EMU_SRCS += $(wildcard $(DESIGN_DIR)/picorv32/*.v)
SIM_SRCS += emu_system_wrap.v
SIM_SRCS += $(shell remu-config --cosim-ivl-srcs)

IVL_ARGS += $(shell remu-config --cosim-ivl-flags)
VVP_ARGS += $(shell remu-config --cosim-vvp-flags)

PLAT_MAP := y

include ../../common.mk
