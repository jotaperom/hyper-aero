#!/usr/bin/env bash

cmd="${1:-show}"
LOG="${XDG_RUNTIME_DIR:-/tmp}/aero-control.log"

if pgrep -f "qs -c aero-control$" >/dev/null; then
    timeout 3 qs -c aero-control ipc call control "$cmd" >/dev/null 2>&1 && exit 0
    pkill -f "qs -c aero-control$"
    sleep 0.3
fi

if [ "$cmd" = "welcome" ]; then
    AERO_CONTROL_MODE=welcome setsid -f qs -c aero-control >"$LOG" 2>&1 </dev/null
else
    setsid -f qs -c aero-control >"$LOG" 2>&1 </dev/null
fi
