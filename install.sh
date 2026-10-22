#!/usr/bin/env bash
set -o pipefail

VERSION="1.1.0"
UPSTREAM="jotaperom/hyper-aero"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
C="$HOME/.config"
A="$C/hyper-aero"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.local/share/hyper-aero/backups/$STAMP"
LOGFILE="$HOME/.local/share/hyper-aero/install-$STAMP.log"

ASSUME_YES=0
PROFILE=""
DO_DEPS=1
DO_ASSETS=1
WITH_LOGIN=0
WITH_GPU=0
LAT=""
LON=""
CITY=""

c_b=$'\e[38;2;61;155;233m'
c_w=$'\e[38;2;240;180;76m'
c_e=$'\e[38;2;255;93;108m'
c_ok=$'\e[38;2;61;220;151m'
c_0=$'\e[0m'
c_bold=$'\e[1m'

say()  { printf '%s◢%s %s\n' "$c_b" "$c_0" "$*"; }
ok()   { printf '%s✓%s %s\n' "$c_ok" "$c_0" "$*"; }
warn() { printf '%s!%s %s\n' "$c_w" "$c_0" "$*"; }
die()  { printf '%s✗%s %s\n' "$c_e" "$c_0" "$*"; exit 1; }

declare -A TR=()

detect_lang() {
    local saved
    saved=$(cat "$A/lang" 2>/dev/null)
    case "$saved" in es|en) echo "$saved"; return ;; esac
    case "${LC_ALL:-${LANG:-}}" in es*) echo es ;; *) echo en ;; esac
}

load_lang() {
    TR=()
    [ "$UI_LANG" = en ] || return 0
    local f="$HERE/dotfiles/.config/hyper-aero/i18n/en.json" line k v
    local re='^ *"(([^"\\]|\\.)*)": "(([^"\\]|\\.)*)",?$'
    [ -f "$f" ] || return 0
    while IFS= read -r line; do
        [[ $line =~ $re ]] || continue
        k="${BASH_REMATCH[1]}"
        v="${BASH_REMATCH[3]}"
        k="${k//\\\\/$'\x01'}"; k="${k//\\\"/\"}"; k="${k//$'\x01'/\\}"
        v="${v//\\\\/$'\x01'}"; v="${v//\\\"/\"}"; v="${v//$'\x01'/\\}"
        TR["$k"]="$v"
    done < "$f"
}

t() {
    local v="${TR[$1]-}"
    printf '%s' "${v:-$1}"
}

tf() {
    local f
    f=$(t "$1")
    shift
    printf "$f" "$@"
}

profile_label() {
    if [ "$UI_LANG" = en ]; then
        case "$1" in completo) echo full ;; equilibrado) echo balanced ;; ligero) echo lite ;; *) echo "$1" ;; esac
    else
        echo "$1"
    fi
}

profile_key() {
    case "$1" in full|completo) echo completo ;; balanced|equilibrado) echo equilibrado ;; lite|light|ligero) echo ligero ;; *) echo "$1" ;; esac
}

UI_LANG=$(detect_lang)
load_lang

usage() {
    if [ "$UI_LANG" = en ]; then
        cat <<EOF
HYPER·AERO $VERSION

usage: ./install.sh [options]

  --profile full|balanced|lite            performance profile (otherwise one is recommended)
  --lang en|es                            interface language
  --yes                                   don't ask, use the detected values
  --no-deps                               don't install packages
  --no-assets                             don't download the wallpapers
  --location LAT LON                      location for the day/night cycle
  --with-login                            install the login screen (greetd + ReGreet)
  --with-gpu-session                      install the session for dual-GPU laptops
  -h, --help                              this help
EOF
        return
    fi
    cat <<EOF
HYPER·AERO $VERSION

uso: ./install.sh [opciones]

  --profile completo|equilibrado|ligero   perfil de rendimiento (si no, se recomienda uno)
  --lang es|en                            idioma de la interfaz
  --yes                                   no preguntar, usar lo detectado
  --no-deps                               no instalar paquetes
  --no-assets                             no descargar los fondos
  --location LAT LON                      ubicación para el ciclo día/noche
  --with-login                            instalar la pantalla de inicio de sesión (greetd + ReGreet)
  --with-gpu-session                      instalar la sesión para laptops con dos tarjetas gráficas
  -h, --help                              esta ayuda
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --profile) PROFILE=$(profile_key "$2"); shift ;;
        --lang) case "$2" in es|en) UI_LANG="$2"; LANG_SET=1; load_lang ;; *) die "--lang es|en" ;; esac; shift ;;
        --yes|-y) ASSUME_YES=1 ;;
        --no-deps) DO_DEPS=0 ;;
        --no-assets) DO_ASSETS=0 ;;
        --location) LAT="$2"; LON="$3"; shift 2 ;;
        --with-login) WITH_LOGIN=1 ;;
        --with-gpu-session) WITH_GPU=1 ;;
        -h|--help) usage; exit 0 ;;
        *) usage; die "$(t "Opción desconocida:") $1" ;;
    esac
    shift
