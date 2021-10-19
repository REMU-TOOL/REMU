TESTS-cpu := singlecycle

VSRC-cpu-singlecycle := common/singlecycle_top.v common/singlecycle.v
VTOP-cpu-singlecycle := emu_top
VSIM-cpu-singlecycle := cpu/singlecycle_test.v $(VSRC-cpu-singlecycle)
