#!/usr/bin/env bash

RUN="${XDG_RUNTIME_DIR:-/tmp}"
sock="$RUN/aero-motion.sock"
manual="$RUN/aero-motion.manual"

if [ ! -S "$sock" ]; then
    notify-send -a "HYPER·AERO" "Fondo animado" "No está corriendo."
    exit 1
fi

ipc() {
    printf '%s\n' "$1" | socat - "$sock" 2>/dev/null
}

state=$(ipc '{"command":["get_property","pause"]}' | jq -r '.data' 2>/dev/null)
want="${1:-toggle}"
if [ "$want" = toggle ]; then
    if [ "$state" = true ]; then want=resume; else want=pause; fi
fi

if [ "$want" = pause ]; then
    ipc '{"command":["set_property","pause",true]}' >/dev/null
    touch "$manual"
    notify-send -a "HYPER·AERO" "Fondo animado" "En pausa" -t 2000
else
    ipc '{"command":["set_property","pause",false]}' >/dev/null
    rm -f "$manual" "$RUN/aero-motion.guard"
    notify-send -a "HYPER·AERO" "Fondo animado" "Reproduciendo" -t 2000
fi
