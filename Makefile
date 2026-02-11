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
CFLAGS_EXTRA = -DMICROPY_PY_BLUETOOTH_ENABLE_HCI_CMD -DMICROPY_HW_USB_CDC_NUM=2 -Wno-dangling-pointer

# Default target will build the native module
.PHONY: all
all: build-module

# Build mpy-cross first, required for native module compilation
.PHONY: mpy-cross
mpy-cross:
	$(MAKE) -C $(MPY_DIR)/mpy-cross

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

# ===== MODULE TARGETS =====

# Build the native module
.PHONY: build-module
build-module: venv mpy-cross
	. ./$(VENV_DIR)/bin/activate && $(MAKE) -C $(MOD_DIR) MPY_DIR=../$(MPY_DIR)

# Deploy the module to a connected device
.PHONY: deploy-module
deploy-module: build-module
ifdef DEVICE
	. ./$(VENV_DIR)/bin/activate && mpremote connect $(DEVICE) cp $(MOD_DIR)/rfcore_transparent.mpy :
else
	. ./$(VENV_DIR)/bin/activate && mpremote cp $(MOD_DIR)/rfcore_transparent.mpy :
endif

# Deploy module + boot.py + main.py to a connected device
.PHONY: deploy-module-full
deploy-module-full: build-module
ifdef DEVICE
	. ./$(VENV_DIR)/bin/activate && mpremote connect $(DEVICE) resume cp $(MOD_DIR)/rfcore_transparent.mpy :
	. ./$(VENV_DIR)/bin/activate && mpremote connect $(DEVICE) resume cp boot.py :
	. ./$(VENV_DIR)/bin/activate && mpremote connect $(DEVICE) resume cp main.py :
else
	. ./$(VENV_DIR)/bin/activate && mpremote resume cp $(MOD_DIR)/rfcore_transparent.mpy :
	. ./$(VENV_DIR)/bin/activate && mpremote resume cp boot.py :
	. ./$(VENV_DIR)/bin/activate && mpremote resume cp main.py :
endif

# ===== FIRMWARE TARGETS =====

# Build firmware for the STM32WB55 Nucleo board
.PHONY: build-firmware-nucleo
build-firmware-nucleo: mpy-cross
	@echo "Building MicroPython firmware for STM32WB55 Nucleo board..."
	@mkdir -p $(FIRMWARE_DIR)/$(NUCLEO_BOARD)
	@. ./$(VENV_DIR)/bin/activate && cd $(STM32_PORT) && $(MAKE) BOARD=$(NUCLEO_BOARD) CFLAGS_EXTRA="$(CFLAGS_EXTRA)" submodules all
	@cp $(STM32_PORT)/build-$(NUCLEO_BOARD)/firmware.* $(FIRMWARE_DIR)/$(NUCLEO_BOARD)/
	@echo "Firmware built successfully: $(FIRMWARE_DIR)/$(NUCLEO_BOARD)/"

# Build firmware for the STM32WB55 USB Dongle
.PHONY: build-firmware-dongle
build-firmware-dongle: mpy-cross
	@echo "Building MicroPython firmware for STM32WB55 USB Dongle..."
	@mkdir -p $(FIRMWARE_DIR)/$(DONGLE_BOARD)
	@. ./$(VENV_DIR)/bin/activate && cd $(STM32_PORT) && $(MAKE) BOARD=$(DONGLE_BOARD) CFLAGS_EXTRA="$(CFLAGS_EXTRA)" submodules all
	@cp $(STM32_PORT)/build-$(DONGLE_BOARD)/firmware.* $(FIRMWARE_DIR)/$(DONGLE_BOARD)/
	@echo "Firmware built successfully: $(FIRMWARE_DIR)/$(DONGLE_BOARD)/"

# Deploy (flash) firmware to the Nucleo board via DFU
.PHONY: deploy-firmware-nucleo
deploy-firmware-nucleo: build-firmware-nucleo
	@echo "Flashing firmware to STM32WB55 Nucleo board via DFU..."
	@. ./$(VENV_DIR)/bin/activate && cd $(STM32_PORT) && $(MAKE) BOARD=$(NUCLEO_BOARD) CFLAGS_EXTRA="$(CFLAGS_EXTRA)" deploy

# Deploy (flash) firmware to the USB Dongle via DFU
.PHONY: deploy-firmware-dongle
deploy-firmware-dongle: build-firmware-dongle
	@echo "Flashing firmware to STM32WB55 USB Dongle via DFU..."
	@. ./$(VENV_DIR)/bin/activate && cd $(STM32_PORT) && $(MAKE) BOARD=$(DONGLE_BOARD) CFLAGS_EXTRA="$(CFLAGS_EXTRA)" deploy

# Deploy (flash) firmware to the Nucleo board via ST-Link
# Optional: STLINK_SN=<serial> to select a specific programmer
.PHONY: deploy-firmware-nucleo-stlink
deploy-firmware-nucleo-stlink: build-firmware-nucleo
	@echo "Flashing firmware to STM32WB55 Nucleo board via ST-Link..."
ifdef STLINK_SN
	STM32_Programmer_CLI -c port=SWD sn=$(STLINK_SN) -w $(FIRMWARE_DIR)/$(NUCLEO_BOARD)/firmware.hex -v -rst
else
	STM32_Programmer_CLI -c port=SWD -w $(FIRMWARE_DIR)/$(NUCLEO_BOARD)/firmware.hex -v -rst
endif

