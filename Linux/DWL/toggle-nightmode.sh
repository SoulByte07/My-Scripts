#!/bin/sh
# Script to toggle wlsunset with notifications

# Sample Input: Executing the script via keybind (Super+n)
# Expected Output: Toggles the wlsunset process and triggers a desktop notification

if pgrep -x "wlsunset" > /dev/null
then
    # Kill the process if it is already running
    pkill -x "wlsunset"
    notify-send "Display" "Nightmode Deactivated"
else
    # Start wlsunset with Vijayawada coordinates in the background
    wlsunset -l 16.5 -L 81.5 &
    notify-send "Display" "Nightmode Activated"
fi
