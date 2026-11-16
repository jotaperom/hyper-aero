#!/usr/bin/env bash

cache="$HOME/.cache/hyper-aero"
mkdir -p "$cache"

declare -A ST TI AR AU
last=""

choose() {
    local spot="" play="" first="" p
    for p in "${!ST[@]}"; do
        case "$p" in
            spotify*)
                if [ "${ST[$p]}" = Playing ]; then
                    printf '%s' "$p"
                    return
                fi
                [ -n "$spot" ] || spot="$p"
                ;;
        esac
        [ "${ST[$p]}" = Playing ] && [ -z "$play" ] && play="$p"
        [ -n "$first" ] || first="$p"
    done
    printf '%s' "${play:-${spot:-$first}}"
}

prune() {
    local live p
    live=$(playerctl -l 2>/dev/null | sed 's/\.instance[0-9_]*$//')
    for p in "${!ST[@]}"; do
        grep -qxF "$p" <<< "$live" || unset "ST[$p]" "TI[$p]" "AR[$p]" "AU[$p]"
    done
}

emit() {
    local p status="" title="" artist="" art="" path="" raw line
    p=$(choose)
    if [ -n "$p" ]; then
        status="${ST[$p]}"
        title="${TI[$p]}"
        artist="${AR[$p]}"
        art="${AU[$p]}"
    fi
    line="$status|$title|$artist|$art"
    [ "$line" = "$last" ] && return
    last="$line"
    case "$art" in
        file://*)
            raw="${art#file://}"
            path=$(printf '%b' "${raw//%/\\x}")
            ;;
        http*)
            path="$cache/cover-$(printf '%s' "$art" | sha256sum | cut -c1-16).jpg"
            [ -f "$path" ] || curl -sfL "$art" -o "$path" || path=""
            ;;
    esac
    jq -nc --arg s "$status" --arg t "$title" --arg a "$artist" --arg p "$path" \
        '{status: $s, title: $t, artist: $a, art: $p}'
}

emit
while true; do
    if IFS=$'\t' read -r -t 5 name status title artist art; then
        if [ -z "$name" ]; then
            prune
        else
            ST[$name]="$status"
            TI[$name]="$title"
            AR[$name]="$artist"
            AU[$name]="$art"
        fi
        emit
    else
        [ $? -gt 128 ] || break
        prune
        emit
    fi
done < <(playerctl --follow -a metadata --format $'{{playerName}}\t{{status}}\t{{title}}\t{{artist}}\t{{mpris:artUrl}}' 2>/dev/null)
