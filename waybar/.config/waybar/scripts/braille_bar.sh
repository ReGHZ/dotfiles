#!/bin/bash
value=$1
max=$2
width=${3:-10}

# Hitung total granularity (8 titik per blok Braille)
total_granularity=$((width * 8))
current_granularity=$((value * total_granularity / max))

# Karakter Braille yang akan digunakan untuk mengisi progress bar
# Urutan dari kosong hingga penuh sesuai jumlah titik yang terisi
braille_chars=("⠀" "⠁" "⠉" "⠋" "⠛" "⠟" "⠿" "⡿" "⣿")

bar=""
for ((i=0; i<width; i++)); do
    # Hitung titik untuk setiap blok (8 titik per blok)
    start=$((i*8))
    end=$((start+7))
    
    # Hitung berapa banyak titik yang harus terisi untuk blok ini
    dots_filled=0
    for ((j=start; j<=end; j++)); do
        if ((j < current_granularity)); then
            dots_filled=$((dots_filled+1))
        fi
    done
    
    # Pilih karakter Braille yang sesuai berdasarkan jumlah titik yang terisi
    bar+="${braille_chars[$dots_filled]}"
done

echo "[$bar]"