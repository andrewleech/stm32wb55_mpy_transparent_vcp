"""
STM32WB55 BLE HCI Transparent Mode - Dongle Startup Script
This script automatically starts the HCI transparent mode when the device powers up.
It enables dual CDC interfaces - one for REPL/debug and one for HCI data.
It also provides LED feedback for HCI activity.
"""

import sys
import time
from machine import Pin
import os
import pyb

# Correct import path - add src directory to path if needed
if '/src' not in sys.path:
    sys.path.append('/src')

# Import the rfcore_transparent module
import rfcore_transparent

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

print("Starting BLE HCI transparent mode on second USB CDC interface...")
print("You can continue to use this interface for debug/REPL")

# Start transparent mode with second VCP interface for HCI and activity callback
rfcore_transparent.start(hci_vcp, activity_callback)

# Note: Code execution will not reach this point as transparent mode is blocking