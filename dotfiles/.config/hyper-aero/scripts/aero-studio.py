#!/usr/bin/env python3

import os
import re
import sys
import json
import time
import shutil
import subprocess

HOME = os.path.expanduser("~")
A = os.path.join(HOME, ".config", "hyper-aero")
THEME = os.path.join(A, "theme")
SCRIPTS = os.path.join(A, "scripts")
WALL = os.path.join(A, "wallpapers")
CUSTOM = os.path.join(WALL, "custom")
STUDIO = os.path.join(A, "studio")
THEMES = os.path.join(STUDIO, "themes.json")
CACHE = os.path.join(HOME, ".cache", "hyper-aero", "studio")
GEN = os.path.join(SCRIPTS, "aero-wallgen.py")
ND = os.path.join(SCRIPTS, "night-deck.py")
PRESETS = ("blue", "red", "green", "black")
CUSTOM_RE = re.compile(r"^c-\d{1,3}-\d{1,3}$")


def out(obj):
    print(json.dumps(obj, ensure_ascii=False), flush=True)


def read(path, default=""):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read().strip()
    except OSError:
        return default


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
    os.replace(tmp, path)


def valid_accent(a):
    return a in PRESETS or bool(CUSTOM_RE.match(a or ""))


def load_themes():
    try:
        with open(THEMES, encoding="utf-8") as f:
            data = json.load(f)
        return [t for t in data if isinstance(t, dict) and t.get("id")]
    except (OSError, ValueError):
        return []


def save_themes(items):
    write(THEMES, json.dumps(items, ensure_ascii=False, indent=2) + "\n")


def walls():
    res = []
    if not os.path.isdir(CUSTOM):
        return res
    for wid in sorted(os.listdir(CUSTOM), reverse=True):
        d = os.path.join(CUSTOM, wid)
        if not (os.path.isfile(os.path.join(d, "day.mp4")) and os.path.isfile(os.path.join(d, "night.mp4"))):
            continue
        try:
            spec = json.load(open(os.path.join(d, "spec.json"), encoding="utf-8"))
        except (OSError, ValueError):
            spec = {}
        res.append({"id": wid, "name": spec.get("name") or wid, "thumb": os.path.join(d, "thumb.jpg"),
                    "day": os.path.join(d, "day.jpg"), "night": os.path.join(d, "night.jpg")})
    return res


def preset_video(accent, mode):
    acc = accent if accent in PRESETS else "blue"
    if acc != "blue":
        own = os.path.join(WALL, f"aero-{acc}-{mode}.mp4")
        if os.path.isfile(own):
            return own
    night = os.path.join(WALL, "aero-motion-night.mp4")
    if mode == "night" and os.path.isfile(night):
        return night
    return os.path.join(WALL, "aero-motion.mp4")


def still(video, tag):
    if not os.path.isfile(video):
        return ""
    os.makedirs(CACHE, exist_ok=True)
    stamp = int(os.stat(video).st_mtime)
    dest = os.path.join(CACHE, f"{tag}-{stamp}.jpg")
    if not os.path.isfile(dest):
        for f in os.listdir(CACHE):
            if f.startswith(tag + "-"):
                try:
                    os.remove(os.path.join(CACHE, f))
                except OSError:
                    pass
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", "4", "-i", video, "-frames:v", "1",
                        "-vf", "scale=960:-2", "-q:v", "3", dest], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return dest if os.path.isfile(dest) else ""


def cmd_state():
    accent = read(os.path.join(THEME, "accent"), "blue")
    if not valid_accent(accent):
        accent = "blue"
    mode = "night" if read(os.path.join(THEME, "mode"), "day") == "night" else "day"
    wall = read(os.path.join(THEME, "wallpaper"), "auto") or "auto"
    ws = walls()
    if wall != "auto" and not any(w["id"] == wall for w in ws):
        wall = "auto"
    preset = accent if accent in PRESETS else "blue"
    autos = {}
    for p in PRESETS:
        autos[p] = {"day": still(preset_video(p, "day"), f"auto-{p}-day"),
                    "night": still(preset_video(p, "night"), f"auto-{p}-night")}
    out({"accent": accent, "mode": mode, "wallpaper": wall, "walls": ws, "themes": load_themes(),
         "autoDay": autos[preset]["day"], "autoNight": autos[preset]["night"], "autos": autos})


