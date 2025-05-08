#!/bin/bash

volume=$(amixer get Master | awk -F'[][]' '/%/ { print $2; exit }' | tr -d '%')
is_muted=$(amixer get Master | grep -o '\[off\]' | head -n 1)

if [ "$is_muted" == "[off]" ]; then
  bar="[Muted]"
  class="muted"
  volume=0
else
  bar=$(bash ~/.config/waybar/scripts/ascii_bar.sh "$volume" 100)
  if [ "$volume" -ge 80 ]; then
    class="critical"
  elif [ "$volume" -ge 60 ]; then
    class="warning"
  else
    class="normal"
  fi
fi

echo "{\"text\": \"Vol: $bar\", \"percentage\": $volume, \"class\": \"$class\"}"
