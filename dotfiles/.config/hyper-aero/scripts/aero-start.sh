#!/usr/bin/env bash

S="$HOME/.config/hyper-aero/scripts"

pgrep -x eww >/dev/null || setsid -f eww daemon >/dev/null 2>&1 </dev/null
for _ in $(seq 1 150); do
    eww ping >/dev/null 2>&1 && break
    sleep 0.1
done

if ! eww active-windows 2>/dev/null | grep -q '^telemetry'; then
    "$S/aero-eww" open telemetry >/dev/null 2>&1 || eww open telemetry >/dev/null 2>&1
fi

pgrep -x waybar >/dev/null || setsid -f "$S/aerobar.sh" >/dev/null 2>&1 </dev/null
