# STM32WB55 BLE HCI Transparent Mode natmod for MicroPython
#
# This Makefile builds the native module for STM32WB55 microcontrollers
# that allows it to be used as a USB/UART Bluetooth HCI Dongle.

# Configuration
MPY_DIR = micropython
MOD_DIR = src
FIRMWARE_DIR = firmware
STM32_PORT = $(MPY_DIR)/ports/stm32
VENV_DIR = .venv

# Board definitions
NUCLEO_BOARD = NUCLEO_WB55
DONGLE_BOARD = USBDONGLE_WB55

# Compiler flags
EXTRA_CFLAGS = -Wno-dangling-pointer

# Default target will build the native module
.PHONY: all
all: build

# Build mpy-cross first, required for native module compilation
.PHONY: mpy-cross
mpy-cross:
	CFLAGS="$(EXTRA_CFLAGS)" $(MAKE) -C $(MPY_DIR)/mpy-cross

# Create virtual environment if it doesn't exist
.PHONY: venv
venv:
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "Creating virtual environment in $(VENV_DIR)..."; \
		python3 -m venv $(VENV_DIR); \
		. ./$(VENV_DIR)/bin/activate && pip install -U pip wheel mpremote pyelftools pyusb; \
	else \
		echo "Virtual environment already exists in $(VENV_DIR)"; \
	fi

# Build the module
.PHONY: build
build: venv mpy-cross
	. ./$(VENV_DIR)/bin/activate && CFLAGS="$(EXTRA_CFLAGS)" $(MAKE) -C $(MOD_DIR) MPY_DIR=../$(MPY_DIR)

# Clean the build artifacts
.PHONY: clean
clean:
	$(MAKE) -C $(MOD_DIR) clean MPY_DIR=../$(MPY_DIR)
	$(MAKE) -C $(MPY_DIR)/mpy-cross clean

# Build the firmware for the STM32WB55 Nucleo board
.PHONY: nucleo-firmware
nucleo-firmware: mpy-cross
	@echo "Building MicroPython firmware for STM32WB55 Nucleo board..."
	@mkdir -p $(FIRMWARE_DIR)/$(NUCLEO_BOARD)
	@. ./$(VENV_DIR)/bin/activate && cd $(STM32_PORT) && CFLAGS="$(EXTRA_CFLAGS)" $(MAKE) BOARD=$(NUCLEO_BOARD) submodules all
	@cp $(STM32_PORT)/build-$(NUCLEO_BOARD)/firmware.* $(FIRMWARE_DIR)/$(NUCLEO_BOARD)/
	@echo "Firmware built successfully: $(FIRMWARE_DIR)/$(NUCLEO_BOARD)/"

# Build the firmware for the STM32WB55 USB Dongle
.PHONY: dongle-firmware
dongle-firmware: mpy-cross
	@echo "Building MicroPython firmware for STM32WB55 USB Dongle..."
	@mkdir -p $(FIRMWARE_DIR)/$(DONGLE_BOARD)
	@. ./$(VENV_DIR)/bin/activate && cd $(STM32_PORT) && CFLAGS="$(EXTRA_CFLAGS)" $(MAKE) BOARD=$(DONGLE_BOARD) submodules all
	@cp $(STM32_PORT)/build-$(DONGLE_BOARD)/firmware.* $(FIRMWARE_DIR)/$(DONGLE_BOARD)/
	@echo "Firmware built successfully: $(FIRMWARE_DIR)/$(DONGLE_BOARD)/"

# Flash the Nucleo board with the firmware
.PHONY: flash-nucleo
flash-nucleo: nucleo-firmware
	@echo "Flashing firmware to STM32WB55 Nucleo board..."
	@. ./$(VENV_DIR)/bin/activate && cd $(STM32_PORT) && $(MAKE) BOARD=$(NUCLEO_BOARD) deploy

# Flash the USB Dongle with the firmware
.PHONY: flash-dongle
flash-dongle: dongle-firmware
	@echo "Flashing firmware to STM32WB55 USB Dongle..."
	@. ./$(VENV_DIR)/bin/activate && cd $(STM32_PORT) && $(MAKE) BOARD=$(DONGLE_BOARD) deploy

# Build the Unix port with Bluetooth support
.PHONY: unix-port
unix-port: mpy-cross
	@echo "Building MicroPython Unix port with Bluetooth support..."
	@. ./$(VENV_DIR)/bin/activate && cd $(MPY_DIR) && $(MAKE) -C ports/unix MICROPY_PY_BLUETOOTH=1 MICROPY_BLUETOOTH_NIMBLE=1 submodules all

# Help text
.PHONY: help
help:
	@echo "STM32WB55 BLE HCI Transparent Mode Native Module"
	@echo ""
	@echo "Targets:"
	@echo "  all              - Build the native module (default)"
	@echo "  build            - Same as 'all'"
	@echo "  venv             - Create Python virtual environment if it doesn't exist"
	@echo "  clean            - Clean build artifacts"
	@echo "  deploy           - Build and copy module to the target device"
	@echo "  nucleo-firmware  - Build MicroPython firmware for STM32WB55 Nucleo board"
	@echo "  dongle-firmware  - Build MicroPython firmware for STM32WB55 USB Dongle"
	@echo "  flash-nucleo     - Flash firmware to STM32WB55 Nucleo board"
	@echo "  flash-dongle     - Flash firmware to STM32WB55 USB Dongle"
	@echo "  unix-port        - Build MicroPython Unix port with Bluetooth support"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Optional environment variables:"
	@echo "  DEVICE           - Device identifier for mpremote (for deploy target)"
	@echo "  CFLAGS           - Additional C compiler flags (default: $(EXTRA_CFLAGS))"

# Deploy the module to a connected device
.PHONY: deploy
deploy: build
ifdef DEVICE
	. ./$(VENV_DIR)/bin/activate && mpremote connect $(DEVICE) cp $(MOD_DIR)/build/rfcore_transparent.mpy :
else
	. ./$(VENV_DIR)/bin/activate && mpremote cp $(MOD_DIR)/build/rfcore_transparent.mpy :
endif