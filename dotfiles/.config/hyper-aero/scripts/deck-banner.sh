#!/usr/bin/env bash

cobalt=$'\e[38;2;20;70;194m'
blue=$'\e[38;2;30;111;217m'
graph=$'\e[38;2;90;98;112m'
rule=$'\e[38;2;154;163;174m'
ok=$'\e[38;2;15;123;90m'
warn=$'\e[38;2;168;101;10m'
if [ "$(cat "$HOME/.config/hyper-aero/theme/mode" 2>/dev/null)" = night ]; then
    cobalt=$'\e[38;2;111;211;255m'
    blue=$'\e[38;2;61;155;233m'
    graph=$'\e[38;2;139;151;171m'
    rule=$'\e[38;2;74;90;120m'
    ok=$'\e[38;2;61;220;151m'
    warn=$'\e[38;2;240;180;76m'
fi
[ -f "$HOME/.config/hyper-aero/theme/current/banner.env" ] && . "$HOME/.config/hyper-aero/theme/current/banner.env"
bold=$'\e[1m'
reset=$'\e[0m'

host=$(cat /proc/sys/kernel/hostname)
kernel=$(uname -r | cut -d- -f1)
read -r up _ < /proc/uptime
up=${up%.*}
uptime_fmt=$(printf '%dh %02dm' $((up / 3600)) $((up % 3600 / 60)))
eval "$("$HOME/.config/hyper-aero/scripts/hw-info.sh")"
cpu=${HW_CPU:-unknown}
mem=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%.1f/%.1fG", (t-a)/1048576, t/1048576}' /proc/meminfo)
disk=$(LC_ALL=C df -h / | awk 'NR==2 {print $3 "/" $2}')
dgpu_state=""
[ -n "$HW_DGPU_SLOT" ] && dgpu_state=$(cat "/sys/bus/pci/devices/$HW_DGPU_SLOT/power/runtime_status" 2>/dev/null)
dgpu_state=${dgpu_state:-active}

if [ "$dgpu_state" = "suspended" ]; then
    dgpu="${ok}idle${reset}"
else
    dgpu="${warn}${dgpu_state}${reset}"
fi

line=$(printf '─%.0s' $(seq 1 62))

row() {
    printf "  ${graph}%-7s${reset}${bold}%-14s${reset}${graph}%-7s${reset}${bold}%-14s${reset}${graph}%-7s${reset}%b\n" "$1" "$2" "$3" "$4" "$5" "$6"
    sleep 0.03
}

printf "\n  ${cobalt}${bold}◢ HYPER·AERO${reset}  ${graph}DECK TERMINAL · v1${reset}                ${blue}[ SYS ONLINE ]${reset}\n"
printf "  ${rule}%s${reset}\n" "$line"
sleep 0.03
row "HOST"  "$host"      "KERNEL" "$kernel" "UPTIME" "${bold}${uptime_fmt}${reset}"
row "CPU"   "$cpu"       "MEM"    "$mem"    "DISK"   "${bold}${disk}${reset}"
if [ -n "$HW_DGPU" ]; then
    row "GPU"   "${HW_IGPU:0:13}" "dGPU" "${HW_DGPU:0:13}" "STATE" "$dgpu"
else
    row "GPU"   "${HW_IGPU:0:13}" "" "" "STATE" "${ok}ok${reset}"
fi
printf "  ${rule}%s${reset}\n\n" "$line"
