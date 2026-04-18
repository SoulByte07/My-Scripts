#!/bin/bash
# Universal Turbo Launcher (Native + Flatpak)

# Safety Check: Exit if no app is specified
if [ -z "$1" ]; then
    echo "Error: You must specify an app to launch."
    echo "Usage: ./turbo-launch.sh <app_name> [arguments]"
    exit 1
fi

APP=$1
shift 

# Logic: Use an array to cleanly handle arguments and avoid string-splitting bugs
if [[ "$APP" == *"."* && "$APP" != "/"* && ! -f "$APP" ]]; then
    # It is a Flatpak (e.g., com.brave.Browser)
    CMD_ARRAY=(flatpak run "$APP")
else
    # It is Native (e.g., chromium)
    CMD_ARRAY=("$APP")
fi

# Execute via systemd and ionice. 
# -c 2 is Best-Effort (allowed for users), -n 0 is highest priority.
exec systemd-run --user --scope \
  -p CPUWeight=10000 \
  -p IOWeight=10000 \
  ionice -c 2 -n 0 \
  "${CMD_ARRAY[@]}" "$@"
