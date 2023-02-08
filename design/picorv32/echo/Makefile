CFLAGS = -MD -O3 -march=rv32imc -ffreestanding -nostdlib
TOOLCHAIN_PREFIX = /opt/riscv32imc/bin/riscv32-unknown-elf-

NAME = echo

OBJS = $(NAME).o start.o

all: $(NAME).bin $(NAME).hex $(NAME).log

%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

%.o: %.S
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

$(NAME).elf: $(OBJS) sections.lds
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,sections.lds,-Map,$(NAME).map,--strip-debug -o $@ $(OBJS) -lgcc

$(NAME).bin: $(NAME).elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@

$(NAME).hex: $(NAME).elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

$(NAME).log: $(NAME).elf
	$(TOOLCHAIN_PREFIX)objdump -d $< > $@

clean:
	rm -f *.elf *.o *.d *.map *.bin *.hex *.log
