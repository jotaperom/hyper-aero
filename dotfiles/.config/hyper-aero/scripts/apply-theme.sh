#!/usr/bin/env bash

iface=org.gnome.desktop.interface

gsettings set $iface color-scheme 'prefer-light'
gsettings set $iface gtk-theme 'adw-gtk3'
gsettings set $iface icon-theme 'Papirus-Light'
gsettings set $iface cursor-theme 'Bibata-Modern-Ice'
gsettings set $iface cursor-size 24
gsettings set $iface font-name 'Exo 2 10'
gsettings set $iface document-font-name 'Exo 2 11'
gsettings set $iface monospace-font-name 'JetBrainsMono Nerd Font 10'
gsettings set $iface accent-color 'blue' 2>/dev/null || true

hyprctl setcursor Bibata-Modern-Ice 24

echo "HYPER-AERO theme applied."
