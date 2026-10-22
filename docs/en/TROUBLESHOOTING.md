# Troubleshooting

[← Back to README](../../README.md) · [Español](../es/TROUBLESHOOTING.md)

Most HYPER·AERO pieces write a log to `$XDG_RUNTIME_DIR` (usually `/run/user/1000/`):

```bash
ls $XDG_RUNTIME_DIR/aero-*.log
```

`aero-phone.log`, `aero-desk.log`, `aero-studio.log`, `aero-carousel.log`, `aero-veil.log`, `aero-displays.log`, `aero-displays-ui.log`, `aero-snap.log`.

## Hyprland shows a red error bar, or starts with defaults

```bash
hyprctl configerrors
hyprctl version
```

- Version older than 0.56 → update: `sudo pacman -Syu`. HYPER·AERO needs the Lua config.
- The error points to `user.lua` → fix or empty that file, then `hyprctl reload`.

## No wallpaper (black or plain background)

```bash
ls ~/.config/hyper-aero/wallpapers/
aero-assets
~/.config/hyper-aero/scripts/wallpaper.sh restart
```

If `aero-assets` can't download, it generates the wallpapers locally (several minutes). Check that `mpvpaper` is installed: `command -v mpvpaper`.

## The phone, desk or a panel doesn't open

Restart that piece and read its log:

```bash
~/.config/hyper-aero/scripts/phone.sh restart
~/.config/hyper-aero/scripts/desk.sh restart
~/.config/hyper-aero/scripts/displays.sh restart
cat $XDG_RUNTIME_DIR/aero-phone.log
```

If `SUPER + R` opens rofi instead of the phone, Quickshell couldn't start the phone in time — the log says why. In the *Lite* profile the first opening takes a moment, that's expected.

## Icons look like empty boxes

A Nerd Font is missing:

```bash
sudo pacman -S --needed ttf-jetbrains-mono-nerd noto-fonts-emoji
fc-cache -f
```

Then log out and back in.

## External monitor stays black (dual-GPU laptop)

1. Check that the dedicated GPU driver works (NVIDIA: `nvidia-smi`).
2. Install the GPU session: `./install.sh --with-gpu-session --no-deps`.
3. Log out and pick **HYPER·AERO** in the login screen.
4. Press `SUPER + P` and choose a mode.

If the panel always shows only the laptop, look at `$XDG_RUNTIME_DIR/aero-displays.log`.

## Everything looks too big or too small

The installer picks a size from the laptop screen's resolution (125 % for 1080p, 150 % for 1440p/1600p, 200 % for 4K). To change it, press `SUPER + P` and choose another value under **SIZE ON THE LAPTOP** (for example 125 % on a 15" 1080p laptop). The choice is remembered.

At 150 % or more on a 1080p screen, the TELEMETRY HUD may not fit; use the slim HUD (`SUPER + H`) or a smaller size.

## Day and night switch at the wrong time

- Check your time zone: `timedatectl`.
- Set your location: `aero-location LAT LON`.
- `SUPER + ALT + T` cancels a manual override.

## Weather shows “--”

No internet, or wttr.in is down or rate-limiting you. It retries by itself. Check the city in `~/.config/hyper-aero/weather-location`.

## Wrong keyboard layout

Add to `~/.config/hypr/user.lua`:

```lua
hl.config({ input = { kb_layout = "latam" } })
```

Then `hyprctl reload`.

## It feels slow

1. `SUPER + F2` → **Lite**.
2. Hide heavy widgets (LYRICS, GIF, SPECTRA) or the whole desk (`SUPER + D`).
3. `top -o %CPU` and see what's on top. `mpvpaper` high → your GPU may lack video decoding support for H.264; the *Lite* profile uses a still image instead.
4. Make sure you're not in a VM without 3D acceleration.

More in [Performance](PERFORMANCE.md).

## Bluetooth or Wi-Fi panels are empty

```bash
sudo systemctl enable --now bluetooth NetworkManager
```

If you use `iwd` or `systemd-networkd` instead of NetworkManager, the Wi-Fi panel won't see your networks.

## I want my old desktop back

```bash
cd hyper-aero
./uninstall.sh
```

Your backups are in `~/.local/share/hyper-aero/backups/`.

## Reporting a bug

Open an issue with:

- `hyprctl version`
- your profile (`aero-profile`)
- the install log (`~/.local/share/hyper-aero/install-*.log`)
- the log of the piece that fails (`$XDG_RUNTIME_DIR/aero-*.log`)
- what you did, what you expected, what happened, and a screenshot if possible
