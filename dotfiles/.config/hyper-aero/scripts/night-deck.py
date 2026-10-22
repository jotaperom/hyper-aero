#!/usr/bin/env python3

import os
import re
import sys
import json
import math
import time
import fcntl
import shutil
import socket
import datetime
import threading
import subprocess
from aero_i18n import t as _t

sys.path.insert(0, os.path.join(os.path.expanduser("~"), ".config", "hyper-aero", "scripts"))
try:
    import aero_tint
except ImportError:
    aero_tint = None

HOME = os.path.expanduser("~")
AERO = os.path.join(HOME, ".config", "hyper-aero")
THEME = os.path.join(AERO, "theme")
CURRENT = os.path.join(THEME, "current")
MODE = os.path.join(THEME, "mode")
STATE = os.path.join(THEME, "state.json")
CONFIG = os.path.join(THEME, "config.json")
SCRIPTS = os.path.join(AERO, "scripts")
WALL = os.path.join(AERO, "wallpapers")
RUN = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
LOG = os.path.join(RUN, "night-deck.log")

DEFAULTS = {"lat": 0.0, "lon": round(-time.timezone / 3600.0 * 15.0, 2), "warm_kelvin": 4200, "warm_enabled": True,
            "night_offset_min": 0, "day_offset_min": 0}

ICON_DAY = "\U000f0599"
ICON_NIGHT = "\U000f0594"

WAYBAR_MAP = {"#5a6270": "#8b97ab", "#1446c2": "#6fd3ff", "#9aa3ae": "#4a5a78", "#a8650a": "#f0b44c",
              "#0f7b5a": "#3ddc97", "#c4283b": "#ff5d6c", "#0b0d12": "#e6eefb", "#1e6fd9": "#3d9be9"}

HYPR = {
    "day": ('hl.config({ general = { col = { active_border = { colors = { "rgba(1446c2ff)", "rgba(1e6fd9ff)", '
            '"rgba(3d9be9ff)" }, angle = 135 }, inactive_border = { colors = { "rgba(5a627055)", "rgba(c6d0db77)" }, '
            'angle = 135 } } }, decoration = { shadow = { color = "rgba(0b0d1240)", color_inactive = "rgba(0b0d1222)" }, '
            'glow = { color = "rgba(3d9be977)" } }, misc = { background_color = "rgb(f5f8fb)" } })'),
    "night": ('hl.config({ general = { col = { active_border = { colors = { "rgba(3d9be9ff)", "rgba(6fd3ffff)", '
              '"rgba(1e6fd9ff)" }, angle = 135 }, inactive_border = { colors = { "rgba(4a5a7866)", "rgba(1e2a4488)" }, '
              'angle = 135 } } }, decoration = { shadow = { color = "rgba(00000088)", color_inactive = "rgba(00000044)" }, '
              'glow = { color = "rgba(6fd3ff66)" } }, misc = { background_color = "rgb(070c18)" } })'),
}


def log(msg):
    try:
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(f"{time.strftime('%H:%M:%S')} {msg}\n")
    except OSError:
        pass


def sh(args, timeout=20, **kw):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout, **kw)
    except (OSError, subprocess.TimeoutExpired) as e:
        log(f"{args[0]}: {e}")
        return None


def has(cmd):
    return shutil.which(cmd) is not None


def running(name):
    r = sh(["pgrep", "-x", name])
    return bool(r and r.returncode == 0)


def spawn(args):
    try:
        subprocess.Popen(args, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         start_new_session=True)
    except OSError as e:
        log(f"spawn {args[0]}: {e}")


def load_json(path, default):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else default
    except (OSError, ValueError):
        return default


def save_json(path, data):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, path)


def config():
    cfg = dict(DEFAULTS)
    cfg.update(load_json(CONFIG, {}))
    return cfg


def current_mode():
    try:
        with open(MODE, encoding="utf-8") as f:
            return "night" if f.read().strip() == "night" else "day"
    except OSError:
        return "day"


def sun_times(day, lat, lon):
    n = day.timetuple().tm_yday
    g = 2 * math.pi / 365 * (n - 1)
    eqtime = 229.18 * (0.000075 + 0.001868 * math.cos(g) - 0.032077 * math.sin(g)
                       - 0.014615 * math.cos(2 * g) - 0.040849 * math.sin(2 * g))
    decl = (0.006918 - 0.399912 * math.cos(g) + 0.070257 * math.sin(g) - 0.006758 * math.cos(2 * g)
            + 0.000907 * math.sin(2 * g) - 0.002697 * math.cos(3 * g) + 0.00148 * math.sin(3 * g))
    phi = math.radians(lat)
    x = math.cos(math.radians(90.833)) / (math.cos(phi) * math.cos(decl)) - math.tan(phi) * math.tan(decl)
    x = max(-1.0, min(1.0, x))
    ha = math.degrees(math.acos(x))
    midnight = datetime.datetime(day.year, day.month, day.day, tzinfo=datetime.timezone.utc).timestamp()
    sunrise = midnight + (720 - 4 * (lon + ha) - eqtime) * 60
    sunset = midnight + (720 - 4 * (lon - ha) - eqtime) * 60
    return sunrise, sunset


