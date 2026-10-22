#!/usr/bin/env bash

. "$HOME/.config/hyper-aero/scripts/i18n.sh"

case "${1:-date}" in
    date)
        LC_TIME="$(t "es_ES.UTF-8")" date "+$(t "%A  ·  %d de %B")" | tr '[:lower:]' '[:upper:]'
        ;;
    hint)
        t "◢  HYPER·AERO  ·  STATION IDLE  ·  MOVÉ EL MOUSE PARA VOLVER"
        echo
        ;;
esac
