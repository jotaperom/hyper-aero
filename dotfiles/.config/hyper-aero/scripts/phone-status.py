#!/usr/bin/env python3

import os
import re
import glob
import json
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor

HOME = os.path.expanduser("~")
AERO = os.path.join(HOME, ".config", "hyper-aero")
NIGHT_DECK = os.path.join(AERO, "scripts", "night-deck.py")


def run(args, timeout=2):
    if not shutil.which(args[0]) and not os.access(args[0], os.X_OK):
        return None
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return r.stdout if r.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""


def read(path, default=""):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read().strip()
    except OSError:
        return default


def wifi():
    radio = run(["nmcli", "radio", "wifi"])
    if radio is None:
        return {"wifi": False, "ssid": ""}
    on = radio.strip() == "enabled"
    ssid = ""
    if on:
        out = run(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]) or ""
        for line in out.splitlines():
            name, _, kind = line.rpartition(":")
            if kind == "802-11-wireless":
                ssid = name.replace("\\:", ":")
                break
    return {"wifi": on, "ssid": ssid}


def bluetooth():
    show = run(["bluetoothctl", "show"])
    if show is None or not show.strip() or "No default controller" in show:
        return {"bt": False, "btAvail": False, "btDev": ""}
    on = bool(re.search(r"Powered:\s*yes", show))
    dev = ""
    if on:
        out = run(["bluetoothctl", "devices", "Connected"]) or ""
        for line in out.splitlines():
            parts = line.split(" ", 2)
            if len(parts) == 3 and parts[0] == "Device":
                dev = parts[2].strip()
                break
    return {"bt": on, "btAvail": True, "btDev": dev}


def warm():
    out = run([NIGHT_DECK, "status"], timeout=3) or ""
    m = re.search(r"Luz cálida:\s*(\d+)\s*K", out)
    return {"warm": bool(m), "kelvin": int(m.group(1)) if m else 0}


def dnd():
    out = run(["swaync-client", "-D", "-sw"]) or ""
    return {"dnd": out.strip() == "true"}


def brightness():
    out = run(["brightnessctl", "-m"]) or ""
    parts = out.strip().split(",")
    try:
        return {"bri": int(parts[3].rstrip("%"))}
    except (IndexError, ValueError):
        return {"bri": -1}


def battery():
    for b in sorted(glob.glob("/sys/class/power_supply/BAT*")):
        cap = read(os.path.join(b, "capacity"))
        if cap.isdigit():
            st = read(os.path.join(b, "status")).lower()
            return {"bat": int(cap), "charging": st in ("charging", "full", "not charging")}
    return {"bat": -1, "charging": False}


def recording():
    out = run([os.path.join(AERO, "scripts", "screenrec.sh"), "status"]) or ""
    try:
        d = json.loads(out)
    except ValueError:
        d = {}
    return {"rec": bool(d.get("rec")), "recSince": d.get("since", 0) or 0}


def main():
    mode = "night" if read(os.path.join(AERO, "theme", "mode"), "day") == "night" else "day"
    accent = read(os.path.join(AERO, "theme", "accent"), "blue")
    data = {"mode": mode, "accent": accent if accent in ("blue", "red", "green", "black") or re.match(r"^c-\d{1,3}-\d{1,3}$", accent) else "blue"}
    with ThreadPoolExecutor(max_workers=7) as pool:
        for part in pool.map(lambda f: f(), [wifi, bluetooth, warm, dnd, brightness, battery, recording]):
            data.update(part)
    print(json.dumps(data, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    main()