def cmd_pick():
    start = os.path.join(HOME, "Imágenes")
    if not os.path.isdir(start):
        start = os.path.join(HOME, "Pictures")
    if not os.path.isdir(start):
        start = HOME
    path = ""
    try:
        if shutil.which("zenity"):
            r = subprocess.run(["zenity", "--file-selection", "--title=Elegí una imagen para el fondo",
                                f"--filename={start}/", "--file-filter=Imágenes | *.png *.jpg *.jpeg *.webp *.PNG *.JPG *.JPEG *.WEBP"],
                               capture_output=True, text=True)
            path = r.stdout.strip()
        elif shutil.which("kdialog"):
            r = subprocess.run(["kdialog", "--getopenfilename", start, "*.png *.jpg *.jpeg *.webp"], capture_output=True, text=True)
            path = r.stdout.strip()
        else:
            out({"toast": "Instalá zenity para elegir imágenes: sudo pacman -S zenity"})
            return
    except OSError:
        pass
    if path:
        out({"image": path})


def cmd_palette(image):
    if not image or not os.path.isfile(image):
        out({"toast": "No encontré la imagen para analizar"})
        return
    r = subprocess.run([sys.executable, GEN, "palette", image], capture_output=True, text=True)
    for line in r.stdout.splitlines():
        if line.strip():
            print(line, flush=True)


def spec_file(raw, extra=None):
    spec = json.loads(raw)
    if extra:
        spec.update(extra)
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, "spec.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(spec, f, ensure_ascii=False)
    return spec, path


def cmd_preview(raw):
    spec, path = spec_file(raw)
    if not os.path.isfile(spec.get("image", "")):
        out({"toast": "Primero elegí una imagen"})
        return
    stamp = int(time.time() * 1000)
    for f in os.listdir(CACHE):
        if f.startswith("preview-"):
            try:
                os.remove(os.path.join(CACHE, f))
            except OSError:
                pass
    d, n = os.path.join(CACHE, f"preview-{stamp}-day.jpg"), os.path.join(CACHE, f"preview-{stamp}-night.jpg")
    r = subprocess.run([sys.executable, GEN, "preview", path, d, n], capture_output=True, text=True)
    if r.returncode == 0:
        out({"previewDay": d, "previewNight": n})
    else:
        out({"toast": "No pude preparar la vista previa"})


def cmd_render(raw):
    spec = json.loads(raw)
    img = spec.get("image", "")
    if not os.path.isfile(img):
        out({"toast": "Primero elegí una imagen"})
        return 1
    wid = time.strftime("%Y%m%d-%H%M%S")
    base = os.path.splitext(os.path.basename(img))[0].replace("_", " ").replace("-", " ").strip()
    name = (base[:1].upper() + base[1:])[:28] if base else "Fondo"
    spec, path = spec_file(raw, {"name": name})
    dest = os.path.join(CUSTOM, wid)
    os.makedirs(dest, exist_ok=True)
    shutil.copyfile(img, os.path.join(dest, "source" + os.path.splitext(img)[1].lower()))
    proc = subprocess.Popen([sys.executable, GEN, "render", path, dest], stdout=subprocess.PIPE, text=True)
    for line in proc.stdout:
        line = line.strip()
        if line:
            print(line, flush=True)
    if proc.wait() != 0 or not os.path.isfile(os.path.join(dest, "night.mp4")):
        shutil.rmtree(dest, ignore_errors=True)
        out({"toast": "No pude generar el fondo"})
        return 1
    out({"rendered": wid, "toast": f"Fondo «{name}» listo"})
    return 0


def cmd_apply(accent, wall):
    if not valid_accent(accent):
        out({"toast": "Ese color no es válido"})
        return 1
    if wall != "auto" and not os.path.isfile(os.path.join(CUSTOM, wall, "day.mp4")):
        wall = "auto"
    write(os.path.join(THEME, "wallpaper"), wall + "\n")
    r = subprocess.run([ND, "accent", accent], capture_output=True, text=True, env=dict(os.environ, AERO_KEEP_WALL="1"))
    out({"applied": True, "toast": "Tema aplicado" if r.returncode == 0 else "No pude aplicar el tema"})
    return 0


PRESET_NAMES = {"blue": "Azul", "red": "Rojo", "green": "Verde", "black": "Negro"}
PRESET_HEX = {"blue": "#3d9be9", "red": "#e0384f", "green": "#2fbf8a", "black": "#5a6270"}