# Deploy (flash) firmware to the USB Dongle via ST-Link
# Optional: STLINK_SN=<serial> to select a specific programmer
.PHONY: deploy-firmware-dongle-stlink
deploy-firmware-dongle-stlink: build-firmware-dongle
	@echo "Flashing firmware to STM32WB55 USB Dongle via ST-Link..."
ifdef STLINK_SN
	STM32_Programmer_CLI -c port=SWD sn=$(STLINK_SN) -w $(FIRMWARE_DIR)/$(DONGLE_BOARD)/firmware.hex -v -rst
else
	STM32_Programmer_CLI -c port=SWD -w $(FIRMWARE_DIR)/$(DONGLE_BOARD)/firmware.hex -v -rst
endif

# ===== UNIX PORT TARGETS =====

# Build the Unix port with Bluetooth support
.PHONY: build-unix
build-unix: mpy-cross
	@echo "Building MicroPython Unix port..."
	@. ./$(VENV_DIR)/bin/activate && cd $(MPY_DIR) && $(MAKE) -C ports/unix MICROPY_PY_BLUETOOTH=1 MICROPY_BLUETOOTH_NIMBLE=1 submodules
	@. ./$(VENV_DIR)/bin/activate && cd $(MPY_DIR) && $(MAKE) -C ports/unix MICROPY_PY_BLUETOOTH=1 MICROPY_BLUETOOTH_NIMBLE=1 all
	@echo "Unix port built successfully. Binary location: $(MPY_DIR)/ports/unix/build-standard/micropython"

# Run the Unix port with the STM32WB55 as Bluetooth adapter
.PHONY: run-unix
run-unix: build-unix
ifndef MICROPYBTUART
	@echo "ERROR: Please set MICROPYBTUART environment variable to your device port"
	@echo "Example: make run-unix MICROPYBTUART=/dev/ttyACM0"
	@exit 1
else
	@echo "Running MicroPython Unix port with Bluetooth adapter at $(MICROPYBTUART)..."
	MICROPYBTUART=$(MICROPYBTUART) $(MPY_DIR)/ports/unix/build-standard/micropython
endif

# ===== UTILITY TARGETS =====

# Clean all build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	$(MAKE) -C $(MOD_DIR) clean MPY_DIR=../$(MPY_DIR)
	$(MAKE) -C $(MPY_DIR)/mpy-cross clean
	@. ./$(VENV_DIR)/bin/activate && cd $(STM32_PORT) && $(MAKE) BOARD=$(NUCLEO_BOARD) clean
	@. ./$(VENV_DIR)/bin/activate && cd $(STM32_PORT) && $(MAKE) BOARD=$(DONGLE_BOARD) clean
	@. ./$(VENV_DIR)/bin/activate && cd $(MPY_DIR) && $(MAKE) -C ports/unix clean
	@echo "All build artifacts cleaned"

# Help text
.PHONY: help
help:
	@echo "STM32WB55 BLE HCI Transparent Mode Native Module"
	@echo ""
	@echo "MODULE TARGETS:"
	@echo "  build-module         - Build the native module (default)"
	@echo "  deploy-module        - Deploy module to connected device"
	@echo "  deploy-module-full   - Deploy module + boot.py + main.py"
	@echo ""
	@echo "FIRMWARE TARGETS:"
	@echo "  build-firmware-nucleo          - Build firmware for STM32WB55 Nucleo board"
	@echo "  build-firmware-dongle          - Build firmware for STM32WB55 USB Dongle"
	@echo "  deploy-firmware-nucleo         - Flash firmware to Nucleo board via DFU"
	@echo "  deploy-firmware-dongle         - Flash firmware to USB Dongle via DFU"
	@echo "  deploy-firmware-nucleo-stlink  - Flash firmware to Nucleo board via ST-Link"
	@echo "  deploy-firmware-dongle-stlink  - Flash firmware to USB Dongle via ST-Link"
	@echo ""
	@echo "UNIX PORT TARGETS:"
	@echo "  build-unix           - Build MicroPython Unix port with Bluetooth"
	@echo "  run-unix             - Run Unix port with STM32WB55 as BT adapter"
	@echo ""
	@echo "UTILITY TARGETS:"
	@echo "  venv                 - Create Python virtual environment"
	@echo "  clean                - Clean all build artifacts"
	@echo "  help                 - Show this help message"
	@echo ""
	@echo "ENVIRONMENT VARIABLES:"
	@echo "  DEVICE               - Device identifier for mpremote (e.g., auto-com3)"
	@echo "  MICROPYBTUART        - Device port for Unix Bluetooth (e.g., /dev/ttyACM0)"
	@echo "  STLINK_SN            - ST-Link serial number for stlink targets (optional)"
	@echo ""
	@echo "EXAMPLES:"
	@echo "  make build-module"
	@echo "  make deploy-module DEVICE=auto-com3"
	@echo "  make deploy-firmware-nucleo-stlink"
	@echo "  make deploy-firmware-nucleo-stlink STLINK_SN=066AFF505655806687082951"
	@echo "  make run-unix MICROPYBTUART=/dev/ttyACM0"

# ===== LEGACY ALIASES (for backward compatibility) =====
.PHONY: build
build: build-module

.PHONY: deploy
deploy: deploy-module

.PHONY: deploy-all
deploy-all: deploy-module-full

.PHONY: nucleo-firmware
nucleo-firmware: build-firmware-nucleo

.PHONY: dongle-firmware
dongle-firmware: build-firmware-dongle

.PHONY: flash-nucleo
flash-nucleo: deploy-firmware-nucleo-stlink

.PHONY: flash-dongle
flash-dongle: deploy-firmware-dongle-stlink

.PHONY: unix-port
unix-port: build-unix
