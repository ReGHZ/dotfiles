#!/usr/bin/env bash
# Hyprland Brightness Control (ASCII Style, brightnessctl)

# ========================
# Config Section
# ========================
THEME_DIR="$HOME/.config/rofi/applets/themes"
THEME_STYLE='style-1.rasi'
THEME="$THEME_DIR/$THEME_STYLE"

# ========================
# Brightness Info
# ========================
get_brightness_info() {
  backlight_device=$(brightnessctl --list | grep backlight | head -n1 | cut -d"'" -f2)
  current_brightness=$(brightnessctl get)
  max_brightness=$(brightnessctl max)
  percentage=$(( (current_brightness * 100) / max_brightness ))

  # Level kategori (ASCII style)
  if [[ $percentage -le 29 ]]; then
    level="Low"
  elif [[ $percentage -le 49 ]]; then
    level="Optimal"
  elif [[ $percentage -le 60 ]]; then
    level="High"
  else
    level="Peak"
  fi
}

# ========================
# UI Elements
# ========================
update_ui() {
  prompt="${percentage}% "
  mesg="Device: ${backlight_device##*/} | Level: $level"
  options=(
    "[UP]   Increase"
    "[OPT]  Optimal"
    "[DOWN] Decrease"
  )
}

# ========================
# Brightness Operations
# ========================
adjust_brightness() {
  case $1 in
    up) brightnessctl -q set 5%+ ;;
    down) brightnessctl -q set 5%- ;;
    set) brightnessctl -q set "$2" ;;
  esac

  # Update nilai setelah perubahan
  get_brightness_info
  notify-send -a "Brightness" "[BRI] ${percentage}%" -h int:value:${percentage} -t 1000
}

# ========================
# Rofi Interface
# ========================
show_menu() {
  rofi -theme "$THEME" \
    -theme-str "window {width: 400px;}" \
    -theme-str "listview {columns: 1; lines: 3;}" \
    -theme-str 'textbox-prompt-colon {str: "[BRI]";}' \
    -dmenu \
    -p "$prompt" \
    -mesg "$mesg" \
    <<< "$(printf "%s\n" "${options[@]}")"
}

# ========================
# Main Execution
# ========================
get_brightness_info
update_ui

case $(show_menu) in
  *"[UP]"*)   adjust_brightness up ;;
  *"[OPT]"*)  adjust_brightness set 40% ;;
  *"[DOWN]"*) adjust_brightness down ;;
esac