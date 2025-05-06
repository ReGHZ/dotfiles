#!/bin/bash
capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1)
bar=$(bash ~/.config/waybar/scripts/ascii_bar.sh "$capacity" 100)

# Tentukan class berdasarkan value
if [ "$capacity" -le 20 ]; then
  class="critical"
elif [ "$capacity" -le 30 ]; then
  class="warning"
else
  class="normal"
fi

echo "{\"text\": \"Bat: $bar\", \"percentage\": $capacity, \"class\": \"$class\"}"