# STM32WB55 BLE HCI Transparent Mode

MicroPython firmware for STM32WB55 that makes the board act as a standard BLE HCI dongle. The firmware patches MicroPython to expose the STM32WB55's internal Bluetooth controller via a firmware HCI stream, then an asyncio Python relay bridges that stream to a USB CDC serial interface. The host sees a standard HCI UART transport.

Two boards are supported:
- **NUCLEO_WB55** — ST Nucleo development board (ST-Link + USB)
- **USBDONGLE_WB55** — ST USB dongle form factor (USB only, DFU flash)

## Quick Start

```bash
git clone --recurse-submodules https://github.com/nickovs/stm32wb55_mpy_transparent_vcp.git
cd stm32wb55_mpy_transparent_vcp

# Build and flash the Nucleo board
make deploy-firmware-nucleo
```

After flashing, the board enumerates two USB CDC interfaces: VCP 0 (MicroPython REPL) and VCP 1 (HCI transport). The HCI relay starts automatically via `main.py`.

The firmware sets a USB product string that identifies the board variant. On Linux, both CDC interfaces appear under `/dev/serial/by-id/` with stable names:

- **Nucleo:** `usb-WB55_Nucleo_VCP-BLE_*-if00` (REPL) and `usb-WB55_Nucleo_VCP-BLE_*-if02` (HCI)
- **Dongle:** `usb-WB55_Dongle_VCP-BLE_*-if00` (REPL) and `usb-WB55_Dongle_VCP-BLE_*-if02` (HCI)

The `if02` interface is the HCI transport used by the Unix port and BlueZ.

## Build Targets

| Target | Description |
|--------|-------------|
| `build-module` | Build the native module (default) |
| `deploy-module` | Deploy `.mpy` to a connected device |
| `deploy-module-full` | Deploy `.mpy` + `boot.py` + `main.py` |
| `build-firmware-nucleo` | Build firmware for NUCLEO_WB55 |
| `build-firmware-dongle` | Build firmware for USBDONGLE_WB55 |
| `deploy-firmware-nucleo` | Build + flash Nucleo via DFU |
| `deploy-firmware-dongle` | Build + flash USB Dongle via DFU |
| `deploy-firmware-nucleo-stlink` | Build + flash Nucleo via ST-Link |
| `build-unix` | Build MicroPython Unix port with BLE + aioble |
| `run-unix` | Run Unix port with STM32WB55 as BT adapter |
| `clean` | Clean all build artifacts |

### Environment Variables

| Variable | Description |
|----------|-------------|
| `DEVICE` | Device identifier for mpremote (e.g., `auto-com3`) |
| `MICROPYBTUART` | HCI serial port for Unix port BLE adapter (e.g., `/dev/serial/by-id/usb-WB55_Dongle_VCP-BLE_*-if02`) |

## Usage with MicroPython Unix Port

The STM32WB55 running transparent mode can serve as a BLE HCI adapter for the MicroPython Unix port. Use the `if02` (HCI) interface from `/dev/serial/by-id/`:

```bash
# Dongle
make run-unix MICROPYBTUART=/dev/serial/by-id/usb-WB55_Dongle_VCP-BLE_*-if02

# Nucleo
make run-unix MICROPYBTUART=/dev/serial/by-id/usb-WB55_Nucleo_VCP-BLE_*-if02
```

Then from the MicroPython REPL:

```python
import bluetooth
ble = bluetooth.BLE()
ble.active(True)
```

## Usage with BlueZ (Linux)

Attach the HCI VCP interface to BlueZ:

```bash
sudo btattach -B /dev/serial/by-id/usb-WB55_Dongle_VCP-BLE_*-if02 -S 115200 -P h4
```

The dongle will appear as an HCI device visible to `hciconfig`, `bluetoothctl`, etc.

## Project Structure

```
boot.py                      — Configures dual USB CDC (VCP+VCP)
main.py                      — Auto-starts HCI relay on VCP(1)
src/
  rfcore_transparent.py      — Asyncio HCI relay (host ↔ firmware HCI stream)
  stm32wb55_transparent.c    — C native module: HCI packet state machine
  stm32wb55_local_commands.c — Handles STM32CubeMonitor-RF local commands (type 0x20)
patches/
  rfcore_ble_hci.patch       — Exposes firmware HCI stream to Python
  hci_uart_stream.patch      — HCI UART stream support for stm32 port
  usb_product_string.patch   — Sets board-specific USB product strings
  unix_hci_uart_no_crtscts.patch — Disables CTS/RTS for Unix port HCI UART
micropython/                 — MicroPython submodule (initialised on first build)
.github/workflows/           — CI: firmware builds for both boards + Unix port
```

## CI

GitHub Actions builds firmware for both boards and the Unix port on every push to `main` and on PRs. Tags matching `v*` trigger a release with packaged artifacts.

## License

- Core module code: MIT License
- STM32-specific code in `stm32wb55_local_commands.c`: ST's Ultimate Liberty Software License (see `src/LICENCE_ST.md`)

## Acknowledgments

Derived from the STMicroelectronics BLE_TransparentModeVCP example. Originally adapted by Andrew Leech.
