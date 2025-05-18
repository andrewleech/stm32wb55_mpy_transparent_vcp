# STM32WB55 BLE HCI Transparent Mode

This project provides a MicroPython native module for STM32WB55 microcontrollers, enabling them to be used as Bluetooth HCI dongles over USB or UART. The module works by creating a transparent bridge between the host (via USB/UART) and the internal Bluetooth controller in the STM32WB55.

## Features

- Creates a transparent HCI bridge for Bluetooth communication
- Compatible with standard Bluetooth HCI tools and stacks
- Supports STM32CubeMonitor-RF for advanced RF debugging
- Configurable to use either REPL (stdio) or a specific stream
- Optional activity callback for LED blinking or other feedback

## Build Requirements

- Python 3.6 or newer with virtualenv support
- ARM GCC toolchain for cross-compilation
- Git for managing submodules

## Building the Module

To build the native module, follow these steps:

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/stm32wb55_ble_hci.git
   cd stm32wb55_ble_hci
   ```

2. Build the module:
   ```bash
   make
   ```

   This will:
   - Build the mpy-cross compiler
   - Compile the native module

3. Deploy to your STM32WB55 device:
   ```bash
   # If your device appears with a specific port/identifier
   make deploy DEVICE=auto-comX
   
   # Or with default device
   make deploy
   ```

## Building and Flashing MicroPython Firmware

This project includes convenience targets for building and flashing MicroPython firmware to STM32WB55 boards.

### For the STM32WB55 Nucleo Board

1. Build the firmware:
   ```bash
   make nucleo-firmware
   ```

2. Flash the firmware to the board:
   ```bash
   make flash-nucleo
   ```

### For the STM32WB55 USB Dongle

1. Build the firmware:
   ```bash
   make dongle-firmware
   ```

2. Flash the firmware to the board:
   ```bash
   make flash-dongle
   ```

The firmware will include the necessary hardware drivers for the STM32WB55, but you'll still need to deploy the transparent mode module separately using `make deploy` after flashing the firmware.

## Usage

### Basic Usage

```python
import rfcore_transparent

# Use the default REPL I/O (this will take over stdio)
rfcore_transparent.start()
```

### Advanced Usage with UART and LED Feedback

```python
import os
from pyb import Pin, LED

sw = Pin("SW3", Pin.IN, Pin.PULL_UP)

def activity(status):
    if status:
        LED(3).on()  # Turn on LED when transmitting
    else:
        LED(3).off() # Turn off LED when receiving/idle

if sw.value():
    LED(2).on()
    import rfcore_transparent

    # Disconnect USB VCP from repl to use here
    usb = os.dupterm(None, 1)  # startup default is usb (repl) on slot 1

    # Start transparent mode with USB stream and activity callback
    rfcore_transparent.start(usb, activity)
```

### Using with a Custom UART

```python
import rfcore_transparent
from machine import UART

# Configure a UART for HCI communication
uart = UART(1, 115200)

# Start the transparent mode with the UART
rfcore_transparent.start(uart)
```

## Example Integration with BlueZ (Linux)

1. Install BlueZ utilities:
   ```bash
   sudo apt install bluez
   ```

2. Identify your STM32WB55 device:
   ```bash
   ls -l /dev/ttyACM*
   ```

3. Configure BlueZ to use your device:
   ```bash
   sudo btattach -B /dev/ttyACM0 -S 115200 -P h4
   ```

4. Scan for devices:
   ```bash
   sudo hcitool lescan
   ```

## Using with MicroPython Unix Port

You can use the STM32WB55 as a Bluetooth adapter for the MicroPython Unix port:

1. Flash the dongle with MicroPython firmware:
   ```bash
   make flash-dongle
   ```

2. Deploy both the native module and the example `main.py` to the dongle:
   ```bash
   # If your device appears with a specific port/identifier
   make deploy-all DEVICE=auto-comX
   
   # Or with default device
   make deploy-all
   ```

   You can also deploy them separately:
   ```bash
   # Just the module
   make deploy
   
   # Just main.py
   mpremote cp main.py :
   ```
   
   The included `main.py` provides LED feedback using the blue LED and looks like this:
   ```python
   import rfcore_transparent
   import time
   from machine import Pin
   import os

   # Wait a moment for USB to initialize
   time.sleep(1)

   # Set up the blue LED for activity indication
   led_blue = Pin.board.LED_BLUE
   led_blue.init(Pin.OUT)

   def activity_callback(state):
       """Turn LED on when receiving data, off when transmitting response"""
       if state:
           led_blue.on()
       else:
           led_blue.off()

   # Disconnect USB VCP from REPL to use for HCI
   usb = os.dupterm(None, 1)  # startup default is USB (REPL) on slot 1

   # Start transparent mode with USB stream and activity callback
   rfcore_transparent.start(usb, activity_callback)
   ```

4. Build the MicroPython Unix port with Bluetooth support:
   ```bash
   make unix-port
   ```

5. Run the Unix port with the dongle as the Bluetooth HCI device:
   ```bash
   MICROPYBTUSB=/dev/ttyACM0 micropython/ports/unix/build-standard/micropython
   ```

6. Now you can use Bluetooth from the Unix port:
   ```python
   import bluetooth
   ble = bluetooth.BLE()
   print("BLE state:", ble.active())
   ble.active(True)
   print("BLE state after activation:", ble.active())
   ```

## Project Structure

- `src/` - Source code for the native module
  - `stm32wb55_transparent.c` - Main implementation of the HCI bridge
  - `stm32wb55_local_commands.c` - Commands handled locally by CPU1
  - `rfcore_transparent.py` - Python wrapper for the native module
- `micropython/` - MicroPython submodule (required for building)
- `.github/workflows/` - GitHub Actions for CI/CD

## Continuous Integration

This project uses GitHub Actions to automatically build:

1. The native module (`rfcore_transparent.mpy`)
2. MicroPython firmware for the STM32WB55 Nucleo board
3. MicroPython firmware for the STM32WB55 USB Dongle

Each build is available as an artifact for 7 days. When creating a release (by tagging the repository), all builds are automatically packaged into a single ZIP file that's attached to the GitHub Release.

## License

- Core module code: MIT License
- STM32-specific code in `stm32wb55_local_commands.c`: ST's Ultimate Liberty Software License (see `LICENCE_ST.md`)

## Acknowledgments

This module is derived from the STMicroelectronics BLE_TransparentModeVCP example code with modifications to work as a MicroPython native module. Originally adapted by Andrew Leech, with further improvements and standalone project structure.