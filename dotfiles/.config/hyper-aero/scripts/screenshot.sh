#!/usr/bin/env bash

. "$HOME/.config/hyper-aero/scripts/i18n.sh"

dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Imágenes")/$(t "Capturas")"
mkdir -p "$dir"
file="$dir/$(t "captura")-$(date +%Y%m%d-%H%M%S).png"

case "${1:-region}" in
    region)
        pidof slurp >/dev/null && exit 0
        freeze=""
        if command -v hyprpicker >/dev/null; then
            hyprpicker -r -z >/dev/null 2>&1 &
            freeze=$!
            sleep 0.15
        fi
        unfreeze() { [ -n "$freeze" ] && kill "$freeze" 2>/dev/null; true; }
        geom=$(slurp -b 0b0d1240 -c 1446c2ff -s 3d9be926 -w 2 -B 0b0d1240) || { unfreeze; exit 0; }
        grim -g "$geom" "$file"
        rc=$?
        unfreeze
        [ "$rc" = 0 ] || exit 1
        label="$(t "Zona capturada")"
        ;;
    window)
        geom=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        [ -z "$geom" ] || [ "$geom" = "null,null nullxnull" ] && exit 1
        grim -g "$geom" "$file" || exit 1
        label="$(t "Ventana capturada")"
        ;;
    full)
        grim "$file" || exit 1
        label="$(t "Pantalla capturada")"
        ;;
esac

wl-copy --type image/png < "$file"
notify-send -a "SIGNAL" -i "$file" "$label" "$(t "Copiada al portapapeles · guardada en Capturas")"
