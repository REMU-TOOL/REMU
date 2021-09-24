include ../common.mk

TEST ?= mem
DUMP ?= n

include $(TEST)/include.mk

SIM := $(TEST).out
OUT_V := $(TEST).out.v
SIM_FLAGS :=

ifeq ($(DUMP),y)
	SIM_FLAGS += +DUMP
endif

test: $(SIM)
	$(abspath $(SIM)) $(SIM_FLAGS)

$(SIM): $(foreach n,$(VSIM),$(TEST)/$(n)) $(OUT_V)
	iverilog -o $@ $^

$(OUT_V): $(foreach n,$(VSRC),$(TEST)/$(n))
	yosys -m $(TRANSFORM_LIB) -p "tcl $(TRANSFORM_TCL) -top $(VTOP)" -o $@ $^

clean:
	rm -f *.out
	rm -f *.out.v
	rm -f *.vcd
