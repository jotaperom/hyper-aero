#!/usr/bin/env python3

import os
import re
import sys
import json
import time
import fcntl
import shutil
import socket
import threading
import subprocess

HOME = os.path.expanduser("~")
A = os.path.join(HOME, ".config", "hyper-aero")
SCRIPTS = os.path.join(A, "scripts")
STORE = os.path.join(A, "displays.json")
HYPRCONF = os.path.join(HOME, ".config", "hypr", "hyprland.lua")
GEN = os.path.join(HOME, ".config", "hypr", "aero-displays.lua")
RUN = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
PRIMARY = os.path.join(RUN, "aero-primary")
STATEFILE = os.path.join(RUN, "aero-displays.state")
KEYFILE = os.path.join(RUN, "aero-displays.key")
LOCK = os.path.join(RUN, "aero-displays.lock")
LOG = os.path.join(RUN, "aero-displays.log")
SOCK = os.path.join(RUN, "aero-motion.sock")
HUD = os.path.join(RUN, "aero-hud.variant")
HUDSCREEN = os.path.join(RUN, "aero-hud.screen")
INTERNAL = re.compile(r"^(eDP|LVDS|DSI)-")
VIRTUAL = re.compile(r"^(FALLBACK|HEADLESS|WAYLAND|X11)", re.I)
MODES = ("laptop", "duplicate", "extend", "external")
SIDES = ("left", "right", "above", "below")
QUIET = {"stdin": subprocess.DEVNULL, "stdout": subprocess.DEVNULL, "stderr": subprocess.DEVNULL}
MODE_NAMES = {"laptop": "Solo laptop", "duplicate": "Duplicar", "extend": "Extender", "external": "Solo monitor"}


def log(msg):
    try:
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(time.strftime("%H:%M:%S ") + msg + "\n")
    except OSError:
        pass


def sh(args, timeout=5):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout, stdin=subprocess.DEVNULL)
    except (OSError, subprocess.TimeoutExpired) as e:
        log(f"{args[0]}: {e}")
        return None


def ok(r):
    return bool(r and r.returncode == 0)


def spawn(args):
    try:
        subprocess.Popen(args, start_new_session=True, **QUIET)
    except OSError as e:
        log(f"spawn {args[0]}: {e}")


def write_text(path, text):
    try:
        tmp = path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            f.write(text)
        os.replace(tmp, path)
    except OSError:
        pass


def read_text(path, default=""):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read().strip()
    except OSError:
        return default


def load():
    try:
        with open(STORE, encoding="utf-8") as f:
            d = json.load(f)
        if isinstance(d, dict):
            d.setdefault("monitors", {})
            d.setdefault("laptop", {})
            return d
    except (OSError, ValueError):
        pass
    return {"monitors": {}, "laptop": {}}


def save(d):
    os.makedirs(os.path.dirname(STORE), exist_ok=True)
    write_text(STORE, json.dumps(d, ensure_ascii=False, indent=2) + "\n")


def monitors():
    r = sh(["hyprctl", "-j", "monitors", "all"], 4)
    if not ok(r):
        return []
    try:
        data = json.loads(r.stdout)
    except ValueError:
        return []
    return [m for m in data if isinstance(m, dict) and m.get("name") and not VIRTUAL.match(m["name"])]


def key_of(m):
    desc = (m.get("description") or "").strip()
    return desc or m.get("name", "")


def split(mons):
    lap = [m for m in mons if INTERNAL.match(m["name"])]
    ext = sorted((m for m in mons if not INTERNAL.match(m["name"])), key=lambda m: m["name"])
    return (lap[0] if lap else None), ext


def conf_profile(name):
    text = ""
    for path in (HYPRCONF, GEN, GEN + ".orig"):
        try:
            text += open(path, encoding="utf-8").read() + "\n"
        except OSError:
            pass
    for block in re.findall(r"hl\.monitor\(\s*\{(.*?)\}\s*\)", text, re.S):
        if re.search(r'output\s*=\s*"' + re.escape(name) + '"', block):
            out = {}
            m = re.search(r'mode\s*=\s*"([^"]+)"', block)
            if m:
                out["mode"] = m.group(1)
            s = re.search(r"scale\s*=\s*\"?([0-9.]+)", block)
            if s:
                out["scale"] = float(s.group(1))
            return out
    return {}


