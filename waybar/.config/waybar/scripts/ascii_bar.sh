#!/bin/bash
value=$1
max=$2
width=${3:-10}  # default width is 10

filled=$((value * width / max))
empty=$((width - filled))

bar=$(printf "%0.s█" $(seq 1 $filled))
bar+=$(printf "%0.s░" $(seq 1 $empty))

echo "[$bar]"