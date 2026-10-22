#!/usr/bin/env bash

A="$HOME/.config/hyper-aero"
CONF="$A/record.conf"
MODEF="$A/theme/mode"
RUN="${XDG_RUNTIME_DIR:-/tmp}/aero-rec"
STATE="$RUN/state"
LOG="$RUN/recorder.log"

AUDIO="system"
FPS=60
FORMAT="mp4"
DIR=""
[ -f "$CONF" ] && . "$CONF"

mkdir -p "$RUN"

PID=""
START=""
FILE=""
MODS=""

load_state() {
    PID=""; START=""; FILE=""; MODS=""
    [ -f "$STATE" ] && . "$STATE"
}

recording() {
    load_state
    [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null
}

note() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a "Grabación" "$@"
}

videos_dir() {
    if [ -n "$DIR" ]; then
        printf '%s\n' "$DIR"
        return
    fi
    local base
    base=$(xdg-user-dir VIDEOS 2>/dev/null)
    if [ -z "$base" ] || [ "$base" = "$HOME" ]; then
        base="$HOME/Vídeos"
    fi
    printf '%s\n' "$base/Grabaciones"
}

intel_node() {
    local n
    for n in /sys/class/drm/renderD*; do
        [ -r "$n/device/vendor" ] || continue
        if [ "$(cat "$n/device/vendor")" = "0x8086" ]; then
            printf '/dev/dri/%s\n' "${n##*/}"
            return
        fi
    done
}

focused_output() {
    hyprctl monitors -j 2>/dev/null | python3 -c '
import json, sys
try:
    m = json.load(sys.stdin)
except ValueError:
    m = []
pick = next((x for x in m if x.get("focused")), m[0] if m else {})
print(pick.get("name", ""))'
}

close_phone() {
    if pgrep -f "qs -c aero-phone$" >/dev/null 2>&1; then
        timeout 2 qs -c aero-phone ipc call phone close >/dev/null 2>&1
        sleep 0.5
    fi
}

unload_mods() {
    local m
    for m in $1; do
        pactl unload-module "$m" >/dev/null 2>&1
    done
}

audio_source() {
    MODS=""
    SRC=""
    command -v pactl >/dev/null 2>&1 || return
    local sink mic a b c
    sink=$(pactl get-default-sink 2>/dev/null)
    mic=$(pactl get-default-source 2>/dev/null)
    case "$AUDIO" in
        system)
            [ -n "$sink" ] && SRC="$sink.monitor"
            ;;
        mic)
            SRC="$mic"
            ;;
        both)
            [ -n "$sink" ] && [ -n "$mic" ] || { SRC="${sink:+$sink.monitor}"; return; }
            a=$(pactl load-module module-null-sink sink_name=aero_rec_mix sink_properties=device.description=AeroRecMix 2>/dev/null)
            [ -n "$a" ] || { SRC="$sink.monitor"; return; }
            b=$(pactl load-module module-loopback source="$sink.monitor" sink=aero_rec_mix latency_msec=30 2>/dev/null)
            c=$(pactl load-module module-loopback source="$mic" sink=aero_rec_mix latency_msec=30 2>/dev/null)
            pactl set-default-sink "$sink" >/dev/null 2>&1
            pactl set-default-source "$mic" >/dev/null 2>&1
            MODS="$c $b $a"
            SRC="aero_rec_mix.monitor"
            ;;
    esac
}

launch() {
    setsid wf-recorder "$@" </dev/null >"$LOG" 2>&1 &
    NEWPID=$!
    local i
    for i in 1 2 3 4 5 6 7 8; do
        sleep 0.2
        kill -0 "$NEWPID" 2>/dev/null || return 1
    done
    return 0
}

start() {
    local mode="${1:-full}"
    if recording; then
        echo "Ya estoy grabando: $FILE"
        return 0
    fi
    if ! command -v wf-recorder >/dev/null 2>&1; then
        note -u critical "Falta wf-recorder" "Instalalo con: sudo pacman -S wf-recorder"
        echo "Falta wf-recorder. Instalalo con: sudo pacman -S wf-recorder"
        return 1
    fi

    close_phone

    local where=()
    if [ "$mode" = "region" ]; then
        local geom
        geom=$(slurp -d 2>/dev/null)
        if [ -z "$geom" ]; then
            echo "Grabación cancelada."
            return 0
        fi
        where=(-g "$geom")
    else
        local out
        out=$(focused_output)
        [ -n "$out" ] && where=(-o "$out")
    fi

    local dir file
    dir=$(videos_dir)
    mkdir -p "$dir"
    file="$dir/Grabación_$(date +%Y-%m-%d_%H-%M-%S).$FORMAT"

    audio_source
    local audio=()
    [ -n "$SRC" ] && audio=("--audio=$SRC")

    local node
    node=$(intel_node)
    local ok=1
    if [ -n "$node" ]; then
        launch -f "$file" -r "$FPS" "${where[@]}" "${audio[@]}" -c h264_vaapi -d "$node" && ok=0
    fi
    if [ "$ok" -ne 0 ]; then
        rm -f "$file"
        launch -f "$file" -r "$FPS" "${where[@]}" "${audio[@]}" -c libx264 -p preset=veryfast -p crf=23 -x yuv420p && ok=0
    fi
    if [ "$ok" -ne 0 ]; then
        unload_mods "$MODS"
        rm -f "$file"
        local why
        why=$(tail -n 3 "$LOG" 2>/dev/null)
        note -u critical "No pude grabar" "${why:-wf-recorder se cerró al iniciar}"
        echo "No pude empezar la grabación. Detalle en $LOG"
        return 1
    fi

    {
        printf 'PID=%q\n' "$NEWPID"
        printf 'START=%q\n' "$(date +%s)"
        printf 'FILE=%q\n' "$file"
        printf 'MODS=%q\n' "$MODS"
    } > "$STATE"
    echo "Grabando la pantalla. Para detener: SUPER + ALT + R o clic en el indicador REC de la barra."
}

