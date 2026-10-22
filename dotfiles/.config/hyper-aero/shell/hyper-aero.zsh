if [[ -o interactive ]]; then
    [ -f "$HOME/.config/hyper-aero/theme/shell.sh" ] && . "$HOME/.config/hyper-aero/theme/shell.sh"
    if [ "$TERM" = "xterm-kitty" ] && [ -z "$AERO_NO_BANNER" ]; then
        "$HOME/.config/hyper-aero/scripts/deck-banner.sh"
    fi
    command -v starship >/dev/null && eval "$(starship init zsh)"
fi
alias aero-profile="$HOME/.config/hyper-aero/scripts/aero-profile"
alias aero-assets="$HOME/.config/hyper-aero/scripts/aero-assets.sh"
alias aero-location="$HOME/.config/hyper-aero/scripts/night-deck.py location"
alias aero-lang="$HOME/.config/hyper-aero/scripts/aero-lang"
