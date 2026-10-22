#!/usr/bin/env bash

run="${XDG_RUNTIME_DIR:-/tmp}"
dir="$run/aero-thumbs"
flag="$run/aero-overview.open"
here="$(dirname "$(readlink -f "$0")")"
mkdir -p "$dir"
exec 9>"$dir/.lock"
flock -w 30 9 || exit 0

sock="$run/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

busy() {
    [ -e "$flag" ] || pidof rofi hyprlock >/dev/null
}

grab_window() {
    local addr geom
    read -r addr geom < <(hyprctl activewindow -j 2>/dev/null | jq -r '
        select(.address != null and .mapped == true and (.workspace.id // 0) > 0)
        | "\(.address) \(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
    [ -n "$addr" ] || return
    local out="$dir/${addr#0x}.jpg"
    grim -s 0.3 -t jpeg -q 80 -g "$geom" "$out.$BASHPID" 2>/dev/null && mv -f "$out.$BASHPID" "$out"
}

grab_workspace() {
    local mon special id count
    read -r mon special < <(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | "\(.name) \(.specialWorkspace.id // 0)"')
    [ -n "$mon" ] && [ "$special" = 0 ] || return
    read -r id count < <(hyprctl activeworkspace -j 2>/dev/null | jq -r '"\(.id) \(.windows)"')
    [[ "$id" =~ ^[0-9]+$ ]] && (( id > 0 )) || return
    local out="$dir/ws-$id.jpg"
    grim -o "$mon" -s 0.3 -t jpeg -q 78 "$out.$BASHPID" 2>/dev/null || return
    [ "$count" = 0 ] && cp -f "$out.$BASHPID" "$dir/ws-empty.jpg"
    mv -f "$out.$BASHPID" "$out"
}

forget() {
    local name="$1"
    [[ "$name" =~ ^(ws-)?[0-9a-fA-F]+$ ]] || return
    find "$dir" -maxdepth 1 -type f -name "$name.jpg" -delete
}

shot() {
    sleep "$1"
    busy && return
    grab_window
    grab_workspace
}

fullscreen() {
    hyprctl activewindow -j 2>/dev/null | jq -e '(.fullscreen // 0) as $f | ($f == true) or (($f | type) == "number" and $f > 0)' >/dev/null
}

shot 0.2 &
(
    while true; do
        sleep 20 9>&-
        fullscreen || shot 0
    done
) &

socat -U - "UNIX-CONNECT:$sock" 9>&- | while IFS= read -r line; do
    case "$line" in
        "activewindowv2>>"*)
            shot 0.4 &
            ;;
        "workspacev2>>"*)
            [ -e "$flag" ] && "$here/overview.sh" close &
            shot 0.7 &
            ;;
        "closewindow>>"*)
            forget "${line#closewindow>>}"
            shot 0.5 &
            ;;
        "destroyworkspacev2>>"*)
            id="${line#destroyworkspacev2>>}"
            forget "ws-${id%%,*}"
            ;;
    esac
done
