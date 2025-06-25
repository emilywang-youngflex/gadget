
#!/bin/bash
#mount configfs 
mount -t configfs none /sys/kernel/config

#create gadget framework 
cd /sys/kernel/config/usb_gadget/
mkdir -p hid_gadget
cd hid_gadget 

#device properties 
#Vendor ID
echo 0x1d6b > idVendor
#Product ID
echo 0x0104 > idProduct 
#Device Version
echo 0x0100 > bcdDevice 
#USB specification 
echo 0x0200 > bcdUSB

#string descriptors 
mkdir -p strings/0x409  # 0x409 = English (US)
echo "My Company Inc." > strings/0x409/manufacturer
# Product Name
echo "Custom HID Device" > strings/0x409/product
# Serial Number (optional, but useful)
echo "12345678" > strings/0x409/serialnumber

#configuration 
mkdir configs/c.1
echo 250 > configs/c.1/MaxPower # 500mA (250 * 2mA)
# Configuration String
mkdir -p configs/c.1/strings/0x409
echo "HID Configuration" > configs/c.1/strings/0x409/configuration

#create HID function
mkdir -p functions/hid.usb0

#configure HID properties 
#Custom HID
echo 0 > functions/hid.usb0/protocol
#Boot Interface
echo 0 > functions/hid.usb0/subclass # 0 = No Boot Interface
# Report length
echo 65 > functions/hid.usb0/report_length
# Report descriptor
# Add Report ID (0x01) to your descriptor
echo -ne \\x06\\x00\\xff\\x09\\x01\\xa1\\x01\\x85\\x01\\x09\\x01\\x15\\x00\\x26\\xff\\x00\\x75\\x08\\x95\\x40\\x81\\x02\\x09\\x01\\x15\\x00\\x26\\xff\\x00\\x75\\x08\\x95\\x40\\x91\\x02\\xc0 > functions/hid.usb0/report_desc

# Bind function with configuration 
ln -s functions/hid.usb0 configs/c.1/

#bind to UDC 
echo "ffb00000.usb" > UDC