def is_mirror(m):
    return str(m.get("mirrorOf", "none") or "none") not in ("", "none")


def laptop_profile(store, lap):
    prof = store.setdefault("laptop", {})
    if not lap:
        return prof
    if prof.get("name") != lap["name"]:
        prof.clear()
        prof["name"] = lap["name"]
    fresh = "mode" not in prof
    if not lap.get("disabled") and lap.get("width") and not is_mirror(lap):
        rate = int(round(lap.get("refreshRate") or 60))
        prof.update({"mode": f'{lap["width"]}x{lap["height"]}@{rate}', "scale": lap.get("scale") or 1,
                     "w": lap["width"], "h": lap["height"]})
    if "mode" not in prof or "scale" not in prof:
        c = conf_profile(lap["name"])
        prof.setdefault("mode", c.get("mode", "preferred"))
        prof.setdefault("scale", c.get("scale", 1))
    if "w" not in prof:
        m = re.match(r"(\d+)x(\d+)", prof["mode"])
        if m:
            prof["w"], prof["h"] = int(m.group(1)), int(m.group(2))
        else:
            prof["w"], prof["h"] = native(lap)
    if fresh and not prof.get("scale_user"):
        prof["scale_user"] = laptop_scale(prof.get("w") or 1920)
    if prof.get("scale_user"):
        prof["scale"] = prof["scale_user"]
    return prof


def laptop_scale(w):
    if w >= 3800:
        return 2
    if w >= 2800:
        return 1.75
    if w >= 2500:
        return 1.5
    if w >= 1900:
        return 1.25
    return 1


def native(m):
    modes = m.get("availableModes") or []
    mm = re.match(r"(\d+)x(\d+)", modes[0]) if modes else None
    if mm:
        return int(mm.group(1)), int(mm.group(2))
    return int(m.get("width") or 1920), int(m.get("height") or 1080)


def default_scale(m):
    w, _ = native(m)
    if w >= 3800:
        return 1.5
    if w >= 2500:
        return 1.25
    return 1


def settings(store, ext):
    s = store["monitors"].get(key_of(ext))
    fresh = s is None
    if fresh:
        s = {"mode": "extend", "side": "right", "offset": 0.5, "scale": default_scale(ext), "hud": "primary"}
    s.setdefault("mode", "extend")
    s.setdefault("side", "right")
    s.setdefault("offset", 0.5)
    s.setdefault("scale", 1)
    s.setdefault("hud", "primary")
    return s, fresh


def lua_str(v):
    return '"' + str(v).replace("\\", "\\\\").replace('"', '\\"') + '"'


def num(v):
    f = float(v)
    return str(int(f)) if f == int(f) else f"{f:g}"


def rule(name, mode=None, pos=None, scale=None, disabled=False, mirror=None):
    parts = [f"output = {lua_str(name)}"]
    if disabled:
        parts.append("disabled = true")
    else:
        parts.append("disabled = false")
        parts.append(f"mode = {lua_str(mode or 'preferred')}")
        parts.append(f"position = {lua_str(pos or 'auto')}")
        parts.append(f"scale = {num(scale or 1)}")
        if mirror:
            parts.append(f"mirror = {lua_str(mirror)}")
    return "hl.monitor({ " + ", ".join(parts) + " })"


def layout_sig():
    return sorted((m["name"], bool(m.get("disabled")), m.get("x"), m.get("y"), m.get("width"), m.get("height"),
                   round(float(m.get("scale") or 1), 3), str(m.get("mirrorOf", "none"))) for m in monitors())


def connected_key(mons=None):
    return ",".join(sorted(m["name"] for m in (mons if mons is not None else monitors())))


def settle(limit=6.0):
    last, same, end = None, 0, time.time() + limit
    while time.time() < end:
        now = layout_sig()
        if now == last:
            same += 1
            if same >= 2:
                return now
        else:
            same = 0
        last = now
        time.sleep(0.25)
    return last


def logical(w, h, scale):
    s = float(scale) if scale else 1.0
    return int(round(w / s)), int(round(h / s))


