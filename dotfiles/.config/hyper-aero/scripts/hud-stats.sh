#!/usr/bin/env bash

export LC_ALL=C
interval=2

temp_file=""
for h in /sys/class/hwmon/hwmon*; do
    if [ "$(cat "$h/name" 2>/dev/null)" = "coretemp" ] && [ -r "$h/temp1_input" ]; then
        temp_file="$h/temp1_input"
        break
    fi
done
if [ -z "$temp_file" ]; then
    for z in /sys/class/thermal/thermal_zone*; do
        if [ "$(cat "$z/type" 2>/dev/null)" = "x86_pkg_temp" ]; then
            temp_file="$z/temp"
            break
        fi
    done
fi

eval "$("$HOME/.config/hyper-aero/scripts/hw-info.sh")"
igpu_file=""
igpu_max_file=""
igpu_busy=""
if [ -n "$HW_IGPU_CARD" ]; then
    if [ -r "$HW_IGPU_CARD/gt_act_freq_mhz" ]; then
        igpu_file="$HW_IGPU_CARD/gt_act_freq_mhz"
        igpu_max_file="$HW_IGPU_CARD/gt_max_freq_mhz"
    elif [ -r "$HW_IGPU_CARD/device/gpu_busy_percent" ]; then
        igpu_busy="$HW_IGPU_CARD/device/gpu_busy_percent"
    fi
fi
dgpu_file=""
[ -n "$HW_DGPU_SLOT" ] && dgpu_file="/sys/bus/pci/devices/$HW_DGPU_SLOT/power/runtime_status"
host_name=$(printf '%s' "$HW_HOST" | tr '[:lower:]' '[:upper:]' | tr -d '"\\')
bat_dir=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)

human_rate() {
    awk -v b="$1" 'BEGIN { if (b >= 1048576) printf "%.1f MB/s", b / 1048576; else printf "%.0f KB/s", b / 1024 }'
}

read_cpu() {
    read -r _ u n s i w x y z _ < /proc/stat
    cpu_total=$((u + n + s + i + w + x + y + z))
    cpu_idle=$((i + w))
}

net_if=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
read_net() {
    if [ -n "$net_if" ] && [ -r "/sys/class/net/$net_if/statistics/rx_bytes" ]; then
        rx=$(cat "/sys/class/net/$net_if/statistics/rx_bytes")
        tx=$(cat "/sys/class/net/$net_if/statistics/tx_bytes")
    else
        rx=0
        tx=0
    fi
}

read_cpu
prev_total=$cpu_total
prev_idle=$cpu_idle
read_net
prev_rx=$rx
prev_tx=$tx

