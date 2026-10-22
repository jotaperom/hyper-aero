#!/usr/bin/env bash

printf '%s\n' \
    "SUPER + R              NEXUS phone (apps)" \
    "SUPER + X              NEXUS phone (control)" \
    "SUPER + I              Hoy: reloj, clima y nota (phone)" \
    "SUPER + SHIFT + R      NEXUS classic (rofi)" \
    "SUPER + Q              DECK terminal" \
    "SUPER + B              Browser" \
    "SUPER + E              Files" \
    "SUPER + C              Close window" \
    "SUPER + V              Float / tile window" \
    "SUPER + P              Pantallas: duplicar, extender, posición" \
    "SUPER + SHIFT + P      Pseudo-tile window" \
    "SUPER + J              Flip split direction" \
    "SUPER + ARROWS         Move focus" \
    "ALT + TAB              Switch windows (hold ALT, tap TAB)" \
    "SUPER + TAB            Workspace overview" \
    "SUPER + 1…0            Go to workspace" \
    "SUPER + SHIFT + 1…0    Send window to workspace" \
    "SUPER + S              Show scratchpad" \
    "SUPER + ALT + S        Send window to scratchpad" \
    "SUPER + SHIFT + S      Screenshot of a region" \
    "PRINT                  Screenshot of the whole screen" \
    "SUPER + PRINT          Screenshot of the active window" \
    "SUPER + ALT + R        Record screen start / stop" \
    "SUPER + ALT + SHIFT + R Record a region" \
    "SUPER + SCROLL         Cycle workspaces" \
    "SUPER + LEFT DRAG      Move window" \
    "SUPER + RIGHT DRAG     Resize window" \
    "SUPER + H              TELEMETRY full / slim" \
    "SUPER + N              SIGNAL notification center" \
    "SUPER + SHIFT + N      Silent running on / off" \
    "SUPER + SHIFT + B      Hide / show AEROBAR" \
    "SUPER + L              AIRLOCK" \
    "SUPER + A              Bluetooth (phone)" \
    "SUPER + W              Wi-Fi (phone)" \
    "SUPER + SHIFT + W      Wi-Fi classic (rofi)" \
    "SUPER + D              Desktop widgets on / off" \
    "SUPER + ALT + D        Edit desktop (grid)" \
    "SUPER + T              NIGHT DECK on / off" \
    "SUPER + G              Temas (carrusel)" \
    "SUPER + SHIFT + T      Warm light on / off" \
    "SUPER + ALT + T        Day / night automatic" \
    "SUPER + SHIFT + D      Motion wallpaper play / pause" \
    "SUPER + M              Exit Hyprland" \
    "SUPER+drag to edge/01-05 Move window to desktop" \
    "SUPER+CTRL+SHIFT+arrows Move window to desktop" \
    "SUPER + F1             This keymap" \
    "SUPER + F2             Performance profile" \
    "MEDIA KEYS             Play / pause / skip" \
    "FN + F-KEYS            Volume and brightness" \
    "NEXUS · CTRL + TAB     Apps / Run / Windows" \
    "DECK · CTRL+SHIFT+A M  More frost" \
    "DECK · CTRL+SHIFT+A L  Less frost" \
    | rofi -dmenu -i -no-custom -p "KEYS" -theme-str '
        window        { width: 600px; }
        mainbox       { children: [ box-header, inputbar, listview ]; }
        textbox-title { content: "NEXUS // KEYMAP"; }
        inputbar      { children: [ textbox-orb, prompt, entry ]; }
        entry         { placeholder: "Filter keybindings"; font: "Exo 2 12"; }
        listview      { columns: 1; lines: 14; spacing: 2px; }
        element       { orientation: horizontal; padding: 6px 14px; border-radius: 10px; }
        element-icon  { size: 0; }
        element-text  { horizontal-align: 0; font: "JetBrainsMono Nerd Font 10"; }
    ' >/dev/null
