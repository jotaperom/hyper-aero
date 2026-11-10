#!/usr/bin/env python3

import os
import re
import sys
import json
import time
import shutil
import hashlib
import zipfile
import subprocess
from aero_i18n import t as _t

HOME = os.path.expanduser("~")
A = os.path.join(HOME, ".config", "hyper-aero")
CUSTOM = os.path.join(A, "wallpapers", "custom")
STUDIO = os.path.join(A, "studio")
THEMES = os.path.join(STUDIO, "themes.json")
IMPORTED = os.path.join(STUDIO, "imported.json")
ACCENT_RE = re.compile(r"^(blue|red|green|black|c-\d{1,3}-\d{1,3})$")
WALL_FILES = ("day.mp4", "night.mp4", "day.jpg", "night.jpg", "thumb.jpg", "spec.json")
MAX_BYTES = 600 * 1024 * 1024
EXT = ".aerotheme"


def notify(title, body=""):
    try:
        subprocess.Popen(["notify-send", "-a", "HYPER·AERO", title, body], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass
    print(title + (("  " + body) if body else ""))


def load(path, default):
    try:
        with open(path, encoding="utf-8") as f:
            v = json.load(f)
        return v if isinstance(v, type(default)) else default
    except (OSError, ValueError):
        return default


def save(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    os.replace(tmp, path)


def user_dir(kind, fallbacks):
    try:
        r = subprocess.run(["xdg-user-dir", kind], capture_output=True, text=True, timeout=5)
        p = r.stdout.strip()
        if p and p != HOME and os.path.isdir(p):
            return p
    except (OSError, subprocess.TimeoutExpired):
        pass
    for f in fallbacks:
        p = os.path.join(HOME, f)
        if os.path.isdir(p):
            return p
    return HOME


def slug(name):
    s = re.sub(r"[^\w\- ]+", "", name, flags=re.UNICODE).strip().replace(" ", "-")
    return s[:40] or "tema"


def export(theme, dest_dir):
    os.makedirs(dest_dir, exist_ok=True)
    dest = os.path.join(dest_dir, "HYPER-AERO-" + slug(theme.get("name", "tema")) + EXT)
    meta = {"format": 1, "name": theme.get("name", ""), "accent": theme.get("accent", "blue"), "wallpaper": False}
    wid = theme.get("wallpaper", "auto")
    wdir = os.path.join(CUSTOM, wid) if wid and wid != "auto" else ""
    with zipfile.ZipFile(dest, "w", compression=zipfile.ZIP_STORED) as z:
        if wdir and os.path.isdir(wdir):
            meta["wallpaper"] = True
            for f in WALL_FILES:
                p = os.path.join(wdir, f)
                if os.path.isfile(p):
                    z.write(p, "wallpaper/" + f)
        z.writestr("theme.json", json.dumps(meta, ensure_ascii=False, indent=2))
    return dest


def cmd_export_all():
    items = load(THEMES, [])
    if not items:
        notify(_t("Todavía no tenés temas propios"), _t("Creá uno en el Estudio de temas y guardalo."))
        return 0
    dest_dir = os.path.join(user_dir("DOCUMENTS", ["Documentos", "Documents"]), "HYPER-AERO")
    for t in items:
        export(t, dest_dir)
    notify(_t("Temas exportados"), dest_dir.replace(HOME, "~"))
    return 0


def digest(path):
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def import_file(path):
    if not zipfile.is_zipfile(path):
        raise ValueError(_t("no es un tema válido"))
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        allowed = {"theme.json"} | {"wallpaper/" + f for f in WALL_FILES}
        if "theme.json" not in names or any(n not in allowed for n in names):
            raise ValueError(_t("no es un tema válido"))
        if sum(i.file_size for i in z.infolist()) > MAX_BYTES:
            raise ValueError(_t("el archivo es demasiado grande"))
        meta = json.loads(z.read("theme.json").decode("utf-8"))
        accent = str(meta.get("accent", "blue"))
        if not ACCENT_RE.match(accent):
            raise ValueError(_t("color inválido"))
        name = str(meta.get("name") or os.path.basename(path)[: -len(EXT)])[:32]
        wid = "auto"
        if meta.get("wallpaper") and "wallpaper/day.mp4" in names and "wallpaper/night.mp4" in names:
            wid = time.strftime("%Y%m%d-%H%M%S")
            while os.path.exists(os.path.join(CUSTOM, wid)):
                wid += "1"
            wdir = os.path.join(CUSTOM, wid)
            os.makedirs(wdir)
            for n in names:
                if n.startswith("wallpaper/"):
                    with z.open(n) as src, open(os.path.join(wdir, n.split("/", 1)[1]), "wb") as dst:
                        shutil.copyfileobj(src, dst)
    items = load(THEMES, [])
    items.append({"id": "t" + str(int(time.time() * 1000)), "name": name, "accent": accent, "wallpaper": wid})
    save(THEMES, items)
    return name


def cmd_import(path):
    try:
        name = import_file(path)
    except (ValueError, OSError, KeyError, zipfile.BadZipFile) as e:
        notify(_t("No pude importar el tema"), str(e))
        return 1
    seen = load(IMPORTED, [])
    seen.append(digest(path))
    save(IMPORTED, seen[-200:])
    notify(_t("Tema importado"), name + "  ·  " + _t("aparece en el carrusel (SUPER + G)"))
    return 0


def cmd_import_found():
    seen = set(load(IMPORTED, []))
    places = [user_dir("DOWNLOAD", ["Descargas", "Downloads"]), user_dir("DOCUMENTS", ["Documentos", "Documents"]), HOME]
    found = []
    for d in places:
        for sub in (d, os.path.join(d, "HYPER-AERO")):
            try:
                for f in sorted(os.listdir(sub)):
                    p = os.path.join(sub, f)
                    if f.endswith(EXT) and os.path.isfile(p) and p not in found:
                        found.append(p)
            except OSError:
                pass
    count = 0
    for p in found:
        try:
            if digest(p) in seen:
                continue
            import_file(p)
            seen.add(digest(p))
            count += 1
        except (ValueError, OSError, KeyError, zipfile.BadZipFile):
            continue
    save(IMPORTED, list(seen)[-200:])
    if count:
        notify(_t("Temas importados: ") + str(count), _t("aparecen en el carrusel (SUPER + G)"))
    else:
        notify(_t("No encontré temas nuevos"), _t("Poné archivos .aerotheme en Descargas o Documentos, o abrilos con doble clic."))
    return 0


def cmd_register():
    apps = os.path.join(HOME, ".local", "share", "applications")
    mime = os.path.join(HOME, ".local", "share", "mime", "packages")
    os.makedirs(apps, exist_ok=True)
    os.makedirs(mime, exist_ok=True)
    with open(os.path.join(mime, "hyper-aero-theme.xml"), "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n'
                '<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">\n'
                '  <mime-type type="application/x-aerotheme">\n'
                '    <comment>HYPER·AERO theme</comment>\n'
                '    <glob pattern="*.aerotheme"/>\n'
                '  </mime-type>\n'
                '</mime-info>\n')
    with open(os.path.join(apps, "hyper-aero-theme.desktop"), "w", encoding="utf-8") as f:
        f.write("[Desktop Entry]\nType=Application\nName=HYPER·AERO\nComment=" + _t("Importar tema") + "\n"
                f"Exec={os.path.join(A, 'scripts', 'aero-theme.py')} import %f\n"
                "Icon=preferences-desktop-theme\nMimeType=application/x-aerotheme;\nNoDisplay=true\n")
    for cmd in (["update-mime-database", os.path.join(HOME, ".local", "share", "mime")], ["update-desktop-database", apps],
                ["xdg-mime", "default", "hyper-aero-theme.desktop", "application/x-aerotheme"]):
        try:
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
        except (OSError, subprocess.TimeoutExpired):
            pass
    return 0


def main(argv):
    cmd = argv[0] if argv else ""
    if cmd == "export-all":
        return cmd_export_all()
    if cmd == "export" and len(argv) >= 2:
        items = [t for t in load(THEMES, []) if t.get("id") == argv[1] or t.get("name") == argv[1]]
        if not items:
            notify(_t("No encontré ese tema"))
            return 1
        dest = export(items[0], argv[2] if len(argv) > 2 else os.path.join(user_dir("DOCUMENTS", ["Documentos", "Documents"]), "HYPER-AERO"))
        notify(_t("Tema exportado"), dest.replace(HOME, "~"))
        return 0
    if cmd == "import" and len(argv) >= 2:
        return cmd_import(argv[1])
    if cmd == "import-found":
        return cmd_import_found()
    if cmd == "register":
        return cmd_register()
    print("uso: aero-theme.py export-all|export NOMBRE [CARPETA]|import ARCHIVO|import-found|register")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
