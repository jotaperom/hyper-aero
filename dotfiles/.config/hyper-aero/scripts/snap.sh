#!/usr/bin/env bash

cmd="${1:-daemon}"
LOG="${XDG_RUNTIME_DIR:-/tmp}/aero-snap.log"

start_daemon() {
    printf '{"active":false}\n' > "${XDG_RUNTIME_DIR:-/tmp}/aero-snap.json"
    setsid -f qs -c aero-snap >"$LOG" 2>&1 </dev/null
}

case "$cmd" in
    daemon)
        pgrep -f "qs -c aero-snap$" >/dev/null && exit 0
        start_daemon
        ;;
    restart)
        pkill -f "qs -c aero-snap$"
        sleep 0.4
        start_daemon
        ;;
    stop)
        pkill -f "qs -c aero-snap$"
        ;;
    *)
        echo "uso: snap.sh daemon|restart|stop"
        exit 1
        ;;
esac
