#!/usr/bin/env bash

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/aero-alttab.lock"
flock -n 9 || exit 0

dir="${XDG_RUNTIME_DIR:-/tmp}/aero-thumbs"

mapfile -t rows < <(hyprctl clients -j | jq -r '
    map(select(.mapped == true and (.hidden | not) and .workspace.id > 0))
    | sort_by(.focusHistoryID)
    | .[]
    | [.address, .class, .title, (.workspace.id | tostring)]
    | @tsv')

n=${#rows[@]}
(( n == 0 )) && exit 0

escape() {
    local s="$1"
    s=${s//&/'&amp;'}
    s=${s//</'&lt;'}
    s=${s//>/'&gt;'}
    printf '%s' "$s"
}

addrs=()
items=()
for row in "${rows[@]}"; do
    IFS=$'\t' read -r addr class title ws <<< "$row"
    addrs+=("$addr")
    thumb="$dir/${addr#0x}.jpg"
    if [ -f "$thumb" ]; then
        icon="$thumb"
    elif [[ "$class" =~ ^[A-Z] ]]; then
        icon="${class,,}"
    else
        icon="$class"
    fi
    name="${class##*.}"
    name="${name^}"
    short="$title"
    (( ${#short} > 34 )) && short="${short:0:33}…"
    label="<b>$(escape "$name")</b>  <span foreground='#5a6270'>· $(printf '%02d' "$ws")</span>"$'\n'"<span size='small'>$(escape "$short")</span>"
    items+=("$label" "$icon")
done

sel=0
if (( n > 1 )); then
    sel=1
    [ "$1" = "reverse" ] && sel=$(( n - 1 ))
fi

cols=$(( n < 5 ? n : 5 ))
lines=$(( (n + 4) / 5 ))
width=$(( cols * 206 + 56 ))

choice=$(printf '%s\0icon\x1f%s\x1e' "${items[@]}" | rofi -dmenu -sep $'\x1e' -eh 2 -markup-rows -show-icons -no-custom \
    -format i -selected-row "$sel" -p "SWITCH" \
    -kb-move-char-back "Control+b" -kb-move-char-forward "Control+f" \
    -kb-mode-next "" -kb-mode-previous "" -kb-row-tab "" \
    -kb-element-next "Alt+Tab,Tab,Right" -kb-element-prev "Alt+ISO_Left_Tab,ISO_Left_Tab,Left" \
    -kb-accept-entry "!Alt+Alt_L,!Alt_L,Return,KP_Enter" -kb-cancel "Escape,Alt+Escape" \
    -theme-str "
        window        { width: ${width}px; }
        mainbox       { children: [ box-header, listview ]; }
        textbox-title { content: \"NEXUS // SWITCH  ·  ${n} WINDOWS\"; }
        listview      { columns: ${cols}; lines: ${lines}; fixed-columns: true; spacing: 12px; padding: 14px 0 0 0; border: 0; }
        element       { orientation: vertical; padding: 12px 10px 10px 10px; spacing: 8px; border-radius: 18px; }
        element-icon  { size: 170px; horizontal-align: 0.5; }
        element-text  { horizontal-align: 0.5; font: \"Exo 2 10\"; }
    ")

[ -z "$choice" ] && exit 0
target="${addrs[$choice]}"
[ -z "$target" ] && exit 0

out=$(hyprctl dispatch "hl.dsp.focus({ window = 'address:${target}' })" 2>&1)
if [ "$out" != "ok" ]; then
    notify-send -a "SIGNAL" "Alt + Tab" "No pude enfocar la ventana: $out"
fi
