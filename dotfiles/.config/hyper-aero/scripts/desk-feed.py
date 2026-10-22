#!/usr/bin/env python3

import os
import sys
import glob
import json
import time
import shutil
import socket
import getpass
import platform
import threading
import subprocess
import importlib.util

HOME = os.path.expanduser("~")
SCRIPTS = os.path.join(HOME, ".config", "hyper-aero", "scripts")
PARENT = os.getppid()
LOCK = threading.Lock()


def emit(kind, data):
    data["k"] = kind
    with LOCK:
        try:
            print(json.dumps(data, ensure_ascii=False), flush=True)
        except BrokenPipeError:
            os._exit(0)


def read(path, default=""):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read().strip()
    except OSError:
        return default


def load_sky():
    path = os.path.join(SCRIPTS, "sky-arc.py")
    if not os.path.isfile(path):
        return None
    try:
        spec = importlib.util.spec_from_file_location("sky_arc", path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return mod
    except Exception:
        return None


SKY = load_sky()


def temp_path():
    for h in glob.glob("/sys/class/hwmon/hwmon*"):
        if read(os.path.join(h, "name")) == "coretemp" and os.path.exists(os.path.join(h, "temp1_input")):
            return os.path.join(h, "temp1_input")
    for z in glob.glob("/sys/class/thermal/thermal_zone*"):
        if read(os.path.join(z, "type")) == "x86_pkg_temp":
            return os.path.join(z, "temp")
    return None


TEMP = temp_path()


def cpu_times():
    with open("/proc/stat") as f:
        parts = f.readline().split()[1:9]
    vals = [int(x) for x in parts]
    return sum(vals), vals[3] + vals[4]


def span(seconds):
    m = max(0, int(seconds // 60))
    d, m = divmod(m, 1440)
    h, m = divmod(m, 60)
    return f"{d}d {h:02d}:{m:02d}" if d else f"{h:02d}:{m:02d}"


def uptime():
    try:
        return float(read("/proc/uptime", "0").split()[0])
    except ValueError:
        return 0.0


def sysinfo(prev):
    total, idle = cpu_times()
    dt, di = total - prev[0], idle - prev[1]
    cpu = int(round(100 * (dt - di) / dt)) if dt > 0 else 0
    mem = {}
    for line in read("/proc/meminfo").splitlines():
        k, _, v = line.partition(":")
        mem[k] = int(v.split()[0]) if v.split() else 0
    mt, ma = mem.get("MemTotal", 1), mem.get("MemAvailable", 0)
    du = shutil.disk_usage(HOME)
    temp = 0
    if TEMP:
        try:
            temp = int(read(TEMP, "0")) // 1000
        except ValueError:
            temp = 0
    bat, charging = -1, False
    for b in sorted(glob.glob("/sys/class/power_supply/BAT*")):
        cap = read(os.path.join(b, "capacity"))
        if cap.isdigit():
            bat = int(cap)
            charging = read(os.path.join(b, "status")).lower() in ("charging", "full", "not charging")
            break
    data = {
        "cpu": max(0, min(100, cpu)),
        "mem": int(round(100 * (mt - ma) / mt)),
        "memUsed": round((mt - ma) / 1048576, 1),
        "memTotal": round(mt / 1048576, 1),
        "temp": temp,
        "disk": int(round(100 * du.used / du.total)),
        "diskUsed": int(du.used / 1e9),
        "diskTotal": int(du.total / 1e9),
        "load": read("/proc/loadavg", "0").split()[0],
        "uptime": span(uptime()),
        "bat": bat,
        "charging": charging,
    }
    return data, (total, idle)


def sky():
    if not SKY:
        return {"ok": False}
    now = time.time()
    try:
        cfg = SKY.config()
        st = SKY.state(now, cfg)
        _, lit, name = SKY.moon(now)
        length = st["end"] - st["start"]
        left = st["end"] - now
        night = st["night"]
        return {
            "ok": True,
            "night": night,
            "frac": max(0.0, min(1.0, st["frac"])),
            "tag": f"{'NIGHT' if night else 'DAYLIGHT'} {SKY.span(length)}",
            "left": f"{'▼' if night else '▲'} {SKY.hm(st['start'])}",
            "right": f"{SKY.hm(st['end'])} {'▲' if night else '▼'}",
            "next": f"{'SUNRISE' if night else 'SUNSET'} IN {SKY.span(left)}",
            "moon": f"{name}  ·  {round(lit * 100)}% LIT" if night else "",
            "lit": lit,
        }
    except Exception as e:
        return {"ok": False, "err": str(e)[:60]}


def weather():
    script = os.path.join(SCRIPTS, "desk-weather.sh")
    if not os.access(script, os.X_OK):
        return {"ok": False}
    try:
        out = subprocess.run([script], capture_output=True, text=True, timeout=25).stdout
        return json.loads(out.strip().splitlines()[-1])
    except (OSError, ValueError, IndexError, subprocess.TimeoutExpired):
        return {"ok": False}


def user():
    name = getpass.getuser()
    full = name
    try:
        import pwd
        gecos = pwd.getpwnam(name).pw_gecos.split(",")[0].strip()
        if gecos:
            full = gecos
    except (KeyError, ImportError):
        pass
    face = ""
    for p in (os.path.join(HOME, ".face"), os.path.join(HOME, ".face.icon"),
              f"/var/lib/AccountsService/icons/{name}"):
        if os.path.isfile(p):
            face = p
            break
    pkgs = 0
    try:
        pkgs = len(os.listdir("/var/lib/pacman/local")) - 1
    except OSError:
        pass
    return {
        "name": name,
        "full": full,
        "host": socket.gethostname(),
        "kernel": platform.release().split("-")[0],
        "face": face,
        "pkgs": max(0, pkgs),
        "uptime": span(uptime()),
        "shell": os.path.basename(os.environ.get("SHELL", "bash")),
    }


def main():
    prev = cpu_times()
    last_sky = last_weather = last_user = 0
    while True:
        if os.getppid() != PARENT:
            return 0
        now = time.time()
        data, prev = sysinfo(prev)
        emit("sys", data)
        if now - last_sky >= 30:
            emit("sky", sky())
            last_sky = now
        if now - last_user >= 60:
            emit("user", user())
            last_user = now
        if now - last_weather >= 900:
            last_weather = now
            threading.Thread(target=lambda: emit("weather", weather()), daemon=True).start()
        time.sleep(2)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
