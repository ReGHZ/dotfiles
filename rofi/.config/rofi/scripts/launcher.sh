#!/usr/bin/env bash

dir="$HOME/.config/rofi/launchers"
theme='theme'

## Run
rofi \
    -show drun \
    -theme "${dir}/${theme}.rasi" \
    -run-command "uwsm app -- {cmd}"
