#!/usr/bin/env bash

if pgrep -f "qs -c aero-carousel$" >/dev/null; then
    timeout 2 qs -c aero-carousel ipc call carousel toggle >/dev/null 2>&1 && exit 0
    pkill -f "qs -c aero-carousel$"
    exit 0
fi
setsid -f qs -c aero-carousel >"${XDG_RUNTIME_DIR:-/tmp}/aero-carousel.log" 2>&1 </dev/null
