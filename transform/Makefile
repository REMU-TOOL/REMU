TRANSFORM_LIB := transform.so

CXX := $(shell yosys-config --cxx)
CXXFLAGS := $(shell yosys-config --cxxflags)
LD := $(shell yosys-config --cxx)
LDFLAGS := $(shell yosys-config --ldflags)
LDLIBS := $(shell yosys-config --ldlibs)

OBJS := transform.o emuutil.o

$(TRANSFORM_LIB): $(OBJS)
	$(LD) $(LDFLAGS) $(LDLIBS) -shared -o $@ $^

%.o : %.cc
	$(CXX) $(CXXFLAGS) -c -o $@ $<

clean:
	rm -f $(TRANSFORM_LIB)
	rm -f *.o
	rm -f *.d

-include $(OBJS:%.o=%.d)
