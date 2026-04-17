#!/bin/sh
# tv-cheat-sheet.sh
# Pick a cheat entry via television, copy command, and preview it.
# Usage: ./tv-cheat-sheet.sh

set -u

cheat_dir="$HOME/.config/cheat/cheatsheets"

app="$(tv cheat-sheet-apps || true)"
[ -n "$app" ] || exit 0

sheet_path="$(find "$cheat_dir" -type f -name "$app" -print -quit 2>/dev/null || true)"
[ -n "$sheet_path" ] || exit 0

selection="$(awk '/^#/{desc=$0; next} /^[[:space:]]*$/ {next} {if(desc!="") print desc "  »  " $0; desc=""}' "$sheet_path" | tv cheat-sheet-lines || true)"
[ -n "$selection" ] || exit 0

desc_text="${selection%%  »  *}"
command_text="${selection#*  »  }"

printf '%s' "$command_text" | wl-copy
notify-send 'Cheat Sheet' "Copied: $command_text"

clear
printf '\033[90m----------------------------------------------------------------------\033[0m\n'
printf '\033[1;33m%s\033[0m\n' "$desc_text"
printf '\033[1;32m%s\033[0m\n' "$command_text"
printf '\033[90m----------------------------------------------------------------------\033[0m\n\n'
printf '\033[1;30mPress Enter to close...\033[0m\n'

IFS= read -r _
