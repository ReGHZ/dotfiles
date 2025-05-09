#!/usr/bin/env bash

location=$(curl -s ipinfo.io/city)
location=${location:-Banyuwangi}

replace_icons() {
  sed -e 's/☀️/[sun]/g' \
      -e 's/☁️/[cloud]/g' \
      -e 's/🌧/[rain]/g' \
      -e 's/🌦️/[mixed]/g' \
      -e 's/❄️/[snow]/g' \
      -e 's/🌫️/[fog]/g' \
      -e 's/⚡/[storm]/g' \
      -e 's/🌩️/[lightning]/g' \
      -e 's/🌥️/[cloudy]/g' \
      -e 's/🌤️/[sun-cloud]/g' \
      -e 's/🌦/[mixed]/g'
}

for i in {1..5}; do
  short=$(curl -s "https://wttr.in/${location}?format=1")
  today=$(curl -s "https://wttr.in/${location}?format=3")
  tomorrow=$(curl -s "https://wttr.in/${location}?1&format=3")

  if [[ -n "$short" && -n "$today" && -n "$tomorrow" ]]; then
    short_ascii=$(echo "$short" | sed -E "s/\s+/ /g" | replace_icons)
    today_ascii=$(echo "$today" | replace_icons)
    tomorrow_ascii=$(echo "$tomorrow" | replace_icons | sed 's/^.*: /Tomorrow: /')

    jq -c -n \
      --arg text "$short_ascii" \
      --arg tooltip "$today_ascii $tomorrow_ascii" \
      '{text: $text, tooltip: $tooltip}'
    exit 0
  fi

  sleep 2
done

echo '{"text":"error","tooltip":"error"}'
exit 1
