BUILD_DIR := $(shell pwd)/build
TRANSFORM_LIB := $(BUILD_DIR)/transform.so

CXXSRCS := transform.cc emuutil.cc
CXXDEPS := transform.cc emuutil.cc emuutil.h

.PHONY: build
build: $(TRANSFORM_LIB)

$(TRANSFORM_LIB): $(CXXDEPS)
	mkdir -p $(BUILD_DIR)
	yosys-config --exec --cxx --cxxflags --ldflags -o $(TRANSFORM_LIB) --shared $(CXXSRCS) --ldlibs

.PHONY: test
test: build
	make -C test TRANSFORM_LIB=$(TRANSFORM_LIB) test
