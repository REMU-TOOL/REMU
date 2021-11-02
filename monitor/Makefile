VENDOR ?=
PLAT ?=

ifeq ($(VENDOR),)
$(error VENDOR is not specified)
endif

ifeq ($(PLAT),)
$(error PLAT is not specified)
endif

include ../platform/$(VENDOR)/$(PLAT)/monitor/include.mk

CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)gcc
CFLAGS := -MD -MP -I ../platform/$(VENDOR)/$(PLAT)/monitor
LDFLAGS :=

SRCS := $(wildcard *.c)
OBJS := $(SRCS:%.c=%.o)
DEPS := $(SRCS:%.c=%.d)

monitor: $(OBJS)
	$(LD) $(LDFLAGS) $(LDLIBS) -o $@ $^

%.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f monitor
	rm -f *.o
	rm -f *.d

-include $(DEPS)
