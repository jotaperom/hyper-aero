#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_GH="${1:-}"
ASSETS="${2:-$HERE/build/hyper-aero-wallpapers.tar.gz}"
NAME="hyper-aero"

[ -n "$USER_GH" ] || { echo "uso: tools/publish.sh TU_USUARIO_DE_GITHUB [ruta/hyper-aero-wallpapers.tar.gz]"; exit 1; }
command -v git >/dev/null || { echo "Instalá git: sudo pacman -S git"; exit 1; }
command -v gh >/dev/null || { echo "Instalá GitHub CLI: sudo pacman -S github-cli"; exit 1; }
[ -f "$ASSETS" ] || { echo "No encuentro $ASSETS"; exit 1; }
[ -f "$HERE/assets/screenshots/desktop.png" ] || { echo "Falta la captura principal: assets/screenshots/desktop.png"; exit 1; }
gh auth status >/dev/null 2>&1 || gh auth login
gh auth setup-git

cd "$HERE"
sed -i "s|^UPSTREAM=.*|UPSTREAM=\"$USER_GH/$NAME\"|" install.sh
grep -rlF "USUARIO/hyper-aero" README.md README.es.md docs 2>/dev/null | xargs -r sed -i "s|USUARIO/hyper-aero|$USER_GH/$NAME|g" || true

if [ ! -d .git ]; then
    git init -b main
fi
[ -n "$(git config user.name)" ] || git config user.name "$USER_GH"
[ -n "$(git config user.email)" ] || git config user.email "$USER_GH@users.noreply.github.com"
git add -A
git diff --cached --quiet || git commit -m "HYPER·AERO 1.0.0"

if ! gh repo view "$USER_GH/$NAME" >/dev/null 2>&1; then
    gh repo create "$USER_GH/$NAME" --public --source . --remote origin \
        --description "Frutiger Aero / Y2K rice for Hyprland 0.56+ (Lua config) on Arch Linux"
fi
git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$USER_GH/$NAME.git"
git push -u origin main

if gh release view assets-v1 >/dev/null 2>&1; then
    gh release upload assets-v1 "$ASSETS" --clobber
else
    gh release create assets-v1 "$ASSETS" --title "Wallpapers v1" \
        --notes "Original animated wallpapers for HYPER·AERO. The installer downloads this file automatically."
fi
echo
echo "Publicado: https://github.com/$USER_GH/$NAME"
