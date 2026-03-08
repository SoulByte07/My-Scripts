#!/bin/bash
# Minimal Suspend Pomodoro
# Input: ./pomo.sh 25
# Expected Output: Completes work timer, asks to suspend, sleeps laptop, resumes timer on manual wake.

WORK_MINS=${1:-25}

while true; do
    # 1. Work Phase
    sleep $(( WORK_MINS * 60 ))
    
    # 2. Break Prompt
    notify-send "Pomodoro Timer" "Take a break."
    sleep 5
    CHOICE=$(echo -e "Yes\nNo" | tofi     
        --prompt-text "Pomodoro Timer: break?" \
        --num-results 2 \
        --ascii-input=false \
        --font="FiraCode Nerd Font" \
        --fuzzy-match=false
    )
    if [[ "$CHOICE" == "Yes" ]]; then
        # Launch lock screen so it's secure when you wake it up
        hyprlock &
        sleep 1
        
        # Put the system to sleep (No root required)
        systemctl suspend
        
        # --- SCRIPT PAUSES HERE ---
        # It will only continue once you manually wake the laptop back up.
        
        notify-send "Pomodoro Timer" "Welcome Back"
    else
        notify-send "Pomodoro Timer" "Skipped Continuing work."
    fi
done
