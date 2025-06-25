#!/bin/bash

# Define variables
GADGET_DIR="/sys/kernel/config/usb_gadget"
GADGET_NAME="g1"                  # Gadget name
UDC_NAME="ff500000.dwc3"          # UDC controller name (check with `ls /sys/class/udc/`)
STORAGE_FILE="/usb_disk.img"      # Virtual disk file path
SIZE_MB=64                        # Disk size (MB)

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then  #id-u prints the user ID  -ne means not equal , root user always have 0 as UID
    echo "Error: Please run this script as root!"
    exit 1
fi #closes an if statement, if spelled backwards 

# 1. Create virtual disk file
echo "[1/5] Creating virtual disk file..."
if [ ! -f "$STORAGE_FILE" ]; then # -f checks if it's a regular file
    dd if=/dev/zero of="$STORAGE_FILE" bs=1M count=$SIZE_MB #The zero bytes from /dev/zero will be written to $STORAGE_FILE.
    mkfs.vfat "$STORAGE_FILE"
    echo "Virtual disk created: $STORAGE_FILE"
else
    echo "Virtual disk already exists, skipping creation."
fi

# 2. Enter Gadget configuration directory
echo "[2/5] Configuring Gadget..."
mkdir -p "$GADGET_DIR/$GADGET_NAME" #make directory and creates parent file directory
cd "$GADGET_DIR/$GADGET_NAME" || { echo "Error: Failed to enter Gadget directory"; exit 1; }

# 3. Set USB descriptors
echo "0x1d6b" > idVendor
echo "0x0104" > idProduct
echo "0x0200" > bcdUSB
echo "0x00" > bDeviceClass
echo "0x00" > bDeviceSubClass
echo "0x00" > bDeviceProtocol

# Set device info (optional)
mkdir -p strings/0x409
echo "12345678" > strings/0x409/serialnumber
echo "LuckFox" > strings/0x409/manufacturer
echo "USB Mass Storage" > strings/0x409/product

# 4. Configure Mass Storage function
echo "[3/5] Configuring Mass Storage function..."
mkdir -p functions/mass_storage.usb0
echo "$STORAGE_FILE" > functions/mass_storage.usb0/lun.0/file
echo 1 > functions/mass_storage.usb0/lun.0/removable

# 5. Bind function to configuration
echo "[4/5] Binding function..."
mkdir -p configs/c.1/strings/0x409
echo "Mass Storage Config" > configs/c.1/strings/0x409/configuration
ln -s ../../functions/mass_storage.usb0 configs/c.1/ || { echo "Error: Binding failed"; exit 1; }

# 6. Enable Gadget
echo "[5/5] Enabling Gadget..."
if [ -e "/sys/class/udc/$UDC_NAME" ]; then
    echo "$UDC_NAME" > UDC
    echo "===== Success! Host should detect the USB disk ====="
    lsusb | grep "1d6b:0104" || echo "Note: If not detected, check host USB drivers."
else
    echo "Error: UDC controller $UDC_NAME does not exist!"
    exit 1
fi
