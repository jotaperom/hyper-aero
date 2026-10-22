#!/usr/bin/env bash

id="$1"
label=$(printf '%02d' "$id")
sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

emit() {
    active=$(hyprctl activeworkspace -j | jq -r '.id')
    windows=$(hyprctl workspaces -j | jq -r --argjson id "$id" '[.[] | select(.id == $id) | .windows] | add // 0')
    if [ "$active" = "$id" ]; then
        class="active"
    elif [ "$windows" -gt 0 ]; then
        class="occupied"
    else
        class="empty"
    fi
    printf '{"text":"%s","class":"%s","tooltip":"Workspace %s · %s windows"}\n' "$label" "$class" "$id" "$windows"
}

emit

socat -u "UNIX-CONNECT:$sock" - | while read -r line; do
    case "$line" in
        workspace*|createworkspace*|destroyworkspace*|movewindow*|openwindow*|closewindow*|focusedmon*)
            emit
            ;;
    esac
done
