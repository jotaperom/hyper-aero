#!/usr/bin/env bash

cache="${XDG_RUNTIME_DIR:-/tmp}/aero-hw.env"
if [ -s "$cache" ] && [ "$1" != "--fresh" ]; then
    cat "$cache"
    exit 0
fi

short_gpu() {
    local slot="$1" text inner
    text=$(lspci -s "$slot" 2>/dev/null | head -n1 | sed 's/^[^ ]* [^:]*: //; s/ (rev [0-9a-f]*)$//')
    inner=$(printf '%s' "$text" | sed -n 's/.*\[\([^]]*\)\].*/\1/p' | tail -n1)
    [ -n "$inner" ] && text="$inner"
    text=${text/Corporation /}
    text=${text#GeForce }
    text=${text% Mobile}
    text=${text%%/*}
    case "$text" in
        *UHD*|*Iris*|*"HD Graphics"*) text="Intel ${text}" ;;
    esac
    printf '%s' "$text" | cut -c1-22
}

model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')
cpu=$(printf '%s' "$model" | grep -oE 'i[3579]-[0-9]+[A-Z]*|Ultra [0-9] [0-9]+[A-Z]*|Ryzen [0-9]+ (PRO )?[0-9]+[A-Z0-9]*|Celeron [A-Z0-9-]+|Pentium [A-Za-z0-9 -]+' | head -n1)
[ -z "$cpu" ] && cpu=$(printf '%s' "$model" | sed 's/([RrTtMm]*)//g; s/ CPU//; s/ Processor//; s/ @.*//; s/ with .*//; s/  */ /g' | awk '{ if ($1 == "Intel" || $1 == "AMD") $1 = ""; print }' | sed 's/^ *//' | cut -c1-18)
cpu_short=$(printf '%s' "$cpu" | awk '{print $1}')

igpu_card=""
igpu_slot=""
dgpu_slot=""
for c in /sys/class/drm/card[0-9]*; do
    case "$c" in *-*) continue ;; esac
    dev=$(readlink -f "$c/device")
    [ -r "$dev/class" ] || continue
    case "$(cat "$dev/class")" in 0x03*) ;; *) continue ;; esac
    slot=${dev##*/}
    if [ "$(cat "$dev/boot_vga" 2>/dev/null)" = 1 ] && [ -z "$igpu_slot" ]; then
        igpu_slot=$slot
        igpu_card=$c
    elif [ -z "$dgpu_slot" ]; then
        dgpu_slot=$slot
    fi
done
if [ -z "$igpu_slot" ] && [ -n "$dgpu_slot" ]; then
    igpu_slot=$dgpu_slot
    dgpu_slot=""
fi

igpu_name=$( [ -n "$igpu_slot" ] && short_gpu "$igpu_slot")
dgpu_name=$( [ -n "$dgpu_slot" ] && short_gpu "$dgpu_slot")

{
    printf 'HW_HOST=%q\n' "$(cat /proc/sys/kernel/hostname)"
    printf 'HW_CPU=%q\n' "${cpu:-CPU}"
    printf 'HW_CPU_SHORT=%q\n' "${cpu_short:-CPU}"
    printf 'HW_IGPU=%q\n' "${igpu_name:-GPU}"
    printf 'HW_IGPU_CARD=%q\n' "$igpu_card"
    printf 'HW_IGPU_SLOT=%q\n' "$igpu_slot"
    printf 'HW_DGPU=%q\n' "$dgpu_name"
    printf 'HW_DGPU_SLOT=%q\n' "$dgpu_slot"
} > "$cache.tmp" && mv "$cache.tmp" "$cache"
cat "$cache"
