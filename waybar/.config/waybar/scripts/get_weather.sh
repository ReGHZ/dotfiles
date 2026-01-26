#!/usr/bin/env bash

CACHE_FILE="$HOME/.cache/weather.json"
FALLBACK_CACHE="$HOME/.cache/weather_fallback.json"

# Get location with fallback
location=$(curl -s --connect-timeout 5 --max-time 10 ipinfo.io/city 2>/dev/null)
location=${location:-Banyuwangi}
location=${location// /+}

# Function to create offline fallback data
create_offline_fallback() {
    local fallback_output=$(jq -c -n \
        --arg text "[off] No connection" \
        --arg tooltip "Weather service unavailable - showing offline mode" \
        '{text: $text, tooltip: $tooltip}')
    
    echo "$fallback_output" > "$FALLBACK_CACHE"
    echo "$fallback_output"
}

# Function to create rate limit fallback
create_ratelimit_fallback() {
    local rate_output=$(jq -c -n \
        --arg text "[limit] Rate limited" \
        --arg tooltip "Weather service has reached its daily limit - try again later" \
        '{text: $text, tooltip: $tooltip}')
    
    echo "$rate_output"
}

# Function to create maintenance fallback
create_maintenance_fallback() {
    local maint_output=$(jq -c -n \
        --arg text "[maint] Service down" \
        --arg tooltip "Weather service is under maintenance - please try again later" \
        '{text: $text, tooltip: $tooltip}')
    
    echo "$maint_output"
}

# Function to check if response is valid weather data
is_valid_weather() {
    local response="$1"
    # Check for common error patterns
    if [[ -z "$response" ]] || \
       [[ "$response" =~ (ERROR|Sorry|Unknown|requests|capacity|datasource|problem|location|try) ]] || \
       [[ "$response" =~ (~-[0-9]+\.[0-9]+,[0-9]+\.[0-9]+) ]] || \
       [[ ${#response} -gt 200 ]]; then  # Error messages tend to be long
        return 1
    fi
    return 0
}

# Check if cache exists and is fresh (30 minutes)
if [[ -f "$CACHE_FILE" && $(stat -c %Y "$CACHE_FILE") -ge $(date -d "30 minutes ago" +%s) ]]; then
    cat "$CACHE_FILE"
    exit 0
fi

# Icon replacement function
replace_icons() {
    sed -e 's/☀️/[sun]/g' \
        -e 's/☁️/[cloud]/g' \
        -e 's/🌧/[rain]/g' \
        -e 's/❄️/[snow]/g' \
        -e 's/🌫/[mist]/g' \
        -e 's/⚡/[storm]/g' \
        -e 's/🌩️/[lightning]/g' \
        -e 's/🌥️/[cloudy]/g' \
        -e 's/🌤️/[sun-cloud]/g' \
        -e 's/🌦/[mixed]/g' \
        -e 's/⛅️/[partly cloudy]/g'
}

# Check internet connectivity first
if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    # No internet connection
    if [[ -f "$FALLBACK_CACHE" ]]; then
        cat "$FALLBACK_CACHE"
    else
        create_offline_fallback
    fi
    exit 0
fi

# Try to fetch weather data with retries
for i in {1..3}; do
    # Test if wttr.in is responding and check for rate limiting
    test_response=$(curl -s --connect-timeout 5 --max-time 10 "https://wttr.in/?format=1" 2>/dev/null)
    
    # Debug: uncomment next line to see what we're getting
    # echo "Debug test response: $test_response" >&2
    
    if [[ -z "$test_response" ]]; then
        if [[ $i -eq 3 ]]; then
            create_maintenance_fallback
            exit 0
        fi
        sleep 5
        continue
    elif ! is_valid_weather "$test_response"; then
        # Service has issues (rate limit, errors, etc.)
        if [[ -f "$FALLBACK_CACHE" ]]; then
            cat "$FALLBACK_CACHE"
        else
            create_ratelimit_fallback
        fi
        exit 0
    fi
    
    # Fetch weather data with timeouts
    short=$(curl -s --connect-timeout 5 --max-time 15 -A "Waybar-Weather" \
        "https://wttr.in/${location}?0&format=1&m&qT" 2>/dev/null)
    
    # Debug: uncomment these lines to see what we're getting
    # echo "Debug short: $short" >&2
    
    # Check if response is valid weather data
    if is_valid_weather "$short"; then
        # Process the data
        short_ascii=$(echo "$short" | sed -E "s/\s+/ /g" | replace_icons)
        
        output=$(jq -c -n \
            --arg text "$short_ascii" \
            --arg tooltip "${location/+/ }: $short_ascii" \
            '{text: $text, tooltip: $tooltip}')
        
        # Save both current cache and fallback
        echo "$output" > "$CACHE_FILE"
        echo "$output" > "$FALLBACK_CACHE"
        echo "$output"
        exit 0
    fi
    
    # If this is the last attempt and we have a fallback cache, use it
    if [[ $i -eq 3 && -f "$FALLBACK_CACHE" ]]; then
        cat "$FALLBACK_CACHE"
        exit 0
    fi
    
    sleep 5
done

# Final fallback - create offline indicator
create_offline_fallback
exit 1