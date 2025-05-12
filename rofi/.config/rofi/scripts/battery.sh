#!/usr/bin/env bash
# Hyprland Battery & Power Profile Menu (ASCII / Rofi)

# ========================
# Config Section
# ========================
THEME_DIR="$HOME/.config/rofi/themes"
THEME_STYLE='style-1.rasi'
THEME="$THEME_DIR/$THEME_STYLE"

# ========================
# Battery Info
# ========================
get_battery_info() {
  battery_path=$(upower -e | grep battery | head -1)
  battery_info=$(upower -i "$battery_path")
  
  percentage=$(echo "$battery_info" | grep percentage | awk '{print $2}' | tr -d '%')
  status=$(echo "$battery_info" | grep state | awk '{print $2}')
  time_remaining=$(echo "$battery_info" | grep 'time to empty' | awk '{print $4" "$5}')
  
  [ -z "$time_remaining" ] && time_remaining="Fully Charged"
}


# ========================
# Power Profile Functions
# ========================
get_power_profile() {
  if command -v powerprofilesctl &>/dev/null; then
    powerprofilesctl get
  else
    echo "unavailable"
  fi
}

set_power_profile() {
  if command -v powerprofilesctl &>/dev/null; then
    powerprofilesctl set "$1"
    notify-send -a "Power Manager" "Power Profile Changed" "Set to: $1"
  else
    notify-send -a "Power Manager" "Error" "Power Profile Daemon not installed!"
  fi
}

# ========================
# Update UI Elements
# ========================
update_ui_elements() {
  battery_percent="${percentage}"
  bar=$("$battery_percent")

  if [[ "$status" == "charging" ]]; then
    battery_status="[BAT] Charging: ${battery_percent}% $bar"
  else
    battery_status="${battery_percent}% $bar"
  fi

  current_profile=$(get_power_profile)
  case "$current_profile" in
    "power-saver") profile_status="[PROFILE] power-saver";;
    "balanced") profile_status="[PROFILE] balanced";;
    "performance") profile_status="[PROFILE] performance";;
    *) profile_status="[PROFILE] unknown";;
  esac

  prompt="$battery_status"

  options=(
    "[BAT] Status"
    "$profile_status"
    "[DIAG] Power Diagnostics"
    "[HEALTH] Battery Health"
  )
}

# ========================
# Rofi Menu
# ========================
show_menu() {
  rofi -theme "$THEME" \
    -theme-str "window {width: 400px;}" \
    -theme-str "listview {columns: 1; lines: 4;}" \
    -theme-str 'textbox-prompt-colon {str: "[BAT]";}' \
    -dmenu \
    -p "$prompt" \
    -mesg "[Time remaining: $time_remaining]" \
    <<< "$(printf "%s\n" "${options[@]}")"
}

# ========================
# Main Execution
# ========================
get_battery_info
update_ui_elements

case $(show_menu) in
  "${options[0]}")
    notify-send -a "Battery" "Battery Status" \
      "Percentage: ${battery_percent}%\nState: ${status}\nTime remaining: ${time_remaining}"
    ;;

  "${options[1]}")
    selected_profile=$(printf "%s\n" \
      "[power-saver] Power Saver" \
      "[balanced] Balanced" \
      "[performance] Performance" | \
      rofi -dmenu -p "Select Power Profile" -theme "$THEME")

    case "$selected_profile" in
      *power-saver*) set_power_profile power-saver ;;
      *balanced*) set_power_profile balanced ;;
      *performance*) set_power_profile performance ;;
    esac
    ;;

  "${options[2]}")
    kitty -e sudo powertop
    ;;

  "${options[3]}")
    notify-send -a "Battery" "Health" "$(upower -i $(upower -e | grep battery | head -1) | grep -E 'model|serial|cycle|capacity')"
    ;;
esac