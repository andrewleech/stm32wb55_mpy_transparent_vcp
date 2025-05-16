# STM32WB55 BLE HCI Transparent Mode natmod for MicroPython
#
# This Makefile builds the native module for STM32WB55 microcontrollers
# that allows it to be used as a USB/UART Bluetooth HCI Dongle.

# Configuration
MPY_DIR = micropython
MOD_DIR = src
VENV_DIR = venv
STM32_PORT = $(MPY_DIR)/ports/stm32

# Board definitions
NUCLEO_BOARD = NUCLEO_WB55
DONGLE_BOARD = STM32WB5500G

# Compiler flags
EXTRA_CFLAGS = -Wno-dangling-pointer

# Default target will build the native module
.PHONY: all
all: build

# Set up Python virtual environment and install dependencies
.PHONY: venv
venv:
	@echo "Setting up Python virtual environment..."
	@if [ ! -d "$(VENV_DIR)" ]; then \
		python3 -m venv $(VENV_DIR) || python -m venv $(VENV_DIR); \
		. $(VENV_DIR)/bin/activate && pip install --upgrade pip && pip install pyelftools mpremote; \
	fi

# Initialize required MicroPython submodules
.PHONY: submodules
submodules:
	@echo "Ensuring required submodules are initialized..."
	@cd $(MPY_DIR) && git submodule update --init lib/stm32lib
	@cd $(MPY_DIR) && git submodule update --init lib/cmsis

# Build mpy-cross first, required for native module compilation
.PHONY: mpy-cross
mpy-cross: venv submodules
	CFLAGS="$(EXTRA_CFLAGS)" $(MAKE) -C $(MPY_DIR)/mpy-cross

# Build the module
.PHONY: build
build: mpy-cross
	@echo "Building native module..."
	@. $(VENV_DIR)/bin/activate && CFLAGS="$(EXTRA_CFLAGS)" $(MAKE) -C $(MOD_DIR) MPY_DIR=../$(MPY_DIR)

# Clean the build artifacts
.PHONY: clean
clean:
	$(MAKE) -C $(MOD_DIR) clean MPY_DIR=../$(MPY_DIR)
	$(MAKE) -C $(MPY_DIR)/mpy-cross clean
	@echo "To remove the virtual environment, run: rm -rf $(VENV_DIR)"

# Build the firmware for the STM32WB55 Nucleo board
.PHONY: nucleo-firmware
nucleo-firmware: venv submodules mpy-cross
	@echo "Building MicroPython firmware for STM32WB55 Nucleo board..."
	@cd $(STM32_PORT) && CFLAGS="$(EXTRA_CFLAGS)" $(MAKE) BOARD=$(NUCLEO_BOARD)
	@echo "Firmware built successfully: $(STM32_PORT)/build-$(NUCLEO_BOARD)/firmware.hex"

# Build the firmware for the STM32WB55 USB Dongle
.PHONY: dongle-firmware
dongle-firmware: venv submodules mpy-cross
	@echo "Building MicroPython firmware for STM32WB55 USB Dongle..."
	@cd $(STM32_PORT) && CFLAGS="$(EXTRA_CFLAGS)" $(MAKE) BOARD=$(DONGLE_BOARD)
	@echo "Firmware built successfully: $(STM32_PORT)/build-$(DONGLE_BOARD)/firmware.hex"

# Flash the Nucleo board with the firmware
.PHONY: flash-nucleo
flash-nucleo: nucleo-firmware
	@echo "Flashing firmware to STM32WB55 Nucleo board..."
	@cd $(STM32_PORT) && $(MAKE) BOARD=$(NUCLEO_BOARD) deploy

# Flash the USB Dongle with the firmware
.PHONY: flash-dongle
flash-dongle: dongle-firmware
	@echo "Flashing firmware to STM32WB55 USB Dongle..."
	@cd $(STM32_PORT) && $(MAKE) BOARD=$(DONGLE_BOARD) deploy

# Help text
.PHONY: help
help:
	@echo "STM32WB55 BLE HCI Transparent Mode Native Module"
	@echo ""
	@echo "Targets:"
	@echo "  all              - Build the native module (default)"
	@echo "  build            - Same as 'all'"
	@echo "  clean            - Clean build artifacts"
	@echo "  deploy           - Build and copy module to the target device"
	@echo "  venv             - Set up Python virtual environment with dependencies"
	@echo "  submodules       - Initialize required MicroPython submodules"
	@echo "  nucleo-firmware  - Build MicroPython firmware for STM32WB55 Nucleo board"
	@echo "  dongle-firmware  - Build MicroPython firmware for STM32WB55 USB Dongle"
	@echo "  flash-nucleo     - Flash firmware to STM32WB55 Nucleo board"
	@echo "  flash-dongle     - Flash firmware to STM32WB55 USB Dongle"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Optional environment variables:"
	@echo "  DEVICE      - Device identifier for mpremote (for deploy target)"
	@echo "  CFLAGS      - Additional C compiler flags (default: $(EXTRA_CFLAGS))"

# Deploy the module to a connected device
.PHONY: deploy
deploy: build
ifdef DEVICE
	@. $(VENV_DIR)/bin/activate && mpremote connect $(DEVICE) cp $(MOD_DIR)/rfcore_transparent.mpy :
else
	@. $(VENV_DIR)/bin/activate && mpremote cp $(MOD_DIR)/rfcore_transparent.mpy :
endif