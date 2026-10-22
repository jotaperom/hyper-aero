#!/usr/bin/env bash

cache="$HOME/.cache/hyper-aero"
mkdir -p "$cache"

playerctl --follow metadata --format $'{{status}}\t{{title}}\t{{artist}}\t{{mpris:artUrl}}' 2>/dev/null \
    | while IFS=$'\t' read -r status title artist art; do
        path=""
        case "$art" in
            file://*)
                raw="${art#file://}"
                path=$(printf '%b' "${raw//%/\\x}")
                ;;
            http*)
                path="$cache/cover-$(printf '%s' "$art" | md5sum | cut -c1-12).jpg"
                [ -f "$path" ] || curl -sfL "$art" -o "$path" || path=""
                ;;
        esac
        jq -nc --arg s "$status" --arg t "$title" --arg a "$artist" --arg p "$path" \
            '{status: $s, title: $t, artist: $a, art: $p}'
    done
