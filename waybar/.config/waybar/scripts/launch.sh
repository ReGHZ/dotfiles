#!/usr/bin/env bash

# Prevent multiple concurrent launches (e.g., key repeat)
exec 9>/tmp/waybar-launch.lock
flock -n 9 || exit 0

# Force kill anything remaining
killall -9 waybar 2>/dev/null
killall -9 swaync 2>/dev/null
pkill -9 -f "mediaplayer.py" 2>/dev/null
sleep 0.2

# Start services
swaync &
waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css > /dev/null 2>&1 &
