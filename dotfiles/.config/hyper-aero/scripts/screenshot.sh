#!/usr/bin/env bash

dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Imágenes")/Capturas"
mkdir -p "$dir"
file="$dir/captura-$(date +%Y%m%d-%H%M%S).png"

case "${1:-region}" in
    region)
        pidof slurp >/dev/null && exit 0
        geom=$(slurp -b 0b0d1240 -c 1446c2ff -s 3d9be926 -w 2 -B 0b0d1240) || exit 0
        grim -g "$geom" "$file" || exit 1
        label="Zona capturada"
        ;;
    window)
        geom=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        [ -z "$geom" ] || [ "$geom" = "null,null nullxnull" ] && exit 1
        grim -g "$geom" "$file" || exit 1
        label="Ventana capturada"
        ;;
    full)
        grim "$file" || exit 1
        label="Pantalla capturada"
        ;;
esac

wl-copy --type image/png < "$file"
notify-send -a "SIGNAL" -i "$file" "$label" "Copiada al portapapeles · guardada en Capturas"
