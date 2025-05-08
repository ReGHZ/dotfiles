#!/usr/bin/env bash
# Hyprland Screenshot Tool (ASCII Style)
# Dependency: grim, slurp, hyprctl, wl-copy, jq

# ========================
# Config Section
# ========================
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
FILENAME="screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
FULL_PATH="${SCREENSHOT_DIR}/${FILENAME}"
THEME="$HOME/.config/rofi/applets/themes/style-1.rasi"

# ========================
# UI Elements
# ========================
prompt='[SHOT]'
mesg="DIR: ${SCREENSHOT_DIR}"

options=(
  "[FULL] Fullscreen"
  "[AREA] Select Area"
  "[ACTIVE] Active Window"
  "[PICK] Window Picker"
  "[5SEC] 5s Delay"
  "[10SEC] 10s Delay"
)

# ========================
# Notification Functions
# ========================
notify() {
  notify-send -a "Screenshot" "$1" "$2" -t 2000
}

countdown() {
  for ((i=$1; i>0; i--)); do
    notify "[SHOT]" "Taking shot in $i seconds..."
    sleep 1
  done
}

# ========================
# Capture Functions
# ========================
capture_full() {
  grim "$FULL_PATH"
  echo "$FULL_PATH"
}

capture_area() {
  grim -g "$(slurp)" "$FULL_PATH"
  echo "$FULL_PATH"
}

capture_active() {
  local active_window=$(hyprctl activewindow -j)
  local geometry=$(jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' <<< "$active_window")
  grim -g "$geometry" "$FULL_PATH"
  echo "$FULL_PATH"
}

capture_picker() {
  local window=$(hyprctl clients -j | jq -r '.[] | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])\t\(.title)"' | slurp -f "%x\t%y")
  local geometry=$(cut -d$'\t' -f1 <<< "$window")
  grim -g "$geometry" "$FULL_PATH"
  echo "$FULL_PATH"
}

# ========================
# Main Execution
# ========================
mkdir -p "$SCREENSHOT_DIR"

if [[ $# -eq 0 ]]; then
  chosen=$(printf '%s\n' "${options[@]}" | rofi -dmenu \
    -theme "$THEME" \
    -theme-str "window {width: 400px;}" \
    -theme-str "listview {columns: 1; lines: 6;}" \
    -theme-str 'textbox-prompt-colon {str: "[SHOT]";}' \
    -p "$prompt" \
    -mesg "$mesg")
else
  chosen="$1"
fi

case "$chosen" in
  *"[FULL]"*)
    sleep 0.2
    result=$(capture_full)
    ;;
  *"[AREA]"*)
    sleep 0.2
    result=$(capture_area)
    ;;
  *"[ACTIVE]"*)
    sleep 0.2
    result=$(capture_active)
    ;;
  *"[PICK]"*)
    sleep 0.2
    result=$(capture_picker)
    ;;
  *"[5SEC]"*)
    countdown 5
    sleep 0.2
    result=$(capture_full)
    ;;
  *"[10SEC]"*)
    countdown 10
    sleep 0.2
    result=$(capture_full)
    ;;
  *)
    exit 0
    ;;
esac

# Handle result
if [[ -n "$result" && -f "$result" ]]; then
  wl-copy < "$result"
  notify "[SHOT] Saved" "Path: ${result/#$HOME/\~}\nCopied to clipboard"
fi