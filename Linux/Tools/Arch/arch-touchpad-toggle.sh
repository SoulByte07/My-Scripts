#!/usr/bin/env bash
# A simple script to toggle the touchpad on/off by binding/unbinding the HID driver.
# 1. Hardware ID (Find this with: ls /sys/bus/hid/drivers/hid-multitouch)
# It usually looks like 0018:04F3:32B9.0001
DEV_ID="<your device ID here>"
DRV_PATH="/sys/bus/hid/drivers/hid-multitouch"
NOTIF_ICON="$HOME/.config/swaync/images/ja.png"

# 2. The "synclient-style" Toggle Logic
if [ -e "$DRV_PATH/$DEV_ID" ]; then
    # If the file exists, touchpad is ON. Turn it OFF.
    echo "$DEV_ID" | sudo tee "$DRV_PATH/unbind" > /dev/null
    notify-send -u low -i "$NOTIF_ICON" "Touchpad" "Disabled"
else
    # If the file is missing, touchpad is OFF. Turn it ON.
    echo "$DEV_ID" | sudo tee "$DRV_PATH/bind" > /dev/null
    notify-send -u low -i "$NOTIF_ICON" "Touchpad" "Enabled"
fi
