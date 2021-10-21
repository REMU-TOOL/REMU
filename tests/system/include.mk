TESTS-system := singlecycle

VSRC-system-singlecycle := common/singlecycle_top.v common/singlecycle.v
VTOP-system-singlecycle := emu_top
VSIM-system-singlecycle := system/singlecycle_test.v $(VSRC-system-singlecycle) $(FPGA_SRC)
