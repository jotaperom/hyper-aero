#!/usr/bin/env bash

. "$HOME/.config/hyper-aero/scripts/i18n.sh"

A="$HOME/.config/hyper-aero"
RUN="${XDG_RUNTIME_DIR:-/tmp}"
SOCK="$RUN/aero-motion.sock"
OPTS="no-audio loop hwdec=auto-safe image-display-duration=inf input-ipc-server=$SOCK"

path() {
    p="$("$A/scripts/night-deck.py" wallpath 2>/dev/null)"
    [ -f "$p" ] || p="$A/wallpapers/aero-motion.mp4"
    [ -f "$p" ] || p="$A/wallpapers/aero-motion.jpg"
    printf '%s' "$p"
}

start() {
    p="$(path)"
    if [ ! -f "$p" ]; then
        notify-send -a "HYPER·AERO" "$(t "Falta el fondo")" "$(t "Corré:") ~/.config/hyper-aero/scripts/aero-assets.sh" 2>/dev/null
        exit 1
    fi
    rm -f "$SOCK"
    setsid -f mpvpaper -o "$OPTS" ALL "$p" >/dev/null 2>&1 </dev/null
}

case "${1:-start}" in
    start)
        pgrep -f "mpvpaper.*aero-motion.sock" >/dev/null && exit 0
        start
        ;;
    restart)
        pkill -f "mpvpaper.*aero-motion.sock"
        for _ in $(seq 1 20); do
            pgrep -f "mpvpaper.*aero-motion.sock" >/dev/null || break
            sleep 0.1
        done
        start
        ;;
    path)
        path
        echo
        ;;
    *)
        echo "uso: wallpaper.sh start|restart|path"
        exit 1
        ;;
esac
