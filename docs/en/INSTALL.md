# Install

[← Back to README](../../README.md) · [Español](../es/INSTALL.md)

## Before you start

- **Arch Linux** (or an Arch-based distro that uses `pacman`), up to date: `sudo pacman -Syu`.
- A normal user with `sudo`. **Don't run the installer as root.**
- Internet access.
- Hyprland **0.56 or newer**. HYPER·AERO uses the new Lua config (`hyprland.lua`); older versions with `hyprland.conf` won't work.
- Check the [requirements](PERFORMANCE.md#requirements).

> HYPER·AERO replaces the config of Hyprland, Waybar, eww, kitty, rofi, swaync, cava, Starship and GTK. **Everything it touches is backed up first**, and `./uninstall.sh` puts it back.

## Quick install

```bash
sudo pacman -S --needed git
git clone https://github.com/jotaperom/hyper-aero.git
cd hyper-aero
./install.sh
```

What the installer does, step by step:

1. **Checks your hardware** (CPU threads, RAM, GPUs) and recommends a performance profile.
2. **Installs packages** from the official repos, plus `eww`, `mpvpaper` and `bibata-cursor-theme-bin` from the AUR. If you don't have `yay` or `paru`, it offers to install `yay`.
3. **Checks versions**: Hyprland ≥ 0.56, and that `qs`, `eww` and `mpvpaper` are available.
4. **Asks for a few settings**, with detected defaults:
   - keyboard layout (from `localectl`)
   - your approximate location for the day/night cycle (looked up once via `ipapi.co` — you can decline and type it, or leave it empty to estimate it from your time zone)
   - default browser and file manager are detected automatically
5. **Backs up** your current config to `~/.local/share/hyper-aero/backups/<date>/`.
6. **Copies the files** to `~/.config`, installs the fonts to `~/.local/share/fonts/hyper-aero`, and adds one line to your `~/.bashrc` or `~/.zshrc`.
7. **Downloads the wallpapers** (~36 MB) from the GitHub release.
8. Applies the profile and the GTK theme.

Then **log out and choose “Hyprland”** in your login screen. If you were already in Hyprland, press `SUPER + M` and log back in.

Everything printed is also saved in `~/.local/share/hyper-aero/install-<date>.log`.

The installer adds a few commands to your shell — `aero-profile`, `aero-assets`, `aero-location`. Open a new terminal to use them.

## Options

```text
./install.sh [options]

  --profile completo|equilibrado|ligero   performance profile (otherwise one is recommended)
  --yes                                   don't ask, use the detected values
  --no-deps                               don't install packages
  --no-assets                             don't download the wallpapers
  --location LAT LON                      location for the day/night cycle
  --with-login                            install the login screen (greetd + ReGreet)
  --with-gpu-session                      install the session for dual-GPU laptops
  -h, --help                              help
```

Examples:

```bash
./install.sh --profile ligero
./install.sh --location 40.42 -3.70
./install.sh --yes --profile equilibrado
```

## Packages

**Official repos:** hyprland hyprlock hypridle hyprsunset xdg-desktop-portal-hyprland quickshell waybar swaync rofi kitty mpv ffmpeg python python-numpy python-pillow jq socat curl playerctl cava grim slurp wf-recorder wl-clipboard brightnessctl networkmanager bluez bluez-utils pipewire pipewire-pulse wireplumber libnotify starship zenity pciutils glib2 nano pavucontrol imagemagick xdg-utils ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji papirus-icon-theme adw-gtk-theme qt6-declarative qt6-svg

**AUR:** eww mpvpaper bibata-cursor-theme-bin

If a package from the first list is missing from your mirrors (for example `quickshell` on some setups), the installer tries the AUR instead.

To install them yourself and skip that step:

```bash
sudo pacman -S --needed hyprland hyprlock hypridle ...   # the list above
yay -S --needed eww mpvpaper bibata-cursor-theme-bin
./install.sh --no-deps
```

## Wallpapers

The installer downloads `hyper-aero-wallpapers.tar.gz` from the `assets-v1` release. If that fails (no internet, GitHub down), it **generates them on your computer** instead — same result, takes several minutes.

To retry later:

```bash
aero-assets            # download, or generate if the download fails
aero-assets --build    # always generate locally
```

## Optional: login screen

```bash
./install.sh --with-login
```

Installs `greetd` + `ReGreet` with a HYPER·AERO look (day and night). **It replaces your current display manager** (GDM, SDDM, LightDM…); the installer disables it and remembers which one it was, so uninstalling turns it back on.

## Optional: dual-GPU laptops

Some laptops (many gaming models) wire the HDMI port to the dedicated NVIDIA/AMD GPU. Without help, Hyprland may not show anything on an external monitor.

```bash
./install.sh --with-gpu-session
```

Adds an *HYPER·AERO* session (pick it in your login screen) and a udev rule that make Hyprland use the right GPU. The installer offers it automatically when it finds two GPUs. You still need working drivers (for NVIDIA: `nvidia-open` or `nvidia`, see the [Arch wiki](https://wiki.archlinux.org/title/NVIDIA)).

## Updating

```bash
cd hyper-aero
git pull
./install.sh
```

Reinstalling keeps your **first** backup as the one `uninstall.sh` restores, and keeps your notes, desk layout, custom themes and `user.lua`.

## Uninstall

```bash
cd hyper-aero
./uninstall.sh
```

It:

- stops HYPER·AERO's background processes;
- asks if you want to keep the wallpapers (copied to `~/hyper-aero-fondos`);
- restores every config folder from the original backup, and removes the ones that didn't exist before;
- removes the line from `~/.bashrc` / `~/.zshrc`, the fonts and the Studio launcher;
- if you installed them: turns your old display manager back on and removes the login screen and the GPU session.

Packages are left installed, since other programs may use them. To remove them:

```bash
sudo pacman -Rns quickshell eww mpvpaper hyprsunset swaync cava wf-recorder starship   # pick what you don't need
```

The backups stay in `~/.local/share/hyper-aero/backups/` until you delete them.

## Trying it safely

If you want to test without touching your account, create a new user and install there:

```bash
sudo useradd -m -G wheel prueba
sudo passwd prueba
```

Log in as `prueba` and follow the quick install.
