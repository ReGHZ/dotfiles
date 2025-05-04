#!/bin/bash

# Dependencies: cliphist, wl-copy, rofi, notify-send, a terminal emulator (e.g., foot)

# Show clipboard history with "Clear All" at the top
SELECTION=$(printf "󰆴 Clear All\n%s" "$(cliphist list)" | rofi -dmenu -i -p "Clipboard:" -selected-row 1)

# Exit if nothing selected
[ -z "$SELECTION" ] && exit 0

# If user selects "Clear All", confirm it
if [[ "$SELECTION" == "󰆴 Clear All" ]]; then
    CONFIRM=$(printf "No\nYes" | rofi -dmenu -i -p "Are you sure you want to wipe history?")
    [[ "$CONFIRM" == "Yes" ]] && {
        cliphist wipe
        notify-send "cliphist" "Clipboard history wiped"
    }
    exit 0
fi

# Ask what to do with the selected entry
ACTION=$(printf "Copy\nDelete\nEdit" | rofi -dmenu -i -p "Action for selected:")

case "$ACTION" in
  Copy)
    echo "$SELECTION" | cliphist decode | wl-copy
    notify-send "cliphist" "Copied to clipboard"
    ;;
  Delete)
    echo "$SELECTION" | cliphist delete
    notify-send "cliphist" "Deleted from history"
    ;;
  Edit)
    TMPFILE=$(mktemp)
    echo "$SELECTION" | cliphist decode > "$TMPFILE"
    kitty nvim "$TMPFILE"
    wl-copy < "$TMPFILE"
    echo "$SELECTION" | cliphist delete
    rm "$TMPFILE"
    notify-send "cliphist" "Edited, copied, and original deleted"
    ;;
esac
