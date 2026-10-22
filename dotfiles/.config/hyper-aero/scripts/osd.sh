#!/usr/bin/env bash

. "$HOME/.config/hyper-aero/scripts/i18n.sh"

sink="@DEFAULT_AUDIO_SINK@"
source="@DEFAULT_AUDIO_SOURCE@"

case "$1" in
    vol-up)   wpctl set-mute "$sink" 0; wpctl set-volume -l 1 "$sink" "${2:-5}%+" ;;
    vol-down) wpctl set-volume "$sink" "${2:-5}%-" ;;
    vol-set)  wpctl set-mute "$sink" 0; wpctl set-volume -l 1 "$sink" "${2:-50}%" ;;
    mute)     wpctl set-mute "$sink" toggle ;;
    mic-mute) wpctl set-mute "$source" toggle ;;
    bri-up)   brightnessctl -q -e4 -n2 set "${2:-5}%+" ;;
    bri-down) brightnessctl -q -e4 -n2 set "${2:-5}%-" ;;
    bri-set)  brightnessctl -q set "${2:-50}%" ;;
    *) exit 1 ;;
esac

muted=false
case "$1" in
    vol-*|mute)
        read -r _ level state < <(wpctl get-volume "$sink")
        value=$(awk -v v="$level" 'BEGIN { printf "%d", v * 100 + 0.5 }')
        [ "$state" = "[MUTED]" ] && muted=true
        label="$(t "VOLUMEN")"
        device=$(wpctl inspect "$sink" 2>/dev/null | awk -F'"' '/node.description/ { print $2; exit }')
        if [ "$muted" = true ] || [ "$value" -eq 0 ]; then icon="󰖁"
        elif [ "$value" -ge 66 ]; then icon="󰕾"
        elif [ "$value" -ge 33 ]; then icon="󰖀"
        else icon="󰕿"
        fi
        ;;
    mic-mute)
        read -r _ level state < <(wpctl get-volume "$source")
        value=$(awk -v v="$level" 'BEGIN { printf "%d", v * 100 + 0.5 }')
        [ "$state" = "[MUTED]" ] && muted=true
        label="$(t "MICRÓFONO")"
        device=$(wpctl inspect "$source" 2>/dev/null | awk -F'"' '/node.description/ { print $2; exit }')
        if [ "$muted" = true ]; then icon="󰍭"; else icon="󰍬"; fi
        ;;
    bri-*)
        value=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
        label="$(t "BRILLO")"
        device="PANTALLA"
        icon="󰃠"
        ;;
esac

on=$(( (value + 2) / 5 ))
(( on > 20 )) && on=20
segs="["
for ((i = 0; i < 20; i++)); do
    (( i > 0 )) && segs+=","
    if [ "$muted" = false ] && (( i < on )); then segs+="1"; else segs+="0"; fi
done
segs+="]"

eww update osd_icon="$icon" osd_label="$label" osd_device="${device^^}" osd_value="$value" osd_muted="$muted" osd_segs="$segs"
eww active-windows | grep -q '^osd:' || "$HOME/.config/hyper-aero/scripts/aero-eww" open osd

stamp="${XDG_RUNTIME_DIR:-/tmp}/aero-osd.stamp"
now=$(date +%s%N)
echo "$now" > "$stamp"
(
    sleep 1.6
    [ "$(cat "$stamp" 2>/dev/null)" = "$now" ] && eww close osd
) >/dev/null 2>&1 &
disown
