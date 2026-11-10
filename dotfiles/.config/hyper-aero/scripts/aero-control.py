#!/usr/bin/env python3

import os
import re
import sys
import json
import subprocess
import urllib.request

HOME = os.path.expanduser("~")
AERO = os.path.join(HOME, ".config", "hyper-aero")
SCRIPTS = os.path.join(AERO, "scripts")
SETTINGS = os.path.join(AERO, "settings.json")
DEFAULTS = {
    "fx.glow": True,
    "fx.ripple": True,
    "fx.peek": True,
    "fx.shake": True,
    "fx.weather": True,
    "lyrics.words": True,
    "auto.game": True,
    "auto.battery": False,
    "update.check": True,
}


def read(path, default=""):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read().strip()
    except OSError:
        return default


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
        json.dump(data, f, indent=2, sort_keys=True, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)


def settings():
    s = dict(DEFAULTS)
    s.update(load(SETTINGS, {}))
    return s


def spawn(args):
    try:
        subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    except OSError:
        pass


def keys():
    out = []
    try:
        text = open(os.path.join(SCRIPTS, "keymap.sh"), encoding="utf-8").read()
    except OSError:
        return out
    for m in re.finditer(r'^\s*"(.+?)"\s*\\?$', text, flags=re.M):
        line = m.group(1)
        parts = re.split(r"\s{2,}", line.strip(), maxsplit=1)
        if len(parts) == 2:
            out.append({"keys": parts[0], "what": parts[1]})
    return out


def state():
    info = load(os.path.join(AERO, ".install.json"), {})
    cfg = load(os.path.join(AERO, "theme", "config.json"), {})
    st = load(os.path.join(AERO, "theme", "state.json"), {})
    prof = load(os.path.join(AERO, "profile.json"), {})
    upd = load(os.path.join(HOME, ".cache", "hyper-aero", "update.json"), {})
    return {
        "version": info.get("version", ""),
        "repo": info.get("repo", ""),
        "lang": read(os.path.join(AERO, "lang"), "es") or "es",
        "lat": cfg.get("lat"),
        "lon": cfg.get("lon"),
        "city": read(os.path.join(AERO, "weather-location")),
        "profile": prof.get("name", "equilibrado"),
        "mode": read(os.path.join(AERO, "theme", "mode"), "day"),
        "manual": bool(st.get("manual_until")),
        "accent": read(os.path.join(AERO, "theme", "accent"), "blue"),
        "skin": read(os.path.join(AERO, "phone-skin"), "iphone"),
        "settings": settings(),
        "welcomed": os.path.exists(os.path.join(AERO, "welcome-done")),
        "update": upd,
        "keys": keys(),
        "features": {
            "profiles": os.path.exists(os.path.join(SCRIPTS, "aero-profile")),
            "lang": os.path.exists(os.path.join(SCRIPTS, "aero-lang")),
            "updates": bool(info) and os.path.exists(os.path.join(SCRIPTS, "aero-update")),
        },
    }


def detect():
    req = urllib.request.Request("https://ipapi.co/json/", headers={"User-Agent": "hyper-aero"})
    with urllib.request.urlopen(req, timeout=8) as r:
        d = json.loads(r.read().decode("utf-8"))
    return {"lat": round(float(d.get("latitude")), 2), "lon": round(float(d.get("longitude")), 2), "city": d.get("city") or ""}


def main(argv):
    cmd = argv[0] if argv else "state"
    if cmd == "state":
        print(json.dumps(state(), ensure_ascii=False))
        return 0
    if cmd == "set" and len(argv) >= 3:
        s = load(SETTINGS, {})
        v = argv[2]
        s[argv[1]] = True if v == "true" else False if v == "false" else v
        save(SETTINGS, s)
        if argv[1].startswith("auto."):
            spawn([os.path.join(SCRIPTS, "aero-auto.py"), "restart"])
        print(json.dumps({"ok": True}))
        return 0
    if cmd == "city":
        name = " ".join(argv[1:]).strip()
        with open(os.path.join(AERO, "weather-location"), "w", encoding="utf-8") as f:
            f.write(name + "\n" if name else "")
        print(json.dumps({"ok": True}))
        return 0
    if cmd == "location" and len(argv) >= 3:
        r = subprocess.run([os.path.join(SCRIPTS, "night-deck.py"), "location", argv[1], argv[2]], capture_output=True, text=True)
        print(json.dumps({"ok": r.returncode == 0}))
        return 0
    if cmd == "detect":
        try:
            print(json.dumps(dict(detect(), ok=True), ensure_ascii=False))
        except Exception:
            print(json.dumps({"ok": False}))
        return 0
    if cmd == "skin" and len(argv) >= 2:
        with open(os.path.join(AERO, "phone-skin"), "w", encoding="utf-8") as f:
            f.write(argv[1] + "\n")
        print(json.dumps({"ok": True}))
        return 0
    if cmd == "welcome":
        p = os.path.join(AERO, "welcome-done")
        if len(argv) > 1 and argv[1] == "reset":
            try:
                os.remove(p)
            except OSError:
                pass
        else:
            open(p, "w").close()
        print(json.dumps({"ok": True}))
        return 0
    print("uso: aero-control.py state|set KEY VALUE|city NAME|location LAT LON|detect|skin NAME|welcome [reset]")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
