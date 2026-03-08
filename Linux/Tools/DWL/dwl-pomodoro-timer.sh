#!/bin/bash
# Minimal Suspend Pomodoro - DWL Compatible

WORK_MINS=${1:-25}
BLURRED_WALLPAPER="$HOME/Pictures/wallpapers/Github/1351260.png"
BASE_COLOR="1e1e2e"

while true; do
    # 1. Work Session
    sleep $(( WORK_MINS * 60 ))
    # 2. Break Prompt
    notify-send "Pomodoro Timer" "Take a break."
    sleep 5
    CHOICE=$(echo -e "Yes\nNo" | tofi \
        --prompt "Pomodoro Timer: Break?" \
        --num-results 2 \
        --ascii-input=false \
        --font="FiraCode Nerd Font" \
        --fuzzy-match=false
        )
    
#    CHOICE=$(echo -e "Yes\nNo" | fuzzel -d -p "Suspend for break?" --width 300 --font 'FiraCode Nerd Font' --num-results 2)

    if [[ "$CHOICE" == "Yes" ]]; then
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
        
        # 3. Native Suspend
        systemctl suspend
        
        # --- SCRIPT PAUSES HERE ---
        # It resumes automatically upon manual wake and unlock.
        
        notify-send "Pomodoro Timer" "Welcome back!"
    else
        notify-send "Pomodoro Timer" "Timer Reset Focus mode extended"
    fi
done
