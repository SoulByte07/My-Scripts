#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For disabling touchpad.
# Edit the Touchpad_Device on ~/.config/hypr/UserConfigs/Laptops.conf according to your system
# use hyprctl devices to get your system touchpad device name
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109


#!/usr/bin/env bash

# Get the device name from your Hyprland config or hardcode it here
# It MUST match the name in 'hyprctl devices'
TOUCHPAD_NAME="elan06fa:00-04f3:32b9-touchpad"
STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"
notif="$HOME/.config/swaync/images/ja.png"

# Create status file if it doesn't exist
if [ ! -f "$STATUS_FILE" ]; then
  echo "true" > "$STATUS_FILE"
fi

CURRENT_STATUS=$(cat "$STATUS_FILE")

if [ "$CURRENT_STATUS" = "true" ]; then
    # Disable it
    hyprctl keyword "device[$TOUCHPAD_NAME]:enabled" false
    echo "false" > "$STATUS_FILE"
    notify-send -u low -i "$notif" "Touchpad" "Disabled"
else
    # Enable it
    hyprctl keyword "device[$TOUCHPAD_NAME]:enabled" true
    echo "true" > "$STATUS_FILE"
    notify-send -u low -i "$notif" "Touchpad" "Enabled"
fi




