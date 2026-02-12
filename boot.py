import pyb

try:
    pyb.usb_mode("VCP+VCP")
except Exception as e:
    print("Dual CDC failed:", e)
