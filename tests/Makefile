SUITES := pause ff mem cpu system

SUITE ?=
TEST ?=
DUMP ?= n

SIM_FLAGS :=

ifeq ($(DUMP),y)
	SIM_FLAGS += +DUMP
endif

# find all requested test suites

ifeq ($(SUITE),)
SUITE := $(SUITES)
else
$(foreach S,$(SUITE),$(if $(filter $(S),$(SUITES)),, \
$(error Suite $(S) not found) \
))
endif

# find all requested tests

ifeq ($(TEST),)
TEST_MK := $(foreach S,$(SUITE),$(wildcard $(S)/*.mk))
else
$(foreach S,$(SUITE),$(foreach T,$(TEST),$(if $(wildcard $(S)/$(T).mk),, \
$(error Test $(T) not found in suite $(S)) \
)))
TEST_MK := $(foreach S,$(SUITE),$(foreach T,$(TEST),$(S)/$(T).mk))
endif
TEST_LOG := $(patsubst %.mk,%.log,$(TEST_MK))

.PHONY: FORCE

RESULT_FILE := result.log

.PHONY: test
test: clean-result $(TEST_LOG)
	@cat $(RESULT_FILE)
	@test -z "`grep FAIL $(RESULT_FILE)`"

.PHONY: clean
clean: clean-result
	rm -f $(TEST_LOG)
	@$(foreach T,$(TEST_MK),make -C $(dir $(T)) -f $(notdir $(T)) clean; )

.PHONY: clean-result
clean-result:
	rm -f $(RESULT_FILE)

%.log: %.mk FORCE
	@(stdbuf -o0 make -C $(dir $(<)) -f $(notdir $(<)) \
	&& echo "\033[32m[PASS]\033[39m $*" >> $(RESULT_FILE) \
	|| echo "\033[31m[FAIL]\033[39m $*" >> $(RESULT_FILE) \
	) 2>&1 | tee $@
