#!/bin/sh
# snippets-insert.sh
# Pick snippet with television, then type snippet into focused app via wtype.

set -u

snippet_dir="$HOME/.config/snippets"

[ -d "$snippet_dir" ] || exit 0

# Move into the dir for native tv previews
cd "$snippet_dir" || exit 1

# Launch tv. Use '|| true' to gracefully handle hitting Escape (just like your cheat script)
selected_file="$(tv || true)"

# Exit if empty or not a file
[ -n "$selected_file" ] || exit 0
[ -f "$selected_file" ] || exit 0

# Read the content
snippet_content="$(cat "$selected_file")"

# CRITICAL: Fork the typing process to the background.
# This allows the script (and the terminal running it) to exit immediately.
# The sleep gives DWL exactly 150ms to close the terminal and give focus back to your main app.
(
    sleep 0.15
    wtype "$snippet_content"
) &
