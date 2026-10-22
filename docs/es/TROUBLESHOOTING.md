# Solución de problemas

[← Volver al README](../../README.es.md) · [English](../en/TROUBLESHOOTING.md)

Casi todas las piezas de HYPER·AERO escriben un registro en `$XDG_RUNTIME_DIR` (normalmente `/run/user/1000/`):

```bash
ls $XDG_RUNTIME_DIR/aero-*.log
```

`aero-phone.log`, `aero-desk.log`, `aero-studio.log`, `aero-carousel.log`, `aero-veil.log`, `aero-displays.log`, `aero-displays-ui.log`, `aero-snap.log`.

## Hyprland muestra una barra roja de error, o arranca con la configuración por defecto

```bash
hyprctl configerrors
hyprctl version
```

- Versión menor a 0.56 → actualizá: `sudo pacman -Syu`. HYPER·AERO necesita la configuración en Lua.
- El error apunta a `user.lua` → corregí o vaciá ese archivo y luego `hyprctl reload`.

## No hay fondo (negro o liso)

```bash
ls ~/.config/hyper-aero/wallpapers/
aero-assets
~/.config/hyper-aero/scripts/wallpaper.sh restart
```

Si `aero-assets` no puede descargar, genera los fondos en tu compu (varios minutos). Revisá que `mpvpaper` esté instalado: `command -v mpvpaper`.

## El teléfono, el escritorio o un panel no abre

Reiniciá esa pieza y leé su registro:

```bash
~/.config/hyper-aero/scripts/phone.sh restart
~/.config/hyper-aero/scripts/desk.sh restart
~/.config/hyper-aero/scripts/displays.sh restart
cat $XDG_RUNTIME_DIR/aero-phone.log
```

Si `SUPER + R` abre rofi en vez del teléfono, Quickshell no logró arrancar el teléfono a tiempo; el registro dice por qué. En el perfil *Ligero* la primera vez tarda un poquito, eso es normal.

## Los íconos se ven como cajitas vacías

Falta una Nerd Font:

```bash
sudo pacman -S --needed ttf-jetbrains-mono-nerd noto-fonts-emoji
fc-cache -f
```

Luego cerrá sesión y volvé a entrar.

## El monitor externo se queda en negro (laptop con dos GPUs)

1. Revisá que el driver de la GPU dedicada funcione (NVIDIA: `nvidia-smi`).
2. Instalá la sesión de GPU: `./install.sh --with-gpu-session --no-deps`.
3. Cerrá sesión y elegí **HYPER·AERO** en la pantalla de inicio de sesión.
4. Presioná `SUPER + P` y elegí un modo.

Si el panel siempre muestra solo la laptop, mirá `$XDG_RUNTIME_DIR/aero-displays.log`.

## Todo se ve muy grande o muy pequeño

El instalador elige un tamaño según la resolución de la pantalla de la laptop (125 % para 1080p, 150 % para 1440p/1600p, 200 % para 4K). Para cambiarlo, presioná `SUPER + P` y elegí otro valor en **TAMAÑO EN LA LAPTOP** (por ejemplo 125 % en una laptop de 15" con 1080p). La elección se recuerda.

Con 150 % o más en una pantalla 1080p, el TELEMETRY HUD puede no caber; usá el HUD delgado (`SUPER + H`) o un tamaño menor.

## El día y la noche cambian a la hora equivocada

- Revisá tu zona horaria: `timedatectl`.
- Configurá tu ubicación: `aero-location LAT LON`.
- `SUPER + ALT + T` cancela un cambio manual.

## El clima muestra «--»

No hay internet, o wttr.in está caído o limitando las consultas. Vuelve a intentar solo. Revisá la ciudad en `~/.config/hyper-aero/weather-location`.

## La distribución del teclado está mal

Agregá a `~/.config/hypr/user.lua`:

```lua
hl.config({ input = { kb_layout = "latam" } })
```

Luego `hyprctl reload`.

## Se siente lento

1. `SUPER + F2` → **Ligero**.
2. Quitá los widgets pesados (LYRICS, GIF, SPECTRA) o todo el escritorio (`SUPER + D`).
3. `top -o %CPU` y fijate qué está arriba. `mpvpaper` alto → puede que tu GPU no decodifique H.264 por hardware; el perfil *Ligero* usa una imagen fija.
4. Asegurate de no estar en una máquina virtual sin aceleración 3D.

Más en [Rendimiento](PERFORMANCE.md).

## Los paneles de Bluetooth o Wi-Fi salen vacíos

```bash
sudo systemctl enable --now bluetooth NetworkManager
```

Si usás `iwd` o `systemd-networkd` en vez de NetworkManager, el panel de Wi-Fi no va a ver tus redes.

## Quiero volver a mi escritorio de antes

```bash
cd hyper-aero
./uninstall.sh
```

Tus respaldos están en `~/.local/share/hyper-aero/backups/`.

## Reportar un error

Abrí un issue con:

- `hyprctl version`
- tu perfil (`aero-profile`)
- el registro de instalación (`~/.local/share/hyper-aero/install-*.log`)
- el registro de la pieza que falla (`$XDG_RUNTIME_DIR/aero-*.log`)
- qué hiciste, qué esperabas, qué pasó, y una captura si podés
