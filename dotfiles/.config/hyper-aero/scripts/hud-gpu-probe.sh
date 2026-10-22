#!/usr/bin/env bash

. "$HOME/.config/hyper-aero/scripts/i18n.sh"

eval "$("$HOME/.config/hyper-aero/scripts/hw-info.sh")"
[ -n "$HW_DGPU_SLOT" ] || exit 0
before=$(cat "/sys/bus/pci/devices/$HW_DGPU_SLOT/power/runtime_status" 2>/dev/null)
if command -v nvidia-smi >/dev/null; then
    info=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,power.draw,memory.used --format=csv,noheader 2>&1 | head -n1)
    IFS=',' read -r temp util power mem <<< "$info"
    body=$(printf "$(t 'Estado antes: %s\nTemp %s · Carga %s\nPotencia %s · VRAM %s')" "${before:-?}" "$temp" "$util" "$power" "$mem")
else
    body=$(printf "$(t 'Estado: %s')" "${before:-?}")
fi
notify-send -a "TELEMETRY" "$HW_DGPU · probe" "$body"
