#!/usr/bin/env python3

import json
import math
import os
import re
import select
import signal
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
A = os.path.join(HOME, ".config", "hyper-aero")
CONF = os.path.join(A, "cava-hud.conf")
RUN = os.environ.get("XDG_RUNTIME_DIR") or os.path.join(HOME, ".cache", "hyper-aero")
W = 232
H = 34


def fps():
    try:
        with open(os.path.join(A, "profile.json"), encoding="utf-8") as f:
            v = int(json.load(f).get("visualizer_fps", 24))
    except (OSError, ValueError, TypeError, AttributeError):
        v = 24
    return max(0, min(60, v))


def cava_rate(default):
    try:
        with open(CONF, encoding="utf-8") as f:
            for line in f:
                k, _, v = line.partition("=")
                if k.strip() == "framerate":
                    return max(1, int(v.strip()))
    except (OSError, ValueError):
        pass
    return default


def read(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except OSError:
        return ""


def colors():
    night = read(os.path.join(A, "theme", "mode")).strip() == "night"
    css = read(os.path.join(HOME, ".config", "eww", "eww.scss")) + read(os.path.join(A, "theme", "current", "eww.scss"))
    def var(name, default):
        found = re.findall(r"\$" + name + r":\s*(#[0-9a-fA-F]{6})", css)
        return found[-1] if found else default
    if night:
        return {"line": var("n-glow", "#6fd3ff"), "warm": "#ffd9e8", "glow": 0.75}
    return {"line": var("cobalt", "#1446c2"), "warm": "#e2457a", "glow": 0.35}


def playing():
    try:
        r = subprocess.run(["playerctl", "-a", "status"], capture_output=True, text=True, timeout=2)
        return "Playing" in r.stdout.split()
    except (OSError, subprocess.SubprocessError):
        return False


class Wave:
    def __init__(self):
        self.sm = []
        self.level = 0.0
        self.t = 0.0
        self.flip = 0
        self.pal = colors()

    def feed(self, vals, top, dt):
        if len(self.sm) != len(vals):
            self.sm = [0.0] * len(vals)
        for i, v in enumerate(vals):
            x = min(1.0, v / top)
            self.sm[i] += (x - self.sm[i]) * (0.28 if x > self.sm[i] else 0.1)
        target = min(1.0, sum(self.sm) / max(1, len(self.sm)) * 1.4)
        self.level += (target - self.level) * (0.3 if target > self.level else 0.1)
        self.t += dt

    def calm(self, dt):
        self.sm = [v * 0.8 for v in self.sm]
        self.level *= 0.8
        self.t += dt

    def band(self, f):
        n = len(self.sm)
        if not n:
            return 0.0
        mid = (n - 1) / 2.0
        def at(p):
            p = max(0.0, min(n - 1.0, p))
            i = int(p)
            k = p - i
            return self.sm[i] * (1 - k) + self.sm[min(n - 1, i + 1)] * k
        return (at(mid + f * mid) + at(mid - f * mid)) / 2

    def soft(self, f):
        return self.band(max(0.0, f - 0.1)) * 0.25 + self.band(f) * 0.5 + self.band(min(1.0, f + 0.1)) * 0.25

    def path(self):
        amp = (H / 2 - 4) * (0.12 + 0.88 * self.level)
        cyc = max(2.0, W / 2 / 40)
        pts = []
        x = 0.0
        while x <= W + 0.01:
            u = x / W
            f = abs(u - 0.5) * 2
            fs = math.sqrt(f * f + 0.0036) - 0.06
            env = math.sin(math.pi * u) ** 1.6
            w = 0.9 * math.sin(2 * math.pi * fs * cyc - self.t * 4.5) + 0.1 * math.sin(2 * math.pi * fs * cyc * 0.5 + self.t * 1.8)
            y = H / 2 + env * amp * (0.1 + 0.9 * self.soft(f)) * w
            pts.append("%.1f,%.2f" % (x, y))
            x += 2.0
        return "M" + " L".join(pts)

    def svg(self):
        p = self.pal
        d = self.path()
        g = p["glow"] * (0.4 + 0.6 * self.level)
        return (
            '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">'
            '<defs>'
            '<linearGradient id="g" x1="0" y1="0" x2="%d" y2="0" gradientUnits="userSpaceOnUse">'
            '<stop offset="0" stop-color="%s" stop-opacity="0.15"/>'
            '<stop offset="0.25" stop-color="%s"/>'
            '<stop offset="0.5" stop-color="%s"/>'
            '<stop offset="0.75" stop-color="%s"/>'
            '<stop offset="1" stop-color="%s" stop-opacity="0.15"/>'
            '</linearGradient>'
            '<linearGradient id="h" x1="0" y1="0" x2="%d" y2="0" gradientUnits="userSpaceOnUse">'
            '<stop offset="0" stop-color="%s" stop-opacity="0"/>'
            '<stop offset="0.3" stop-color="%s" stop-opacity="%.2f"/>'
            '<stop offset="0.7" stop-color="%s" stop-opacity="%.2f"/>'
            '<stop offset="1" stop-color="%s" stop-opacity="0"/>'
            '</linearGradient>'
            '<filter id="b" x="-10%%" y="-60%%" width="120%%" height="220%%"><feGaussianBlur stdDeviation="2.2"/></filter>'
            '</defs>'
            '<path d="%s" fill="none" stroke="url(#h)" stroke-width="4" filter="url(#b)"/>'
            '<path d="%s" fill="none" stroke="url(#g)" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>'
            '</svg>'
        ) % (W, H, W, H, W, p["line"], p["line"], p["warm"], p["line"], p["line"],
             W, p["line"], p["line"], g, p["line"], g, p["line"], d, d)

    def show(self):
        self.flip ^= 1
        target = os.path.join(RUN, "aero-wave-%d.svg" % self.flip)
        tmp = target + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            f.write(self.svg())
        os.replace(tmp, target)
        os.write(1, (target + "\n").encode())


def main():
    os.makedirs(RUN, exist_ok=True)
    wave = Wave()
    wave.show()
    rate = fps()
    if rate == 0 or not any(os.access(os.path.join(p, "cava"), os.X_OK) for p in os.environ.get("PATH", "").split(os.pathsep)):
        signal.pause()
        return 0
    frames = cava_rate(rate)
    every = max(1, round(frames / rate))
    cava = None
    count = 0
    still = False
    next_check = 0.0
    try:
        while True:
            now = time.monotonic()
            if now >= next_check:
                next_check = now + 2
                pal = colors()
                if pal != wave.pal:
                    wave.pal = pal
                    still = False
                live = playing()
                if live and cava is None:
                    cava = subprocess.Popen(["cava", "-p", CONF], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
                elif not live and cava is not None:
                    cava.terminate()
                    cava.wait(timeout=2)
                    cava = None
            if cava is None:
                if wave.level > 0.01:
                    wave.calm(0.1)
                    wave.show()
                    time.sleep(0.1)
                    continue
                if not still:
                    wave.level = 0.0
                    wave.sm = [0.0] * len(wave.sm)
                    wave.show()
                    still = True
                time.sleep(0.5)
                continue
            still = False
            ready, _, _ = select.select([cava.stdout], [], [], 0.5)
            if not ready:
                continue
            line = cava.stdout.readline()
            if not line:
                cava.wait()
                cava = None
                continue
            vals = [int(x) for x in line.decode(errors="ignore").strip().split(";") if x.strip().isdigit()]
            if not vals:
                continue
            wave.feed(vals, 7.0, 1.0 / frames)
            count += 1
            if count % every == 0:
                wave.show()
    except (BrokenPipeError, KeyboardInterrupt):
        return 0
    finally:
        if cava is not None:
            cava.terminate()


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, lambda *a: sys.exit(0))
    sys.exit(main())
