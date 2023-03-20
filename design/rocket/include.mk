VTOP := emu_top
VSRCS += $(wildcard $(DESIGN)/verilog/*.v)
COSIM_VSRCS += $(wildcard $(DESIGN)/cosim/*.v)

ISA := riscv64
MEM_BASE := 0x80000000
MEM_SIZE := 0x10000000
UART_BASE := 0x60000000
