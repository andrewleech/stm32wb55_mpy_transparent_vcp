"""
STM32WB55 BLE HCI Transparent Mode - Direct HCI Command Example
This example demonstrates the use of the bluetooth.BLE.hci_cmd method to send raw HCI commands
directly to the Bluetooth controller.
"""

import bluetooth
import struct
import time

# Create BLE instance
ble = bluetooth.BLE()
ble.active(True)

# Wait a moment for the controller to initialize
time.sleep(1)

def print_hex(data):
    """Pretty print hex data"""
    if not data:
        print("  Empty")
        return
    
    hex_str = " ".join([f"{b:02x}" for b in data])
    print(f"  {hex_str}")

def run_hci_command(name, ogf, ocf, data=b''):
    """Run an HCI command and display the results"""
    print(f"\n=== {name} ===")
    print(f"Command: OGF=0x{ogf:02x}, OCF=0x{ocf:04x}")
    print("Request data:")
    print_hex(data)
    
    # Prepare buffers
    cmd_buf = bytearray(data)
    resp_buf = bytearray(256)  # Buffer for the response
    
    # Send HCI command
    status = ble.hci_cmd(ogf, ocf, cmd_buf, resp_buf)
    
    print(f"Status: {status}")
    print("Response data:")
    
    if status == 0:
        # Find the actual response length (first non-zero byte from the end)
        resp_len = 0
        for i in range(len(resp_buf) - 1, -1, -1):
            if resp_buf[i] != 0:
                resp_len = i + 1
                break
        
        if resp_len > 0:
            print_hex(resp_buf[:resp_len])
        else:
            print("  Empty response")
    
    return status, resp_buf

# Example 1: Read Local Version Information
# OGF=0x04 (Information Parameters), OCF=0x0001 (Read Local Version Information)
status, resp = run_hci_command("Read Local Version Information", 0x04, 0x0001)

if status == 0 and len(resp) >= 9:
    hci_version = resp[0]
    hci_revision = struct.unpack("<H", resp[1:3])[0]
    lmp_version = resp[3]
    manufacturer = struct.unpack("<H", resp[4:6])[0]
    lmp_subversion = struct.unpack("<H", resp[6:8])[0]
    
    print("Parsed Information:")
    print(f"  HCI Version: {hci_version}")
    print(f"  HCI Revision: {hci_revision}")
    print(f"  LMP Version: {lmp_version}")
    print(f"  Manufacturer: {manufacturer}")
    print(f"  LMP Subversion: {lmp_subversion}")

# Example 2: Read BD Address
# OGF=0x04 (Information Parameters), OCF=0x0009 (Read BD Address)
status, resp = run_hci_command("Read BD Address", 0x04, 0x0009)

if status == 0 and len(resp) >= 6:
    # BD Address is stored in little-endian format
    bd_addr = resp[0:6][::-1]  # Reverse to show in standard order
    
    print("Parsed Information:")
    print(f"  BD Address: {':'.join([f'{b:02x}' for b in bd_addr])}")

# Example 3: Read Local Supported Features
# OGF=0x04 (Information Parameters), OCF=0x0003 (Read Local Supported Features)
status, resp = run_hci_command("Read Local Supported Features", 0x04, 0x0003)

if status == 0 and len(resp) >= 8:
    features = struct.unpack("<Q", resp[0:8])[0]
    
    print("Parsed Information:")
    print(f"  Features: 0x{features:016x}")
    
    # Common feature bits
    feature_map = {
        0: "3-slot packets",
        1: "5-slot packets",
        2: "Encryption",
        3: "Slot offset",
        4: "Timing accuracy",
        5: "Role switch",
        6: "Hold mode",
        7: "Sniff mode",
        8: "Previously used",
        9: "Power control requests",
        10: "Channel quality driven data rate (CQDDR)",
        11: "SCO link",
        12: "HV2 packets",
        13: "HV3 packets",
        14: "μ-law log synchronous data",
        15: "A-law log synchronous data",
        16: "CVSD synchronous data",
        17: "Paging parameter negotiation",
        18: "Power control",
        19: "Transparent synchronous data",
        25: "EDR ACL 2 Mbps mode",
        26: "EDR ACL 3 Mbps mode",
        27: "Enhanced inquiry scan",
        28: "Interlaced inquiry scan",
        29: "Interlaced page scan",
        30: "RSSI with inquiry results",
        31: "Extended SCO link (EV3 packets)",
    }
    
    print("  Enabled features:")
    for bit, name in feature_map.items():
        if features & (1 << bit):
            print(f"    - {name}")

print("\nHCI command examples completed.")