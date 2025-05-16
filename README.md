# STM32WB55 BLE HCI Transparent Mode

This module allows the usage of a STM32WB55 board (e.g., Nucleo or USB dongle) as a USB/UART Bluetooth HCI Dongle.

## Features

- Enables STM32WB55 boards to function as standard Bluetooth HCI adapters
- Supports use with the Unix MicroPython port to provide Bluetooth functionality
- Full compatibility with STM32CubeMonitor-Rf app for debugging
- Support for activity indication via callbacks (e.g., LED blinking)

## Requirements

- STM32WB55 microcontroller board (Nucleo-WB55, USB dongle, etc.)
- MicroPython firmware flashed on the device
- Python 3.x with `mpremote` installed for deployment

## Building

1. Clone this repository with submodules:
   ```
   git clone --recursive https://github.com/yourusername/stm32wb55_ble_hci.git
   cd stm32wb55_ble_hci
   ```

2. Build the native module:
   ```
   make
   ```

3. Deploy to a connected STM32WB55 board:
   ```
   make deploy
   ```
   
   Optionally specify a device:
   ```
   make deploy DEVICE=/dev/ttyACM0
   ```

## Usage

### Basic Usage

```python
import rfcore_transparent
rfcore_transparent.start()
```

By default, stdio (REPL) will be used/taken over by the transparent mode.

### Advanced Usage

This example shows how to use a specific UART for transparent mode and add activity callbacks:

```python
import os
from pyb import Pin, LED

sw = Pin("SW3", Pin.IN, Pin.PULL_UP)

def activity(status):
    if status:
        LED(3).on()
    else:
        LED(3).off()

if sw.value():
    LED(2).on()
    import rfcore_transparent

    # Disconnect USB VCP from repl to use here
    usb = os.dupterm(None, 1)  # startup default is usb (repl) on slot 1

    rfcore_transparent.start(usb, activity)
```

## License

- Core module code: MIT License
- STM32-specific code in `stm32wb55_local_commands.c`: ST's Ultimate Liberty Software License (see `LICENCE_ST.md`)

## Acknowledgments

This module is derived from the STMicroelectronics BLE_TransparentModeVCP example code with modifications to work as a MicroPython native module.