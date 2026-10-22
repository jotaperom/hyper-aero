# Performance and requirements

[← Back to README](../../README.md) · [Español](../es/PERFORMANCE.md)

## Requirements

|  | Minimum | Recommended |
|---|---|---|
| OS | Arch Linux or Arch-based (`pacman`) | Arch Linux, up to date |
| Hyprland | 0.56 (Lua config) | latest |
| CPU | 4 threads, x86_64 | 8 threads or more |
| RAM | 8 GB | 16 GB |
| GPU | any GPU with working Wayland drivers | recent Intel/AMD integrated graphics, or a dedicated GPU |
| Disk | 1 GB free | 2 GB free |
| Screen | 1366 × 768 (some panels feel tight) | 1920 × 1080 or higher |
| Profile | *Lite* | *Balanced* or *Full* |

Notes:

- **NVIDIA as the only GPU** works with the proprietary or open driver, but Hyprland on NVIDIA needs extra setup — see the [Hyprland wiki](https://wiki.hypr.land/Nvidia/).
- **Virtual machines** without 3D acceleration are not supported: blur and the animated wallpaper fall back to CPU rendering and become very slow.
- On **battery**, the animated wallpaper pauses itself below 50 %.

## Where the resources go

Measured on the author's laptop (12-thread laptop CPU, integrated Intel graphics, 1080p at 144 Hz) with everything on, before the optimizations in this release. `%CPU` is per core, as `top` shows it.

| Component | CPU | What it is |
|---|---|---|
| Hyprland | 8–15 % | Blur, shadows, glow and animations |
| mpvpaper | 5–10 % | Animated wallpaper video decoding |
| Desk (Quickshell) | 2.5–5 % | Widgets |
| cava | 2.5–5 % | Audio visualizer |
| Whole desktop | ~2 GB RAM | Including all the background services |

The profiles below target exactly those costs.

## Profiles

Switch at any time with `SUPER + F2`, or from a terminal:

```bash
aero-profile               # show the current profile
aero-profile list
aero-profile lite          # or: balanced, full
```

The change applies right away, no logout needed.

|  | Full | Balanced | Lite |
|---|---|---|---|
| Wallpaper | animated | animated | still image |
| Wallpaper pauses when | a window is fullscreen | windows cover the screen | — |
| Blur | strong (3 passes) | medium (2 passes) | light (1 pass) |
| Shadows | large | small | off |
| Window glow | on | off | off |
| Animated border | on | off | off |
| Inactive windows | slightly transparent | almost opaque | opaque |
| Workspace animation | slide + fade | slide + fade | fade |
| Visualizer | 24 fps | 15 fps | off |
| Desk widgets refresh | 30 fps | 20 fps | 12 fps |
| Theme / day-night transition | on | on | off |
| Phone and transitions kept in memory | yes | yes | no (open on demand) |
| Recommended for | 8+ threads, dedicated or strong integrated GPU | most computers | 4 threads, 8 GB, older GPUs, battery |

What “kept in memory” means: in *Full* and *Balanced* the NEXUS phone and the transition layer stay loaded so they appear instantly. In *Lite* they start when you open them (a short delay) and use no memory otherwise.

## Things that always help

- The **animated wallpaper also pauses on battery** below 50 %, and while the screensaver is running.
- `SUPER + SHIFT + D` pauses the wallpaper by hand; it stays paused until you press it again.
- The **visualizer** only runs while music is playing.
- Hide desk widgets you don't use (`SUPER + ALT + D`). **LYRICS**, **GIF** and **SPECTRA** are the heaviest ones.
- `SUPER + D` hides the whole desk.
- With a **dual-GPU laptop**, the integrated GPU handles the laptop screen; only an external monitor wired to the dedicated GPU uses it.

## Checking it yourself

```bash
top -o %CPU
```

Look for `Hyprland`, `mpvpaper`, `qs`, `eww` and `cava`. If one of them stays high with the desktop idle, see [Troubleshooting](TROUBLESHOOTING.md#it-feels-slow).
