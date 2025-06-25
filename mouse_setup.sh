#HID Mouse 
#!bin/bash
#mount configfs 
mount -t configfs none /sys/kernel/config 

#create gadget framework 
cd /sys/kernel/config/usb_gadget/
mkdir g2
cd g2   #also make sure only one gadget is active 

#device properties 
# Vendor ID (Linux Foundation)
echo 0x1d6b > idVendor
# Product ID (Multifunction Composite Gadget)
echo 0x0104 > idProduct
# Device version
echo 0x0100 > bcdDevice
# USB specification 
echo 0x0200 > bcdUSB

#string descriptors   
mkdir strings/0x409
echo "12345678" > strings/0x409/serialnumber
echo "Linux" > strings/0x409/manufacturer
echo "HID Mouse" > strings/0x409/product

#configuration (this step is purely for identification)
mkdir configs/c.1 
mkdir configs/c.1/strings/0x409
echo "Mouse Configuraton" > configs/c.1/strings/0x409/configuration

#create HID function 
mkdir functions/hid.usb0


#configure HID properties 
# Mouse protocol
echo 2 > functions/hid.usb0/protocol
# Boot Interface Subclass
echo 1 > functions/hid.usb0/subclass
# Report length (8 bytes)
echo 8 > functions/hid.usb0/report_length
# Mouse report descriptor
echo -ne \\x05\\x01\\x09\\x02\\xA1\\x01\\x09\\x01\\xA1\\x00\\x05\\x09\\x19\\x01\\x29\\x03\\x15\\x00\\x25\\x01\\x95\\x03\\x75\\x01\\x81\\x02\\x95\\x01\\x75\\x05\\x81\\x01\\x05\\x01\\x09\\x30\\x09\\x31\\x09\\x38\\x15\\x81\\x25\\x7F\\x75\\x08\\x95\\x03\\x81\\x06\\xC0\\xC0 > functions/hid.usb0/report_desc

#bind function to configuration 
ln -s functions/hid.usb0 configs/c.1/

echo $(pwd)
#bind to UDC 
echo "ffb00000.usb" > UDC





