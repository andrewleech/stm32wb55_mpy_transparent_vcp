# STM32WB55 BLE HCI Transparent Mode natmod for MicroPython
#
# This Makefile builds the native module for STM32WB55 microcontrollers
# that allows it to be used as a USB/UART Bluetooth HCI Dongle.

# Configuration
MPY_DIR = micropython
MOD_DIR = src

# Default target will build the native module
.PHONY: all
all: build

# Build mpy-cross first, required for native module compilation
.PHONY: mpy-cross
mpy-cross:
	$(MAKE) -C $(MPY_DIR)/mpy-cross

# Build the module
.PHONY: build
build: mpy-cross
	$(MAKE) -C $(MOD_DIR) MPY_DIR=../$(MPY_DIR)

# Clean the build artifacts
.PHONY: clean
clean:
	$(MAKE) -C $(MOD_DIR) clean MPY_DIR=../$(MPY_DIR)
	$(MAKE) -C $(MPY_DIR)/mpy-cross clean

# Help text
.PHONY: help
help:
	@echo "STM32WB55 BLE HCI Transparent Mode Native Module"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build the native module (default)"
	@echo "  build     - Same as 'all'"
	@echo "  clean     - Clean build artifacts"
	@echo "  deploy    - Build and copy module to the target device"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Optional environment variables:"
	@echo "  DEVICE    - Device identifier for mpremote (for deploy target)"

# Deploy the module to a connected device
.PHONY: deploy
deploy: build
ifdef DEVICE
	mpremote connect $(DEVICE) cp $(MOD_DIR)/rfcore_transparent.mpy :
else
	mpremote cp $(MOD_DIR)/rfcore_transparent.mpy :
endif