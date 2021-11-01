TESTS-system := singlecycle
EXTRA_INCLUDE += -I$(ROOT_DIR)/rtl/include

VSRC-system-singlecycle := $(ROOT_DIR)/design/example_singlecycle/emu_top.v $(ROOT_DIR)/design/example_singlecycle/mips_cpu.v
VTOP-system-singlecycle := emu_top
VSIM-system-singlecycle := system/singlecycle_test.v $(VSRC-system-singlecycle) $(RTLSRCS)