while true; do
    sleep "$interval"

    read_cpu
    dt=$((cpu_total - prev_total))
    di=$((cpu_idle - prev_idle))
    if [ "$dt" -gt 0 ]; then
        cpu=$(( (100 * (dt - di)) / dt ))
    else
        cpu=0
    fi
    prev_total=$cpu_total
    prev_idle=$cpu_idle

    if [ -n "$temp_file" ]; then
        cpu_temp=$(( $(cat "$temp_file") / 1000 ))
    else
        cpu_temp=0
    fi

    cpu_freq=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null \
        | awk '{ s += $1; n++ } END { if (n) printf "%.2f", s / n / 1000000; else printf "0.00" }')
    load=$(cut -d' ' -f1 /proc/loadavg)

    read -r mem mem_used mem_total < <(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2}
        END { printf "%d %.1f %.1f", (t - a) * 100 / t, (t - a) / 1048576, t / 1048576 }' /proc/meminfo)

    read -r disk_used disk_total disk < <(df -h / | awk 'NR==2 { gsub("%", "", $5); print $3, $2, $5 }')

    if [ -n "$igpu_file" ]; then
        igpu_mhz=$(cat "$igpu_file")
        igpu_max=$(cat "$igpu_max_file" 2>/dev/null)
        igpu_max=${igpu_max:-1400}
        igpu_pct=$(( igpu_mhz * 100 / igpu_max ))
    elif [ -n "$igpu_busy" ]; then
        igpu_pct=$(cat "$igpu_busy" 2>/dev/null || echo 0)
        igpu_mhz=$(awk '/\*/ { gsub("Mhz", "", $2); print $2; exit }' "$HW_IGPU_CARD/device/pp_dpm_sclk" 2>/dev/null)
        igpu_mhz=${igpu_mhz:-0}
    else
        igpu_mhz=0
        igpu_pct=0
    fi

    if [ -n "$dgpu_file" ]; then
        dgpu=$(cat "$dgpu_file" 2>/dev/null)
        dgpu=${dgpu:-unknown}
    else
        dgpu="none"
    fi

    read_net
    down=$(( (rx - prev_rx) / interval ))
    up=$(( (tx - prev_tx) / interval ))
    [ "$down" -lt 0 ] && down=0
    [ "$up" -lt 0 ] && up=0
    prev_rx=$rx
    prev_tx=$tx
    net_down=$(human_rate "$down")
    net_up=$(human_rate "$up")
    net_down_kb=$(( down / 1024 ))

    bat=0
    bat_status="AC"
    bat_watts="0.0"
    bat_time="--"
    if [ -n "$bat_dir" ]; then
        bat=$(cat "$bat_dir/capacity" 2>/dev/null || echo 0)
        status=$(cat "$bat_dir/status" 2>/dev/null)
        case "$status" in
            Charging)     bat_status="CHARGING" ;;
            Discharging)  bat_status="ON BATTERY" ;;
            Full)         bat_status="FULL" ;;
            *)            bat_status="AC" ;;
        esac
        p_uw=$(cat "$bat_dir/power_now" 2>/dev/null)
        if [ -z "$p_uw" ]; then
            c=$(cat "$bat_dir/current_now" 2>/dev/null)
            v=$(cat "$bat_dir/voltage_now" 2>/dev/null)
            p_uw=$(( ${c:-0} * ${v:-0} / 1000000 ))
        fi
        bat_watts=$(awk -v p="$p_uw" 'BEGIN { printf "%.1f", p / 1000000 }')
        if [ "$status" = "Discharging" ] && [ "$p_uw" -gt 0 ] && [ -r "$bat_dir/energy_now" ]; then
            e_uwh=$(cat "$bat_dir/energy_now")
            mins=$(( e_uwh * 60 / p_uw ))
            bat_time=$(printf '%dh %02dm' $((mins / 60)) $((mins % 60)))
        fi
    fi

    read -r up_s _ < /proc/uptime
    up_s=${up_s%.*}
    uptime=$(printf '%02d:%02d' $((up_s / 3600)) $((up_s % 3600 / 60)))

    printf '{"cpu":%d,"cpu_temp":%d,"cpu_freq":"%s","load":"%s","mem":%d,"mem_used":"%s","mem_total":"%s","disk":%d,"disk_used":"%s","disk_total":"%s","igpu_mhz":%d,"igpu_pct":%d,"dgpu":"%s","net_if":"%s","net_down":"%s","net_up":"%s","net_down_kb":%d,"bat":%d,"bat_status":"%s","bat_watts":"%s","bat_time":"%s","uptime":"%s","host":"%s","cpu_short":"%s","igpu_name":"%s","dgpu_name":"%s"}\n' \
        "$cpu" "$cpu_temp" "$cpu_freq" "$load" "$mem" "$mem_used" "$mem_total" "$disk" "$disk_used" "$disk_total" \
        "$igpu_mhz" "$igpu_pct" "$dgpu" "${net_if:-none}" "$net_down" "$net_up" "$net_down_kb" \
        "$bat" "$bat_status" "$bat_watts" "$bat_time" "$uptime" "$host_name" "$HW_CPU_SHORT" "$HW_IGPU" "$HW_DGPU"
done
