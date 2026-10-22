#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${1:-$HERE/build/wallpapers}"
OUT="${2:-$HERE/build/hyper-aero-wallpapers.tar.gz}"

FILES=(aero-motion.mp4 aero-motion.jpg aero-motion-night.mp4 aero-motion-night.jpg
       aero-red-day.mp4 aero-red-day.jpg aero-red-night.mp4 aero-red-night.jpg
       aero-green-day.mp4 aero-green-day.jpg aero-green-night.mp4 aero-green-night.jpg
       aero-black-day.mp4 aero-black-day.jpg aero-black-night.mp4 aero-black-night.jpg
       aero-saver.mp4 bg.jpg bg-night.jpg)

for f in "${FILES[@]}"; do
    [ -f "$SRC/$f" ] || { echo "Falta $SRC/$f — corré primero: python3 tools/build-wallpapers.py"; exit 1; }
done
mkdir -p "$(dirname "$OUT")"
tar -C "$SRC" -czf "$OUT" "${FILES[@]}"
echo "Listo: $OUT ($(du -h "$OUT" | cut -f1))"
