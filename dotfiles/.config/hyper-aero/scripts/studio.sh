#!/usr/bin/env bash

if pgrep -f "qs -c aero-studio$" >/dev/null; then
    timeout 3 qs -c aero-studio ipc call studio show >/dev/null 2>&1 && exit 0
fi
setsid -f qs -c aero-studio >"${XDG_RUNTIME_DIR:-/tmp}/aero-studio.log" 2>&1 </dev/null
