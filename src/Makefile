# This module is intended for use on stm32wb55 microcontrollers
# and shows how a native module can be used to extend hardware
# functionality.

# Location of top-level MicroPython directory
MPY_DIR ?= ../micropython

# Name of module
MOD = rfcore_transparent

# Architecture to build for (x86, x64, armv7m, xtensa, xtensawin)
ARCH = armv7m

# Source files (.c or .py)
SRC = \
  stm32wb55_transparent.c \
  stm32wb55_local_commands.c \
  rfcore_transparent.py

MCU_SERIES = wb
CMSIS_MCU = STM32WB55xx

# Ensure compiler warnings don't cause errors
CFLAGS += -Wno-dangling-pointer
CFLAGS += -Os
CFLAGS += -D$(CMSIS_MCU) -DUSE_FULL_LL_DRIVER $(CFLAGS_MCU_$(MCU_SERIES))

# Adjusted include paths for the standalone project
CFLAGS += -I$(MPY_DIR)/ports/stm32
CFLAGS += -I$(MPY_DIR)/ports/stm32/boards/NUCLEO_WB55
CFLAGS += -I$(MPY_DIR)/lib/cmsis/inc
CFLAGS += -I$(MPY_DIR)/lib/stm32lib/STM32WBxx_HAL_Driver/Inc
CFLAGS += -I$(MPY_DIR)/lib/stm32lib/CMSIS/STM32WBxx/Include

# We need to initialize the STM32 submodule to get the required headers
# The following command can be run first if needed:
# cd $(MPY_DIR) && git submodule update --init lib/stm32lib

include $(MPY_DIR)/py/dynruntime.mk

# Add a help target
.PHONY: help
help:
	@echo "STM32WB55 BLE HCI Transparent Mode Native Module"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build the native module (default)"
	@echo "  clean     - Clean build artifacts"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  MPY_DIR   - Path to the MicroPython directory (default: ../../..)"
	@echo "  CFLAGS    - Additional C compiler flags"