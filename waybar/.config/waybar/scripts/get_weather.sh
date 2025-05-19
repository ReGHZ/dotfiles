#!/usr/bin/env bash


CACHE_FILE="$HOME/.cache/weather.json"
location=$(curl -s ipinfo.io/city)
location=${location:-Banyuwangi}
location=${location// /+}

# Jika cache ada dan belum kadaluarsa (30 menit), gunakan cache
if [[ -f "$CACHE_FILE" && $(stat -c %Y "$CACHE_FILE") -ge $(date -d "30 minutes ago" +%s) ]]; then
    cat "$CACHE_FILE"
    exit 0
fi

replace_icons() {
  sed -e 's/☀️/[sun]/g' \
      -e 's/☁️/[cloud]/g' \
      -e 's/🌧/[rain]/g' \
      -e 's/❄️/[snow]/g' \
      -e 's/🌫️/[fog]/g' \
      -e 's/⚡/[storm]/g' \
      -e 's/🌩️/[lightning]/g' \
      -e 's/🌥️/[cloudy]/g' \
      -e 's/🌤️/[sun-cloud]/g' \
      -e 's/🌦/[mixed]/g'
}

for i in {1..3}; do
  # Format:
  # ?0 = hari ini (current weather)
  # ?1 = current + hari ini + besok
    short=$(curl -s -A "Waybar-Weather" "https://wttr.in/${location}?0&format=1&m&qT")
    today=$(curl -s -A "Waybar-Weather" "https://wttr.in/${location}?1&format=3&m&qT")
    tomorrow=$(curl -s -A "Waybar-Weather" "https://wttr.in/${location}?1&format=%c+%t&m&qT")

  if [[ -n "$short" && -n "$today" && -n "$tomorrow" ]]; then
    short_ascii=$(echo "$short" | sed -E "s/\s+/ /g" | replace_icons)
    today_ascii=$(echo "$today" | replace_icons)
    tomorrow_ascii="Tomorrow: $(echo "$tomorrow" | replace_icons)"

   output=$(jq -c -n \
            --arg text "$short_ascii" \
            --arg tooltip "$today_ascii $tomorrow_ascii" \
            '{text: $text, tooltip: $tooltip}')

        echo "$output" > "$CACHE_FILE"
        echo "$output"
        exit 0  
  fi

  sleep 5
done

echo '{"text":"error","tooltip":"error"}'
exit 1
