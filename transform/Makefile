include ../common.mk

CXX := $(shell yosys-config --cxx)
CXXFLAGS := $(shell yosys-config --cxxflags)
LD := $(shell yosys-config --cxx)
LDFLAGS := $(shell yosys-config --ldflags)
LDLIBS := $(shell yosys-config --ldlibs)

# workaround to include some header files not installed in /usr/local
CXXFLAGS += -I"$(YOSYS_DIR)"

SRCS := $(wildcard *.cc)
OBJS := $(SRCS:%.cc=%.o)
DEPS := $(SRCS:%.cc=%.d)

$(TRANSFORM_LIB): $(OBJS)
	$(LD) $(LDFLAGS) $(LDLIBS) -shared -o $@ $^

%.o : %.cc
	$(CXX) $(CXXFLAGS) -c -o $@ $<

clean:
	rm -f $(TRANSFORM_LIB)
	rm -f *.o
	rm -f *.d

-include $(DEPS)
