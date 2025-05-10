#!/bin/bash
value=$1
max=$2
width=${3:-10}

# Hitung total granularitas (8 titik per blok Braille)
total_granularity=$((width * 8))
current_granularity=$((value * total_granularity / max))

# Karakter Braille bertingkat dari kosong (0 titik) ke penuh (8 titik)
braille_chars=("⠀" "⠁" "⠉" "⠋" "⠛" "⠟" "⠿" "⡿" "⣿")

bar=""
for ((i=0; i<width; i++)); do
    dots_filled=$(( current_granularity - i * 8 ))
    [[ $dots_filled -lt 0 ]] && dots_filled=0
    [[ $dots_filled -gt 8 ]] && dots_filled=8

    bar+="${braille_chars[$dots_filled]}"
done

echo "[$bar]"
