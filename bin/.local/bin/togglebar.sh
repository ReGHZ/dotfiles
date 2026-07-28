#!/bin/bash

until hyprctl activewindow -j &>/dev/null; do
	sleep 0.5
done

# Ensure waybar is not already running from previous session
pkill -x waybar 2>/dev/null
sleep 0.5

while true; do
	clients=$(hyprctl activewindow -j | jq -r '.class // empty')

    	if [[ -n "$clients" ]]; then
        	# Window(s) open — use horizontal bar
		if eww active-windows 2>/dev/null | grep -q sysinfo; then
			eww close sysinfo 2>/dev/null
			sleep 0.3
		fi
        	if ! pgrep -f "waybar.*config.jsonc" > /dev/null 2>&1; then
            		waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css > /dev/null 2>&1 &
            		sleep 0.2
        	fi
    	else
        	# No windows open — eww
		pkill -x waybar 2>/dev/null
		pkill -f "mediaplayer.py" 2>/dev/null
		sleep 0.3
		
        	if ! eww active-windows 2>/dev/null | grep -q sysinfo; then
        		eww open sysinfo 2>/dev/null
		fi
    	fi

    	sleep 1
done
