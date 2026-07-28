#!/usr/bin/env bash
# Rofi Audio Control - ASCII Style for Hyprland

# ========================
# Config Section
# ========================
THEME_DIR="$HOME/.config/rofi/themes"
THEME_STYLE='style-1.rasi'
THEME="$THEME_DIR/$THEME_STYLE"

# ========================
# Audio Status Check
# ========================
get_audio_status() {
  speaker_info=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
  speaker_vol=$(echo "$speaker_info" | awk '{print int($2 * 100)}')
  [[ "$speaker_info" == *"MUTED"* ]] && speaker_muted="yes" || speaker_muted="no"

  mic_info=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
  mic_vol=$(echo "$mic_info" | awk '{print int($2 * 100)}')
  [[ "$mic_info" == *"MUTED"* ]] && mic_muted="yes" || mic_muted="no"

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
  wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
}

toggle_mic() {
  wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
}

adjust_volume() {
  wpctl set-volume @DEFAULT_AUDIO_SINK@ "$1"
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
  "${options[0]}") adjust_volume 5%+ ;;
  "${options[1]}") toggle_speaker ;;
  "${options[2]}") adjust_volume 5%- ;;
  "${options[3]}") toggle_mic ;;
  "${options[4]}") pavucontrol ;;
esac
