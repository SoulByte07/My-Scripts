#!/bin/bash

# variables
BLURRED_WALLPAPER="$HOME/Pictures/wallpapers/Github/1351260.png"
BASE_COLOR="1e1e2e"
# Define the options using UTF-8 hex escape sequences
OPTIONS="\U000f0425 Shutdown\n\U000f0709 Reboot\n\U000f05fc Exit\n\U000f0904 Suspend\n"

# launch tofi and capture the user's choice
CHOICE=$(echo -e "$OPTIONS" | tofi \
    --prompt-text "Power Menu: " \
    --num-results 4 \
    --ascii-input=false \
    --font="FiraCode Nerd Font" \
    --fuzzy-match=false
  )


# logic
case "$CHOICE" in
    *Shutdown)
        systemctl poweroff
        ;;
    *Reboot)
        systemctl reboot
        ;;
    *Exit)
        # Using killall for dwl as per your previous setup
        killall dwl
        ;;
    *Suspend)
        # wallpaper blur for lock screen
        if [ -f "$BLURRED_WALLPAPER" ]; then
            LOCK_BG="--image $BLURRED_WALLPAPER"
        else
            LOCK_BG="--color $BASE_COLOR"
        fi

        # Start Lock (Catppuccin styling) in the background
        swaylock \
          $LOCK_BG \
          --clock \
          --indicator \
          --indicator-radius 120 \
          --indicator-thickness 7 \
          --ring-color b4befe \
          --key-hl-color a6e3a1 \
          --bs-hl-color f38ba8 \
          --text-color cdd6f4 \
          --line-color 00000000 \
          --inside-color 1e1e2e88 \
          --separator-color 00000000 \
          --fade-in 0.2 &
        
        # Give swaylock a second to render so it's locked before sleep
        sleep 1 
        
        systemctl suspend
        
 
        ;;
   *)
        exit 1
        ;;
esac
