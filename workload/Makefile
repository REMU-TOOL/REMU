DESIGN ?=
WORKLOAD ?=

BUILD_DIR := $(shell pwd)/build/$(DESIGN)

include ../design/$(DESIGN)/include.mk

ifeq ($(ISA),riscv32)
CROSS_COMPILE := /opt/riscv32-none/bin/riscv32-unknown-elf-
else
ifeq ($(ISA),riscv64)
CROSS_COMPILE := /opt/riscv64-linux/bin/riscv64-unknown-linux-gnu-
endif
endif

STACK_TOP := $(shell printf "0x%x" $$(($(MEM_BASE)+$(MEM_SIZE))))

export BUILD_DIR
export CROSS_COMPILE
export CFLAGS
export MEM_BASE
export STACK_TOP
export UART_BASE

.PHONY: all
all:
	make -C $(WORKLOAD) all

.PHONY: clean
clean:
	make -C $(WORKLOAD) clean
