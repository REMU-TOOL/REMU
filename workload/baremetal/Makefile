CROSS_COMPILE ?= riscv64-unknown-elf-
MEM_BASE ?= 0x80000000
STACK_TOP ?= 0x90000000
UART_BASE ?= 0x60000000

CFLAGS += -O3 -ffreestanding -nostdlib -mcmodel=medany
CFLAGS += -DSTACK_TOP=$(STACK_TOP)
CFLAGS += -DUART_BASE=$(UART_BASE)

NAME := baremetal
BUILD_DIR ?= build
BUILD_ELF := $(BUILD_DIR)/$(NAME).elf
BUILD_MAP := $(BUILD_DIR)/$(NAME).map
BUILD_BIN := $(BUILD_DIR)/$(NAME).bin
BUILD_HEX := $(BUILD_DIR)/$(NAME).hex
BUILD_TXT := $(BUILD_DIR)/$(NAME).txt

OBJS += start.o
OBJS += main.o
OBJS += print.o
OBJS += sieve.o
OBJS += echo.o

.PHONY: all
all: $(BUILD_BIN) $(BUILD_HEX) $(BUILD_TXT)

%.o: %.c
	$(CROSS_COMPILE)gcc -c $(CFLAGS) $<

%.o: %.S
	$(CROSS_COMPILE)gcc -c $(CFLAGS) $<

$(BUILD_ELF): $(OBJS) | sections.lds.in
	mkdir -p $(BUILD_DIR)
	sed -e "s#@BASE@#$(MEM_BASE)#" sections.lds.in > $(BUILD_DIR)/sections.lds
	$(CROSS_COMPILE)gcc $(CFLAGS) -Wl,-Bstatic,-T,$(BUILD_DIR)/sections.lds,-Map,$(BUILD_MAP),--strip-debug -o $@ $^ -lgcc

$(BUILD_BIN): $(BUILD_ELF)
	$(CROSS_COMPILE)objcopy -O binary $< $@

$(BUILD_HEX): $(BUILD_ELF)
	$(CROSS_COMPILE)objcopy -O verilog $< $@

$(BUILD_TXT): $(BUILD_ELF)
	$(CROSS_COMPILE)objdump -d $< > $@

.PHONY: clean
clean:
	rm -rf *.o $(BUILD_DIR)
