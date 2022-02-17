include ../common.mk

CXX := gcc
CXXFLAGS := -Wall -Wextra -ggdb -I"$(YOSYS_DIR)" \
	-MD -MP -D_YOSYS_ -fPIC -std=c++11 -Os \
	-DYOSYS_ENABLE_READLINE \
	-DYOSYS_ENABLE_PLUGINS \
	-DYOSYS_ENABLE_GLOB \
	-DYOSYS_ENABLE_ZLIB \
	-DYOSYS_ENABLE_ABC \
	-DYOSYS_ENABLE_COVER
LD := $(CXX)
LDFLAGS := -rdynamic
LDLIBS := -lstdc++ -lm -lrt -lreadline -lffi -ldl -lz

SRCS := $(wildcard *.cc)
OBJS := $(SRCS:%.cc=%.o)
DEPS := $(SRCS:%.cc=%.d)

transform.so: $(OBJS)
	$(LD) $(LDFLAGS) $(LDLIBS) -shared -o $@ $^

%.o : %.cc
	$(CXX) $(CXXFLAGS) -c -o $@ $<

clean:
	rm -f transform.so
	rm -f *.o
	rm -f *.d

-include $(DEPS)
