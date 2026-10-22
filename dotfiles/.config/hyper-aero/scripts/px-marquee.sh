#!/usr/bin/env bash

width=30
text=""
i=0
last=0

while true; do
    now=$(date +%s)
    if (( now - last >= 2 )); then
        new=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null)
        [ -z "$new" ] || [ "$new" = " - " ] && new="NO DISC"
        new=${new^^}
        if [ "$new" != "$text" ]; then
            text="$new"
            i=0
        fi
        last=$now
    fi
    if (( ${#text} <= width )); then
        echo "$text"
    else
        loop="$text   ·   $text"
        echo "${loop:i:width}"
        i=$(( (i + 1) % (${#text} + 7) ))
    fi
    sleep 0.3
done
