# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MicroPython native module for STM32WB55 that bridges host HCI traffic (over USB/UART) to the chip's internal Bluetooth controller, making the STM32WB55 usable as a standard BLE HCI dongle.

## Build Commands

The root `Makefile` manages all build targets. A Python venv (`.venv/`) is auto-created on first build.

```bash
make build-module             # Build native module (default target)
make deploy-module            # Build + deploy .mpy to device
make deploy-module-full       # Deploy .mpy + boot.py + main.py
make deploy-module DEVICE=auto-comX  # Deploy to specific device

make build-firmware-nucleo    # Build STM32WB55 Nucleo firmware
make build-firmware-dongle    # Build STM32WB55 USB Dongle firmware
make deploy-firmware-nucleo   # Build + flash Nucleo
make deploy-firmware-dongle   # Build + flash Dongle

make build-unix               # Build MicroPython Unix port with BLE (Nimble)
make run-unix MICROPYBTUART=/dev/ttyACM0  # Run Unix port with STM32WB55 as BT adapter

make clean                    # Clean all build artifacts
make help                     # List all targets
```

## Architecture

### Hardware Model

The STM32WB55 is dual-core: CPU1 (Cortex-M4) runs MicroPython, CPU2 (Cortex-M0+) runs the Bluetooth stack firmware. This module bridges HCI packets between a host stream and CPU2's Bluetooth controller.

### Native Module Build Chain

The module is a MicroPython "native module" (`.mpy` file containing ARM machine code + Python bytecode). The build chain:

1. Root `Makefile` builds `mpy-cross`, then invokes `src/Makefile`
2. `src/Makefile` includes MicroPython's `py/dynruntime.mk` which compiles and links the C and Python sources together into a single `rfcore_transparent.mpy`
3. The `.mpy` output contains both the compiled C functions and the Python wrapper bytecode

Source files compiled into the module:
- `src/stm32wb55_transparent.c` — C entry point (`rfcore_transparent()`): HCI packet state machine that reads bytes from a stream, assembles packets, dispatches to either `bluetooth.BLE.hci_cmd()` or local command handler, and writes responses back
- `src/stm32wb55_local_commands.c` — Handles STM32CubeMonitor-RF local commands (type `0x20`) on CPU1 without forwarding to CPU2
- `src/rfcore_transparent.py` — Python API layer providing `start()`, `start_async()`, and `process_once()` wrappers around the C function `_rfcore_transparent_start()`

### HCI Packet Flow

The C function processes one byte at a time via a three-state machine (`STATE_IDLE` → `STATE_NEED_LEN` → `STATE_IN_PAYLOAD`). Packet types handled: BT Command (`0x01`), ACL (`0x02`), Event (`0x04`), Vendor Response/Event (`0x11`/`0x12`), and Local Command (`0x20`).

### Compiler Flags

- `-DMICROPY_PY_BLUETOOTH_ENABLE_HCI_CMD` — enables `bluetooth.BLE.hci_cmd()` for direct HCI command access (used by the C code to forward commands to CPU2)
- `-DMICROPY_HW_USB_CDC_NUM=2` — configures dual USB CDC interfaces (REPL + HCI)

### Device Startup Files

- `boot.py` — configures dual USB CDC interfaces (VCP 0 for REPL, VCP 1 for HCI)
- `main.py` — auto-starts HCI transparent mode with LED activity feedback

## CI/CD

GitHub Actions (`.github/workflows/build.yml`) runs on push to main, PRs, and tags. Three parallel jobs build the native module, Nucleo firmware, and Dongle firmware using the `micropython/build-micropython-arm` container. Artifacts are retained for 7 days. Tags matching `v*` trigger a release job that packages all artifacts into a ZIP attached to a GitHub Release.