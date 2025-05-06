#!/bin/bash
volume=$(amixer get Master | awk -F'[][]' '/%/ { print $2; exit }' | tr -d '%')
bar=$(bash ~/.config/waybar/scripts/ascii_bar.sh "$volume" 100)

# Tentukan class berdasarkan value
if [ "$volume" -ge 80 ]; then
  class="critical"
elif [ "$volume" -ge 60 ]; then
  class="warning"
else
  class="normal"
fi

echo "{\"text\": \"Vol: $bar\", \"percentage\": $volume, \"class\": \"$class\"}"
