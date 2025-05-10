#!/usr/bin/env bash

# Import Current Theme
type="$HOME/.config/rofi/applets/themes"
style='style-1.rasi'
theme="$type/$style"

# Theme Elements
prompt="$(hostname)"
mesg="[Uptime: $(uptime -p | sed -e 's/up //g')]"

if [[ "$theme" == *'themes'* ]]; then
	list_col='1'
	list_row='6'
fi

# Options (pure ASCII)
option_1="[Lock]"
option_2="[Logout]"
option_3="[Suspend]"
option_4="[Hibernate]"
option_5="[Reboot]"
option_6="[Shutdown]"
yes='[Yes]'
no='[No]'

# Rofi CMD
rofi_cmd() {
	rofi -theme-str "listview {columns: $list_col; lines: $list_row;}" \
		-theme-str 'textbox-prompt-colon {str: "[PWR]";}' \
		-dmenu \
		-p "$prompt" \
		-mesg "$mesg" \
		-markup-rows \
		-theme "$theme"
}

# Confirmation CMD
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
		-theme-str 'mainbox {orientation: vertical; children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Are you sure?' \
		-theme "$theme"
}

# Confirmation logic
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

confirm_run () {	
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
        ${1} && ${2} && ${3}
    else
        exit
    fi	
}

# Run selected command
run_cmd() {
	case "$1" in
		'--opt1') hyprlock ;;
		'--opt2') confirm_run 'hyprctl dispatch exit' ;;
		'--opt3') confirm_run 'amixer set Master mute' 'systemctl suspend' ;;
		'--opt4') confirm_run 'systemctl hibernate' ;;
		'--opt5') confirm_run 'systemctl reboot' ;;
		'--opt6') confirm_run 'systemctl poweroff' ;;
	esac
}

# Run rofi menu
chosen="$(echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6" | rofi_cmd)"

case "$chosen" in
	"$option_1") run_cmd --opt1 ;;
	"$option_2") run_cmd --opt2 ;;
	"$option_3") run_cmd --opt3 ;;
	"$option_4") run_cmd --opt4 ;;
	"$option_5") run_cmd --opt5 ;;
	"$option_6") run_cmd --opt6 ;;
esac
