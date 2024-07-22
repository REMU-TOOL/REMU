BUILD_DIR ?= build

config: 
	mkdir -p $(BUILD_DIR)
	cmake -S . -B $(BUILD_DIR) -DCMAKE_EXPORT_COMPILE_COMMANDS=1

build: config
	make -C $(BUILD_DIR) all -j

# run test to print TraceBackend.v to stdout
backend: build
	$(BUILD_DIR)/tests/TraceBackendTest  

# run test to print TraceBatch.v to stdout
batch: build
	$(BUILD_DIR)/tests/TraceBatchTest

clean:
	rm -rf ./$(BUILD_DIR)

.PHONY: config build backend batch clean