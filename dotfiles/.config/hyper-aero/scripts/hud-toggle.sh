#!/usr/bin/env bash

if eww active-windows | grep -q '^telemetry:'; then
    eww close telemetry
    "$HOME/.config/hyper-aero/scripts/aero-eww" open telemetry-slim
else
    eww close telemetry-slim
    "$HOME/.config/hyper-aero/scripts/aero-eww" open telemetry
fi