def place(side, offset, ew, eh, lw, lh):
    offset = max(0.0, min(1.0, float(offset)))
    if side == "left":
        lx, ly = -lw, int(round(offset * (eh - lh)))
    elif side == "above":
        lx, ly = int(round(offset * (ew - lw))), -lh
    elif side == "below":
        lx, ly = int(round(offset * (ew - lw))), eh
    else:
        lx, ly = ew, int(round(offset * (eh - lh)))
    mx, my = min(0, lx), min(0, ly)
    return (-mx, -my), (lx - mx, ly - my)


def plan(store, lap, exts):
    prof = laptop_profile(store, lap) if lap else {}
    rules = []
    if not exts:
        if lap:
            rules.append(rule(lap["name"], prof["mode"], "0x0", prof["scale"]))
            return rules, lap["name"], lap["name"], "laptop", False, None
        return rules, None, None, "laptop", False, None
    e = exts[0]
    s, fresh = settings(store, e)
    mode = s["mode"] if lap else "external"
    es = s["scale"]
    ew, eh = logical(*native(e), es)
    if mode == "laptop":
        rules.append(rule(lap["name"], prof["mode"], "0x0", prof["scale"]))
        rules += [rule(x["name"], disabled=True) for x in exts]
        return rules, lap["name"], lap["name"], mode, fresh, s
    primary = hud = e["name"]
    if mode == "duplicate":
        rules.append(rule(e["name"], "preferred", "0x0", es))
        rules.append(rule(lap["name"], prof["mode"], "auto", prof["scale"], mirror=e["name"]))
    elif mode == "external" or not lap:
        rules.append(rule(e["name"], "preferred", "0x0", es))
        if lap:
            rules.append(f"if aero_has({lua_str(e['name'])}) then")
            rules.append("    " + rule(lap["name"], disabled=True))
            rules.append("else")
            rules.append("    " + rule(lap["name"], prof["mode"], f"{ew}x0", prof["scale"]))
            rules.append("end")
    else:
        lw, lh = logical(prof["w"], prof["h"], prof["scale"])
        (ex, ey), (lx, ly) = place(s["side"], s["offset"], ew, eh, lw, lh)
        rules.append(rule(e["name"], "preferred", f"{ex}x{ey}", es))
        rules.append(rule(lap["name"], prof["mode"], f"{lx}x{ly}", prof["scale"]))
        if s.get("hud") == "laptop":
            hud = lap["name"]
    x = 10000
    for other in exts[1:]:
        rules.append(rule(other["name"], "preferred", f"{x}x0", 1))
        x += native(other)[0]
    return rules, primary, hud, mode, fresh, s


HEADER = """local function aero_has(name)
    local ok, list = pcall(hl.get_monitors)
    if not ok or type(list) ~= "table" then
        return false
    end
    for _, m in ipairs(list) do
        local okn, n = pcall(function() return m.name end)
        if okn and n == name then
            return true
        end
    end
    return false
end

"""


def render(rules):
    return HEADER + "\n".join(rules) + "\n"


def install_rules(text, force=False):
    if not force and read_text(GEN) == text.strip():
        return False
    os.makedirs(os.path.dirname(GEN), exist_ok=True)
    write_text(GEN, text)
    r = sh(["hyprctl", "reload"], 10)
    if not ok(r):
        log(f"hyprctl reload: {(r.stdout + r.stderr).strip() if r else 'sin respuesta'}")
    return True


def notify(title, body):
    if shutil.which("notify-send"):
        spawn(["notify-send", "-a", "HYPER·AERO", "-t", "3500", "-h", "string:x-canonical-private-synchronous:aero-displays", title, body])


def gpu_hint():
    flag = os.path.join(RUN, "aero-displays.gpuhint")
    if os.environ.get("AERO_GPU_MODE") == "alt" or os.path.exists(flag):
        return
    alt = "/dev/dri/aero-gpu-alt"
    if not os.path.exists(alt):
        return
    card = os.path.basename(os.path.realpath(alt))
    base = "/sys/class/drm"
    try:
        names = os.listdir(base)
    except OSError:
        return
    for n in names:
        if n.startswith(card + "-") and read_text(os.path.join(base, n, "status")) == "connected":
            write_text(flag, "1")
            notify("◢ Monitor en la NVIDIA", "Para que vaya sin lag: cerrá sesión y volvé a entrar con la sesión HYPER·AERO")
            return


