# Instalación

[← Volver al README](../../README.es.md) · [English](../en/INSTALL.md)

## Antes de empezar

- **Arch Linux** (o una distro basada en Arch que use `pacman`), al día: `sudo pacman -Syu`.
- Un usuario normal con `sudo`. **No corrás el instalador como root.**
- Conexión a internet.
- Hyprland **0.56 o más nuevo**. HYPER·AERO usa la configuración nueva en Lua (`hyprland.lua`); las versiones viejas con `hyprland.conf` no sirven.
- Revisá los [requisitos](PERFORMANCE.md#requisitos).

> HYPER·AERO reemplaza la configuración de Hyprland, Waybar, eww, kitty, rofi, swaync, cava, Starship y GTK. **Todo lo que toca se respalda antes**, y `./uninstall.sh` lo deja como estaba.

## Instalación rápida

```bash
sudo pacman -S --needed git
git clone https://github.com/jotaperom/hyper-aero.git
cd hyper-aero
./install.sh
```

Lo que hace el instalador, paso a paso:

1. **Revisa tu equipo** (hilos de CPU, RAM, GPUs) y te recomienda un perfil de rendimiento.
2. **Instala los paquetes** de los repos oficiales, más `eww`, `mpvpaper` y `bibata-cursor-theme-bin` del AUR. Si no tenés `yay` ni `paru`, te ofrece instalar `yay`.
3. **Revisa versiones**: Hyprland ≥ 0.56, y que estén `qs`, `eww` y `mpvpaper`.
4. **Te pregunta algunos ajustes**, con valores detectados:
   - distribución del teclado (de `localectl`)
   - tu ubicación aproximada para el ciclo día/noche (se consulta una vez en `ipapi.co`; podés decir que no y escribirla, o dejarla vacía para calcularla por tu zona horaria)
   - el navegador y el administrador de archivos se detectan solos
5. **Respalda** tu configuración actual en `~/.local/share/hyper-aero/backups/<fecha>/`.
6. **Copia los archivos** a `~/.config`, instala las fuentes en `~/.local/share/fonts/hyper-aero` y agrega una línea a tu `~/.bashrc` o `~/.zshrc`.
7. **Descarga los fondos** (~36 MB) del release de GitHub.
8. Aplica el perfil y el tema GTK.

Después **cerrá sesión y elegí «Hyprland»** en tu pantalla de inicio de sesión. Si ya estabas en Hyprland, presioná `SUPER + M` y volvé a entrar.

Todo lo que se muestra también queda en `~/.local/share/hyper-aero/install-<fecha>.log`.

El instalador agrega algunos comandos a tu terminal: `aero-profile`, `aero-assets`, `aero-location`. Abrí una terminal nueva para usarlos.

## Opciones

```text
./install.sh [opciones]

  --profile completo|equilibrado|ligero   perfil de rendimiento (si no, se recomienda uno)
  --yes                                   no preguntar, usar lo detectado
  --no-deps                               no instalar paquetes
  --no-assets                             no descargar los fondos
  --location LAT LON                      ubicación para el ciclo día/noche
  --with-login                            instalar la pantalla de inicio de sesión (greetd + ReGreet)
  --with-gpu-session                      instalar la sesión para laptops con dos tarjetas gráficas
  -h, --help                              ayuda
```

Ejemplos:

```bash
./install.sh --profile ligero
./install.sh --location 19.43 -99.13
./install.sh --yes --profile equilibrado
```

## Paquetes

**Repos oficiales:** hyprland hyprlock hypridle hyprsunset xdg-desktop-portal-hyprland quickshell waybar swaync rofi kitty mpv ffmpeg python python-numpy python-pillow jq socat curl playerctl cava grim slurp wf-recorder wl-clipboard brightnessctl networkmanager bluez bluez-utils pipewire pipewire-pulse wireplumber libnotify starship zenity pciutils glib2 nano pavucontrol imagemagick xdg-utils ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji papirus-icon-theme adw-gtk-theme qt6-declarative qt6-svg

**AUR:** eww mpvpaper bibata-cursor-theme-bin

Si algún paquete de la primera lista no está en tus mirrors (por ejemplo `quickshell` en algunos casos), el instalador lo busca en el AUR.

Para instalarlos vos y saltarte ese paso:

```bash
sudo pacman -S --needed hyprland hyprlock hypridle ...   # la lista de arriba
yay -S --needed eww mpvpaper bibata-cursor-theme-bin
./install.sh --no-deps
```

## Fondos

El instalador descarga `hyper-aero-wallpapers.tar.gz` del release `assets-v1`. Si eso falla (sin internet, GitHub caído), **los genera en tu compu**: mismo resultado, tarda varios minutos.

Para intentarlo de nuevo después:

```bash
aero-assets            # descargar, o generar si la descarga falla
aero-assets --build    # siempre generar en tu compu
```

## Opcional: pantalla de inicio de sesión

```bash
./install.sh --with-login
```

Instala `greetd` + `ReGreet` con el estilo de HYPER·AERO (día y noche). **Reemplaza tu gestor de inicio de sesión actual** (GDM, SDDM, LightDM…): el instalador lo desactiva y anota cuál era, así al desinstalar se vuelve a activar.

## Opcional: laptops con dos tarjetas gráficas

Algunas laptops (muchas gamer) tienen el puerto HDMI conectado a la GPU dedicada NVIDIA/AMD. Sin ayuda, Hyprland puede no mostrar nada en un monitor externo.

```bash
./install.sh --with-gpu-session
```

Agrega una sesión *HYPER·AERO* (elegila en la pantalla de inicio de sesión) y una regla de udev que hacen que Hyprland use la GPU correcta. El instalador te la ofrece solo cuando encuentra dos GPUs. Igual necesitás los drivers funcionando (para NVIDIA: `nvidia-open` o `nvidia`, ver la [wiki de Arch](https://wiki.archlinux.org/title/NVIDIA_(Espa%C3%B1ol))).

## Actualizar

```bash
cd hyper-aero
git pull
./install.sh
```

Al reinstalar se conserva tu **primer** respaldo como el que restaura `uninstall.sh`, y se mantienen tus notas, el acomodo del escritorio, tus temas y tu `user.lua`.

## Desinstalar

```bash
cd hyper-aero
./uninstall.sh
```

Esto:

- detiene los procesos de HYPER·AERO;
- te pregunta si querés conservar los fondos (se copian a `~/hyper-aero-fondos`);
- restaura cada carpeta de configuración desde el respaldo original, y borra las que no existían antes;
- quita la línea de `~/.bashrc` / `~/.zshrc`, las fuentes y el acceso al Estudio;
- si los instalaste: vuelve a activar tu gestor de inicio de sesión anterior y quita la pantalla de inicio y la sesión de GPU.

Los paquetes se quedan instalados, porque otros programas pueden usarlos. Para quitarlos:

```bash
sudo pacman -Rns quickshell eww mpvpaper hyprsunset swaync cava wf-recorder starship   # elegí los que no necesités
```

Los respaldos quedan en `~/.local/share/hyper-aero/backups/` hasta que los borrés.

## Probarlo sin riesgo

Si querés probar sin tocar tu cuenta, creá un usuario nuevo e instalá ahí:

```bash
sudo useradd -m -G wheel prueba
sudo passwd prueba
```

Entrá como `prueba` y seguí la instalación rápida.
