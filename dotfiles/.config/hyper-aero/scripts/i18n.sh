declare -gA AERO_T=()
if [ "$(cat "$HOME/.config/hyper-aero/lang" 2>/dev/null)" = en ] && [ -f "$HOME/.config/hyper-aero/i18n/current.sh" ]; then
    . "$HOME/.config/hyper-aero/i18n/current.sh"
fi

t() {
    local v="${AERO_T[$1]-}"
    printf '%s' "${v:-$1}"
}

tf() {
    local f
    f=$(t "$1")
    shift
    printf "$f" "$@"
}
