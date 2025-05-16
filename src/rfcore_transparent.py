# This will be built into the native mpy module.
# Functions here will be available in the rfcore_transparent module along with
# the native C functions.
import sys
import time
import micropython
from bluetooth import BLE


def init_bluetooth():
    """Initialize the Bluetooth controller"""
    # Ensure rfcore has been started at least once, then turn off bluetooth.
    BLE().active(1)
    BLE().active(0)


def start(stream=None, callback=None):
    """
    Start the transparent mode HCI bridge in a continuous loop.
    This function will not return until interrupted.
    
    Args:
        stream: The stream to use for I/O. If None, uses stdin/stdout.
        callback: Optional callback function for activity indication.
    """
    import sys
    import micropython
    
    # Initialize Bluetooth controller
    init_bluetooth()

    in_stream = out_stream = stream

    if not in_stream:
        # Disable the ctrl-c interrupt when using repl stream.
        micropython.kbd_intr(-1)

        in_stream = sys.stdin
        out_stream = sys.stdout

    # Start in continuous polling loop
    try:
        while True:
            _rfcore_transparent_start(in_stream, out_stream, callback)
            # Small sleep to prevent tight loop if no data
            time.sleep_ms(1)
    except KeyboardInterrupt:
        # Re-enable keyboard interrupt if using REPL
        if not stream:
            micropython.kbd_intr(3)
        raise


async def start_async(stream=None, callback=None):
    """
    Async version of the transparent mode HCI bridge.
    
    Args:
        stream: The stream to use for I/O. If None, uses stdin/stdout.
        callback: Optional callback function for activity indication.
    
    Example:
        import asyncio
        import rfcore_transparent
        
        async def main():
            await rfcore_transparent.start_async()
            
        asyncio.run(main())
    """
    import asyncio
    
    # Initialize Bluetooth controller
    init_bluetooth()

    in_stream = out_stream = stream

    if not in_stream:
        # Disable the ctrl-c interrupt when using repl stream.
        micropython.kbd_intr(-1)

        in_stream = sys.stdin
        out_stream = sys.stdout

    try:
        while True:
            # Process one step
            _rfcore_transparent_start(in_stream, out_stream, callback)
            # Yield to other tasks
            await asyncio.sleep(0)
    except KeyboardInterrupt:
        # Re-enable keyboard interrupt if using REPL
        if not stream:
            micropython.kbd_intr(3)
        raise


def process_once(stream=None, callback=None):
    """
    Process a single iteration of the transparent mode HCI bridge.
    Returns True if data was processed, False otherwise.
    
    Args:
        stream: The stream to use for I/O. If None, uses stdin/stdout.
        callback: Optional callback function for activity indication.
        
    Returns:
        bool: True if data was processed, False otherwise.
    
    Example:
        import rfcore_transparent
        
        # Initialize HCI bridge
        rfcore_transparent.init_bluetooth()
        
        # Process in custom loop
        while True:
            if rfcore_transparent.process_once():
                print("Data processed")
            # Do other work here
    """
    in_stream = out_stream = stream

    if not in_stream:
        in_stream = sys.stdin
        out_stream = sys.stdout

    return _rfcore_transparent_start(in_stream, out_stream, callback)