done

ask() {
    local q="$1" def="$2" ans
    if [ "$ASSUME_YES" = 1 ] || [ ! -t 0 ]; then
        REPLY="$def"
        return
    fi
    read -r -p "$(printf '%s?%s %s [%s]: ' "$c_b" "$c_0" "$q" "$def")" ans
    REPLY="${ans:-$def}"
}

yesno() {
    local q="$1" def="${2:-s}"
    if [ "$UI_LANG" = en ]; then
        case "$def" in s) def=y ;; esac
        ask "$q (y/n)" "$def"
    else
        ask "$q (s/n)" "$def"
    fi
    case "$REPLY" in s|S|y|Y|si|sí|yes) return 0 ;; *) return 1 ;; esac
}

banner() {
    printf '\n%s%s  ◢ HYPER·AERO%s  %s%s v%s%s\n' "$c_b" "$c_bold" "$c_0" "$c_b" "$(t "instalador")" "$VERSION" "$c_0"
    printf '  %s\n\n' "────────────────────────────────────────────────"
}

check_base() {
    [ "$(id -u)" -eq 0 ] && die "$(t "No corrás esto como root. Usá tu usuario normal (te pedirá sudo cuando haga falta).")"
    command -v pacman >/dev/null || die "$(t "HYPER·AERO necesita Arch Linux (o una distro basada en Arch con pacman).")"
    [ "$(uname -m)" = "x86_64" ] || warn "$(t "Solo está probado en x86_64.")"
    command -v sudo >/dev/null || die "$(t "Falta sudo.")"
}

hw_report() {
    CORES=$(nproc)
    RAM_GB=$(awk '/MemTotal/ { printf "%d", ($2 / 1048576) + 0.5 }' /proc/meminfo)
    GPUS=$(lspci 2>/dev/null | grep -E "VGA|3D|Display" | sed 's/^[^ ]* [^:]*: //')
    GPU_COUNT=$(printf '%s\n' "$GPUS" | grep -c . || true)
    CPU=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')
    say "$(t "Equipo detectado")"
    printf '    CPU   %s (%s %s)\n' "$CPU" "$CORES" "$(t "hilos")"
    printf '    RAM   %s GB\n' "$RAM_GB"
    printf '%s\n' "$GPUS" | sed 's/^/    GPU   /'
    echo
    if [ "$RAM_GB" -lt 6 ] || [ "$CORES" -lt 4 ]; then
        warn "$(t "Tu equipo está por debajo de los requisitos mínimos (4 hilos y 8 GB de RAM). Puede ir lento.")"
        REC="ligero"
    elif [ "$RAM_GB" -lt 12 ] || [ "$CORES" -lt 8 ]; then
        REC="equilibrado"
    else
        REC="equilibrado"
        if printf '%s' "$GPUS" | grep -qiE "nvidia|radeon rx|arc a"; then REC="completo"; fi
    fi
}

pick_profile() {
    if [ -z "$PROFILE" ]; then
        say "$(t "Perfiles de rendimiento: completo (todo animado), equilibrado (recomendado para la mayoría), ligero (equipos modestos)")"
        ask "$(t "Perfil")" "$(profile_label "$REC")"
        PROFILE=$(profile_key "$REPLY")
    fi
    case "$PROFILE" in completo|equilibrado|ligero) ;; *) die "$(t "Perfil inválido:") $PROFILE" ;; esac
    ok "$(t "Perfil:") $(profile_label "$PROFILE")"
}