def day_bounds(now, cfg):
    local = datetime.datetime.fromtimestamp(now).date()
    out = {}
    for delta in (-1, 0, 1):
        d = local + datetime.timedelta(days=delta)
        sr, ss = sun_times(d, cfg["lat"], cfg["lon"])
        out[delta] = (sr + cfg["day_offset_min"] * 60, ss + cfg["night_offset_min"] * 60)
    return out


def schedule(now=None, cfg=None):
    now = now or time.time()
    cfg = cfg or config()
    b = day_bounds(now, cfg)
    sr, ss = b[0]
    if now < sr:
        return "night", sr
    if now < ss:
        return "day", ss
    return "night", b[1][0]


def warm_factor(now, cfg):
    b = day_bounds(now, cfg)
    sr, ss = b[0]
    if now < sr - 1800:
        return 1.0
    if now < sr + 1800:
        return max(0.0, min(1.0, (sr + 1800 - now) / 3600))
    if now < ss:
        return 0.0
    return max(0.0, min(1.0, (now - ss) / 3600))


def next_warm_end(now, cfg):
    b = day_bounds(now, cfg)
    for delta in (0, 1):
        end = b[delta][0] + 1800
        if end > now:
            return end
    return now + 86400


ACCENT_FILE = os.path.join(os.path.expanduser("~"), ".config", "hyper-aero", "theme", "accent")
ACCENTS = ["blue", "red", "green", "black"]
ACCENT_NAMES = {"blue": _t("AZUL"), "red": _t("ROJO"), "green": _t("VERDE"), "black": _t("NEGRO")}
GNOME_ACCENT = {"blue": "blue", "red": "red", "green": "teal", "black": "slate"}


def current_accent():
    try:
        with open(ACCENT_FILE, encoding="utf-8") as f:
            v = f.read().strip()
    except OSError:
        return "blue"
    custom = bool(aero_tint and hasattr(aero_tint, "valid") and aero_tint.valid(v))
    return v if (v in ACCENTS or custom) and (v == "blue" or aero_tint) else "blue"


def tint(text):
    acc = current_accent()
    if acc == "blue" or not aero_tint:
        return text
    return aero_tint.recolor(text, acc)


def ensure_layout():
    for d in ("day", "night"):
        os.makedirs(os.path.join(THEME, d), exist_ok=True)
    cfg = os.path.join(HOME, ".config")
    links = [
        (os.path.join(THEME, "day", "starship.toml"), os.path.join(cfg, "starship.toml")),
        (os.path.join(THEME, "day", "hyprlock.conf"), os.path.join(cfg, "hypr", "hyprlock.conf")),
        (os.path.join(THEME, "day", "waybar.jsonc"), os.path.join(cfg, "waybar", "config.jsonc")),
        (os.path.join(THEME, "day", "gtk4.css"), os.path.join(THEME, "base", "gtk4.css")),
        (os.path.join(THEME, "night", "gtk4.css"), os.path.join(THEME, "base", "gtk4.css")),
        (os.path.join(cfg, "eww", "night-deck.scss"), os.path.join(CURRENT, "eww.scss")),
    ]
    for link, target in links:
        if not os.path.lexists(link):
            try:
                os.makedirs(os.path.dirname(link), exist_ok=True)
                os.symlink(target, link)
            except OSError:
                pass
    if not os.path.lexists(CURRENT):
        os.symlink(os.path.join(THEME, current_mode()), CURRENT)


def write_mirror(mode):
    mirror = "/var/lib/hyper-aero"
    if os.path.isdir(mirror) and os.access(mirror, os.W_OK):
        try:
            tmp = os.path.join(mirror, ".mode.tmp")
            with open(tmp, "w", encoding="utf-8") as f:
                f.write(mode + "\n")
            os.chmod(tmp, 0o644)
            os.replace(tmp, os.path.join(mirror, "mode"))
        except OSError:
            pass


def write_night_jsonc():
    src = waybar_config()
    if not src:
        return
    with open(src, encoding="utf-8") as f:
        text = f.read()
    for a, b in WAYBAR_MAP.items():
        text = re.sub(re.escape(a), b, text, flags=re.I)
    with open(os.path.join(THEME, "night", "waybar.jsonc"), "w", encoding="utf-8") as f:
        f.write(text)


def point_current(mode):
    tmp = CURRENT + ".new"
    try:
        os.remove(tmp)
    except FileNotFoundError:
        pass
    if mode == "night":
        try:
            write_night_jsonc()
        except OSError as e:
            log(f"night jsonc: {e}")
    acc = current_accent()
    target = os.path.join(THEME, mode)
    if acc != "blue":
        try:
            target = aero_tint.build(acc, mode)
        except Exception as e:
            log(f"accent build {acc}-{mode}: {e}")
            target = os.path.join(THEME, mode)
    os.symlink(target, tmp)
    os.replace(tmp, CURRENT)
    with open(MODE, "w", encoding="utf-8") as f:
        f.write(mode + "\n")
    write_mirror(mode)


