#!/bin/bash
brightness=$(brightnessctl get)
max=$(brightnessctl max)
percent=$((brightness * 100 / max))
bar=$(bash ~/.config/waybar/scripts/braille_bar.sh "$percent" 100)

# Tentukan class berdasarkan value
if [ "$percent" -ge 80 ]; then
  class="critical"
elif [ "$percent" -ge 60 ]; then
  class="warning"
else
  class="normal"
fi

echo "{\"text\": \"Bri: $bar\", \"percentage\": $percent, \"class\": \"$class\"}"