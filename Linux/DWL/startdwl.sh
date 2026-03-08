#!/bin/bash
# Description: Starts dwl, pipes slstatus, and triggers the autostart script.

# Sample Input: Run this script from your TTY login.
# Expected Output: slstatus pipes into dwl, dwl launches and runs dwl-autostart.sh cleanly.

slstatus -s | dwl -s ~/.local/bin/DWL/dwl-deamons.sh
