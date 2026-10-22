#!/usr/bin/env bash

cmd="${1:-daemon}"
RUN="${XDG_RUNTIME_DIR:-/tmp}"
LOG="$RUN/aero-veil.log"

start_daemon() {
    : > "$RUN/aero-veil.cmd"
    : > "$RUN/aero-veil.state"
    setsid -f qs -c aero-veil >"$LOG" 2>&1 </dev/null
}

case "$cmd" in
    daemon)
        if [ "$(jq -r '.resident' "$HOME/.config/hyper-aero/profile.json" 2>/dev/null)" = false ]; then exit 0; fi
        pgrep -f "qs -c aero-veil$" >/dev/null && exit 0
        start_daemon
        ;;
    restart)
        pkill -f "qs -c aero-veil$"
        sleep 0.4
        start_daemon
        ;;
    stop)
        pkill -f "qs -c aero-veil$"
        ;;
    *)
        echo "uso: veil.sh daemon|restart|stop"
        exit 1
        ;;
esac
