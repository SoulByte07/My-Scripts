#!/bin/sh
set -eu

# --- 0. WAKE UP TMUX & RESTORE SESSIONS ---
# If no tmux server is running, boot it and force a restore
if ! tmux has-session 2>/dev/null; then
    # Start a dummy session in the background to boot the server
    tmux new-session -d -s "__boot__"
    
    # Trigger tmux-resurrect manually. 
    # (It checks both common plugin locations: ~/.tmux or ~/.config/tmux)
    for script in ~/.config/tmux/plugins/tmux-resurrect/scripts/restore.sh; do
        if [ -f "$script" ]; then
            "$script" >/dev/null 2>&1
            break
        fi
    done
    
    # Remove the dummy session so it doesn't clutter your Rofi menu
    tmux kill-session -t "__boot__" 2>/dev/null || true
fi
# ------------------------------------------

# 1. Gather existing sessions (now guaranteed to include restored ones)
sessions="$(tmux list-sessions -F '#S' 2>/dev/null || true)"

# 2. Prepend the "Create" option seamlessly
if [ -z "${sessions}" ]; then
    menu_items="Create new session..."
else
    menu_items="Create new session...\n${sessions}"
fi

# 3. Define the UI picker (Optimized with Catppuccin Mocha)
rofi_pick_session() {
  if command -v rofi >/dev/null 2>&1; then
   rofi -dmenu -i -p 'tmux sessions:' -theme ~/.config/rofi/themes/KooL_Catppuccin_mocha.rasi \
         -kb-row-down "Down,Control+n,j" -kb-row-up "Up,Control+p,k"
  else
    dmenu -i -l 10 -p 'tmux sessions:'
  fi
}

# 4. Display menu and get the user's choice
chosen="$(printf '%b\n' "$menu_items" | rofi_pick_session)"
[ -n "$chosen" ] || exit 0

# 5. Handle the "Create" logic if selected
is_new=0
if [ "$chosen" = "Create new session..." ]; then
    if command -v rofi >/dev/null 2>&1; then
        chosen="$(printf '' | rofi -dmenu -p 'New session name:' -theme ~/.config/rofi/themes/KooL_Catppuccin_mocha.rasi )"
    else
        chosen="$(printf '' | dmenu -p 'New session name:')"
    fi
    # Exit if user hits Esc or doesn't type a name
    [ -n "$chosen" ] || exit 0
    is_new=1
fi

# 6. Create the session in the background if it doesn't exist yet
if [ "$is_new" -eq 1 ] && ! tmux has-session -t "$chosen" 2>/dev/null; then
    tmux new-session -ds "$chosen"
fi

# 7. Inside Tmux: Switch cleanly
if [ -n "${TMUX-}" ]; then
  exec tmux switch-client -t "${chosen}"
fi

# 8. Outside Tmux: Find an existing Foot terminal to hijack
client_tty="$(
  tmux list-clients -F '#{client_tty} #{client_termname}' 2>/dev/null \
  | awk '$2 ~ /^foot/ { print $1; exit }' || true
)"

if [ -n "${client_tty}" ]; then
  # Switch that specific existing Foot client to the chosen session
  tmux switch-client -c "${client_tty}" -t "${chosen}"
  exit 0
fi

# 9. Outside Tmux & No existing client: Open a fresh Foot terminal
exec foot --title "Tmux-Main" env TERM=xterm-256color tmux attach -t "${chosen}"