detect_settings() {
    KB_LAYOUT=$(localectl status 2>/dev/null | awk -F': ' '/X11 Layout/ { print $2 }' | cut -d, -f1)
    KB_VARIANT=$(localectl status 2>/dev/null | awk -F': ' '/X11 Variant/ { print $2 }' | cut -d, -f1)
    [ -n "$KB_LAYOUT" ] || KB_LAYOUT=$(localectl status 2>/dev/null | awk -F': ' '/VC Keymap/ { print $2 }' | sed 's/-.*//')
    [ -n "$KB_LAYOUT" ] && [ "$KB_LAYOUT" != "n/a" ] || KB_LAYOUT="us"
    ask "$(t "Distribución de teclado (us, es, latam, de…)")" "$KB_LAYOUT"
    KB_LAYOUT="$REPLY"

    BROWSER="firefox"
    desk=$(xdg-settings get default-web-browser 2>/dev/null)
    if [ -n "$desk" ]; then
        exe=$(grep -m1 '^Exec=' "/usr/share/applications/$desk" "$HOME/.local/share/applications/$desk" 2>/dev/null | head -n1 | sed 's/^[^=]*=//; s/ .*//')
        [ -n "$exe" ] && BROWSER="$exe"
    else
        for b in firefox brave chromium google-chrome-stable zen-browser librewolf; do
            command -v "$b" >/dev/null && { BROWSER="$b"; break; }
        done
    fi
    FILEMANAGER="nautilus"
    for f in nautilus thunar dolphin nemo pcmanfm-qt pcmanfm; do
        command -v "$f" >/dev/null && { FILEMANAGER="$f"; break; }
    done

    if [ -z "$LAT" ]; then
        geo=$(curl -fs --max-time 6 https://ipapi.co/json 2>/dev/null)
        LAT=$(printf '%s' "$geo" | jq -r '.latitude // empty' 2>/dev/null)
        LON=$(printf '%s' "$geo" | jq -r '.longitude // empty' 2>/dev/null)
        CITY=$(printf '%s' "$geo" | jq -r '.city // empty' 2>/dev/null)
        if [ -n "$LAT" ]; then
            say "$(t "Ubicación aproximada para el ciclo día/noche:") ${CITY:-?} ($LAT, $LON)"
            yesno "$(t "¿La uso?")" s || { LAT=""; LON=""; }
        fi
        if [ -z "$LAT" ]; then
            ask "$(t "Latitud (por ejemplo 19.43; vacío = calcular por zona horaria)")" ""
            LAT="$REPLY"
            if [ -n "$LAT" ]; then ask "$(t "Longitud (por ejemplo -99.13)")" ""; LON="$REPLY"; fi
        fi
    fi
    if [ -z "$LAT" ] || [ -z "$LON" ]; then
        off=$(date +%z)
        sign=1; [ "${off:0:1}" = "-" ] && sign=-1
        LAT="0.0"
        LON=$(awk -v h="${off:1:2}" -v m="${off:3:2}" -v s="$sign" 'BEGIN { printf "%.2f", s * (h + m / 60) * 15 }')
    fi
    LOCALE=$(locale 2>/dev/null | awk -F= '/^LANG=/ { gsub("\"", "", $2); print $2 }' | cut -d. -f1)
    LOCALE=${LOCALE:-en_US}
    ok "$(t "Teclado:") $KB_LAYOUT${KB_VARIANT:+ ($KB_VARIANT)} · $(t "Navegador:") $BROWSER · $(t "Archivos:") $FILEMANAGER"
}

PKGS=(hyprland hyprlock hypridle hyprsunset xdg-desktop-portal-hyprland quickshell waybar swaync rofi kitty
      mpv ffmpeg python python-numpy python-pillow jq socat curl playerctl cava grim slurp wf-recorder wl-clipboard
      brightnessctl networkmanager bluez bluez-utils pipewire pipewire-pulse wireplumber libnotify starship zenity
      pciutils glib2 nano pavucontrol imagemagick xdg-utils ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
      papirus-icon-theme adw-gtk-theme qt6-declarative qt6-svg)
AUR_PKGS=(eww mpvpaper bibata-cursor-theme-bin)

aur_helper() {
    for h in yay paru; do command -v "$h" >/dev/null && { echo "$h"; return; }; done
}

install_deps() {
    say "$(t "Instalando paquetes oficiales (pide tu contraseña)…")"
    local missing=()
    for p in "${PKGS[@]}"; do pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p"); done
    local avail=() gone=()
    for p in "${missing[@]}"; do
        if pacman -Si "$p" >/dev/null 2>&1; then avail+=("$p"); else gone+=("$p"); fi
    done
    if [ ${#avail[@]} -gt 0 ]; then
        sudo pacman -S --needed --noconfirm "${avail[@]}" || die "$(t "Falló la instalación de paquetes. Revisá la salida de arriba.")"
    fi
    local helper
    helper=$(aur_helper)
    local aur=("${gone[@]}")
    for p in "${AUR_PKGS[@]}"; do pacman -Qq "$p" >/dev/null 2>&1 || pacman -Qq "${p%-bin}" >/dev/null 2>&1 || pacman -Qq "$p-git" >/dev/null 2>&1 || aur+=("$p"); done
    if [ ${#aur[@]} -gt 0 ]; then
        if [ -z "$helper" ]; then
            warn "$(t "Faltan paquetes del AUR:") ${aur[*]}"
            if yesno "$(t "¿Instalo yay para conseguirlos?")" s; then
                sudo pacman -S --needed --noconfirm git base-devel || die "$(t "No pude instalar git/base-devel")"
                tmp=$(mktemp -d)
                git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" && (cd "$tmp/yay-bin" && makepkg -si --noconfirm) || die "$(t "No pude instalar yay")"
                rm -rf "$tmp"
                helper=yay
            else
                die "$(t "Sin esos paquetes HYPER·AERO no funciona:") ${aur[*]}"
            fi
        fi
        say "$(tf "Instalando del AUR con %s:" "$helper") ${aur[*]}"
        "$helper" -S --needed --noconfirm "${aur[@]}" || die "$(tf "Falló %s. Revisá la salida de arriba." "$helper")"
    fi
    for svc in NetworkManager bluetooth; do
        systemctl is-enabled "$svc" >/dev/null 2>&1 || sudo systemctl enable --now "$svc" >/dev/null 2>&1 || true
    done
    ok "$(t "Paquetes listos")"
}

check_versions() {
    local hv
    hv=$(pacman -Q hyprland 2>/dev/null | awk '{print $2}' | cut -d- -f1)
    if [ -n "$hv" ] && [ "$(printf '%s\n0.56.0\n' "$hv" | sort -V | head -n1)" != "0.56.0" ]; then
        die "$(tf "Hyprland %s es muy viejo: HYPER·AERO usa la configuración en Lua de Hyprland 0.56 o más nuevo." "$hv")"
    fi
    command -v qs >/dev/null || die "$(t "Falta Quickshell (qs).")"
    command -v eww >/dev/null || die "$(t "Falta eww.")"
    command -v mpvpaper >/dev/null || die "$(t "Falta mpvpaper.")"
}

TARGETS=(hypr hyper-aero quickshell/aero-carousel quickshell/aero-desk quickshell/aero-displays quickshell/aero-phone
         quickshell/aero-snap quickshell/aero-studio quickshell/aero-veil eww waybar kitty rofi swaync gtk-3.0 gtk-4.0 cava
         starship.toml)

backup() {
    mkdir -p "$BACKUP"
    : > "$BACKUP/manifest"
    for t in "${TARGETS[@]}"; do
        if [ -e "$C/$t" ]; then
            mkdir -p "$BACKUP/.config"
            tar -C "$C" --exclude="hyper-aero/wallpapers" --exclude="hyper-aero/backups" -cf - "$t" | tar -C "$BACKUP/.config" -xf -
            echo "saved .config/$t" >> "$BACKUP/manifest"
        else
            echo "new .config/$t" >> "$BACKUP/manifest"
        fi
    done
    for f in .bashrc .zshrc; do
        [ -f "$HOME/$f" ] && cp -a "$HOME/$f" "$BACKUP/$f" && echo "rc $f" >> "$BACKUP/manifest"
    done
    ok "$(t "Respaldo de tu configuración en") $BACKUP"
}

render_copy() {
    python3 - "$HERE/dotfiles" "$HOME" "$KB_LAYOUT" "${KB_VARIANT:-}" "$BROWSER" "$FILEMANAGER" "$LAT" "$LON" <<'PY'
import os, sys, shutil
src, home, kb, kbv, browser, files, lat, lon = sys.argv[1:9]
subs = {"__HOME__": home, "__KB_LAYOUT__": kb, "__KB_VARIANT__": kbv, "__BROWSER__": browser,
        "__FILEMANAGER__": files, "__LAT__": lat, "__LON__": lon}
keep = {os.path.join(".config", "hypr", "user.lua"), os.path.join(".config", "hyper-aero", "desk", "notes.txt"),
        os.path.join(".config", "hyper-aero", "studio", "themes.json"), os.path.join(".config", "hyper-aero", "desk", "layout.json")}
n = 0
for root, dirs, fs in os.walk(src):
    for f in fs:
        s = os.path.join(root, f)
        rel = os.path.relpath(s, src)
        d = os.path.join(home, rel)
        if rel in keep and os.path.exists(d):
            continue
        os.makedirs(os.path.dirname(d), exist_ok=True)
        try:
            text = open(s, encoding="utf-8").read()
        except UnicodeDecodeError:
            shutil.copy2(s, d)
            n += 1
            continue
        for a, b in subs.items():
            text = text.replace(a, b)
        tmp = d + ".aero-tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            fh.write(text)
        os.chmod(tmp, os.stat(s).st_mode & 0o777)
        os.replace(tmp, d)
        n += 1
print(n)
PY
}

install_files() {
    say "$(t "Copiando la configuración…")"
    local n
    n=$(render_copy) || die "$(t "No pude copiar los archivos")"
    printf '%s\n' "$UI_LANG" > "$A/lang"
    python3 "$A/scripts/aero-lang" refresh >/dev/null 2>&1 || true
    mkdir -p "$A/theme" "$A/wallpapers" "$A/desk" "$A/studio"
    [ -f "$A/theme/accent" ] || echo blue > "$A/theme/accent"
    [ -f "$A/theme/mode" ] || echo day > "$A/theme/mode"
    [ -f "$A/theme/wallpaper" ] || echo auto > "$A/theme/wallpaper"
    [ -n "$CITY" ] && printf '%s\n' "$CITY" > "$A/weather-location"
    [ -f "$A/weather-location" ] || : > "$A/weather-location"
    find "$A/scripts" -type f -exec chmod 755 {} +
    ok "$(tf "%s archivos instalados" "$n")"

    mkdir -p "$HOME/.local/share/fonts/hyper-aero"
    cp -f "$HERE"/assets/fonts/*.ttf "$HOME/.local/share/fonts/hyper-aero/"
    fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
    ok "$(t "Fuentes Exo 2 y Michroma")"

    local rc snippet line
    case "$(basename "${SHELL:-bash}")" in
        zsh) rc="$HOME/.zshrc"; snippet="$A/shell/hyper-aero.zsh" ;;
        *) rc="$HOME/.bashrc"; snippet="$A/shell/hyper-aero.bash" ;;
    esac
    line="[ -f \"$snippet\" ] && . \"$snippet\""
    touch "$rc"
    if ! grep -qF "hyper-aero/shell/hyper-aero" "$rc"; then
        printf '\n%s\n' "$line" >> "$rc"
    fi
    ok "$(tf "Terminal: banner DECK y prompt Starship en %s" "$(basename "$rc")")"
}

link_theme() {
    local T="$A/theme" m
    m=$(cat "$T/mode" 2>/dev/null)
    case "$m" in day|night) ;; *) m=day ;; esac
    mk() { [ -e "$1" ] || [ -L "$1" ] || ln -s "$2" "$1"; }
    mk "$T/day/starship.toml" "$C/starship.toml"
    mk "$T/day/hyprlock.conf" "$C/hypr/hyprlock.conf"
    mk "$T/day/waybar.jsonc" "$C/waybar/config.jsonc"
    mk "$T/day/gtk4.css" "$T/base/gtk4.css"
    mk "$T/night/gtk4.css" "$T/base/gtk4.css"
    mk "$T/current" "$T/$m"
    mk "$C/eww/night-deck.scss" "$T/current/eww.scss"
}

seed_display() {
    local gen="$C/hypr/aero-displays.lua" d b name mode w sc
    [ -e "$gen" ] && return
    for d in /sys/class/drm/card*-eDP-* /sys/class/drm/card*-LVDS-*; do
        [ -e "$d/status" ] || continue
        [ "$(cat "$d/status" 2>/dev/null)" = connected ] || continue
        b=$(basename "$d")
        name=${b#card*-}
        mode=$(head -n1 "$d/modes" 2>/dev/null)
        w=${mode%%x*}
        [ -n "$w" ] && [ "$w" -gt 0 ] 2>/dev/null || continue
        if [ "$w" -ge 3800 ]; then sc=2
        elif [ "$w" -ge 2800 ]; then sc=1.75
        elif [ "$w" -ge 2500 ]; then sc=1.5
        elif [ "$w" -ge 1900 ]; then sc=1.25
        else sc=1; fi
        printf 'hl.monitor({ output = "%s", mode = "preferred", position = "0x0", scale = %s })\n' "$name" "$sc" > "$gen"
        ok "$(tf "Pantalla de la laptop (%s, %s) al %s %%" "$name" "$mode" "$(awk -v s="$sc" 'BEGIN { printf "%d", s * 100 }')")"
        return
    done
}

install_assets() {
    [ "$DO_ASSETS" = 1 ] || { warn "$(t "Sin fondos: corré luego ~/.config/hyper-aero/scripts/aero-assets.sh")"; return; }
    "$A/scripts/aero-assets.sh" || warn "$(t "Los fondos no quedaron listos. Corré luego: ~/.config/hyper-aero/scripts/aero-assets.sh")"
}

install_login() {
    say "$(t "Pantalla de inicio de sesión (greetd + ReGreet)")"
    warn "$(t "Esto reemplaza tu gestor de inicio de sesión actual (GDM, SDDM, LightDM…).")"
    yesno "$(t "¿Seguro?")" n || return
    sudo -v || { warn "$(t "Sin permisos de sudo: no instalé la pantalla de inicio")"; return; }
    local pk=(greetd greetd-regreet)
    sudo pacman -S --needed --noconfirm "${pk[@]}" || { warn "$(t "No pude instalar greetd")"; return; }
    sudo install -d /etc/greetd /usr/share/backgrounds/hyper-aero /var/lib/hyper-aero
    [ -f /etc/greetd/config.toml ] && sudo cp -a /etc/greetd/config.toml "/etc/greetd/config.toml.pre-hyper-aero-$STAMP"
    local tmp
    tmp=$(mktemp -d)
    cp "$HERE"/system/greetd/* "$tmp/"
    sed -i "s|__KB_LAYOUT__|$KB_LAYOUT|g; s|__KB_VARIANT__|${KB_VARIANT:-}|g; s|__LAT__|$LAT|g; s|__LON__|$LON|g; s|__LOCALE__|$LOCALE|g" "$tmp"/*
    sudo install -m 644 "$tmp"/config.toml "$tmp"/hyprland.lua "$tmp"/*.toml "$tmp"/*.css /etc/greetd/
    sudo install -m 755 "$tmp"/aero-greet.sh "$tmp"/aero-sun.py /etc/greetd/
    rm -rf "$tmp"
    [ -f "$A/wallpapers/bg.jpg" ] && sudo install -m 644 "$A/wallpapers/bg.jpg" /usr/share/backgrounds/hyper-aero/aero-login.jpg
    [ -f "$A/wallpapers/bg-night.jpg" ] && sudo install -m 644 "$A/wallpapers/bg-night.jpg" /usr/share/backgrounds/hyper-aero/aero-login-night.jpg
    sudo chown "$USER" /var/lib/hyper-aero
    for dm in gdm sddm lightdm lxdm ly; do
        systemctl is-enabled "$dm" >/dev/null 2>&1 && sudo systemctl disable "$dm" >/dev/null 2>&1 && echo "dm $dm" >> "$BACKUP/manifest"
    done
    sudo systemctl enable greetd >/dev/null 2>&1
    echo "login yes" >> "$BACKUP/manifest"
    ok "$(t "Inicio de sesión HYPER·AERO activado (se ve al reiniciar)")"
}

install_gpu_session() {
    say "$(t "Sesión para dos tarjetas gráficas")"
    if [ -f /usr/share/wayland-sessions/hyper-aero.desktop ] && [ -f /usr/local/bin/hyper-aero-session ]; then
        ok "$(t "Ya estaba instalada")"
        return 1
    fi
    sudo -v || { warn "$(t "Sin permisos de sudo: no instalé la sesión de GPU")"; return 1; }
    sudo install -m 644 "$HERE/system/session/99-hyper-aero-gpu.rules" /etc/udev/rules.d/99-hyper-aero-gpu.rules
    sudo install -m 755 "$HERE/system/session/hyper-aero-session" /usr/local/bin/hyper-aero-session
    sudo install -d /usr/share/wayland-sessions
    sudo install -m 644 "$HERE/system/session/hyper-aero.desktop" /usr/share/wayland-sessions/hyper-aero.desktop
    sudo udevadm control --reload && sudo udevadm trigger --subsystem-match=drm
    echo "gpu yes" >> "$BACKUP/manifest"
    ok "$(t "Sesión «HYPER·AERO» disponible en la pantalla de inicio")"
}

write_info() {
    jq -n --arg v "$VERSION" --arg b "$ORIGINAL" --arg l "$BACKUP" --arg s "$HERE" --arg r "$REPO_SLUG" --arg p "$PROFILE" \
        '{version: $v, backup: $b, last: $l, source: $s, repo: $r, profile: $p}' > "$A/.install.json"
}

apply_look() {
    "$A/scripts/aero-profile" "$PROFILE" --no-apply >/dev/null
    if command -v gsettings >/dev/null; then
        "$A/scripts/apply-theme.sh" >/dev/null 2>&1 || true
    fi
}

finish() {
    echo
    ok "$(tf "HYPER·AERO %s instalado" "$VERSION")"
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        say "$(t "Estás dentro de Hyprland: cerrá sesión (SUPER + M) y volvé a entrar para arrancar todo.")"
    else
        if [ "$WITH_GPU" = 1 ]; then
            say "$(t "Cerrá sesión y entrá a «HYPER·AERO» (o «Hyprland»).")"
        else
            say "$(t "Cerrá sesión y entrá a «Hyprland».")"
        fi
    fi
    say "$(t "Atajos: SUPER + F1 · Perfil de rendimiento: SUPER + F2 o 'aero-profile ligero|equilibrado|completo'")"
    say "$(t "Para deshacer:") $HERE/uninstall.sh"
    say "$(t "Registro:") $LOGFILE"
}

main() {
    mkdir -p "$(dirname "$LOGFILE")"
    exec > >(tee -a "$LOGFILE") 2>&1
    banner
    if [ -z "${LANG_SET:-}" ]; then
        ask "Idioma / Language (es/en)" "$UI_LANG"
        case "$REPLY" in es|en) UI_LANG="$REPLY" ;; esp*|spa*) UI_LANG=es ;; eng*) UI_LANG=en ;; esac
        load_lang
    fi
    check_base
    REPO_SLUG=$(git -C "$HERE" remote get-url origin 2>/dev/null | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')
    case "$REPO_SLUG" in */*) ;; *) REPO_SLUG="$UPSTREAM" ;; esac
    hw_report
    pick_profile
    if [ "$DO_DEPS" = 1 ]; then
        command -v jq >/dev/null || sudo pacman -S --needed --noconfirm jq curl
        install_deps
    fi
    check_versions
    detect_settings
    yesno "$(t "¿Instalo HYPER·AERO ahora? Tu configuración actual queda respaldada")" s || die "$(t "Cancelado")"
    ORIGINAL=$(jq -r '.backup // empty' "$A/.install.json" 2>/dev/null)
    [ -n "$ORIGINAL" ] && [ -f "$ORIGINAL/manifest" ] || ORIGINAL="$BACKUP"
    backup
    install_files
    link_theme
    seed_display
    write_info
    install_assets
    apply_look
    if [ "$WITH_GPU" = 0 ] && [ "${GPU_COUNT:-1}" -ge 2 ] && [ ! -f /usr/share/wayland-sessions/hyper-aero.desktop ]; then
        yesno "$(t "Tenés dos tarjetas gráficas. ¿Instalo la sesión que usa la dedicada cuando conectás un monitor externo?")" n && WITH_GPU=1
    fi
    if [ "$WITH_GPU" = 1 ] && install_gpu_session; then [ "$ORIGINAL" != "$BACKUP" ] && echo "gpu yes" >> "$ORIGINAL/manifest"; fi
    if [ "$WITH_LOGIN" = 1 ]; then install_login; [ "$ORIGINAL" != "$BACKUP" ] && grep "^dm \|^login " "$BACKUP/manifest" >> "$ORIGINAL/manifest"; fi
    finish
}

main "$@"
