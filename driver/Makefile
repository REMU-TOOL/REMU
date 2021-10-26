CROSS_COMPILE ?= aarch64-linux-gnu-
CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)gcc
CFLAGS := -MD -MP
LDFLAGS :=

SRCS := $(wildcard *.c)
OBJS := $(SRCS:%.c=%.o)
DEPS := $(SRCS:%.c=%.d)

DRIVER_OUT := driver.out

$(DRIVER_OUT): $(OBJS)
	$(LD) $(LDFLAGS) $(LDLIBS) -o $@ $^

%.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(DRIVER_OUT)
	rm -f *.o
	rm -f *.d

-include $(DEPS)
