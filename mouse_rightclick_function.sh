#!/bin/bash
echo -ne "\x02\x00\x00\x00" > /dev/hidg0
sleep 0.1
echo -ne "\x00\x00\x00\x00" > /dev/hidg0

# Scroll up (positive value = up)
echo -ne "\x00\x00\x00\x05" > /dev/hidg0  
# Reset scroll wheel (stops continuous scrolling in some OSes)
echo -ne "\x00\x00\x00\x00" > /dev/hidg0