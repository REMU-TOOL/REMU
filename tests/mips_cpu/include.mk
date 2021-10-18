TESTS-mips_cpu := singlecycle

VSRC-mips_cpu-singlecycle := singlecycle_top.v singlecycle.v
VTOP-mips_cpu-singlecycle := emu_top
VSIM-mips_cpu-singlecycle := singlecycle_test.v singlecycle_top.v singlecycle.v
