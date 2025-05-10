#!/usr/bin/env bash
# Rofi Audio Control - ASCII Style for Hyprland

# ========================
# Config Section
# ========================
THEME_DIR="$HOME/.config/rofi/applets/themes"
THEME_STYLE='style-1.rasi'
THEME="$THEME_DIR/$THEME_STYLE"

DEFAULT_SINK="alsa_output.pci-0000_00_1f.3.analog-stereo"
DEFAULT_SOURCE="alsa_input.pci-0000_00_1f.3.analog-stereo"

# ========================
# Audio Status Check
# ========================
get_audio_status() {
  speaker_muted=$(pactl get-sink-mute "$DEFAULT_SINK" | awk '{print $2}')
  speaker_vol=$(pactl get-sink-volume "$DEFAULT_SINK" | awk '{print $5}' | tr -d '%')

  mic_muted=$(pactl get-source-mute "$DEFAULT_SOURCE" | awk '{print $2}')
  mic_vol=$(pactl get-source-volume "$DEFAULT_SOURCE" | awk '{print $5}' | tr -d '%' 2>/dev/null || echo "N/A")

  active=""
  urgent=""
}

# ========================
# Update UI Elements
# ========================
update_ui_elements() {
  if [[ "$speaker_muted" == "no" ]]; then
    sicon='[SPK]' 
    stext='Unmute'
    active="-a 1"
  else
    sicon='[SPK]'
    stext='Mute'
    urgent="-u 1"
  fi

  if [[ "$mic_muted" == "no" ]]; then
    micon='[MIC]' 
    mtext='Unmute'
    [ -n "$active" ] && active+=",3" || active="-a 3"
  else
    micon='[MIC]'
    mtext='Mute'
    [ -n "$urgent" ] && urgent+=",3" || urgent="-u 3"
  fi

  prompt="Speaker: $stext | Mic: $mtext"
  mesg="[Volume: $speaker_vol% ] | [Mic Level: $mic_vol%]"

  options=(
      "[+VOL] Increase"
      "$sicon $stext"
      "[-VOL] Decrease"
      "$micon $mtext"
      "[SET] Pavucontrol"
    )
}

# ========================
# Audio Control Functions
# ========================
toggle_speaker() {
  pactl set-sink-mute "$DEFAULT_SINK" toggle
}

toggle_mic() {
  pactl set-source-mute "$DEFAULT_SOURCE" toggle
}

adjust_volume() {
  pactl set-sink-volume "$DEFAULT_SINK" "$1"
}


# ========================
# Rofi Menu
# ========================

show_menu() {
  rofi -theme "$THEME" \
  -theme-str "window {width: 400px;}" \
  -theme-str "listview {columns: 1; lines: 5;}" \
  -theme-str 'textbox-prompt-colon {str: "[VOL]";}' \
  -dmenu \
  -p "$prompt" \
  -mesg "$mesg" \
  ${active} ${urgent} \
  -markup-rows \
  <<< "$(printf "%s\n" "${options[@]}")"
}

# ========================
# Main Execution
# ========================
get_audio_status
update_ui_elements

case $(show_menu) in
  "${options[0]}") adjust_volume +5% ;;
  "${options[1]}") toggle_speaker ;;
  "${options[2]}") adjust_volume -5% ;;
  "${options[3]}") toggle_mic ;;
  "${options[4]}") pavucontrol ;;
esac
