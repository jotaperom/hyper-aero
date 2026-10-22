#!/usr/bin/env bash

run="${XDG_RUNTIME_DIR:-/tmp}"
dir="$run/aero-thumbs"
flag="$run/aero-overview.open"
fallback="/usr/share/backgrounds/hyper-aero/aero-login.jpg"

close() {
    rm -f "$flag"
    eww close overview >/dev/null 2>&1
}

case "$1" in
    close)
        close
        exit 0
        ;;
    escape)
        [ -e "$flag" ] && close
        exit 0
        ;;
    go|send)
        [[ "$2" =~ ^[0-9]+$ ]] || exit 1
        close
        if [ "$1" = go ]; then
            hyprctl dispatch "hl.dsp.focus({ workspace = $2 })" >/dev/null
        else
            hyprctl dispatch "hl.dsp.window.move({ workspace = $2 })" >/dev/null
        fi
        exit 0
        ;;
esac

if eww active-windows 2>/dev/null | grep -q '^overview:'; then
    close
    exit 0
fi

mkdir -p "$dir"

app_dirs=()
for d in "$HOME/.local/share/applications" /usr/share/applications \
         "$HOME/.local/share/flatpak/exports/share/applications" /var/lib/flatpak/exports/share/applications; do
    [ -d "$d" ] && app_dirs+=("$d")
done

resolve_icon() {
    local class="$1" file="" icon="" d
    for d in "${app_dirs[@]}"; do
        if [ -f "$d/$class.desktop" ]; then file="$d/$class.desktop"; break; fi
        if [ -f "$d/${class,,}.desktop" ]; then file="$d/${class,,}.desktop"; break; fi
    done
    if [ -z "$file" ] && (( ${#app_dirs[@]} )); then
        file=$(grep -rlixF --include='*.desktop' -- "StartupWMClass=$class" "${app_dirs[@]}" 2>/dev/null | head -n 1)
    fi
    [ -n "$file" ] && icon=$(grep -m 1 '^Icon=' "$file" | cut -d= -f2-)
    if [ -z "$icon" ] || [[ "$icon" == /* ]]; then
        icon="application-x-executable"
    fi
    printf '%s' "$icon"
}

ws_json=$(hyprctl workspaces -j)
cl_json=$(hyprctl clients -j)
active=$(hyprctl activeworkspace -j | jq '.id')

icons_json=$(
    jq -r '[.[] | select(.workspace.id > 0) | .class] | unique | .[]' <<< "$cl_json" \
    | while IFS= read -r class; do
        printf '%s\t%s\n' "$class" "$(resolve_icon "$class")"
    done \
    | jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | {(.[0]): .[1]}) | add // {}'
)

snap="$dir/ov-$EPOCHSECONDS-$$"
mkdir -p "$snap"
find "$dir" -mindepth 1 -maxdepth 1 -type d -name 'ov-*' ! -path "$snap" -exec rm -r {} +
cp -f "$dir"/ws-*.jpg "$snap"/ 2>/dev/null

shots_json=$(
    for f in "$snap"/ws-*.jpg; do
        [ -f "$f" ] || continue
        n="${f##*/ws-}"
        n="${n%.jpg}"
        [[ "$n" =~ ^[0-9]+$ ]] && printf '%s\n' "$n"
    done | jq -s '.'
)

if [ -f "$snap/ws-empty.jpg" ]; then
    empty="$snap/ws-empty.jpg"
elif [ -f "$fallback" ]; then
    empty="$fallback"
else
    empty=""
fi

state=$(jq -n -c \
    --argjson ws "$ws_json" --argjson cl "$cl_json" --argjson active "$active" \
    --argjson icons "$icons_json" --argjson shots "$shots_json" \
    --arg snap "$snap" --arg empty "$empty" '
    ([range(1; 6)] + [$ws[] | select(.id > 0) | .id] | unique) as $ids
    | ($ids | length) as $total
    | (if $total <= 6 then {c: 3, w: 320, h: 180}
       elif $total <= 8 then {c: 4, w: 256, h: 144}
       else {c: 4, w: 224, h: 126} end) as $g
    | [$cl[] | select(.workspace.id > 0 and .mapped == true)] as $live
    | ($ids | map(
        . as $id
        | ([$live[] | select(.workspace.id == $id)] | sort_by(.focusHistoryID)) as $wins
        | ($wins | length) as $n
        | {
            id: $id,
            label: (if $id < 10 then "0\($id)" else "\($id)" end),
            active: ($id == $active),
            windows: $n,
            state: (if $id == $active then "● CURRENT"
                    elif $n == 0 then "EMPTY"
                    elif $n == 1 then "1 WINDOW"
                    else "\($n) WINDOWS" end),
            shot: (if $n > 0 and ($shots | index($id)) != null then "\($snap)/ws-\($id).jpg" else $empty end),
            title: (if $n == 0 then "Free sector" else ($wins[0].title // $wins[0].class) end),
            apps: ($wins | map(.class) | reduce .[] as $c ([]; if index([$c]) then . else . + [$c] end)
                   | .[:5] | map($icons[.] // "application-x-executable"))
          })) as $cards
    | {
        rows: [range(0; $total; $g.c) as $i | $cards[$i:$i + $g.c]],
        w: $g.w,
        h: $g.h,
        meta: "\($total) SECTORS  ·  \($live | length) WINDOWS"
      }')

[ -n "$state" ] || exit 1

eww update \
    ov_rows="$(jq -c '.rows' <<< "$state")" \
    ov_w="$(jq '.w' <<< "$state")" \
    ov_h="$(jq '.h' <<< "$state")" \
    ov_meta="$(jq -r '.meta' <<< "$state")"
read -r mw mh rl rt < <(hyprctl monitors -j | jq -r '
    .[] | select(.focused)
    | (if ((.transform // 0) % 2) == 1 then [.height, .width] else [.width, .height] end) as $px
    | "\(($px[0] / .scale) | round) \(($px[1] / .scale) | round) \(.reserved[0] // 0) \(.reserved[1] // 0)"')

touch "$flag"
ewwx="$HOME/.config/hyper-aero/scripts/aero-eww"
[ -x "$ewwx" ] || ewwx=eww
if [[ "$mw$mh$rl$rt" =~ ^[0-9]+$ ]]; then
    "$ewwx" open overview --anchor "top left" --pos="-${rl}x-${rt}" --size="${mw}x${mh}" >/dev/null 2>&1 || rm -f "$flag"
else
    "$ewwx" open overview >/dev/null 2>&1 || rm -f "$flag"
fi
