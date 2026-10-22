#!/usr/bin/env bash

S="$HOME/.config/hyper-aero/scripts"
RUN="${XDG_RUNTIME_DIR:-/tmp}"
cmd="${1:-toggle}"

start_daemon() {
    pgrep -f "python3 .*aero-displays.py daemon" >/dev/null && return 0
    setsid -f python3 "$S/aero-displays.py" daemon >>"$RUN/aero-displays.log" 2>&1 </dev/null
}

case "$cmd" in
    daemon)
        start_daemon
        ;;
    restart)
        pkill -f "python3 .*aero-displays.py daemon"
        sleep 0.5
        start_daemon
        ;;
    stop)
        pkill -f "python3 .*aero-displays.py daemon"
        pkill -f "qs -c aero-displays$"
        ;;
    next)
        start_daemon
        if pgrep -f "qs -c aero-displays$" >/dev/null; then
            timeout 3 qs -c aero-displays ipc call displays next >/dev/null 2>&1 && exit 0
        fi
        exec python3 "$S/aero-displays.py" next
        ;;
    apply|state|mode|side|scale|lapscale|offset|hud|set)
        exec python3 "$S/aero-displays.py" "$@"
        ;;
    show|toggle)
        start_daemon
        if pgrep -f "qs -c aero-displays$" >/dev/null; then
            timeout 3 qs -c aero-displays ipc call displays "$cmd" >/dev/null 2>&1 && exit 0
            pkill -f "qs -c aero-displays$"
            [ "$cmd" = "toggle" ] && exit 0
            sleep 0.2
        fi
        setsid -f qs -c aero-displays >"$RUN/aero-displays-ui.log" 2>&1 </dev/null
        ;;
    *)
        echo "uso: displays.sh toggle|show|next|daemon|restart|stop|apply|state|mode X|side X|scale N"
        exit 1
        ;;
esac
