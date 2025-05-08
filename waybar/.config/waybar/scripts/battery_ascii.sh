#!/bin/bash
capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1)
status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1)
bar=$(bash ~/.config/waybar/scripts/ascii_bar.sh "$capacity" 100)

# Tentukan class berdasarkan value
if [[ "$status" == "Charging" ]]; then
  class="charging"
elif [ "$capacity" -le 20 ]; then
  class="critical"
elif [ "$capacity" -le 30 ]; then
  class="warning"
else
  class="normal"
fi

# Notifikasi hanya dikirim sekali saat masuk critical
STATE_FILE="/tmp/waybar_battery_notify_state"

# Baca status sebelumnya
prev_state=""
[ -f "$STATE_FILE" ] && prev_state=$(cat "$STATE_FILE")

if [ "$class" == "critical" ]; then
  if [ "$prev_state" != "critical" ]; then
    notify-send -u critical "Low Battery ($capacity%)" "Please plug in your charger."
    canberra-gtk-play -i battery-caution -d "waybar-battery-alert"
    echo "critical" > "$STATE_FILE"
  fi
elif [ "$class" == "charging" ]; then
  if [ "$capacity" -ge 98 ]; then
    # Notifikasi full hanya jika sebelumnya bukan full
    if [ "$prev_state" != "full" ]; then
      notify-send -u normal "Battery Full ($capacity%)" "Please unplug your charger."
      canberra-gtk-play -i complete -d "waybar-battery-full"
      echo "full" > "$STATE_FILE"
    fi
  else
    # Notifikasi charging hanya jika sebelumnya bukan charging
    if [ "$prev_state" != "charging" ]; then
      notify-send -u normal "Charging" "Battery is charging ($capacity%)"
      canberra-gtk-play -i complete -d "waybar-battery-charging"
      echo "charging" > "$STATE_FILE"
    fi
  fi
else
  # Simpan state lain (normal/warning)
  if [ "$prev_state" != "$class" ]; then
    echo "$class" > "$STATE_FILE"
  fi
fi

echo "{\"text\": \"Bat: $bar\", \"percentage\": $capacity, \"class\": \"$class\"}"