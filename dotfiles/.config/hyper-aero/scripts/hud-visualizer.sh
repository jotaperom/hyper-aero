#!/usr/bin/env bash

A="$HOME/.config/hyper-aero"
flat="▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁"
fps=$(jq -r '.visualizer_fps // 15' "$A/profile.json" 2>/dev/null)
fps=${fps:-15}

playing() {
    [ "$(playerctl status 2>/dev/null)" = "Playing" ]
}

echo "$flat"
if [ "$fps" = 0 ] || ! command -v cava >/dev/null; then
    exec sleep infinity
fi

cleanup() {
    [ -n "$pid" ] && kill "$pid" 2>/dev/null
    exit 0
}
trap cleanup TERM INT EXIT

pid=""
while true; do
    if playing; then
        if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
            cava -p "$A/cava-hud.conf" 2>/dev/null \
                | sed -u 's/;//g; s/0/▁/g; s/1/▂/g; s/2/▃/g; s/3/▄/g; s/4/▅/g; s/5/▆/g; s/6/▇/g; s/7/█/g' &
            pid=$!
        fi
    elif [ -n "$pid" ]; then
        pkill -P "$pid" 2>/dev/null
        kill "$pid" 2>/dev/null
        pkill -f "cava -p $A/cava-hud.conf" 2>/dev/null
        pid=""
        echo "$flat"
    fi
    sleep 2
done
