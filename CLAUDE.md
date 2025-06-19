# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project provides a MicroPython native module for STM32WB55 microcontrollers, enabling them to be used as Bluetooth HCI (Host Controller Interface) dongles over USB or UART. The module creates a transparent bridge between the host (via USB/UART) and the internal Bluetooth controller in the STM32WB55 chip.

## Key Components

1. **Native Module** (`rfcore_transparent.mpy`): A MicroPython native module that implements the HCI bridge
2. **Source Files**:
   - `stm32wb55_transparent.c`: Main implementation of the HCI bridge
   - `stm32wb55_local_commands.c`: Commands handled locally by CPU1
   - `rfcore_transparent.py`: Python wrapper for the native module
3. **Startup Files**:
   - `boot.py`: Configures dual USB CDC interfaces (one for REPL, one for HCI)
   - `main.py`: Auto-starts HCI transparent mode with LED feedback

## Build Commands

### Setting up Environment

```bash
# Virtual environment is auto-created by the makefile with required packages
# You can also create it manually:
python -m venv .venv
. ./.venv/bin/activate
pip install -U pip wheel mpremote pyelftools pyusb
```

### Module Commands

```bash
# Build the native module
make build-module

# Deploy module to connected device
make deploy-module

# Deploy module + boot.py + main.py (full deployment)
make deploy-module-full

# Deploy to a specific device
make deploy-module DEVICE=auto-comX  # Replace X with port number
```

### Firmware Commands

```bash
# Build firmware for STM32WB55 Nucleo board
make build-firmware-nucleo

# Build firmware for STM32WB55 USB Dongle
make build-firmware-dongle

# Flash firmware to STM32WB55 Nucleo board
make deploy-firmware-nucleo

# Flash firmware to STM32WB55 USB Dongle
make deploy-firmware-dongle
```

### Unix Port Commands

```bash
# Build MicroPython Unix port with Bluetooth support
make build-unix

# Run Unix port with STM32WB55 as Bluetooth adapter
make run-unix MICROPYBTUART=/dev/ttyACM0
```

### Utility Commands

```bash
# Clean all build artifacts (native module, STM32 ports, Unix port)
make clean

# Show help with all available targets
make help
```

## Architecture

The project implements a Bluetooth HCI transparent bridge using the dual-core architecture of the STM32WB55:

1. **CPU1 (Cortex-M4)**: Runs MicroPython and handles the transparent mode bridge
2. **CPU2 (Cortex-M0+)**: Runs the Bluetooth stack firmware

The transparent mode bridge forwards HCI commands from the host to the STM32WB's internal Bluetooth controller and returns responses back to the host. This allows the STM32WB55 to be used as a standard Bluetooth HCI adapter with tools like BlueZ on Linux.

### Key C Functions
- `rfcore_transparent()`: Main C function that processes HCI packets (in `stm32wb55_transparent.c`)
- `hci_local_cmd()`: Handles HCI commands locally on CPU1 (in `stm32wb55_local_commands.c`)

### Key Python Functions
- `start()`: Python function that runs the transparent mode in a continuous loop
- `start_async()`: Asynchronous version for use with MicroPython's asyncio
- `process_once()`: Process a single HCI packet for custom integration

### Important Compiler Flags
- `-DMICROPY_PY_BLUETOOTH_ENABLE_HCI_CMD`: Enables `bluetooth.BLE.hci_cmd()` for direct HCI command access
- `-DMICROPY_HW_USB_CDC_NUM=2`: Configures dual USB CDC interfaces

## Usage Notes

The module can be used in several ways:

1. **Basic Usage**: Use REPL I/O for HCI communication
   ```python
   import rfcore_transparent
   rfcore_transparent.start()  # Takes over stdio for HCI comms
   ```

2. **Custom UART**: Use a specific UART for HCI communication
   ```python
   import rfcore_transparent
   from machine import UART
   uart = UART(1, 115200)
   rfcore_transparent.start(uart)
   ```

3. **Activity Feedback**: Provide visual feedback for HCI activity
   ```python
   import rfcore_transparent
   from pyb import LED
   
   def activity(status):
       if status:
           LED(3).on()  # Turn on LED when transmitting
       else:
           LED(3).off() # Turn off LED when receiving/idle
           
   rfcore_transparent.start(None, activity)
   ```

4. **Asynchronous Operation**: Use with asyncio for non-blocking operation
   ```python
   import asyncio
   import rfcore_transparent
   
   async def main():
       await rfcore_transparent.start_async()
       
   asyncio.run(main())
   ```

5. **Dual USB CDC Mode**: With `boot.py` configuration for separate REPL and HCI interfaces
   ```python
   # boot.py sets up dual CDC: hci_vcp = pyb.USB_VCP(1)
   import rfcore_transparent
   rfcore_transparent.start(hci_vcp, activity_callback)
   ```

## Testing with MicroPython Unix Port

To use the STM32WB55 as a Bluetooth adapter for testing:

```bash
# Set the environment variable to point to your device
export MICROPYBTUART=/dev/ttyACM0

# Run MicroPython Unix port with Bluetooth support
micropython/ports/unix/build-standard/micropython
```

## Direct HCI Command Access

The firmware enables `bluetooth.BLE.hci_cmd()` for direct HCI command access. See `examples/hci_cmd_example.py` for usage examples:

```python
import bluetooth
ble = bluetooth.BLE()
ble.active(True)

# Send HCI command (ogf, ocf, cmd_buf, resp_buf)
status = ble.hci_cmd(0x04, 0x0001, bytearray(0), bytearray(20))
```

## CI/CD Pipeline

GitHub Actions automatically builds:
- Native module (`rfcore_transparent.mpy`)
- STM32WB55 Nucleo firmware
- STM32WB55 USB Dongle firmware

Builds are available as artifacts for 7 days. Tagged releases include all builds in a single ZIP file.

## Known Issues

### macOS Build Issues (Fixed)
The MicroPython Unix port with Bluetooth (Nimble) had compatibility issues with clang on macOS, but these have been resolved:
- ✅ GCC-specific warning flags (fixed in `micropython/extmod/nimble/nimble.mk`)
- ✅ Macro redefinition conflicts with system headers (fixed in `micropython/extmod/nimble/syscfg/syscfg.h`)
- ✅ Missing baud rate and stdio.h includes (fixed in `micropython/ports/unix/mpbthciport.c`)

The Unix port now builds successfully with Bluetooth support on macOS using clang.