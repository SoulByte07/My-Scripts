#!/bin/bash

# Get a list of available wifi networks
wifi_list=$(nmcli --fields "SECURITY,SSID" device wifi list | sed 1d | sed 's/^--/󰤨  Free/g' | sed 's/^[* ]//g')

# Select network using rofi
chosen_network=$(echo -e "$wifi_list" | uniq -u | rofi -dmenu -i -p "WiFi Networks: -theme ~/.config/rofi/themes/KooL_Catppuccin_mocha.rasi")

# Exit if nothing is selected
[ -z "$chosen_network" ] && exit

# Extract SSID (removing the security icon/text)
ssid=$(echo "$chosen_network" | sed 's/^.* //')

# Attempt to connect
if nmcli connection show "$ssid" > /dev/null 2>&1; then
    nmcli connection up "$ssid"
else
    # Prompt for password if it's a new connection
    pass=$(rofi -dmenu -p "Password for $ssid: " -password)
    nmcli device wifi connect "$ssid" password "$pass"
fi
