#!/usr/bin/env bash

vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{ if ($3 == "[MUTED]") print "MUTE"; else print int($2 * 100 + 0.5) }')
vol=${vol:-0}

raw=$(playerctl metadata --format '{{status}}|{{playerName}}|{{duration(position)}}|{{duration(mpris:length)}}|{{position}}|{{mpris:length}}' 2>/dev/null)

if [ -z "$raw" ]; then
    printf '{"status":"Stopped","player":"NO PLAYER","pos":"0:00","len":"0:00","pct":0,"vol":"%s","icon":"■","state":"STANDBY"}\n' "$vol"
    exit 0
fi

IFS='|' read -r st pl pos len p l <<< "$raw"

pct=0
if [[ "$p" =~ ^[0-9]+$ && "$l" =~ ^[0-9]+$ && "$l" -gt 0 ]]; then
    pct=$(( p * 100 / l ))
    (( pct > 100 )) && pct=100
fi

case "$st" in
    Playing) icon="▶"; state="PLAY" ;;
    Paused)  icon="||"; state="PAUSE" ;;
    *)       icon="■"; state="STOP" ;;
esac

pl=${pl//\"/}
printf '{"status":"%s","player":"%s","pos":"%s","len":"%s","pct":%d,"vol":"%s","icon":"%s","state":"%s"}\n' \
    "$st" "${pl^^}" "${pos:-0:00}" "${len:-0:00}" "$pct" "$vol" "$icon" "$state"
