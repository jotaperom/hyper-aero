#!/usr/bin/env python3

import os
import re
import sys
import json
import time
import glob
import socket
import signal
import subprocess
import threading
from aero_i18n import t as _t

HOME = os.path.expanduser("~")
A = os.path.join(HOME, ".config", "hyper-aero")
SCRIPTS = os.path.join(A, "scripts")
SETTINGS = os.path.join(A, "settings.json")
PROFILE = os.path.join(A, "profile.json")
RUN = os.environ.get("XDG_RUNTIME_DIR") or os.path.join(HOME, ".cache", "hyper-aero")
os.makedirs(RUN, exist_ok=True)
STATE = os.path.join(RUN, "aero-auto.json")
LOG = os.path.join(RUN, "aero-auto.log")
GAMES = re.compile(r"^(steam_app_\d+|gamescope|.*\.exe|lutris|heroic|minecraft.*|osu!?|retroarch|dolphin-emu|pcsx2.*|rpcs3|ryujinx|cemu|ppsspp.*|duckstation.*|citra.*|xemu|shadps4|factorio|terraria|cs2|dota2|hl2_linux|tf_linux64)$", re.I)


def load(path, default):
    try:
        with open(path, encoding="utf-8") as f:
            v = json.load(f)
        return v if isinstance(v, type(default)) else default
    except (OSError, ValueError):
        return default


def save(path, data):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f)
    os.replace(tmp, path)


def settings():
    s = {"auto.game": True, "auto.battery": False}
    s.update(load(SETTINGS, {}))
    return s


def profile():
    return load(PROFILE, {}).get("name", "equilibrado")


def hypr(*args):
    try:
        r = subprocess.run(["hyprctl", "-j", *args], capture_output=True, text=True, timeout=5)
        return json.loads(r.stdout or "null")
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return None


def gaming():
    w = hypr("activewindow")
    if not isinstance(w, dict) or not w.get("address"):
        return False
    if not w.get("fullscreen"):
        return False
    if str(w.get("contentType", w.get("content_type", ""))).lower() == "game":
        return True
    for k in ("class", "initialClass"):
        if GAMES.match(str(w.get(k) or "")):
            return True
    return False


def on_battery():
    supplies = glob.glob("/sys/class/power_supply/*")
    mains = []
    has_battery = False
    for p in supplies:
        kind = open(os.path.join(p, "type")).read().strip() if os.path.exists(os.path.join(p, "type")) else ""
        if kind == "Battery":
            has_battery = True
        elif kind in ("Mains", "USB", "USB_C", "USB_PD"):
            try:
                mains.append(open(os.path.join(p, "online")).read().strip() == "1")
            except OSError:
                pass
    if not has_battery or not mains:
        return False
    return not any(mains)


class Auto:
    def __init__(self):
        self.lock = threading.Lock()
        self.state = load(STATE, {})

    def log(self, msg):
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(time.strftime("%H:%M:%S ") + msg + "\n")

    def set_profile(self, name, why):
        self.log(f"{why}: {name}")
        subprocess.run([os.path.join(SCRIPTS, "aero-profile"), name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def evaluate(self, why="tick"):
        with self.lock:
            s = settings()
            game = bool(s.get("auto.game")) and gaming()
            batt = bool(s.get("auto.battery")) and on_battery()
            want = game or batt
            active = bool(self.state.get("active"))
            if want and not active:
                cur = profile()
                self.state = {"active": True, "restore": cur, "reason": "game" if game else "battery"}
                save(STATE, self.state)
                if cur != "ligero":
                    self.set_profile("ligero", why)
                    note = _t("Modo juego: perfil Ligero mientras jugás.") if game else _t("Con batería: perfil Ligero para ahorrar.")
                    subprocess.Popen(["notify-send", "-a", "HYPER·AERO", "◢ " + _t("Automático"), note], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            elif not want and active:
                restore = self.state.get("restore", "equilibrado")
                self.state = {"active": False}
                save(STATE, self.state)
                if restore != "ligero" and profile() == "ligero":
                    self.set_profile(restore, why)

    def events(self):
        sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
        path = os.path.join(RUN, "hypr", sig, ".socket2.sock")
        while True:
            try:
                s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                s.connect(path)
                buf = b""
                while True:
                    data = s.recv(4096)
                    if not data:
                        break
                    buf += data
                    while b"\n" in buf:
                        line, buf = buf.split(b"\n", 1)
                        ev = line.split(b">>", 1)[0]
                        if ev in (b"fullscreen", b"activewindowv2", b"closewindow"):
                            time.sleep(0.4)
                            self.evaluate(ev.decode())
            except OSError:
                time.sleep(3)

    def run(self):
        threading.Thread(target=self.events, daemon=True).start()
        while True:
            try:
                self.evaluate()
            except Exception as e:
                self.log("error " + str(e))
            time.sleep(20)


def main(argv):
    cmd = argv[0] if argv else "daemon"
    me = os.path.abspath(__file__)
    if cmd in ("restart", "stop"):
        subprocess.run(["pkill", "-f", "python3 .*aero-auto.py daemon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if cmd == "stop":
            return 0
        time.sleep(0.3)
        cmd = "spawn"
    if cmd == "spawn":
        s = settings()
        if not (s.get("auto.game") or s.get("auto.battery")):
            st = load(STATE, {})
            if st.get("active") and st.get("restore") and profile() == "ligero" and st.get("restore") != "ligero":
                subprocess.run([os.path.join(SCRIPTS, "aero-profile"), st["restore"]], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            save(STATE, {"active": False})
            return 0
        subprocess.Popen(["python3", me, "daemon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        return 0
    if cmd == "daemon":
        r = subprocess.run(["pgrep", "-fc", "python3 .*aero-auto.py daemon"], capture_output=True, text=True)
        if r.stdout.strip() not in ("", "0", "1"):
            return 0
        signal.signal(signal.SIGTERM, lambda *a: sys.exit(0))
        Auto().run()
        return 0
    if cmd == "status":
        print(json.dumps({"state": load(STATE, {}), "gaming": gaming(), "battery": on_battery(), "profile": profile()}))
        return 0
    print("uso: aero-auto.py daemon|restart|stop|status")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
