# Changelog

## 2.0.10

**Fixed**

- Workspace pills (01–05) no longer leave helper processes behind when Waybar restarts; each helper now exits as soon as the bar closes it. Thanks to @Pix3lM0on (#4).
- The pill helper test runs in CI (`tools/tests/test_ws_pill.py`).

## 2.0.9

**Security**

- CI installs its Python tools from a hash-locked list (`tools/ci-requirements.txt`) and only from prebuilt wheels.
- The wallpaper builder no longer takes an output path from the command line: it writes to `build/wallpapers` in the project, or to your wallpaper folder with `--user`.
- Downloads in `aero-update` and the wallpaper fetcher refuse anything that isn't HTTPS, including redirects.

## 2.0.8

**Security**

- Asset generators in `tools/` only write inside the project, your home folder or the temp folder (for the wallpaper builder), and refuse any other output path.
- The media widget names its cover art cache with SHA-256 instead of MD5.

## 2.0.7

**Security**

- CI workflow runs with read-only permissions, pins its actions to exact commits and doesn't keep the checkout token.
- Theme fingerprints and the lyrics cache use SHA-256 instead of SHA-1.
- Python helpers no longer fall back to the shared `/tmp` folder when `XDG_RUNTIME_DIR` is missing; they use `~/.cache/hyper-aero`.

## 2.0.6

**Changed**

- Calmer, smoother music waves on the window outline: longer and lower waves, softer motion, no sharp peaks.

## 2.0.5

**Fixed**

- The music-reactive outline, click ripples and the Peek corner no longer show on top of the screensaver.

## 2.0.4

**Fixed**

- The music-reactive outline gets its soft glow back, rendered only on the strips around the window.
- Aero Peek (bottom-right corner) turns off blur and shadows while peeking, so windows really turn into clear outlines instead of frosted panes.
- Display panel (`SUPER + P`): the arrangement board is always there when a monitor is connected (outside Extend it tells you to pick Extend), the panel scrolls on short screens, and a slow or out-of-order state read no longer blanks it.
- Region screenshots (`SUPER + SHIFT + S`) freeze the screen while you select, like Windows (needs `hyprpicker`).

## 2.0.3

**Changed**

- The music-reactive outline now fades out of the old window and into the new one when you switch focus, instead of sliding across the screen.

**Performance**

- The outline is drawn on four thin strips around the window instead of a full-screen layer, with no live blur. The compositor only redraws those strips.
- Window tracking follows Hyprland events instead of polling `hyprctl` seven times a second.
- Weather effects pause while windows cover the desktop.

## 2.0.2

**Changed**

- Music-reactive borders: the window outline itself now ripples like a waveform. Strong waves run along the bottom with a warm glow in the center, and softer waves run along the top and sides. The bars are gone.

## 2.0.1

**Fixed**

- Weather effects (fog, rain, clouds) blurred a band across the middle of the wallpaper. They now draw on their own layer without blur.
- The music-reactive borders and ripples no longer blur what's behind them.

## 2.0.0

**New**

- **Control Panel** (`SUPER + O`) with every setting in one place, and a **Welcome Center** on the first start.
- **Aero effects**: music-reactive window borders, Aero Ripple, Aero Peek, Aero Shake, Flip 3D (`SUPER + ALT + TAB`) and a **radial quick menu** (`SUPER + Z` / `SUPER + middle click`).
- **Weather on the desktop**: rain, drizzle, storms, snow, fog and clouds following the real weather.
- **NEXUS audio panel**: output and input devices, volume per device and per app.
- **Pin apps to the dock** by dragging, in NEXUS and on the desk DOCK widget.
- **Word-by-word lyrics** in the LYRICS widget.
- **Clipboard history**, **emoji picker** and **color picker** (`SUPER + SHIFT + V`, `SUPER + .`, `SUPER + SHIFT + C`).
- **.aerotheme** files to share themes made in the Studio.
- **Automatic profiles**: Lite while a game is fullscreen (on by default) or on battery (off by default).
- **`aero-update`** with a daily update check, and **`aero-doctor`** for bug reports.
- Automatic checks on GitHub for every push (shell, Python, Lua, QML, JSON, translations and simulations of the window-drag logic).

**Changed**

- New packages: `cliphist` and `hyprpicker`.
- The user.lua example in the docs moved from `SUPER + O` (now the Control Panel) to `SUPER + SHIFT + O`.

## 1.2.3

- Fixed `SUPER + drag` to another desktop dying after a while: every click left a small timer running in Hyprland, and after enough clicks they piled up and broke the feature (and wasted CPU). Now a single timer is reused and fully stopped between drags.

## 1.2.2

- `SUPER + drag` to another desktop works reliably on Hyprland 0.57: the new keybind system silently swallowed the mouse release, so the window was never moved. The end of the drag is now detected three independent ways, and the dragged window is moved by its address, even if focus changes.
- Works on both Hyprland 0.56 and 0.57.

## 1.2.1

- Fixed a config error on recent Hyprland versions (`hl.bind: mouse is exclusive`) that also stopped `SUPER + drag` from sending windows to another desktop.

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
