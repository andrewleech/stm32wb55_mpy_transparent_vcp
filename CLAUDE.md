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

## Build Commands

### Setting up Environment

```bash
# Virtual environment is auto-created by the makefile with required packages
# You can also create it manually:
python -m venv .venv
. ./.venv/bin/activate
pip install -U pip wheel mpremote pyelftools pyusb
```

### Building the Module

```bash
# Build the native module
make

# Clean the build artifacts
make clean
```

### Building Firmware

```bash
# Build firmware for STM32WB55 Nucleo board
make nucleo-firmware

# Build firmware for STM32WB55 USB Dongle
make dongle-firmware

# Build MicroPython Unix port
make unix-port
```

### Flashing Firmware

```bash
# Flash firmware to STM32WB55 Nucleo board
make flash-nucleo

# Flash firmware to STM32WB55 USB Dongle
make flash-dongle
```

### Deploying the Module

```bash
# Deploy the module to a connected device (auto-detect)
make deploy

# Deploy to a specific device
make deploy DEVICE=auto-comX  # Replace X with port number
```

## Architecture

The project implements a Bluetooth HCI transparent bridge using a dual-core architecture of the STM32WB55:

1. **CPU1 (Cortex-M4)**: Runs MicroPython and handles the transparent mode bridge
2. **CPU2 (Cortex-M0+)**: Runs the Bluetooth stack firmware

The transparent mode bridge forwards HCI commands from the host to the STM32WB's internal Bluetooth controller and returns responses back to the host. This allows the STM32WB55 to be used as a standard Bluetooth HCI adapter with tools like BlueZ on Linux.

Key functions in the codebase:
- `rfcore_transparent()`: Main C function that processes HCI packets
- `start()`: Python function that runs the transparent mode in a continuous loop
- `start_async()`: Asynchronous version for use with MicroPython's asyncio
- `process_once()`: Process a single HCI packet for custom integration

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