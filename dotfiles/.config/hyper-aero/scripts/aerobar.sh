#!/usr/bin/env bash

cur="$HOME/.config/hyper-aero/theme/current/waybar.jsonc"

if [ -f "$cur" ]; then
    exec waybar -c "$cur"
fi
exec waybar
