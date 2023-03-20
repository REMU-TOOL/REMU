VTOP := emu_top
VSRCS += $(wildcard $(DESIGN)/verilog/*.v)
COSIM_VSRCS += $(wildcard $(DESIGN)/cosim/*.v)

ISA := riscv32
CFLAGS += -march=rv32imc
MEM_BASE := 0x00000000
MEM_SIZE := 0x00010000
UART_BASE := 0x10000000
