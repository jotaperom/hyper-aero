#!/usr/bin/env bash

case "$1" in
    seek)
        len=$(playerctl metadata mpris:length 2>/dev/null)
        [[ "$len" =~ ^[0-9]+$ ]] || exit 0
        playerctl position "$(awk -v p="$2" -v l="$len" 'BEGIN { printf "%.1f", p * l / 100 / 1000000 }')"
        ;;
    vol-up)
        wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    vol-down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
esac
