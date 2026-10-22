# Customizing

[← Back to README](../../README.md) · [Español](../es/CUSTOMIZING.md)

## The golden rule: `user.lua`

Put your own Hyprland changes in **`~/.config/hypr/user.lua`** (`SUPER + F12` opens it). It is loaded last, so it wins over everything else, and **the installer never overwrites it** when you update. Changes made directly in `hyprland.lua` are lost on the next `./install.sh`.

After saving, apply it with `hyprctl reload`. If something breaks, `hyprctl configerrors` tells you the line.

### Examples

```lua
hl.config({
    general = { gaps_in = 4, gaps_out = 8 },
    decoration = { rounding = 8 },
    input = { kb_layout = "es", natural_scroll = true, touchpad = { natural_scroll = true } },
})
```

### Keybinds

Add new shortcuts in `user.lua`:

```lua
hl.bind("SUPER + O", hl.dsp.exec_cmd("obsidian"))
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("kitty --class aero-float"))
```

Use a combination that isn't already taken (see [Keybinds](KEYBINDS.md)).

### Startup apps

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("nextcloud --background")
end)
```

## Default browser and file manager

The installer detects them. To change them later, run `./install.sh` again (it keeps your notes, themes, layout and `user.lua`), or bind your own keys in `user.lua`.

## Themes and colors

- `SUPER + G` — theme carousel.
- **Theme Studio** — open *Theme Studio* from the launcher (`SUPER + R`). From there you can:
  - choose any accent color;
  - pick one of your images and turn it into an animated wallpaper, adding layers (bubbles, waves, sparkles, bokeh, rays, caustics, petals, stars, flare, grid) with their amount and speed;
  - save the result as your own theme, which then shows up in the carousel.

Your themes live in `~/.config/hyper-aero/studio/themes.json`; your wallpapers in `~/.config/hyper-aero/wallpapers/`.

## Language

The interface is available in English and Spanish:

```bash
aero-lang en      # English
aero-lang es      # Español
aero-lang         # show the current one
```

Everything switches right away; the phone, desk and panels restart for a second.

## Location (day / night and weather)

The day/night cycle uses your latitude and longitude:

```bash
aero-location 40.42 -3.70
```

(Search “*your city* coordinates” to find them. South and West are negative.)

The weather widgets use the city in `~/.config/hyper-aero/weather-location`. Leave it empty to let wttr.in guess from your connection:

```bash
echo "Madrid" > ~/.config/hyper-aero/weather-location
```

## Performance profile

`SUPER + F2` or `aero-profile lite|balanced|full`. See [Performance](PERFORMANCE.md).

The profile writes `~/.config/hypr/aero-profile.lua` (blur, shadows, animations). Settings in `user.lua` still win over it.

## Phone skin

`SUPER + X` → **SKIN**. Eight skins; the choice is saved in `~/.config/hyper-aero/phone-skin`.

## Desk

- `SUPER + ALT + D` opens the editor: add widgets from the tray, drag them on the grid, resize from the corner.
- Right-click a widget for its options.
- The layout is saved in `~/.config/hyper-aero/desk/layout.json`.

## Terminal

- `CTRL + SHIFT + A`, then `M` / `L` — more or less transparency.
- Set `AERO_NO_BANNER=1` in your shell config to hide the startup banner.
- The prompt is [Starship](https://starship.rs): `~/.config/starship.toml`.

## Displays

`SUPER + P` covers most needs. The panel writes its rules to `~/.config/hypr/aero-displays.lua`; don't edit that file, it is regenerated.

## Files at a glance

| Path | What |
|---|---|
| `~/.config/hypr/hyprland.lua` | Main Hyprland config (overwritten on update) |
| `~/.config/hypr/user.lua` | **Your** changes (kept) |
| `~/.config/hyper-aero/scripts/` | All the helper scripts |
| `~/.config/hyper-aero/theme/` | Theme files for each mode and accent |
| `~/.config/hyper-aero/wallpapers/` | Wallpapers |
| `~/.config/quickshell/aero-*` | Phone, desk, studio, carousel, displays, transitions |
| `~/.config/eww/` | TELEMETRY HUD |
| `~/.config/waybar/` | Bar |
| `~/.local/share/hyper-aero/` | Install logs and backups |
