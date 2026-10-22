#!/usr/bin/env bash

file="$HOME/.config/hyper-aero/mission-log.md"

if [ ! -f "$file" ]; then
    printf '%s\n' \
        "- [ ] Click a task to mark it done" \
        "- [ ] Click EDIT to add your own" \
        "- [x] Install the desktop widgets" > "$file"
fi

case "$1" in
    toggle)
        n="$2"
        if sed -n "${n}p" "$file" | grep -q '^- \[ \]'; then
            sed -i "${n}s/^- \[ \]/- [x]/" "$file"
        else
            sed -i "${n}s/^- \[[xX]\]/- [ ]/" "$file"
        fi
        eww poll desk_log >/dev/null 2>&1 &
        ;;
    edit)
        exec kitty --class aero-float -o initial_window_width=72c -o initial_window_height=20c -e nano "$file"
        ;;
    *)
        awk '
            BEGIN { printf "[" }
            /^- \[[ xX]\] / {
                done = ($0 ~ /^- \[[xX]\]/)
                t = substr($0, 7)
                gsub(/\\/, "\\\\", t)
                gsub(/"/, "\\\"", t)
                printf "%s{\"line\":%d,\"done\":%s,\"text\":\"%s\"}", (c++ ? "," : ""), NR, (done ? "true" : "false"), t
                if (c >= 8) exit
            }
            END { print "]" }
        ' "$file"
        ;;
esac
