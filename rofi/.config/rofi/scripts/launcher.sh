#!/usr/bin/env bash

dir="$HOME/.config/rofi/themes"
theme='theme'

## Run
rofi \
    -show drun \
    -theme "${dir}/${theme}.rasi"

#use this for uwsm
##\-run-command "uwsm app -- {cmd}"
