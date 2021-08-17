BUILD_DIR := $(shell pwd)/build
TRANSFORM_LIB := $(BUILD_DIR)/transform.so

CXXSRCS := transform.cc

.PHONY: build
build: $(TRANSFORM_LIB)

$(TRANSFORM_LIB): $(CXXSRCS)
	mkdir -p $(BUILD_DIR)
	yosys-config --exec --cxx --cxxflags --ldflags -o $(TRANSFORM_LIB) --shared $(CXXSRCS) --ldlibs

.PHONY: test
test: build
	make -C test TRANSFORM_LIB=$(TRANSFORM_LIB) test
