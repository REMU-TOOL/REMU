CFLAGS = -MD -O3 -march=rv32imc -ffreestanding -nostdlib
TOOLCHAIN_PREFIX = /opt/riscv32imc/bin/riscv32-unknown-elf-

OBJS = baremetal.o start.o

all: baremetal.hex

%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

%.o: %.S
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

baremetal.elf: $(OBJS) sections.lds
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,sections.lds,-Map,baremetal.map,--strip-debug -o $@ $(OBJS) -lgcc

baremetal.hex: baremetal.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

clean:
	rm -f *.elf *.o *.d *.map