def step_gtk(mode):
    if not has("gsettings"):
        return
    iface = "org.gnome.desktop.interface"
    night = mode == "night"
    sh(["gsettings", "set", iface, "color-scheme", "prefer-dark" if night else "prefer-light"])
    themes = [os.path.join(HOME, ".local/share/themes"), os.path.join(HOME, ".themes"), "/usr/share/themes"]
    gtk = "adw-gtk3-dark" if night else "adw-gtk3"
    if any(os.path.isdir(os.path.join(t, gtk)) for t in themes):
        sh(["gsettings", "set", iface, "gtk-theme", gtk])
    icons = [os.path.join(HOME, ".local/share/icons"), os.path.join(HOME, ".icons"), "/usr/share/icons"]
    icon = "Papirus-Dark" if night else "Papirus-Light"
    if any(os.path.isdir(os.path.join(t, icon)) for t in icons):
        sh(["gsettings", "set", iface, "icon-theme", icon])
    sh(["gsettings", "set", iface, "accent-color", GNOME_ACCENT.get(current_accent(), "blue")])


def step_hyprland(mode):
    if has("hyprctl"):
        r = sh(["hyprctl", "eval", tint(HYPR[mode])])
        if r and r.returncode != 0:
            log(f"hyprctl eval: {r.stdout.strip()} {r.stderr.strip()}")


def profile_still():
    try:
        with open(os.path.join(AERO, "profile.json"), encoding="utf-8") as f:
            return json.load(f).get("wallpaper") == "still"
    except (OSError, ValueError, AttributeError):
        return False


def wall_path(mode):
    night = os.path.join(WALL, "aero-motion-night.mp4")
    day = os.path.join(WALL, "aero-motion.mp4")
    path = night if mode == "night" and os.path.isfile(night) else day
    acc = current_accent()
    if acc != "blue":
        own = os.path.join(WALL, f"aero-{acc}-{mode}.mp4")
        if os.path.isfile(own):
            path = own
    try:
        with open(os.path.join(THEME, "wallpaper"), encoding="utf-8") as f:
            wid = f.read().strip()
    except OSError:
        wid = ""
    if wid and wid != "auto" and "/" not in wid:
        own = os.path.join(WALL, "custom", wid, f"{mode}.mp4")
        if os.path.isfile(own):
            path = own
    if profile_still() or not os.path.isfile(path):
        still = os.path.splitext(path)[0] + ".jpg"
        if os.path.isfile(still):
            path = still
    return path


def step_wallpaper(mode):
    path = wall_path(mode)
    sock = os.path.join(RUN, "aero-motion.sock")
    if not os.path.exists(sock):
        return
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(2)
            s.connect(sock)
            s.sendall((json.dumps({"command": ["loadfile", path, "replace"]}) + "\n").encode())
            time.sleep(0.1)
    except OSError as e:
        log(f"wallpaper: {e}")


def waybar_config():
    for name in ("config.jsonc", "config"):
        p = os.path.join(HOME, ".config", "waybar", name)
        if os.path.isfile(p):
            return p
    return None


def step_waybar(mode):
    if running("waybar"):
        sh(["pkill", "-x", "waybar"])
        for _ in range(20):
            if not running("waybar"):
                break
            time.sleep(0.1)
        spawn([os.path.join(SCRIPTS, "aerobar.sh")])


def step_swaync(mode):
    if has("swaync-client") and running("swaync"):
        sh(["swaync-client", "-rs"])


def step_eww(mode):
    if not has("eww"):
        return
    safe = os.path.join(SCRIPTS, "aero-eww")
    reload = [safe, "reload"] if os.access(safe, os.X_OK) else ["eww", "reload"]
    for _ in range(3):
        r = sh(["eww", "ping"], timeout=3)
        if r and r.returncode == 0:
            done = sh(reload, timeout=60)
            if done and done.returncode == 0:
                return
        time.sleep(1.0)
    log("eww reload failed")


def step_kitty(mode):
    sh(["pkill", "-USR1", "-x", "kitty"])


def step_vesktop(mode):
    target = os.path.join(HOME, ".config", "vesktop", "settings", "quickCss.css")
    if not os.path.isdir(os.path.dirname(target)):
        return
    day = os.path.join(THEME, "day", "vesktop-quickcss.css")
    if not os.path.isfile(day):
        return
    with open(day, encoding="utf-8") as f:
        text = f.read()
    if mode == "night":
        extra = os.path.join(THEME, "night", "vesktop.css")
        if os.path.isfile(extra):
            with open(extra, encoding="utf-8") as f:
                text = text.rstrip() + "\n\n" + f.read()
    with open(target, "w", encoding="utf-8") as f:
        f.write(tint(text))


def spicetify_theme_dir():
    if not has("spicetify"):
        return None, None
    r = sh(["spicetify", "config", "current_theme"])
    theme = r.stdout.strip() if r and r.returncode == 0 else ""
    if not theme or theme.lower() in ("none", "marketplace"):
        return None, None
    roots = []
    r = sh(["spicetify", "path", "userdata"])
    if r and r.returncode == 0 and r.stdout.strip():
        roots.append(r.stdout.strip().splitlines()[-1])
    roots.append(os.path.join(HOME, ".config", "spicetify"))
    for root in roots:
        d = os.path.join(root, "Themes", theme)
        if os.path.isdir(d):
            return theme, d
    return theme, None