def apply(reason="manual"):
    before = layout_sig()
    mons = monitors()
    if not mons:
        log("hyprctl no respondió; no cambio nada")
        return None
    store = load()
    lap, exts = split(mons)
    rules, primary, hud, mode, fresh, s = plan(store, lap, exts)
    if not rules:
        log("no encontré pantallas para configurar")
        return None
    reloaded = install_rules(render(rules), force=reason == "inicio")
    if exts and fresh:
        store["monitors"][key_of(exts[0])] = s
    save(store)
    after = settle()
    if mode == "external" and lap and exts:
        now = {m["name"]: m for m in monitors()}
        if not now.get(lap["name"], {}).get("disabled") and now.get(exts[0]["name"]):
            log("el monitor venía apagado; recargo otra vez para apagar la laptop")
            sh(["hyprctl", "reload"], 10)
            after = settle()
    write_text(KEYFILE, connected_key(mons))
    write_text(PRIMARY, (primary or "") + "\n")
    publish()
    changed = after != before
    target = hud or primary or ""
    moved = target != read_text(HUDSCREEN)
    log(f"aplicado ({reason}) modo={mode} principal={primary} hud={hud} recarga={reloaded} cambio={changed}")
    if changed or reason == "hotplug":
        refresh(target)
    elif moved:
        telemetry(target)
    write_text(HUDSCREEN, target)
    if reason == "hotplug":
        if exts and fresh:
            spawn([os.path.join(SCRIPTS, "displays.sh"), "show"])
        elif exts:
            notify("◢ Monitor conectado", f"{MODE_NAMES.get(mode, mode)} · SUPER + P para cambiar")
        if exts:
            gpu_hint()
        else:
            notify("◢ Monitor desconectado", "Volviste a la pantalla de la laptop")
    return primary


def mpv(cmd):
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(1.0)
            s.connect(SOCK)
            s.sendall((json.dumps({"command": cmd, "request_id": 7}) + "\n").encode())
            buf = b""
            end = time.time() + 1.5
            while time.time() < end:
                chunk = s.recv(4096)
                if not chunk:
                    break
                buf += chunk
                for line in buf.split(b"\n"):
                    try:
                        m = json.loads(line)
                    except ValueError:
                        continue
                    if m.get("request_id") == 7:
                        return m.get("data") if m.get("error") == "success" else None
    except OSError:
        return None
    return None


def wallpaper():
    if not shutil.which("mpvpaper"):
        return
    path = mpv(["get_property", "path"])
    paused = mpv(["get_property", "pause"])
    last = os.path.join(RUN, "aero-wall.last")
    if not (isinstance(path, str) and os.path.isfile(path)):
        path = read_text(last)
    if not os.path.isfile(path):
        path = os.path.join(A, "wallpapers", "aero-motion.mp4")
    if not os.path.isfile(path):
        return
    write_text(last, path)
    sh(["pkill", "-f", "mpvpaper.*aero-motion.sock"], 3)
    for _ in range(10):
        if not ok(sh(["pgrep", "-f", "mpvpaper.*aero-motion.sock"], 2)):
            break
        time.sleep(0.1)
    try:
        os.remove(SOCK)
    except OSError:
        pass
    spawn(["mpvpaper", "-o", f"no-audio loop hwdec=auto-safe image-display-duration=inf input-ipc-server={SOCK}", "ALL", path])
    if paused is True:
        for _ in range(25):
            time.sleep(0.15)
            if os.path.exists(SOCK) and mpv(["set_property", "pause", True]) is not None:
                break


def eww_alive():
    return ok(sh(["eww", "ping"], 2))


def eww_restart():
    sh(["pkill", "-x", "eww"], 3)
    time.sleep(0.5)
    sh(["pkill", "-9", "-x", "eww"], 2)
    spawn(["eww", "daemon"])
    for _ in range(30):
        time.sleep(0.2)
        if eww_alive():
            return True
    return False


def screen_index(name):
    r = sh(["hyprctl", "-j", "monitors"], 3)
    try:
        act = sorted(json.loads(r.stdout), key=lambda m: m.get("id", 0)) if ok(r) else []
    except ValueError:
        act = []
    for i, m in enumerate(act):
        if m.get("name") == name:
            return str(i)
    return None


