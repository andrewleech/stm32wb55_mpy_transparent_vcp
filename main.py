import asyncio
import pyb
import rfcore_transparent

async def main():
    hci_vcp = pyb.USB_VCP(1)
    hci_vcp.setinterrupt(-1)
    hci_vcp.init(flow=pyb.USB_VCP.RTS)
    while True:
        try:
            print("Starting BLE HCI transparent mode on USB VCP(1)...")
            await rfcore_transparent.start_async(hci_vcp)
        except Exception as e:
            print("HCI relay error:", e)
            await asyncio.sleep_ms(1000)

asyncio.run(main())
