TESTS-cpu := singlecycle

VSRC-cpu-singlecycle := $(ROOT_DIR)/design/example_singlecycle/emu_top.v $(ROOT_DIR)/design/example_singlecycle/mips_cpu.v
VTOP-cpu-singlecycle := emu_top
VSIM-cpu-singlecycle := cpu/singlecycle_test.v $(VSRC-cpu-singlecycle)
