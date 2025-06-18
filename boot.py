import pyb

# Configure USB for dual CDC interfaces
try:
    pyb.usb_mode("VCP+VCP")  # Configure USB with two VCP interfaces

    # Get USB VCP instance for the second CDC interface
    # First interface (index 0) remains connected to REPL
    # Second interface (index 1) will be used for HCI
    hci_vcp = pyb.USB_VCP(1)
except:
    hci_vcp = pyb.USB_VCP(0)
