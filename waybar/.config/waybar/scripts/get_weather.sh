#!/usr/bin/env bash

CACHE_FILE="$HOME/.cache/weather.json"
FALLBACK_CACHE="$HOME/.cache/weather_fallback.json"
LOCATION_CACHE="$HOME/.cache/weather_location"
CACHE_MAX_AGE=1800    # 30 minutes
LOCATION_MAX_AGE=3600 # 1 hour

# Return cached result if fresh
if [[ -f "$CACHE_FILE" && $(stat -c %Y "$CACHE_FILE") -ge $(date -d "${CACHE_MAX_AGE} seconds ago" +%s) ]]; then
    cat "$CACHE_FILE"
    exit 0
fi

# Get location (cached separately — IP rarely changes)
if [[ -f "$LOCATION_CACHE" && $(stat -c %Y "$LOCATION_CACHE") -ge $(date -d "${LOCATION_MAX_AGE} seconds ago" +%s) ]]; then
    location=$(<"$LOCATION_CACHE")
else
    location=$(curl -s --connect-timeout 3 --max-time 5 ipinfo.io/city 2>/dev/null)
    location=${location:-Banyuwangi}
    echo "$location" > "$LOCATION_CACHE"
fi
location=${location// /+}

condition_label() {
    local cond="${1,,}"
    case "$cond" in
        *thunder*|*storm*)       echo "[storm]" ;;
        *sleet*)                 echo "[sleet]" ;;
        *shower*)                echo "[shower]" ;;
        *drizzle*|*rain*)        echo "[rain]" ;;
        *snow*|*blizzard*)       echo "[snow]" ;;
        *mist*|*fog*|*haze*)     echo "[mist]" ;;
        *overcast*|*very*cloud*) echo "[cloud]" ;;
        *partly*|*cloudy*)       echo "[cloudy]" ;;
        *clear*|*sunny*)         echo "[sun]" ;;
        *)                       echo "[${cond:0:8}]" ;;
    esac
}

# Single curl — condition, temp, feels-like, humidity, wind, UV
raw=$(curl -s --connect-timeout 5 --max-time 10 -A "Waybar-Weather" \
    "https://wttr.in/${location}?format=%C|%t|%f|%h|%w|%u&m" 2>/dev/null)

# Validate response
if [[ -z "$raw" || "$raw" =~ (ERROR|Sorry|Unknown|requests|capacity|datasource|problem|location|try) || ${#raw} -gt 200 ]]; then
    # Fetch failed — serve fallback cache or offline message
    if [[ -f "$FALLBACK_CACHE" ]]; then
        cat "$FALLBACK_CACHE"
    else
        echo '{"text":"[off] No connection","tooltip":"Weather unavailable"}'
    fi
    exit 0
fi

# Parse "Condition|+26°C|+28°C|94%|↖10km/h|0"
IFS='|' read -r condition temp feels humidity wind uv <<< "$raw"

if [[ -z "$condition" || -z "$temp" ]]; then
    [[ -f "$FALLBACK_CACHE" ]] && cat "$FALLBACK_CACHE"
    exit 0
fi

label=$(condition_label "$condition")
text="$label $temp"

city="${location/+/ }"
tooltip="$city: $condition $temp\nFeels like $feels | Humidity $humidity\nWind $wind | UV $uv"

output=$(printf '{"text":"%s","tooltip":"%s"}' "$text" "$tooltip")

echo "$output" > "$CACHE_FILE"
echo "$output" > "$FALLBACK_CACHE"
echo "$output"
