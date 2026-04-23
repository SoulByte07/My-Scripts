#!/usr/bin/env bash

# 1. Pick the app
app=$(tv cheat-sheet-apps)
[ -z "$app" ] && exit 0

sheet_path="$HOME/.config/cheat/cheatsheets/community/$app"

# 2. Pick the command (Merged Desc + Command)
# Using '  »  ' as a unique separator
selection=$(awk '/^#/{desc=$0; next} /^[[:space:]]*$/ {next} {if(desc!="") print desc "  »  " $0; desc=""}' "$sheet_path" | tv cheat-sheet-lines)

# 3. If a selection was made
if [ -n "$selection" ]; then
    # Extract just the command part (everything after the »)
    # We use '  »  ' as the delimiter
    command_text=$(echo "$selection" | awk -F '  »  ' '{print $2}')
    
    # Copy to Wayland clipboard
    echo "$command_text" | wl-copy
    
    # Send a quick desktop notification
    notify-send "Cheat Sheet" "Copied: $command_text"
    
    # 4. Display for reading
    clear
    echo -e "\033[1;33m----------------------------------------------------------------------\033[0m"
    echo "$selection"
    echo -e "\033[1;33m----------------------------------------------------------------------\033[0m"
    echo ""
    echo -e "\033[1;30mPress any key to close...\033[0m"
    
    # Keeps the terminal open until you acknowledge
    read -n 1 -s -r
fi
