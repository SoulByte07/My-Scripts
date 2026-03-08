#!/bin/bash
# Description: Handles all background daemons for the dwl session.


# 1. Start the wallpaper daemon
#swaybg -i /home/soul/Pictures/wallpapers/Anime-Ladys/anime-lady-orange.png &
/home/soul/.local/bin/DWL/dwl-random-wall.sh




# 2. Start the clipboard watchers
  # The Boot Waper: Delete all images from previous sessions immediately
cliphist list | grep "\[\[binary data" | cliphist delete

  # Start the Text Watcher (Persistent, saves everything)
wl-paste --type text --watch cliphist store &

  # Start the Image Watcher (Strict diet: keeps only the newest 5 images)
wl-paste --type image --watch bash -c 'cliphist store && cliphist list | grep "\[\[binary data" | tail -n +6 | cliphist delete' &

  # Keep the active clipboard alive when apps close
wl-clip-persist --clipboard regular &




# 3. Start the notification daemon
mako &



# 4. night mode
wlsunset -l 16.5 -L 81.5 &




# 5. pomodoro timer
/home/soul/.local/bin/Tools/DWL/dwl-pomodoro-timer.sh 25 5 &
