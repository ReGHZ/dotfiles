#!/bin/bash

SOCKET="/tmp/nvimsocket-sticky"
NOTE_FILE="$HOME/.local/share/notes.txt"

# Jika belum ada instance nvim dengan socket, buat
if ! nvr --servername "$SOCKET" --remote-expr 1 2>/dev/null; then
    kitty --class sticky-note -e nvim --listen "$SOCKET" "$NOTE_FILE" &
    sleep 0.5  # beri waktu untuk startup
else
    # Kalau sudah ada, buka file di tab baru atau pindah ke buffer
    nvr --servername "$SOCKET" --remote "$NOTE_FILE"
fi