def accent_hex(acc):
    if acc in PRESET_HEX:
        return PRESET_HEX[acc]
    m = re.match(r"^c-(\d{1,3})-(\d{1,3})$", acc or "")
    if not m:
        return PRESET_HEX["blue"]
    import colorsys
    r, g, b = colorsys.hls_to_rgb(int(m.group(1)) / 360.0, 0.57, min(1.0, 0.82 * int(m.group(2)) / 100.0))
    return "#%02x%02x%02x" % (int(r * 255), int(g * 255), int(b * 255))


def cmd_switch():
    accent = read(os.path.join(THEME, "accent"), "blue")
    if not valid_accent(accent):
        accent = "blue"
    mode = "night" if read(os.path.join(THEME, "mode"), "day") == "night" else "day"
    wall = read(os.path.join(THEME, "wallpaper"), "auto") or "auto"
    ws = {w["id"]: w for w in walls()}
    if wall != "auto" and wall not in ws:
        wall = "auto"
    autos = {}
    for p in PRESETS:
        autos[p] = {"day": still(preset_video(p, "day"), f"auto-{p}-day"),
                    "night": still(preset_video(p, "night"), f"auto-{p}-night")}
    items = [{"id": "p-" + p, "name": PRESET_NAMES[p], "accent": p, "wallpaper": "auto", "builtin": True} for p in PRESETS]
    items += [t for t in load_themes() if valid_accent(t.get("accent", ""))]
    out_items = []
    for t in items:
        wid = t.get("wallpaper") or "auto"
        w = ws.get(wid)
        if w:
            day, night, wname = w["day"], w["night"], w["name"]
        else:
            wid = "auto"
            a = autos[t["accent"] if t["accent"] in PRESETS else "blue"]
            day, night, wname = a["day"], a["night"], "Original del tema"
        out_items.append({"id": t["id"], "name": t.get("name") or "Tema", "accent": t["accent"], "wallpaper": wid,
                          "day": day, "night": night, "wallName": wname, "hex": accent_hex(t["accent"]),
                          "builtin": bool(t.get("builtin")), "current": t["accent"] == accent and wid == wall})
    if not any(i["current"] for i in out_items):
        w = ws.get(wall)
        a = autos[accent if accent in PRESETS else "blue"]
        out_items.insert(0, {"id": "now", "name": "Actual", "accent": accent, "wallpaper": wall,
                             "day": w["day"] if w else a["day"], "night": w["night"] if w else a["night"],
                             "wallName": w["name"] if w else "Original del tema", "hex": accent_hex(accent),
                             "builtin": False, "current": True})
    out({"mode": mode, "themes": out_items})


def cmd_save(name, accent, wall):
    items = load_themes()
    items.append({"id": "t" + str(int(time.time() * 1000)), "name": name[:32], "accent": accent, "wallpaper": wall})
    save_themes(items)
    out({"toast": f"Tema «{name[:32]}» guardado"})


def cmd_deltheme(tid):
    save_themes([t for t in load_themes() if t.get("id") != tid])
    out({"toast": "Tema borrado"})


def cmd_delwall(wid):
    if not re.match(r"^[0-9-]+$", wid or ""):
        return
    if read(os.path.join(THEME, "wallpaper"), "auto") == wid:
        write(os.path.join(THEME, "wallpaper"), "auto\n")
        subprocess.run([ND, "reapply"], capture_output=True)
    shutil.rmtree(os.path.join(CUSTOM, wid), ignore_errors=True)
    items = load_themes()
    for t in items:
        if t.get("wallpaper") == wid:
            t["wallpaper"] = "auto"
    save_themes(items)
    out({"toast": "Fondo borrado"})


def main(argv):
    cmd = argv[0] if argv else "state"
    if cmd == "state":
        cmd_state()
    elif cmd == "switch":
        cmd_switch()
    elif cmd == "pick":
        cmd_pick()
    elif cmd == "palette" and len(argv) > 1:
        cmd_palette(argv[1])
    elif cmd == "preview" and len(argv) > 1:
        cmd_preview(argv[1])
    elif cmd == "render" and len(argv) > 1:
        return cmd_render(argv[1])
    elif cmd == "apply" and len(argv) > 2:
        return cmd_apply(argv[1], argv[2])
    elif cmd == "save" and len(argv) > 3:
        cmd_save(argv[1], argv[2], argv[3])
    elif cmd == "deltheme" and len(argv) > 1:
        cmd_deltheme(argv[1])
    elif cmd == "delwall" and len(argv) > 1:
        cmd_delwall(argv[1])
    else:
        print("uso: aero-studio.py state|pick|palette IMG|preview JSON|render JSON|apply ACC WALL|save NOMBRE ACC WALL|deltheme ID|delwall ID")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
