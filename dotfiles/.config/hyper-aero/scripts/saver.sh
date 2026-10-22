#!/usr/bin/env bash

A="$HOME/.config/hyper-aero"
video="$A/wallpapers/aero-saver.mp4"
run="${XDG_RUNTIME_DIR:-/tmp}"
flag="$run/aero-saver.on"
sock="$run/aero-motion.sock"

ipc() {
    [ -S "$sock" ] || return 1
    printf '%s\n' "$1" | socat -t 1 - "UNIX-CONNECT:$sock" 2>/dev/null
}

fullscreen() {
    hyprctl activewindow -j 2>/dev/null | jq -e '(.fullscreen // 0) as $f | ($f == true) or (($f | type) == "number" and $f > 0)' >/dev/null
}

low_battery() {
    for b in /sys/class/power_supply/BAT*; do
        [ -d "$b" ] || continue
        [ "$(cat "$b/status" 2>/dev/null)" = Discharging ] && [ "$(cat "$b/capacity" 2>/dev/null)" -lt 30 ] && return 0
    done
    return 1
}

launch() {
    touch "$flag"
    if [ "$(ipc '{"command":["get_property","pause"]}' | jq -r 'select(has("data")) | .data | tostring' 2>/dev/null | head -n 1)" = false ]; then
        ipc '{"command":["set_property","pause",true]}' >/dev/null
        echo resume > "$flag"
    fi
    opts="no-audio loop hwdec=auto-safe"
    case "$(cat "$A/theme/accent" 2>/dev/null)" in
        red) opts="no-audio loop hwdec=auto-copy-safe vf=lavfi=[hue=h=135]" ;;
        green) opts="no-audio loop hwdec=auto-copy-safe vf=lavfi=[hue=h=-53:s=0.75]" ;;
        black) opts="no-audio loop hwdec=auto-copy-safe vf=lavfi=[hue=s=0]" ;;
    esac
    mpvpaper -l overlay -o "$opts" ALL "$video" >/dev/null 2>&1 &
    sleep 0.8
    [ -e "$flag" ] && "$HOME/.config/hyper-aero/scripts/aero-eww" open saver-clock >/dev/null 2>&1
}

stop() {
    eww close saver-clock >/dev/null 2>&1
    pkill -f "mpvpaper.*aero-saver.mp4"
    if grep -q resume "$flag" 2>/dev/null; then
        ipc '{"command":["set_property","pause",false]}' >/dev/null
    fi
    rm -f "$flag"
}

case "$1" in
    start)
        [ -e "$flag" ] && exit 0
        [ -f "$video" ] || exit 0
        [ -e "$A/saver-off" ] && exit 0
        pidof hyprlock >/dev/null && exit 0
        fullscreen && exit 0
        low_battery && exit 0
        launch
        ;;
    stop)
        stop
        ;;
    preview)
        [ -f "$video" ] || exit 1
        stop
        launch
        sleep "${2:-15}"
        stop
        ;;
    on)
        rm -f "$A/saver-off"
        notify-send -a "SIGNAL" "Protector de pantalla" "Activado · aparece tras 2 minutos sin uso" -u low
        ;;
    off)
        touch "$A/saver-off"
        stop
        notify-send -a "SIGNAL" "Protector de pantalla" "Desactivado" -u low
        ;;
    *)
        echo "uso: saver.sh [start|stop|preview [segundos]|on|off]"
        exit 1
        ;;
esac
