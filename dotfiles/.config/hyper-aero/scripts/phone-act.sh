#!/usr/bin/env bash

S="$HOME/.config/hyper-aero/scripts"

case "$1" in
    wifi)
        if [ "$(nmcli radio wifi)" = "enabled" ]; then nmcli radio wifi off; else nmcli radio wifi on; fi
        ;;
    wifi-menu)
        sleep 0.35
        exec "$S/wifi-menu.sh"
        ;;
    wifi-advanced)
        sleep 0.35
        exec "$S/wifi-menu.sh" advanced
        ;;
    bt)
        if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
            bluetoothctl power off
        else
            rfkill unblock bluetooth 2>/dev/null
            bluetoothctl power on
        fi
        ;;
    bt-menu)
        sleep 0.35
        exec "$S/phone.sh" bluetooth
        ;;
    accent-*)
        exec "$S/night-deck.py" accent "${1#accent-}"
        ;;
    studio)
        "$S/phone.sh" close >/dev/null 2>&1
        exec "$S/studio.sh"
        ;;
    themes)
        "$S/phone.sh" close >/dev/null 2>&1
        sleep 0.25
        exec "$S/carousel.sh"
        ;;
    night)
        exec "$S/night-deck.py" toggle
        ;;
    warm)
        exec "$S/night-deck.py" warm toggle
        ;;
    dnd)
        exec swaync-client -d -sw
        ;;
    shot)
        sleep 0.6
        exec "$S/screenshot.sh" region
        ;;
    rec)
        exec "$S/screenrec.sh" toggle full
        ;;
    rec-region)
        exec "$S/screenrec.sh" toggle region
        ;;
    lock)
        sleep 0.35
        exec "$S/airlock.sh"
        ;;
    suspend)
        sleep 0.4
        exec systemctl suspend
        ;;
    reboot)
        exec systemctl reboot
        ;;
    poweroff)
        exec systemctl poweroff
        ;;
    bri)
        exec brightnessctl -q set "${2:-50}%"
        ;;
    *)
        echo "uso: phone-act.sh accent-NAME|wifi|wifi-menu|wifi-advanced|bt|bt-menu|night|warm|dnd|shot|rec|rec-region|lock|suspend|reboot|poweroff|bri N" >&2
        exit 1
        ;;
esac
