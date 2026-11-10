#!/usr/bin/env bash

. "$HOME/.config/hyper-aero/scripts/i18n.sh"

if ! command -v hyprpicker >/dev/null; then
    notify-send -a "NEXUS" "$(t "Falta hyprpicker")" "sudo pacman -S hyprpicker"
    exit 1
fi
pidof hyprpicker >/dev/null && exit 0
hex=$(hyprpicker -f hex 2>/dev/null | tail -n1)
[ -n "$hex" ] || exit 0
printf '%s' "$hex" | wl-copy
r=$((16#${hex:1:2})); g=$((16#${hex:3:2})); b=$((16#${hex:5:2}))
notify-send -a "NEXUS" "$(t "Color copiado"): $hex" "rgb($r, $g, $b)"