def telemetry(screen):
    if not shutil.which("eww"):
        return
    variant = None
    alive = eww_alive()
    if alive:
        r = sh(["eww", "active-windows"], 3)
        if r is None:
            alive = False
        elif re.search(r"^telemetry-slim\b", r.stdout, re.M):
            variant = "telemetry-slim"
        elif re.search(r"^telemetry\b", r.stdout, re.M):
            variant = "telemetry"
    if variant:
        write_text(HUD, variant)
    else:
        variant = read_text(HUD) or "telemetry"
    if not alive and not eww_restart():
        log("eww no responde ni reiniciado")
        return
    if sh(["eww", "close", "telemetry", "telemetry-slim"], 5) is None and not eww_restart():
        return
    time.sleep(0.15)
    tries = []
    if screen:
        tries.append(["eww", "open", variant, "--screen", screen])
        idx = screen_index(screen)
        if idx is not None:
            tries.append(["eww", "open", variant, "--screen", idx])
    tries.append(["eww", "open", variant])
    for t in tries:
        r = sh(t, 8)
        if ok(r) and "error" not in (r.stdout + r.stderr).lower():
            return
        if r is None:
            eww_restart()


def restart(script, pattern):
    path = os.path.join(SCRIPTS, script)
    if os.access(path, os.X_OK) and ok(sh(["pgrep", "-f", pattern], 2)):
        spawn([path, "restart"])


def refresh(screen):
    for fn in (wallpaper, lambda: telemetry(screen)):
        try:
            fn()
        except Exception as e:
            log(f"refresh: {e}")
    restart("desk.sh", "qs -c aero-desk$")
    restart("phone.sh", "qs -c aero-phone$")
    restart("snap.sh", "qs -c aero-snap$")
    sh(["pkill", "-SIGUSR2", "-x", "waybar"], 2)


def locked(fn, *args, wait=15):
    fd = open(LOCK, "a")
    end = time.time() + wait
    while True:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            break
        except OSError:
            if time.time() > end:
                fd.close()
                log("otro cambio de pantalla sigue en curso; lo salto")
                return None
            time.sleep(0.15)
    try:
        return fn(*args)
    finally:
        fcntl.flock(fd, fcntl.LOCK_UN)
        fd.close()


def snapshot():
    store = load()
    lap, exts = split(monitors())
    out = {"laptop": None, "external": None, "mode": "laptop", "side": "right", "offset": 0.5, "scale": 1,
           "hud": "primary", "extra": max(0, len(exts) - 1)}
    if lap:
        prof = laptop_profile(store, lap)
        out["laptop"] = {"name": lap["name"], "w": prof["w"], "h": prof["h"], "scale": prof["scale"]}
    if exts:
        e = exts[0]
        s, _ = settings(store, e)
        w, h = native(e)
        desc = (str(e.get("make") or "") + " " + str(e.get("model") or "")).strip() or e.get("description") or e["name"]
        out["external"] = {"name": e["name"], "desc": desc, "w": w, "h": h}
        out.update({k: s[k] for k in ("mode", "side", "offset", "scale", "hud")})
    out["primary"] = read_text(PRIMARY)
    out["stamp"] = int(time.time() * 1000)
    return out


def publish():
    try:
        write_text(STATEFILE, json.dumps(snapshot(), ensure_ascii=False) + "\n")
    except Exception as e:
        log(f"publish: {e}")


