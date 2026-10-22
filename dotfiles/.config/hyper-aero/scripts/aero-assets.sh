#!/usr/bin/env bash

. "$HOME/.config/hyper-aero/scripts/i18n.sh"

A="$HOME/.config/hyper-aero"
WALL="$A/wallpapers"
INFO="$A/.install.json"
TAG="assets-v1"
FILE="hyper-aero-wallpapers.tar.gz"

say() { printf '\033[38;2;61;155;233m◢\033[0m %s\n' "$*"; }

repo=$(jq -r '.repo // empty' "$INFO" 2>/dev/null)
src=$(jq -r '.source // empty' "$INFO" 2>/dev/null)
mkdir -p "$WALL"

have() {
    [ -f "$WALL/aero-motion.mp4" ] && [ -f "$WALL/aero-motion.jpg" ]
}

from_dir() {
    [ -d "$1" ] || return 1
    cp -f "$1"/*.mp4 "$1"/*.jpg "$WALL"/ 2>/dev/null
    have
}

download() {
    [ -n "$repo" ] || return 1
    tmp=$(mktemp -d)
    url="https://github.com/$repo/releases/download/$TAG/$FILE"
    say "$(t "Descargando fondos:") $url"
    if curl -fL --progress-bar -o "$tmp/$FILE" "$url"; then
        tar -xzf "$tmp/$FILE" -C "$WALL" && rm -rf "$tmp" && have && return 0
    fi
    rm -rf "$tmp"
    return 1
}

build() {
    [ -n "$src" ] && [ -f "$src/tools/build-wallpapers.py" ] || return 1
    say "$(t "Generando los fondos en esta compu (tarda varios minutos)…")"
    python3 "$src/tools/build-wallpapers.py" "$WALL"
}

case "${1:-auto}" in
    --build|build)
        build
        ;;
    *)
        have && { say "$(t "Los fondos ya están instalados")"; exit 0; }
        from_dir "$src/assets/wallpapers" || download || build
        ;;
esac

if have; then
    say "$(t "Fondos listos en") $WALL"
    pgrep -f "mpvpaper.*aero-motion.sock" >/dev/null && "$A/scripts/wallpaper.sh" restart
    exit 0
fi
say "$(t "No pude conseguir los fondos. Probá:") $A/scripts/aero-assets.sh --build"
exit 1
