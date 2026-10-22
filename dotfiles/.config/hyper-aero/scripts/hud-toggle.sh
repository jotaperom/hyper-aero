#!/usr/bin/env bash

RUN="${XDG_RUNTIME_DIR:-/tmp}"
E="$HOME/.config/hyper-aero/scripts/aero-eww"
screen=$(cat "$RUN/aero-hud.screen" 2>/dev/null)

if eww active-windows | grep -q '^telemetry:'; then
    from=telemetry
    to=telemetry-slim
else
    from=telemetry-slim
    to=telemetry
fi

printf '%s\n' "$to" > "$RUN/aero-hud.variant"
eww close "$from"
if [ -n "$screen" ] && "$E" open "$to" --screen "$screen"; then
    exit 0
fi
"$E" open "$to"
