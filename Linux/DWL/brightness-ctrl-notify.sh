#!/bin/bash

# Change brightness based on argument (up or down)
case $1 in
    up)
        brightnessctl set +1%
        ;;
    down)
        brightnessctl set 1%-
        ;;
esac

# Get current brightness percentage
# brightnessctl -m provides a comma-separated string. We grab the 5th column and strip the '%' symbol.
BRIGHTNESS=$(brightnessctl -m | awk -F, '{print $4}' | sed 's/%//')

# Show notification using notify-send for mako
# Sample Input: Script executed with 'up' argument, bringing brightness to 60%
# Expected Output: A Mako notification saying "Brightness: 60%" (replacing any previous brightness popups, with a progress bar if configured)
notify-send -a "Brightness" -h string:x-canonical-private-synchronous:brightness -h int:value:"$BRIGHTNESS" "Brightness: ${BRIGHTNESS}%"
