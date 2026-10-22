#!/usr/bin/env python3

import os
import sys
import json
import time
import glob
import fcntl
import socket
import threading
import subprocess
from aero_i18n import t as _t

HOME = os.path.expanduser("~")
AERO = os.path.join(HOME, ".config", "hyper-aero")
PROFILE = os.path.join(AERO, "profile.json")
RUN = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
SOCK = os.path.join(RUN, "aero-motion.sock")
MANUAL = os.path.join(RUN, "aero-motion.manual")
SAVER = os.path.join(RUN, "aero-saver.on")
MINE = os.path.join(RUN, "aero-motion.guard")
BATTERY_LIMIT = 50
EVENTS = (b"workspace", b"focusedmon", b"activewindow", b"openwindow", b"closewindow", b"movewindow",
          b"fullscreen", b"changefloatingmode", b"activespecial", b"monitoradded", b"monitorremoved")


def profile():
    try:
        with open(PROFILE, encoding="utf-8") as f:
            d = json.load(f)
        return d if isinstance(d, dict) else {}
    except (OSError, ValueError):
        return {}


def hypr(*args):
    try:
        r = subprocess.run(["hyprctl", "-j", *args], capture_output=True, text=True, timeout=3)
        return json.loads(r.stdout) if r.returncode == 0 else []
    except (OSError, subprocess.TimeoutExpired, ValueError):
        return []


def mpv(cmd):
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(1.0)
            s.connect(SOCK)
            s.sendall((json.dumps({"command": cmd, "request_id": 3}) + "\n").encode())
            buf = b""
            end = time.time() + 1.2
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
                    if m.get("request_id") == 3:
                        return m.get("data")
    except OSError:
        return None
    return None


def low_battery():
    on_ac = False
    level = 100
    for s in glob.glob("/sys/class/power_supply/*"):
        try:
            kind = open(os.path.join(s, "type")).read().strip()
        except OSError:
            continue
        if kind == "Mains":
            try:
                on_ac = on_ac or open(os.path.join(s, "online")).read().strip() == "1"
            except OSError:
                pass
        elif kind == "Battery":
            try:
                level = int(open(os.path.join(s, "capacity")).read().strip())
            except (OSError, ValueError):
                pass
    return not on_ac and level < BATTERY_LIMIT


def covered(mode):
    mons = [m for m in hypr("monitors") if not m.get("disabled")]
    if not mons:
        return False
    clients = hypr("clients")
    for m in mons:
        ws = {(m.get("activeWorkspace") or {}).get("id")}
        special = (m.get("specialWorkspace") or {}).get("id") or 0
        if special:
            ws.add(special)
        hit = False
        for c in clients:
            if (c.get("workspace") or {}).get("id") not in ws or c.get("hidden") or not c.get("mapped", True):
                continue
            full = c.get("fullscreen")
            if (full is True) or (isinstance(full, int) and full > 0):
                hit = True
                break
            if mode == "covered" and not c.get("floating"):
                hit = True
                break
        if not hit:
            return False
    return True


class Guard:
    def __init__(self):
        self.lock = threading.Lock()
        self.timer = None
        self.warned = False

    def evaluate(self):
        p = profile()
        if p.get("wallpaper") == "still" or not os.path.exists(SOCK):
            return
        if os.path.exists(MANUAL) or os.path.exists(SAVER):
            return
        battery = low_battery()
        want = battery or covered(p.get("pause_when", "covered"))
        paused = mpv(["get_property", "pause"])
        if paused is None:
            return
        if want and not paused:
            mpv(["set_property", "pause", True])
            open(MINE, "w").close()
            if battery and not self.warned:
                self.warned = True
                subprocess.Popen(["notify-send", "-a", "HYPER·AERO", _t("Ahorro de batería"), _t("Fondo animado en pausa")],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif not want and paused and os.path.exists(MINE):
            mpv(["set_property", "pause", False])
            try:
                os.remove(MINE)
            except OSError:
                pass
        if not battery:
            self.warned = False

    def soon(self, delay=0.35):
        with self.lock:
            if self.timer:
                self.timer.cancel()
            self.timer = threading.Timer(delay, self.safe)
            self.timer.daemon = True
            self.timer.start()

    def safe(self):
        try:
            self.evaluate()
        except Exception:
            pass


def main():
    me = open(os.path.join(RUN, "aero-motion-guard.lock"), "a")
    try:
        fcntl.flock(me, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return 0
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        return 1
    path = os.path.join(RUN, "hypr", sig, ".socket2.sock")
    g = Guard()

    def tick():
        while True:
            time.sleep(20)
            g.safe()

    threading.Thread(target=tick, daemon=True).start()
    g.soon(3)
    while os.path.exists(path):
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
                        if line.startswith(EVENTS):
                            g.soon()
        except OSError:
            time.sleep(2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