def step_spotify(mode):
    theme, tdir = spicetify_theme_dir()
    if not tdir:
        return
    st = load_json(STATE, {})
    acc = current_accent()
    applied = mode if acc == "blue" else f"{acc}-{mode}"
    if st.get("spotify_applied") == applied:
        return
    user = os.path.join(tdir, "user.css")
    day_css = os.path.join(THEME, "day", "spotify-user.css")
    if not os.path.isfile(day_css):
        return
    color = os.path.join(tdir, "color.ini")
    night_ini = os.path.join(THEME, "night", "spotify-color.ini")
    text = ""
    if os.path.isfile(color):
        with open(color, encoding="utf-8") as f:
            text = f.read()
    if "[night-deck]" not in text and os.path.isfile(night_ini):
        with open(night_ini, encoding="utf-8") as f:
            text = text.rstrip() + ("\n\n" if text.strip() else "") + f.read()
        with open(color, "w", encoding="utf-8") as f:
            f.write(text)
    section = "night-deck" if acc == "blue" else f"night-deck-{acc}"
    if acc != "blue" and f"[{section}]" not in text and os.path.isfile(night_ini) and aero_tint:
        with open(night_ini, encoding="utf-8") as f:
            extra_ini = aero_tint.recolor_ini(f.read(), acc).replace("[night-deck]", f"[{section}]")
        text = text.rstrip() + "\n\n" + extra_ini
        with open(color, "w", encoding="utf-8") as f:
            f.write(text)
    with open(day_css, encoding="utf-8") as f:
        css = f.read()
    if mode == "night":
        extra = os.path.join(THEME, "night", "spotify-user.css")
        if os.path.isfile(extra):
            with open(extra, encoding="utf-8") as f:
                css = css.rstrip() + "\n\n" + f.read()
    with open(user, "w", encoding="utf-8") as f:
        f.write(tint(css))
    wanted = section if mode == "night" else st.get("spotify_day_scheme", "")
    if wanted:
        sh(["spicetify", "config", "color_scheme", wanted])
    r = sh(["spicetify", "apply", "-n"], timeout=180)
    if r and r.returncode == 0:
        st = load_json(STATE, {})
        st["spotify_applied"] = applied
        save_json(STATE, st)
    if running("spotify"):
        notify("Spotify", _t("El tema nuevo de Spotify aparece la próxima vez que lo abras."), low=True)


def has_overlay(path, overlay):
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
        with open(overlay, encoding="utf-8") as f:
            extra = f.read().strip()
    except OSError:
        return False
    return bool(extra) and extra in text


def capture_day():
    vesk = os.path.join(HOME, ".config", "vesktop", "settings", "quickCss.css")
    if os.path.isfile(vesk) and not has_overlay(vesk, os.path.join(THEME, "night", "vesktop.css")):
        shutil.copyfile(vesk, os.path.join(THEME, "day", "vesktop-quickcss.css"))
    theme, tdir = spicetify_theme_dir()
    if tdir:
        st = load_json(STATE, {})
        if st.get("spotify_applied", "day") == "day":
            user = os.path.join(tdir, "user.css")
            day_css = os.path.join(THEME, "day", "spotify-user.css")
            if os.path.isfile(user) and not has_overlay(user, os.path.join(THEME, "night", "spotify-user.css")):
                shutil.copyfile(user, day_css)
            elif not os.path.isfile(day_css):
                open(day_css, "w").close()
            r = sh(["spicetify", "config", "color_scheme"])
            scheme = r.stdout.strip() if r and r.returncode == 0 else ""
            if scheme and not scheme.startswith("night-deck"):
                st["spotify_day_scheme"] = scheme
                save_json(STATE, st)


STEPS = [step_gtk, step_hyprland, step_wallpaper, step_waybar, step_swaync, step_eww, step_kitty, step_vesktop,
         step_spotify]
BOOT_STEPS = [step_gtk, step_hyprland, step_wallpaper]


def notify(title, body, low=False):
    if has("notify-send"):
        args = ["notify-send", "-a", "NIGHT DECK", title, body]
        if low:
            args[1:1] = ["-u", "low"]
        sh(args)


def signal_bar():
    sh(["pkill", "-RTMIN+9", "-x", "waybar"])



def link_wallpaper(name):
    if os.environ.get("AERO_KEEP_WALL"):
        return
    wid = "auto"
    if name not in ("blue", "red", "green", "black"):
        try:
            with open(os.path.join(AERO, "studio", "themes.json"), encoding="utf-8") as f:
                items = json.load(f)
            for t in items:
                if isinstance(t, dict) and t.get("accent") == name and t.get("wallpaper"):
                    wid = str(t["wallpaper"])
                    break
        except (OSError, ValueError):
            pass
    try:
        os.makedirs(THEME, exist_ok=True)
        with open(os.path.join(THEME, "wallpaper.tmp"), "w", encoding="utf-8") as f:
            f.write(wid + "\n")
        os.replace(os.path.join(THEME, "wallpaper.tmp"), os.path.join(THEME, "wallpaper"))
    except OSError as e:
        log(f"link_wallpaper: {e}")

