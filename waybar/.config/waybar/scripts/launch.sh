# Force kill anything remaining
killall -9 waybar 2>/dev/null
killall -9 swaync 2>/dev/null  
pkill -9 -f "mediaplayer.py" 2>/dev/null

# Start services
swaync &
waybar &