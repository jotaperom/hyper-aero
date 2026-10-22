#!/usr/bin/env bash

D="$HOME/.config/hyper-aero/desk"
G="$D/gifs"
STATE="$D/gif.json"
mkdir -p "$G"

fit_now() {
    python3 -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get("fit","cover"))
except Exception: print("cover")' "$STATE"
}

set_file() {
    src="$1"
    case "$src" in file://*) src="$(python3 -c 'import sys,urllib.parse;print(urllib.parse.unquote(sys.argv[1][7:]))' "$src")" ;; esac
    if [ ! -f "$src" ]; then
        notify-send -a "DESK" "GIF" "No encontré ese archivo." 2>/dev/null
        exit 1
    fi
    case "${src,,}" in
        *.gif|*.webp|*.png|*.jpg|*.jpeg|*.apng) ;;
        *) notify-send -a "DESK" "GIF" "Ese archivo no es una imagen o GIF." 2>/dev/null; exit 1 ;;
    esac
    base="$(basename "$src")"
    name="$(date +%s)-${base//[^A-Za-z0-9._-]/_}"
    if [ "$(dirname "$(readlink -f "$src")")" = "$(readlink -f "$G")" ]; then
        name="$(basename "$src")"
    else
        cp -f "$src" "$G/$name"
    fi
    fit="$(fit_now)"
    python3 -c 'import json,sys
json.dump({"file": sys.argv[1], "fit": sys.argv[2], "paused": False}, open(sys.argv[3] + ".tmp", "w"))' "$G/$name" "$fit" "$STATE"
    mv -f "$STATE.tmp" "$STATE"
}

pick() {
    start="$HOME/Imágenes"
    [ -d "$start" ] || start="$HOME/Pictures"
    [ -d "$start" ] || start="$HOME"
    if command -v zenity >/dev/null; then
        f="$(zenity --file-selection --title="Elegí un GIF" --filename="$start/" --file-filter="Imágenes | *.gif *.GIF *.webp *.png *.jpg *.jpeg" 2>/dev/null)"
    elif command -v kdialog >/dev/null; then
        f="$(kdialog --getopenfilename "$start" "*.gif *.webp *.png *.jpg *.jpeg" 2>/dev/null)"
    elif command -v yad >/dev/null; then
        f="$(yad --file --title="Elegí un GIF" --filename="$start/" 2>/dev/null)"
    else
        xdg-open "$G" >/dev/null 2>&1 &
        notify-send -a "DESK" "GIF" "Arrastrá un GIF al widget, o instalá un selector: sudo pacman -S zenity" 2>/dev/null
        exit 0
    fi
    [ -n "$f" ] && set_file "$f"
}

case "${1:-pick}" in
    pick) pick ;;
    set) set_file "$2" ;;
    latest)
        latest="$(ls -t "$G" 2>/dev/null | head -n 1)"
        [ -n "$latest" ] && set_file "$G/$latest"
        ;;
    *) echo "uso: desk-gif.sh pick|set ARCHIVO|latest"; exit 1 ;;
esac
