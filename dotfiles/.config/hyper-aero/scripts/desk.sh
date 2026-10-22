#!/usr/bin/env bash

cmd="${1:-toggle}"
LOG="${XDG_RUNTIME_DIR:-/tmp}/aero-desk.log"

call() {
    timeout 3 qs -c aero-desk ipc call desk "$1" >/dev/null 2>&1
}

start_daemon() {
    if [ -z "$QS_ICON_THEME" ]; then
        theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
        [ -n "$theme" ] && export QS_ICON_THEME="$theme"
    fi
    setsid -f qs -c aero-desk >"$LOG" 2>&1 </dev/null
}

case "$cmd" in
    daemon)
        pgrep -f "qs -c aero-desk$" >/dev/null && exit 0
        start_daemon
        exit 0
        ;;
    restart)
        pkill -f "qs -c aero-desk$"
        sleep 0.4
        start_daemon
        exit 0
        ;;
    stop)
        pkill -f "qs -c aero-desk$"
        exit 0
        ;;
esac

call "$cmd" && exit 0

if ! pgrep -f "qs -c aero-desk$" >/dev/null; then
    start_daemon
fi

for _ in $(seq 1 40); do
    sleep 0.15
    call "$cmd" && exit 0
done
exit 1
