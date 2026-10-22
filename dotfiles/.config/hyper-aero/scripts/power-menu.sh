#!/usr/bin/env bash

choice=$(printf '%s\n' "Lock" "Log out" "Suspend" "Reboot" "Shut down" \
    | rofi -dmenu -i -no-custom -p "SYSTEM" -theme-str '
        window        { width: 340px; }
        mainbox       { children: [ box-header, inputbar, listview ]; }
        textbox-title { content: "SYSTEM // POWER"; }
        inputbar      { children: [ textbox-orb, prompt, entry ]; }
        entry         { placeholder: "Choose an action"; font: "Exo 2 12"; }
        listview      { columns: 1; lines: 5; }
        element       { orientation: horizontal; padding: 10px 16px; }
        element-text  { horizontal-align: 0; font: "Exo 2 12"; }
    ')

case "$choice" in
    "Lock")      __HOME__/.config/hyper-aero/scripts/airlock.sh ;;
    "Log out")   hyprctl dispatch 'hl.dsp.exit()' ;;
    "Suspend")   systemctl suspend ;;
    "Reboot")    systemctl reboot ;;
    "Shut down") systemctl poweroff ;;
esac
