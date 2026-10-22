<div align="center">

# ◢ HYPER·AERO

**A Frutiger Aero / Y2K desktop for Hyprland on Arch Linux**

Glossy glass, bubbles, animated skies and a phone-shaped control center — the optimistic computer future of 2005, running on a modern Wayland compositor.

[English](README.md) · [Español](README.es.md)

![Hyprland](https://img.shields.io/badge/Hyprland-0.56%2B%20(Lua)-3d9be9?style=flat-square)
![Arch](https://img.shields.io/badge/Arch%20Linux-only-1793d1?style=flat-square)
![License](https://img.shields.io/badge/license-GPL--3.0-3ddc97?style=flat-square)

</div>

![Desktop](assets/screenshots/desktop.png)

> The interface comes in **English and Spanish** — the installer asks which one you want, and `aero-lang en|es` switches it later.

## What's inside

| | |
|---|---|
| **Animated wallpapers** | Four original looping scenes (sky, coral sunset, lagoon, chrome), each with a day and a night version |
| **Themes** | Blue, red, green and black accents, light and dark modes, and your own custom themes made in the **Theme Studio** |
| **Day / night cycle** | Switches mode at your local sunrise and sunset, with a glassy transition |
| **NEXUS phone** | A phone-shaped control center (apps, Wi-Fi, Bluetooth, media, quick settings, today view) with 8 skins |
| **Desk widgets** | 13 draggable widgets: clock, player, sun/moon arc, weather, system, tasks, calendar, notes, visualizer, lyrics, GIF… |
| **TELEMETRY HUD** | A side panel with CPU, RAM, GPU, network and battery |
| **Displays panel** | Windows-style *Win + P*: laptop only, duplicate, extend, external only, and drag to arrange — automatic on plug / unplug |
| **Performance profiles** | *Full*, *Balanced* and *Lite*, switchable at any time |
| **Bilingual** | English or Spanish interface: the installer asks, and `aero-lang en\|es` switches it later |
| **Extras** | Lock screen, screensaver, alt-tab with previews, workspace overview, screenshots, screen recording, optional login screen |

See [Features](docs/en/FEATURES.md) for the full tour.

## Requirements

|  | Minimum | Recommended |
|---|---|---|
| OS | Arch Linux (or Arch-based with `pacman`) | Arch Linux, up to date |
| Hyprland | 0.56 (Lua config) | latest |
| CPU | 4 threads | 8 threads or more |
| RAM | 8 GB | 16 GB |
| GPU | any with working Wayland drivers | integrated Intel/AMD of the last ~6 years, or a dedicated GPU |
| Disk | 1 GB free | 2 GB free |
| Profile | *Lite* | *Balanced* or *Full* |

Details and measured usage: [Performance](docs/en/PERFORMANCE.md).

## Install

```bash
git clone https://github.com/jotaperom/hyper-aero.git
cd hyper-aero
./install.sh
```

The installer checks your hardware and recommends a profile, installs the packages (official repos + AUR through `yay`/`paru`), **backs up your current config**, copies the files, and downloads the wallpapers. Log out and choose **Hyprland** to start.

Full guide, options and manual steps: [Install](docs/en/INSTALL.md).

## First steps

| Keys | Action |
|---|---|
| `SUPER + F1` | Show every shortcut |
| `SUPER + R` | NEXUS phone (apps) |
| `SUPER + Q` | Terminal |
| `SUPER + G` | Theme carousel |
| `SUPER + T` | Day / night |
| `SUPER + P` | Displays |
| `SUPER + F2` | Performance profile |

All shortcuts: [Keybinds](docs/en/KEYBINDS.md).

## Uninstall

```bash
./uninstall.sh
```

Restores the backup made during install. See [Install → Uninstall](docs/en/INSTALL.md#uninstall).

## Documentation

- [Install](docs/en/INSTALL.md)
- [Features](docs/en/FEATURES.md)
- [Keybinds](docs/en/KEYBINDS.md)
- [Performance and requirements](docs/en/PERFORMANCE.md)
- [Customizing](docs/en/CUSTOMIZING.md)
- [Troubleshooting](docs/en/TROUBLESHOOTING.md)

## Privacy

HYPER·AERO has no telemetry and no AI features. It only goes online for:

- `ipapi.co` — once, during install, to suggest your location for the day/night cycle (you can refuse or type it yourself).
- `wttr.in` — weather for the widgets.
- `lrclib.net` — song lyrics for the lyrics widget, only while it's on the desk.
- GitHub — to download the wallpaper pack during install.

## Credits

- Fonts: [Exo 2](https://fonts.google.com/specimen/Exo+2) and [Michroma](https://fonts.google.com/specimen/Michroma), SIL Open Font License (see `assets/fonts`).
- Built on [Hyprland](https://hyprland.org), [Quickshell](https://quickshell.org), [eww](https://github.com/elkowar/eww), [Waybar](https://github.com/Alexays/Waybar), [mpvpaper](https://github.com/GhostNaN/mpvpaper), [swaync](https://github.com/ErikReider/SwayNotificationCenter), [rofi](https://github.com/davatorium/rofi), [kitty](https://sw.kovidgoyal.net/kitty/), [Starship](https://starship.rs) and [cava](https://github.com/karlstav/cava).
- Wallpapers, sounds and the phone's globe are generated procedurally by the scripts in `tools/` and are part of this project.

## License

[GPL-3.0](LICENSE)
