#!/bin/bash

# Options for the main menu
options="󰂯 Power On\n󰂲 Power Off\n󰂱 Connect Device"

chosen=$(echo -e "$options" | rofi -dmenu -i -p "Bluetooth: ")

case "$chosen" in
    "󰂯 Power On") bluetoothctl power on ;;
    "󰂲 Power Off") bluetoothctl power off ;;
    "󰂱 Connect Device")
        # List paired devices and connect to selection
        device=$(bluetoothctl devices Paired | rofi -dmenu -i -p "Select Device: ")
        mac=$(echo "$device" | awk '{print $2}')
        bluetoothctl connect "$mac"
        ;;
esac
