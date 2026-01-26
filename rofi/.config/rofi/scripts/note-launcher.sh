#!/bin/bash

dir="$HOME/.config/rofi/themes"
theme='style-1'

chosen=$(printf "Sticky Note\n" | rofi -dmenu -p "Note Menu" -theme "${dir}/${theme}.rasi")

case "$chosen" in
    "Sticky Note")
        ~/.config/rofi/scripts/sticky-note.sh
        ;;
esac
