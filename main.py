"""
STM32WB55 BLE HCI Transparent Mode - Dongle Startup Script
This script automatically starts the HCI transparent mode when the device powers up.
It also provides LED feedback for HCI activity.
"""

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

print("Starting BLE HCI transparent mode...")
# Start transparent mode with USB stream and activity callback
rfcore_transparent.start(usb, activity_callback)

# Note: Code execution will not reach this point as transparent mode is blocking