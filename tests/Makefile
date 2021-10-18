include ../common.mk

OUTPUT_DIR := output
RESULT_FILE := $(OUTPUT_DIR)/result.log

SUITES := halt ff mem

SUITE ?=
TEST ?=
DUMP ?= n

SIM_FLAGS :=

ifeq ($(DUMP),y)
	SIM_FLAGS += +DUMP
endif

# find all requested test suites

ifeq ($(SUITE),)
SUITE_USE := $(SUITES)
else
$(foreach S,$(SUITE),$(if $(filter $(S),$(SUITES)),, \
$(error Suite $(S) not found) \
))
SUITE_USE := $(SUITE)
endif

$(foreach S,$(SUITE_USE),$(eval include $(S)/include.mk))
$(foreach S,$(SUITE_USE),$(foreach T,$(TESTS-$(S)),$(eval VSRC-$$(S)-$$(T)-reloc := $$(foreach F,$$(VSRC-$$(S)-$$(T)),$$(S)/$$(F)))))
$(foreach S,$(SUITE_USE),$(foreach T,$(TESTS-$(S)),$(eval VSIM-$$(S)-$$(T)-reloc := $$(foreach F,$$(VSIM-$$(S)-$$(T)),$$(S)/$$(F)))))

# find all requested tests

ifeq ($(TEST),)
TEST_USE := $(foreach S,$(SUITE_USE),$(foreach T,$(TESTS-$(S)),$(S)-$(T)))
else
$(foreach S,$(SUITE_USE),$(foreach T,$(TEST),$(if $(filter $(T),$(TESTS-$(S))),, \
$(error Test $(T) not found in suite $(S)) \
)))
TEST_USE := $(foreach S,$(SUITE_USE),$(foreach T,$(TEST),$(S)-$(T)))
endif

.PHONY: test
test: clean-result $(foreach N,$(TEST_USE),run-$(N))
	@cat $(RESULT_FILE)
	@test -z "`grep FAIL $(RESULT_FILE)`"

.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)

.PHONY: clean-result
clean-result:
	rm -f $(RESULT_FILE)

.SECONDEXPANSION:

.PHONY: run-%
run-%: $(OUTPUT_DIR)/%.out
	@($(abspath $<) $(SIM_FLAGS) \
	&& echo "\033[32m[PASS]\033[39m $*" >> $(RESULT_FILE) \
	|| echo "\033[31m[FAIL]\033[39m $*" >> $(RESULT_FILE) \
	) 2>&1 | tee $(OUTPUT_DIR)/$*.log

.SECONDARY: $(foreach N,$(TEST_USE),$(OUTPUT_DIR)/$(N).out)
$(OUTPUT_DIR)/%.out: $$(VSIM-%-reloc) $(OUTPUT_DIR)/%.out.v
	iverilog -Icommon -DDUMP_FILE=\"$(OUTPUT_DIR)/$*.vcd\" -o $@ $^

.SECONDARY: $(foreach N,$(TEST_USE),$(OUTPUT_DIR)/$(N).out.v)
$(OUTPUT_DIR)/%.out.v: $(TRANSFORM_LIB) $$(VSRC-%-reloc)
	mkdir -p $(OUTPUT_DIR)
	$(YOSYS) -m $(TRANSFORM_LIB) -p "tcl $(TRANSFORM_TCL) -top $(VTOP-$*) -cfg $(OUTPUT_DIR)/$*.cfg.txt" -o $@ $(EMULIBS) $(VSRC-$*-reloc)
