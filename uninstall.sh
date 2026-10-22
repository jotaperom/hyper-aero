#!/usr/bin/env bash

A="$HOME/.config/hyper-aero"
INFO="$A/.install.json"

if [ -f "$A/scripts/i18n.sh" ]; then
    . "$A/scripts/i18n.sh"
else
    t() { printf '%s' "$1"; }
fi

say()  { printf '\033[38;2;61;155;233m◢\033[0m %s\n' "$*"; }
warn() { printf '\033[38;2;240;180;76m!\033[0m %s\n' "$*"; }

backup=""
[ -f "$INFO" ] && backup=$(jq -r '.backup // empty' "$INFO" 2>/dev/null)
if [ -z "$backup" ] || [ ! -f "$backup/manifest" ]; then
    backup=$(ls -d "$HOME"/.local/share/hyper-aero/backups/* 2>/dev/null | sort | head -n1)
fi
[ -n "$backup" ] && [ -f "$backup/manifest" ] || { echo "$(t "No encontré el respaldo de la instalación.")"; exit 1; }

say "$(t "Voy a restaurar tu configuración desde") $backup"
if [ -t 0 ]; then
    read -r -p "$(t "¿Seguimos? (s/n) [s]: ")" ans
    case "${ans:-s}" in s|S|y|Y) ;; *) exit 0 ;; esac
fi

for p in "qs -c aero-" "aero-displays.py daemon" "motion-guard.py" "night-deck.py daemon" "desk-feed.py" "hud-stats.sh" "hud-visualizer.sh"; do
    pkill -f "$p" 2>/dev/null
done
pkill -f "mpvpaper.*aero-motion.sock" 2>/dev/null

if [ -d "$A/wallpapers" ] && [ -t 0 ]; then
    read -r -p "$(t "¿Conservo tus fondos generados en otra carpeta (~/hyper-aero-fondos)? (s/n) [s]: ")" keep
    case "${keep:-s}" in s|S|y|Y) mkdir -p "$HOME/hyper-aero-fondos" && cp -a "$A/wallpapers/." "$HOME/hyper-aero-fondos/" ;; esac
fi

while read -r kind rel; do
    [ -z "$rel" ] && continue
    case "$kind" in
        saved)
            rm -rf "${HOME:?}/$rel"
            mkdir -p "$(dirname "$HOME/$rel")"
            cp -a "$backup/$rel" "$HOME/$rel"
            ;;
        new)
            rm -rf "${HOME:?}/$rel"
            ;;
        rc)
            sed -i '/hyper-aero\/shell\/hyper-aero/d' "$HOME/$rel"
            ;;
        dm)
            sudo systemctl enable "$rel" >/dev/null 2>&1 && say "$(t "Reactivé") $rel"
            ;;
        login)
            sudo systemctl disable greetd >/dev/null 2>&1
            last=$(ls /etc/greetd/config.toml.pre-hyper-aero-* 2>/dev/null | sort | tail -n1)
            [ -n "$last" ] && sudo cp -a "$last" /etc/greetd/config.toml
            sudo rm -f /etc/greetd/hyprland.lua /etc/greetd/aero-greet.sh /etc/greetd/aero-sun.py /etc/greetd/regreet*.toml /etc/greetd/regreet*.css
            sudo rm -rf /usr/share/backgrounds/hyper-aero
            warn "$(t "Si no tenías otro gestor de inicio de sesión, activá uno antes de reiniciar (por ejemplo: sudo systemctl enable sddm).")"
            ;;
        gpu)
            sudo rm -f /etc/udev/rules.d/99-hyper-aero-gpu.rules /usr/local/bin/hyper-aero-session /usr/share/wayland-sessions/hyper-aero.desktop
            sudo udevadm control --reload
            ;;
    esac
done < "$backup/manifest"

for f in .bashrc .zshrc; do
    [ -f "$HOME/$f" ] && sed -i '/hyper-aero\/shell\/hyper-aero/d' "$HOME/$f"
done
rm -rf "$HOME/.local/share/fonts/hyper-aero" "$HOME/.local/share/applications/aero-studio.desktop"
fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1

say "$(t "Listo. Cerrá sesión y volvé a entrar para usar tu configuración de antes.")"
say "$(t "Los paquetes instalados se quedan; si querés quitarlos, la lista está en docs/es/INSTALL.md (sección Desinstalar).")"
rmdir "$HOME/.config/quickshell" 2>/dev/null
