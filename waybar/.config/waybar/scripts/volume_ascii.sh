#!/bin/bash

# ambil volume dari PipeWire
volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')

# cek mute
is_muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o "MUTED")

if [ "$is_muted" == "MUTED" ]; then
  bar="[Muted]"
  class="muted"
  volume=0
else
  bar=$(bash ~/.config/waybar/scripts/braille_bar.sh "$volume" 100)
  if [ "$volume" -ge 80 ]; then
    class="critical"
  elif [ "$volume" -ge 60 ]; then
    class="warning"
  else
    class="normal"
  fi
fi

echo "{\"text\": \"Vol: $bar\", \"percentage\": $volume, \"class\": \"$class\"}"