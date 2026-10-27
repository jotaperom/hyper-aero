# Changelog

## 1.2.0

- Every monitor has its own desk with its own widgets. The editor (`SUPER + ALT + D`) opens on the screen the mouse is on. Your old layout moves to the main screen automatically.
- Opening or closing TELEMETRY no longer changes the saved widget layout.
- The mouse moves freely between monitors: screens are always placed edge to edge, including setups with three or more monitors and desktops without a laptop.
- Desktops with several monitors get their own displays panel: a size for each screen, where TELEMETRY goes, and swap left/right.
- Monitors start at their best resolution and refresh rate, with a size based on their real pixel density.
- Dragging a window to another desktop (`SUPER + drag`) works reliably: it no longer misses windows that weren't focused, a slightly shaky hand at the edge doesn't cancel it, and with several monitors the edges between screens no longer flash the desktop switch.
- `SUPER + F` toggles fullscreen and `SUPER + SHIFT + F` maximizes.
- The installer warns about LightDM, which can leave mouse and keyboard dead after login. New troubleshooting entries for both issues.

## 1.1.0

- The interface is now bilingual: English and Spanish. The installer asks which one you want (`--lang en|es`), and `aero-lang en|es` switches it at any time.
- The installer and uninstaller speak both languages too.
- `tools/i18n-check.py` lists any text missing from the translation table.
- Desk widgets no longer flicker when TELEMETRY switches between full and slim: they glide to their new place together with the panel.
- `SUPER + H` keeps TELEMETRY on the monitor chosen in the displays panel.
- Profile names in English: Full, Balanced and Lite (`aero-profile full|balanced|lite`; the Spanish names still work).

## 1.0.0

- First public release.
