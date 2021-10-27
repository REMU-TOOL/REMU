include ../common.mk

OUTPUT_DIR := _output
RESULT_FILE := $(OUTPUT_DIR)/result.log

SUITES := halt ff mem cpu system

SUITE ?=
TEST ?=
DUMP ?= n

SIM_FLAGS :=

ifeq ($(DUMP),y)
	SIM_FLAGS += +DUMP
endif

EXTRA_INCLUDE :=

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
run-%: $(OUTPUT_DIR)/%/sim
	@(stdbuf -o0 $(abspath $<) $(SIM_FLAGS) \
	&& echo "\033[32m[PASS]\033[39m $*" >> $(RESULT_FILE) \
	|| echo "\033[31m[FAIL]\033[39m $*" >> $(RESULT_FILE) \
	) 2>&1 | tee $(OUTPUT_DIR)/$*/run.log

.SECONDARY: $(foreach N,$(TEST_USE),$(OUTPUT_DIR)/$(N)/sim)
$(OUTPUT_DIR)/%/sim: $$(VSIM-%) $(OUTPUT_DIR)/%/output.v $(SIMSRCS)
	iverilog -Icommon -I$(OUTPUT_DIR)/$* $(EXTRA_INCLUDE) -DDUMP_FILE=\"$(OUTPUT_DIR)/$*/dump.vcd\" -s sim_top -o $@ $^

.SECONDARY: $(foreach N,$(TEST_USE),$(OUTPUT_DIR)/$(N)/output.v)
$(OUTPUT_DIR)/%/output.v: $$(VSRC-%)
	mkdir -p $(OUTPUT_DIR)/$*
	$(YOSYS) -m transform -p "emu_transform -top $(VTOP-$*) -cfg $(OUTPUT_DIR)/$*/config.json -ldr $(OUTPUT_DIR)/$*/loader.vh" -o $@ $(VSRC-$*)