def set_accent(name, mode=None):
    if name == "next":
        cur = current_accent()
        name = ACCENTS[(ACCENTS.index(cur) + 1) % len(ACCENTS)] if cur in ACCENTS else "blue"
    if name not in ACCENTS and not (aero_tint and hasattr(aero_tint, "valid") and aero_tint.valid(name)):
        print("temas: " + ", ".join(ACCENTS) + ", next")
        return 1
    if name != "blue" and not aero_tint:
        notify(_t("◢ TEMAS"), _t("Falta aero_tint.py en ~/.config/hyper-aero/scripts"), low=True)
        return 1
    tmp = ACCENT_FILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(name + "\n")
    os.replace(tmp, ACCENT_FILE)
    link_wallpaper(name)
    if mode in ("day", "night") and mode != current_mode():
        st = load_json(STATE, {})
        _, nxt = schedule(time.time())
        if mode == schedule(time.time())[0]:
            st.pop("manual_until", None)
            st.pop("manual_mode", None)
        else:
            st["manual_mode"] = mode
            st["manual_until"] = nxt
        save_json(STATE, st)
    target = mode if mode in ("day", "night") else current_mode()
    apply(target, announce=False)
    notify(_t("◢ TEMA {}").format(ACCENT_NAMES.get(name, "PERSONAL")), _t("Colores y fondo actualizados · modo noche") if target == "night" else _t("Colores y fondo actualizados · modo día"))
    return 0


VEIL_CMD = os.path.join(RUN, "aero-veil.cmd")
VEIL_STATE = os.path.join(RUN, "aero-veil.state")
VEIL_TINT = {"blue": "3d9be9", "red": "e0384f", "green": "2fbf8a", "black": "4a5060"}
LATE_STEPS = ("step_spotify",)


def veil_alive():
    r = sh(["pgrep", "-f", "qs -c aero-veil$"])
    return bool(r and r.returncode == 0)


def veil_send(line):
    try:
        with open(VEIL_CMD, "w", encoding="utf-8") as f:
            f.write(line + "\n")
    except OSError as e:
        log(f"veil: {e}")


def veil_wait(word, ident, limit):
    end = time.time() + limit
    while time.time() < end:
        try:
            with open(VEIL_STATE, encoding="utf-8") as f:
                got = f.read().split()
        except OSError:
            got = []
        if got[:2] == [word, ident]:
            return True
        time.sleep(0.01)
    return False


def veil_monitors():
    r = sh(["hyprctl", "monitors", "-j"])
    if not r or r.returncode != 0:
        return []
    try:
        return [m["name"] for m in json.loads(r.stdout)]
    except (ValueError, KeyError, TypeError):
        return []



def veil_style(mode):
    import re as _re
    import colorsys as _cs
    if current_mode() != mode:
        if mode == "night":
            return "night", "040a16", 0.2, _t("MODO_NOCHE")
        return "day", "ffffff", 0.18, _t("MODO_DÍA")
    acc = current_accent()
    tint = VEIL_TINT.get(acc)
    m = _re.match(r"^c-(\d{1,3})-(\d{1,3})$", acc or "")
    if not tint and m:
        r, g, b = _cs.hls_to_rgb(int(m.group(1)) / 360.0, 0.57, min(1.0, 0.82 * int(m.group(2)) / 100.0))
        tint = "%02x%02x%02x" % (int(r * 255), int(g * 255), int(b * 255))
    names = globals().get("ACCENT_NAMES", {})
    name = names.get(acc, "PERSONAL") if isinstance(names, dict) else "PERSONAL"
    return "theme", tint or "3d9be9", 0.1, (_t("TEMA_") + str(name)).replace(" ", "_")