clock() {
    local t=$1
    if [ "$t" -ge 3600 ]; then
        printf '%d:%02d:%02d' $((t / 3600)) $((t % 3600 / 60)) $((t % 60))
    else
        printf '%02d:%02d' $((t / 60)) $((t % 60))
    fi
}

stop() {
    if ! recording; then
        rm -f "$STATE"
        echo "No hay ninguna grabación en curso."
        return 0
    fi
    local pid=$PID file=$FILE mods=$MODS start=$START
    kill -INT "$pid" 2>/dev/null
    local i
    for i in $(seq 1 50); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.2
    done
    kill -0 "$pid" 2>/dev/null && kill -TERM "$pid" 2>/dev/null
    unload_mods "$mods"
    rm -f "$STATE"
    local dur
    dur=$(clock $(( $(date +%s) - start )))
    if [ -s "$file" ]; then
        setsid -f "$0" _done "$file" "$dur" </dev/null >/dev/null 2>&1
        echo "Grabación guardada ($dur): $file"
    else
        note -u critical "La grabación quedó vacía" "Revisá $LOG"
        echo "La grabación quedó vacía. Detalle en $LOG"
        return 1
    fi
}

done_note() {
    local file=$1 dur=$2 icon="video-x-generic" thumb="$RUN/thumb.png" size act
    if command -v ffmpeg >/dev/null 2>&1; then
        rm -f "$thumb"
        ffmpeg -y -loglevel error -ss 0.4 -i "$file" -frames:v 1 -vf scale=360:-1 "$thumb" </dev/null >/dev/null 2>&1
        [ -s "$thumb" ] && icon="$thumb"
    fi
    size=$(du -h "$file" 2>/dev/null | cut -f1)
    command -v wl-copy >/dev/null 2>&1 && printf 'file://%s\n' "$file" | wl-copy --type text/uri-list
    command -v notify-send >/dev/null 2>&1 || return
    act=$(notify-send -a "Grabación" -i "$icon" -A open="Ver video" -A folder="Abrir carpeta" \
        "Grabación guardada" "${file##*/}"$'\n'"$dur · ${size:-?}")
    case "$act" in
        open) xdg-open "$file" >/dev/null 2>&1 & ;;
        folder) nautilus --select "$file" >/dev/null 2>&1 || xdg-open "${file%/*}" >/dev/null 2>&1 & ;;
    esac
}

status() {
    if recording; then
        printf '{"rec": true, "since": %s}\n' "$START"
    else
        printf '{"rec": false, "since": 0}\n'
    fi
}

bar() {
    local parent=$PPID last="" out pid start now el mode dot red label
    while :; do
        [ -d "/proc/$parent" ] || exit 0
        pid=""; start=""
        if [ -f "$STATE" ]; then
            while IFS='=' read -r k v; do
                case "$k" in
                    PID) pid=$v ;;
                    START) start=$v ;;
                esac
            done < "$STATE"
        fi
        if [ -n "$pid" ] && [ -n "$start" ] && [ -d "/proc/$pid" ]; then
            printf -v now '%(%s)T' -1
            el=$((now - start))
            mode=day
            [ -f "$MODEF" ] && read -r mode < "$MODEF"
            if [ "$mode" = "night" ]; then
                red="#ff5d6c"; label="#8b97ab"
            else
                red="#c4283b"; label="#5a6270"
            fi
            if [ $((el % 2)) -eq 0 ]; then dot="100%"; else dot="30%"; fi
            out="{\"text\": \"<span foreground='$red' alpha='$dot'>●</span> <span font_family='Exo 2' size='7680' weight='bold' foreground='$label' letter_spacing='1400'>REC</span> $(clock "$el")\", \"class\": \"rec\", \"tooltip\": \"Grabando la pantalla · clic para detener\"}"
        else
            out='{"text": "", "class": "idle", "tooltip": ""}'
        fi
        if [ "$out" != "$last" ]; then
            printf '%s\n' "$out" || exit 0
            last=$out
        fi
        sleep 1
    done
}

case "$1" in
    start)
        start "${2:-full}"
        ;;
    stop)
        stop
        ;;
    toggle)
        if recording; then stop; else start "${2:-full}"; fi
        ;;
    status)
        status
        ;;
    bar)
        bar
        ;;
    _done)
        done_note "$2" "$3"
        ;;
    *)
        echo "uso: screenrec.sh toggle [full|region] | start [full|region] | stop | status"
        exit 1
        ;;
esac
