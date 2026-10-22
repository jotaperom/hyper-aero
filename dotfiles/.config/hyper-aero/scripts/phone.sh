#!/usr/bin/env bash

cmd="${1:-toggle}"
LOG="${XDG_RUNTIME_DIR:-/tmp}/aero-phone.log"

call() {
    timeout 3 qs -c aero-phone ipc call phone "$1" >/dev/null 2>&1
}

start_daemon() {
    if [ -z "$QS_ICON_THEME" ]; then
        theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
        [ -n "$theme" ] && export QS_ICON_THEME="$theme"
    fi
    setsid -f qs -c aero-phone >"$LOG" 2>&1 </dev/null
}

if [ "$cmd" = "daemon" ]; then
    if [ "$(jq -r '.resident' "$HOME/.config/hyper-aero/profile.json" 2>/dev/null)" = false ]; then exit 0; fi
    pgrep -f "qs -c aero-phone$" >/dev/null && exit 0
    start_daemon
    exit 0
fi

if [ "$cmd" = "restart" ]; then
    pkill -f "qs -c aero-phone$"
    sleep 0.4
    start_daemon
    exit 0
fi

call "$cmd" && exit 0

if ! pgrep -f "qs -c aero-phone$" >/dev/null; then
    start_daemon
fi

for _ in $(seq 1 40); do
    sleep 0.15
    call "$cmd" && exit 0
done

exec rofi -show drun