def veil_cover(mode):
    try:
        with open(os.path.join(AERO, "profile.json"), encoding="utf-8") as f:
            if json.load(f).get("transition") is False:
                return None
    except (OSError, ValueError, AttributeError):
        pass
    if os.environ.get("AERO_NO_VEIL") or not has("grim") or not has("hyprctl") or running("hyprlock"):
        return None
    if not veil_alive():
        veil = os.path.join(SCRIPTS, "veil.sh")
        if os.access(veil, os.X_OK):
            spawn([veil, "daemon"])
        return None
    names = veil_monitors()
    if not names:
        return None
    procs = []
    for n in names:
        try:
            procs.append(subprocess.Popen(["grim", "-t", "ppm", "-o", n, os.path.join(RUN, f"aero-veil-{n}.ppm")],
                                          stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
        except OSError as e:
            log(f"veil grim: {e}")
            return None
    for p in procs:
        try:
            if p.wait(timeout=3) != 0:
                return None
        except subprocess.TimeoutExpired:
            p.kill()
            return None
    kind, tint, amount, label = veil_style(mode)
    ident = str(int(time.time() * 1000))
    veil_send(f"cover {ident} {tint} {amount} {kind} {label}")
    if veil_wait("covered", ident, 0.8):
        return ident
    veil_send(f"reveal {ident}")
    return None


def hypr_anims(on):
    sh(["hyprctl", "eval", "hl.config({ animations = { enabled = %s } })" % ("true" if on else "false")])


def mpv_get(prop):
    path = os.path.join(RUN, "aero-motion.sock")
    if not os.path.exists(path):
        return "gone"
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(0.3)
            s.connect(path)
            s.sendall((json.dumps({"command": ["get_property", prop], "request_id": 42}) + "\n").encode())
            buf = b""
            while True:
                chunk = s.recv(4096)
                if not chunk:
                    return None
                buf += chunk
                while b"\n" in buf:
                    line, buf = buf.split(b"\n", 1)
                    try:
                        m = json.loads(line)
                    except ValueError:
                        continue
                    if m.get("request_id") == 42:
                        return m.get("data")
    except OSError:
        return "gone"


def veil_settle(deadline, had_bar):
    while had_bar and time.time() < deadline:
        r = sh(["hyprctl", "layers", "-j"], timeout=2)
        if r and r.returncode == 0 and '"waybar"' in r.stdout:
            break
        time.sleep(0.05)
    while time.time() < deadline:
        t = mpv_get("time-pos")
        if t == "gone" or (isinstance(t, (int, float)) and t > 0.08):
            break
        time.sleep(0.04)
    time.sleep(max(0.0, min(0.16, deadline - time.time())))


def smooth_apply(mode, steps):
    veil = veil_cover(mode) if steps is None else None
    run = list(steps or STEPS)
    late = [s for s in run if s.__name__ in LATE_STEPS] if veil else []
    now = [s for s in run if s not in late]

    def work():
        try:
            point_current(mode)
        except Exception as e:
            log(f"point_current: {e}")
        for step in now:
            try:
                step(mode)
            except Exception as e:
                log(f"{step.__name__}: {e}")

    if not veil:
        work()
        return
    had_bar = running("waybar")
    hypr_anims(False)
    start = time.time()
    worker = threading.Thread(target=work)
    try:
        worker.start()
        worker.join(3.0)
        veil_settle(start + 3.6, had_bar)
    finally:
        hypr_anims(True)
        veil_send(f"reveal {veil}")
    worker.join()
    for step in late:
        try:
            step(mode)
        except Exception as e:
            log(f"{step.__name__}: {e}")


def apply(mode, announce=True, steps=None):
    ensure_layout()
    with open(os.path.join(THEME, ".apply.lock"), "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if current_mode() == "day" and mode == "night":
            try:
                capture_day()
            except Exception as e:
                log(f"capture_day: {e}")
        smooth_apply(mode, steps)
    signal_bar()
    if announce:
        if mode == "night":
            notify("◢ NIGHT DECK", _t("Modo noche · cabina en penumbra"))
        else:
            notify("◢ DAY DECK", _t("Modo día · luces de la estación encendidas"))
    log(f"applied {mode}")


def desired(st, now, cfg):
    if st.get("manual_until", 0) > now and st.get("manual_mode") in ("day", "night"):
        return st["manual_mode"]
    return schedule(now, cfg)[0]


def set_manual(mode):
    now = time.time()
    st = load_json(STATE, {})
    _, nxt = schedule(now)
    if mode == schedule(now)[0]:
        st.pop("manual_until", None)
        st.pop("manual_mode", None)
    else:
        st["manual_mode"] = mode
        st["manual_until"] = nxt
    save_json(STATE, st)
    apply(mode)


def warm_target(now, cfg, st):
    if st.get("warm_until", 0) > now and st.get("warm_manual") in ("on", "off"):
        return cfg["warm_kelvin"] if st["warm_manual"] == "on" else None
    if not cfg.get("warm_enabled", True):
        return None
    f = warm_factor(now, cfg)
    if f <= 0.0:
        return None
    return int(round(6500 - f * (6500 - cfg["warm_kelvin"])))


def ensure_sunset_daemon():
    if not has("hyprsunset"):
        return False
    if not running("hyprsunset"):
        spawn(["hyprsunset", "-i"])
        time.sleep(1.5)
    return True


def set_warm(kelvin):
    if not ensure_sunset_daemon():
        return
    if kelvin is None:
        sh(["hyprctl", "hyprsunset", "identity"])
    else:
        sh(["hyprctl", "hyprsunset", "temperature", str(kelvin)])


def warm_toggle(force=None):
    now = time.time()
    cfg = config()
    st = load_json(STATE, {})
    active = warm_target(now, cfg, st) is not None
    turn_on = (not active) if force is None else force
    st["warm_manual"] = "on" if turn_on else "off"
    st["warm_until"] = next_warm_end(now, cfg)
    save_json(STATE, st)
    set_warm(cfg["warm_kelvin"] if turn_on else None)
    signal_bar()
    notify(_t("Luz cálida"), _t("Encendida · {} K").format(cfg["warm_kelvin"]) if turn_on else _t("Apagada hasta mañana"), low=True)


def status(as_waybar=False):
    now = time.time()
    cfg = config()
    st = load_json(STATE, {})
    mode = current_mode()
    sched, nxt = schedule(now, cfg)
    manual = st.get("manual_until", 0) > now
    kelvin = warm_target(now, cfg, st)
    b = day_bounds(now, cfg)[0]
    fmt = lambda t: datetime.datetime.fromtimestamp(t).strftime("%H:%M")
    lines = [
        f"{'NIGHT' if mode == 'night' else 'DAY'} DECK  ·  " + (_t("manual hasta {}").format(fmt(nxt)) if manual else _t("automático")),
        _t("Amanecer {}  ·  Atardecer {}").format(fmt(b[0]), fmt(b[1])),
        _t("Luz cálida: {}").format(str(kelvin) + " K" if kelvin else _t("apagada")),
        _t("Tema: {}").format(ACCENT_NAMES.get(current_accent(), "PERSONAL")),
        _t("Clic: cambiar  ·  Clic derecho: luz cálida  ·  Clic medio: automático"),
    ]
    if as_waybar:
        text = ICON_NIGHT if mode == "night" else ICON_DAY
        if kelvin:
            text += " <span size='7000'>●</span>"
        cls = [mode, "accent-" + current_accent()] + (["manual"] if manual else []) + (["warm"] if kelvin else [])
        print(json.dumps({"text": text, "class": cls, "alt": mode, "tooltip": "\n".join(lines)}, ensure_ascii=False))
    else:
        print("\n".join(lines))
    return 0


def eww_guard():
    daemons = eww_daemons(min_age=10)
    if len(daemons) >= 2:
        log(f"eww guard: {len(daemons)} daemons running")
        eww_revive("duplicate")


def watch_reloads():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        return
    path = os.path.join(RUN, "hypr", sig, ".socket2.sock")
    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(path)
                buf = b""
                while True:
                    chunk = s.recv(4096)
                    if not chunk:
                        break
                    buf += chunk
                    while b"\n" in buf:
                        line, buf = buf.split(b"\n", 1)
                        if line.startswith(b"configreloaded"):
                            time.sleep(0.5)
                            step_hyprland(current_mode())
        except OSError:
            pass
        time.sleep(5)


DESK_WINDOWS = ["telemetry"]
EWW_LOCK = os.path.join(RUN, "aero-eww.lock")
REVIVE = threading.Lock()
QUIET = {"stdin": subprocess.DEVNULL, "stdout": subprocess.DEVNULL, "stderr": subprocess.DEVNULL}


def eww_procs():
    r = sh(["ps", "-C", "eww", "-o", "pid=,ppid=,etimes="])
    out = []
    if not r or r.returncode != 0:
        return out
    for line in r.stdout.splitlines():
        parts = line.split()
        if len(parts) == 3 and all(x.isdigit() for x in parts):
            out.append(tuple(int(x) for x in parts))
    return out


def eww_listeners():
    r = sh(["ss", "-xlpH"])
    if not r or r.returncode != 0:
        return None
    pids = set()
    for line in r.stdout.splitlines():
        if "eww-server" in line:
            pids.update(int(m) for m in re.findall(r"pid=(\d+)", line))
    return pids


def eww_daemons(min_age=0):
    procs = eww_procs()
    listening = eww_listeners()
    out = []
    for pid, ppid, age in procs:
        if age < min_age:
            continue
        if listening is not None:
            if pid in listening:
                out.append(pid)
        elif ppid == 1:
            out.append(pid)
    return out


def eww_ok(args, timeout):
    try:
        return subprocess.run(["eww", *args], timeout=timeout, **QUIET).returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


def proc_table():
    table = {}
    for d in os.listdir("/proc"):
        if not d.isdigit():
            continue
        try:
            with open(f"/proc/{d}/stat", encoding="utf-8", errors="replace") as f:
                stat = f.read()
            ppid = int(stat.rsplit(")", 1)[1].split()[1])
            with open(f"/proc/{d}/cmdline", "rb") as f:
                cmd = f.read().replace(b"\0", b" ").decode("utf-8", "replace").strip()
            table[int(d)] = (ppid, cmd)
        except (OSError, ValueError, IndexError):
            continue
    return table


def lock_holders():
    me = os.getpid()
    out = []
    for d in os.listdir("/proc"):
        if not d.isdigit() or int(d) == me:
            continue
        try:
            for fd in os.listdir(f"/proc/{d}/fd"):
                if os.readlink(f"/proc/{d}/fd/{fd}") == EWW_LOCK:
                    out.append(int(d))
                    break
        except OSError:
            continue
    return out


def descendants(table, roots):
    kids = {}
    for pid, (ppid, _) in table.items():
        kids.setdefault(ppid, []).append(pid)
    found = []
    stack = list(roots)
    while stack:
        for child in kids.get(stack.pop(), []):
            if child in roots or child in found:
                continue
            found.append(child)
            stack.append(child)
    return found


def eww_helpers():
    table = proc_table()
    daemons = {p[0] for p in eww_procs()}
    marks = (SCRIPTS + "/", "playerctl", "cava", "socat")
    out = [pid for pid in descendants(table, daemons) if any(m in table[pid][1] for m in marks)]
    feeds = ("hud-media.sh", "hud-stats.sh", "hud-visualizer.sh", "hud-gpu-probe.sh", "sky-arc.py")
    orphans = {pid for pid, (ppid, cmd) in table.items()
               if ppid == 1 and SCRIPTS + "/" in cmd and any(f in cmd for f in feeds)}
    out += list(orphans) + descendants(table, orphans)
    return sorted(set(out))


def kill_all(pids, sig):
    for pid in pids:
        try:
            os.kill(pid, sig)
        except OSError:
            pass


def eww_revive(reason="manual"):
    ready = False
    with REVIVE:
        fd = open(EWW_LOCK, "a")
        try:
            deadline = time.time() + 30
            while True:
                try:
                    fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except OSError:
                    if time.time() > deadline:
                        break
                    time.sleep(0.2)
            helpers = eww_helpers()
            for sig in (15, 9):
                pids = [p[0] for p in eww_procs()]
                if not pids:
                    break
                kill_all(pids, sig)
                time.sleep(1.0)
            kill_all(set(helpers) | set(lock_holders()), 15)
            time.sleep(0.5)
            spawn(["eww", "daemon"])
            end = time.time() + 20
            while time.time() < end:
                if eww_ok(["ping"], 2) and eww_ok(["active-windows"], 3):
                    ready = True
                    break
                time.sleep(0.3)
            if ready:
                try:
                    subprocess.run(["eww", "open-many", *DESK_WINDOWS], timeout=30, **QUIET)
                except (OSError, subprocess.TimeoutExpired):
                    pass
        finally:
            try:
                fcntl.flock(fd, fcntl.LOCK_UN)
            except OSError:
                pass
            fd.close()
    log(f"eww revive ({reason}){'' if ready else ' · daemon did not answer'}")


def eww_lock_free():
    try:
        fd = open(EWW_LOCK, "a")
    except OSError:
        return True
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        fcntl.flock(fd, fcntl.LOCK_UN)
        return True
    except OSError:
        return False
    finally:
        fd.close()


def eww_watchdog():
    started = time.time()
    frozen = 0
    missing = 0
    while True:
        time.sleep(20)
        try:
            if not eww_lock_free():
                continue
            if time.time() - started > 90 and not eww_daemons():
                missing += 1
                if missing >= 2:
                    eww_revive("missing")
                    missing = 0
                continue
            missing = 0
            if not eww_daemons(min_age=45):
                frozen = 0
                continue
            if eww_ok(["active-windows"], 6):
                frozen = 0
                continue
            frozen += 1
            log(f"eww watchdog: no response ({frozen})")
            if frozen >= 2:
                eww_revive("frozen")
                notify("◢ DESK", _t("Los widgets se habían congelado; los reinicié."), low=True)
                frozen = 0
        except Exception as e:
            log(f"eww watchdog: {e}")


def daemon():
    ensure_layout()
    lock = open(os.path.join(THEME, ".daemon.lock"), "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return 0
    threading.Thread(target=watch_reloads, daemon=True).start()
    threading.Thread(target=eww_watchdog, daemon=True).start()
    time.sleep(3)
    first = True
    last_kelvin = "unset"
    while True:
        now = time.time()
        cfg = config()
        st = load_json(STATE, {})
        if st.get("manual_until") and st["manual_until"] <= now:
            st.pop("manual_until", None)
            st.pop("manual_mode", None)
            save_json(STATE, st)
        if st.get("warm_until") and st["warm_until"] <= now:
            st.pop("warm_until", None)
            st.pop("warm_manual", None)
            save_json(STATE, st)
        want = desired(st, now, cfg)
        if first and want == current_mode():
            apply(want, announce=False, steps=BOOT_STEPS)
        elif first or want != current_mode():
            apply(want, announce=not first)
        kelvin = warm_target(now, cfg, st)
        if kelvin != last_kelvin and (kelvin is None or last_kelvin in (None, "unset")
                                      or abs(kelvin - last_kelvin) >= 25):
            set_warm(kelvin)
            last_kelvin = kelvin
            signal_bar()
        write_mirror(current_mode())
        try:
            eww_guard()
        except Exception as e:
            log(f"eww guard: {e}")
        first = False
        time.sleep(15 if first else 30)


def main(argv):
    cmd = argv[0] if argv else "status"
    if cmd == "daemon":
        return daemon()
    if cmd == "toggle":
        set_manual("day" if current_mode() == "night" else "night")
        return 0
    if cmd in ("day", "night"):
        set_manual(cmd)
        return 0
    if cmd == "auto":
        st = load_json(STATE, {})
        for k in ("manual_until", "manual_mode", "warm_until", "warm_manual"):
            st.pop(k, None)
        save_json(STATE, st)
        apply(schedule()[0])
        set_warm(warm_target(time.time(), config(), st))
        notify("◢ NIGHT DECK", _t("Modo automático: sigo el amanecer y el atardecer."), low=True)
        return 0
    if cmd == "reapply":
        apply(current_mode(), announce=False)
        return 0
    if cmd == "warm":
        sub = argv[1] if len(argv) > 1 else "toggle"
        warm_toggle(None if sub == "toggle" else sub == "on")
        return 0
    if cmd == "status":
        return status("--waybar" in argv)
    if cmd == "accent":
        if len(argv) < 2 or argv[1] == "status":
            print(current_accent())
            return 0
        return set_accent(argv[1], argv[2] if len(argv) > 2 else None)
    if cmd == "eww-revive":
        eww_revive()
        return 0
    if cmd == "wallpath":
        print(wall_path(current_mode()))
        return 0
    if cmd == "location" and len(argv) >= 3:
        try:
            lat, lon = float(argv[1]), float(argv[2])
        except ValueError:
            print("uso: night-deck.py location LAT LON")
            return 1
        cfg = load_json(CONFIG, {})
        cfg.update({"lat": round(lat, 3), "lon": round(lon, 3)})
        os.makedirs(THEME, exist_ok=True)
        save_json(CONFIG, cfg)
        print(_t("Ubicación: {}, {}").format(cfg["lat"], cfg["lon"]))
        return 0
    print("uso: night-deck.py [toggle|day|night|auto|reapply|warm toggle|warm on|warm off|status [--waybar]|accent blue|red|green|black|next [day|night]|eww-revive|daemon]")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
