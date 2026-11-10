#!/usr/bin/env bash

cmd="${1:-daemon}"
LOG="${XDG_RUNTIME_DIR:-/tmp}/aero-fx.log"

start_daemon() {
    printf '0\n' > "${XDG_RUNTIME_DIR:-/tmp}/aero-peek"
    setsid -f qs -c aero-fx >"$LOG" 2>&1 </dev/null
}

running() {
    pgrep -f "qs -c aero-fx$" >/dev/null
}

call() {
    timeout 3 qs -c aero-fx ipc call fx "$@" >/dev/null 2>&1
}

case "$cmd" in
    daemon)
        running || start_daemon
        ;;
    restart)
        pkill -f "qs -c aero-fx$"
        sleep 0.4
        start_daemon
        ;;
    stop)
        pkill -f "qs -c aero-fx$"
        ;;
    radial|flip)
        call "$cmd" && exit 0
        running || start_daemon
        for _ in $(seq 1 30); do
            sleep 0.15
            call "$cmd" && exit 0
        done
        ;;
    *)
        echo "uso: fx.sh daemon|restart|stop|radial|flip"
        exit 1
        ;;
esac
