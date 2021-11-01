.PHONY: FORCE

.PHONY: build
build: yosys transform
	mkdir -p $(BUILD_DIR)/share/yosys/plugins
	cp transform/transform.so $(BUILD_DIR)/share/yosys/plugins
	cp -r emulib $(BUILD_DIR)/share/yosys/

.PHONY: yosys
yosys:
	+make -C yosys all
	make -C yosys PREFIX=$(BUILD_DIR) install

.PHONY: transform
transform:
	+make -C transform

.PHONY: test
test:
	make -C tests

.PHONY: monitor
monitor:
	make -C monitor

.PHONY: clean test_clean transform_clean build_clean yosys_clean monitor_clean

clean: build_clean yosys_clean transform_clean test_clean monitor_clean

build_clean:
	rm -rf $(BUILD_DIR)

yosys_clean:
	make -C yosys clean

transform_clean:
	make -C transform clean

test_clean:
	make -C tests clean

monitor_clean:
	make -C monitor clean