def update(changes):
    store = load()
    lap, exts = split(monitors())
    lapset = [v for f, v in changes if f == "lapscale"]
    changes = [(f, v) for f, v in changes if f != "lapscale"]
    if lapset:
        try:
            val = round(max(0.5, min(3.0, float(lapset[-1]))), 2)
        except ValueError:
            print(json.dumps({"error": f"valor inválido: lapscale {lapset[-1]}"}), flush=True)
            return 1
        prof = store.setdefault("laptop", {})
        if lap:
            if prof.get("name") != lap["name"]:
                prof.clear()
            prof["name"] = lap["name"]
        prof["scale_user"] = val
        prof["scale"] = val
        if not changes:
            save(store)
            locked(apply, "manual", wait=30)
            return 0
    if not exts:
        print(json.dumps({"error": "No hay otro monitor conectado"}), flush=True)
        return 1
    e = exts[0]
    s, _ = settings(store, e)
    for field, value in changes:
        try:
            if field == "mode" and value in MODES:
                s["mode"] = value
            elif field == "side" and value in SIDES:
                s["side"] = value
            elif field == "offset":
                s["offset"] = round(max(0.0, min(1.0, float(value))), 3)
            elif field == "scale":
                s["scale"] = round(max(0.5, min(3.0, float(value))), 2)
            elif field == "hud" and value in ("primary", "laptop"):
                s["hud"] = value
            else:
                raise ValueError
        except ValueError:
            print(json.dumps({"error": f"valor inválido: {field} {value}"}), flush=True)
            return 1
    store["monitors"][key_of(e)] = s
    save(store)
    locked(apply, "manual", wait=30)
    return 0


def daemon():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        print("No estoy dentro de Hyprland")
        return 1
    me = open(os.path.join(RUN, "aero-displays.daemon"), "a")
    try:
        fcntl.flock(me, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        print("El servicio de pantallas ya está corriendo")
        return 0
    path = os.path.join(RUN, "hypr", sig, ".socket2.sock")
    log(f"servicio iniciado (pid {os.getpid()})")
    timer = {"t": None, "force": False}
    guard = threading.Lock()

    def fire():
        try:
            run_fire()
        except Exception as e:
            log(f"error al aplicar: {e}")

    def run_fire():
        with guard:
            timer["t"] = None
            force = timer["force"]
            timer["force"] = False
        mons = monitors()
        if not mons:
            log("evento de monitor pero hyprctl no respondió")
            return
        log(f"evento de monitor: {connected_key(mons)}")
        if connected_key(mons) != read_text(KEYFILE):
            locked(apply, "hotplug", wait=30)
        elif force:
            locked(apply, "recarga", wait=30)

    def schedule(force=False, delay=0.8):
        with guard:
            timer["force"] = timer["force"] or force
            if timer["t"]:
                timer["t"].cancel()
            timer["t"] = threading.Timer(delay, fire)
            timer["t"].daemon = True
            timer["t"].start()

    for _ in range(40):
        if monitors():
            break
        time.sleep(0.25)
    try:
        locked(apply, "inicio", wait=30)
    except Exception as e:
        log(f"inicio falló: {e}")
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
                        if line.startswith((b"monitoradded", b"monitorremoved")):
                            schedule()
                        elif line.startswith(b"configreloaded"):
                            schedule(force=True, delay=0.6)
        except OSError as e:
            log(f"socket2: {e}")
        if not os.path.exists(path):
            log("Hyprland se cerró; termino el servicio")
            return 0
        time.sleep(1)


def main(argv):
    cmd = argv[0] if argv else "state"
    if cmd == "daemon":
        return daemon()
    if cmd == "apply":
        locked(apply, "manual", wait=30)
        return 0
    if cmd == "state":
        snap = snapshot()
        write_text(STATEFILE, json.dumps(snap, ensure_ascii=False) + "\n")
        print(json.dumps(snap, ensure_ascii=False), flush=True)
        return 0
    if cmd == "set" and len(argv) >= 3 and len(argv) % 2 == 1:
        return update(list(zip(argv[1::2], argv[2::2])))
    if cmd in ("mode", "side", "scale", "lapscale", "offset", "hud") and len(argv) > 1:
        return update([(cmd, argv[1])])
    if cmd == "next":
        store = load()
        lap, exts = split(monitors())
        if not exts:
            notify("◢ Pantallas", "No hay otro monitor conectado")
            return 0
        s, _ = settings(store, exts[0])
        nxt = MODES[(MODES.index(s["mode"]) + 1) % len(MODES)] if s["mode"] in MODES else "extend"
        notify("◢ Pantallas", MODE_NAMES[nxt])
        return update([("mode", nxt)])
    print("uso: aero-displays.py daemon | apply | state | next | mode laptop|duplicate|extend|external | "
          "side left|right|above|below | offset 0..1 | scale N | lapscale N | hud primary|laptop | set CAMPO VALOR ...")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
