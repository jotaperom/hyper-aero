#!/usr/bin/env bash

mirror=/var/lib/hyper-aero/mode
mode=day

if [ -f "$mirror" ] && [ $(( $(date +%s) - $(stat -c %Y "$mirror") )) -lt 900 ]; then
    [ "$(cat "$mirror")" = night ] && mode=night
else
    mode=$(python3 /etc/greetd/aero-sun.py 2>/dev/null || echo day)
fi

if [ "$mode" = night ]; then
    hyprctl eval 'hl.config({ misc = { background_color = "rgb(070c18)" } })' >/dev/null 2>&1
    exec regreet --config /etc/greetd/regreet-night.toml --style /etc/greetd/regreet-night.css
fi
exec regreet --config /etc/greetd/regreet.toml --style /etc/greetd/regreet.css
