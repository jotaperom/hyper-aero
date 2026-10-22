#!/usr/bin/env python3

import os
import re
import sys
import json
import math
import colorsys
import subprocess

import numpy as np
from PIL import Image, ImageFilter

W, H = 1920, 1080
FPS = 24
T = 30.0
FRAMES = int(FPS * T)
TAU = 2 * math.pi

LAYERS = ["bubbles", "waves", "sparkles", "aurora", "rain", "hud", "mist", "snow", "bokeh", "rays", "petals", "stars",
          "caustics", "flare", "grid"]

PRESET = {
    "blue": (215, 1.0),
    "red": (350, 1.0),
    "green": (162, 0.72),
    "black": (188, 0.06),
}


def accent_hs(acc):
    if acc in PRESET:
        return PRESET[acc]
    m = re.match(r"^c-(\d{1,3})-(\d{1,3})$", acc or "")
    if m:
        return max(0, min(359, int(m.group(1)))), max(0, min(140, int(m.group(2)))) / 100.0
    return PRESET["blue"]


def hsl(h, s, l):
    r, g, b = colorsys.hls_to_rgb((h % 360) / 360.0, max(0.0, min(1.0, l)), max(0.0, min(1.0, s)))
    return np.array([r, g, b], np.float32)


def palette_for(acc):
    h, s = accent_hs(acc)
    sat = min(1.0, 0.82 * s)
    return {
        "deep": hsl(h, sat, 0.42),
        "mid": hsl(h, sat, 0.57),
        "glow": hsl(h - 10, min(1.0, sat * 1.05), 0.72),
        "pale": hsl(h, sat * 0.6, 0.86),
        "night": hsl(h, min(1.0, sat * 0.7), 0.07),
        "white": np.array([1.0, 1.0, 1.0], np.float32),
        "hue": h,
        "sat": sat,
    }


def fit_cover(img):
    w, h = img.size
    k = max(W / w, H / h)
    nw, nh = max(W, int(round(w * k))), max(H, int(round(h * k)))
    img = img.resize((nw, nh), Image.LANCZOS)
    x, y = (nw - W) // 2, (nh - H) // 2
    return img.crop((x, y, x + W, y + H))


def load_base(path):
    img = Image.open(path)
    try:
        img.seek(0)
    except EOFError:
        pass
    return fit_cover(img.convert("RGB"))


def night_from(img, pal):
    a = np.asarray(img).astype(np.float32) / 255.0
    lum = 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]
    if lum.mean() > 0.68:
        inv = np.clip(1.0 - lum, 0, 1) ** 1.35
        sat = a.max(axis=2) - a.min(axis=2)
        mono = pal["night"] * (1 - inv[..., None]) + (pal["pale"] * 0.85) * inv[..., None]
        colorful = np.clip((sat - 0.18) / 0.35, 0, 1)[..., None]
        tint = a * 0.45 + pal["deep"] * 0.35
        tint = tint * (0.5 + 0.5 * lum[..., None])
        out = mono * (1 - colorful) + tint * colorful
    else:
        grey = lum[..., None]
        desat = a * 0.62 + grey * 0.38
        dark = desat * (0.18 + 0.42 * np.clip(grey, 0, 1) ** 1.2)
        out = dark * 0.72 + pal["night"] * 0.6 + pal["deep"] * (grey ** 2.2) * 0.25
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    vign = 1 - 0.55 * (((xx - W * 0.5) / W) ** 2 + ((yy - H * 0.5) / H) ** 2) * 2.0
    out = out * np.clip(vign, 0.5, 1)[..., None]
    return Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8))


def blend(img, y0, y1, x0, x1, alpha, color):
    a = alpha[..., None]
    img[y0:y1, x0:x1] = img[y0:y1, x0:x1] * (1 - a) + color * a


def screen(img, y0, y1, x0, x1, alpha, color):
    a = alpha[..., None] * color
    img[y0:y1, x0:x1] = 1 - (1 - img[y0:y1, x0:x1]) * (1 - a)


class Layer:
    def __init__(self, spec, pal, night, seed):
        self.amount = max(0.0, min(1.0, float(spec.get("amount", 0.7))))
        self.cyc = max(1, min(3, int(spec.get("speed", 1))))
        self.pal = pal
        self.night = night
        self.rng = np.random.default_rng(seed)
        self.setup()

    def setup(self):
        pass

    def draw(self, img, t):
        pass


class Waves(Layer):
    def setup(self):
        self.xs = np.arange(W, dtype=np.float32)
        base = [
            dict(yc=0.75, amp=34, lam=1500, k=1, ph=0.0, amp2=16, lam2=2600, k2=-1, ph2=1.1, a=1.0),
            dict(yc=0.78, amp=28, lam=1250, k=1, ph=1.9, amp2=12, lam2=2900, k2=-1, ph2=2.4, a=0.8),
            dict(yc=0.81, amp=40, lam=1800, k=1, ph=3.6, amp2=18, lam2=2200, k2=-2, ph2=0.4, a=0.6),
            dict(yc=0.27, amp=22, lam=2100, k=-1, ph=0.7, amp2=10, lam2=3100, k2=1, ph2=2.0, a=0.45),
        ]
        self.waves = base[: 2 + int(round(self.amount * 2))]

    def draw(self, img, t):
        tau = TAU * t / T * self.cyc
        for w in self.waves:
            yc = w["yc"] * H
            y = (yc + w["amp"] * np.sin(TAU * self.xs / w["lam"] - w["k"] * tau + w["ph"])
                 + w["amp2"] * np.sin(TAU * self.xs / w["lam2"] - w["k2"] * tau + w["ph2"]))
            reach = w["amp"] + w["amp2"] + 26
            y0, y1 = int(max(0, yc - reach)), int(min(H, yc + reach))
            d = np.arange(y0, y1, dtype=np.float32)[:, None] - y[None, :]
            k = w["a"] * (0.55 + 0.45 * self.amount)
            glow = (0.2 if self.night else 0.13) * k * np.exp(-(d / 10.0) ** 2)
            core = (0.55 if self.night else 0.42) * k * np.exp(-(d / 1.1) ** 2)
            shine = (0.4 if self.night else 0.55) * k * np.exp(-((d + 1.8) / 0.85) ** 2)
            blend(img, y0, y1, 0, W, glow, self.pal["glow"] if self.night else self.pal["mid"])
            blend(img, y0, y1, 0, W, core, self.pal["mid"] if self.night else self.pal["deep"])
            blend(img, y0, y1, 0, W, shine, self.pal["white"])


class Bubbles(Layer):
    def setup(self):
        n = int(6 + 20 * self.amount)
        self.items = []
        for _ in range(n):
            r = float(self.rng.choice([9, 11, 13, 16, 19, 23, 28, 34, 42], p=[.14, .14, .13, .13, .12, .11, .1, .07, .06]))
            self.items.append(dict(r=r, x0=float(self.rng.uniform(60, W - 60)), off=float(self.rng.uniform(0, 1)),
                                   cyc=self.cyc if r >= 23 else self.cyc * int(self.rng.choice([1, 2])),
                                   wob=float(self.rng.uniform(8, 26)), m=int(self.rng.choice([1, 2, 3])),
                                   p=float(self.rng.uniform(0, TAU)), s=float(self.rng.uniform(0.75, 1.0))))

    def bubble(self, img, cx, cy, r, s):
        x0, x1 = int(math.floor(cx - r - 3)), int(math.ceil(cx + r + 3))
        y0, y1 = int(math.floor(cy - r - 3)), int(math.ceil(cy + r + 3))
        if x1 <= 0 or y1 <= 0 or x0 >= W or y0 >= H:
            return
        cx0, cy0, cx1, cy1 = max(x0, 0), max(y0, 0), min(x1, W), min(y1, H)
        Y, X = np.mgrid[cy0:cy1, cx0:cx1].astype(np.float32)
        dx, dy = (X + 0.5 - cx) / r, (Y + 0.5 - cy) / r
        rho = np.sqrt(dx * dx + dy * dy)
        inside = np.clip((1 - rho) * r + 0.5, 0, 1)
        k = 1.2 if self.night else 1.0
        body = inside * (0.04 + 0.13 * rho ** 4) * s * k
        edge = 0.4 * np.exp(-(((rho - 0.985) * r) / 1.1) ** 2) * s
        rim = 0.55 * np.exp(-(((rho - 0.90) * r) / 1.3) ** 2) * inside * s
        u = (dx + 0.34) * math.cos(0.7) + (dy + 0.40) * math.sin(0.7)
        v = -(dx + 0.34) * math.sin(0.7) + (dy + 0.40) * math.cos(0.7)
        hi = 0.8 * np.exp(-((u / 0.30) ** 2 + (v / 0.12) ** 2) * 2.2) * inside * s
        blend(img, cy0, cy1, cx0, cx1, body, self.pal["mid"])
        blend(img, cy0, cy1, cx0, cx1, edge, self.pal["glow"] if self.night else self.pal["deep"])
        blend(img, cy0, cy1, cx0, cx1, rim, self.pal["white"])
        blend(img, cy0, cy1, cx0, cx1, hi, self.pal["white"])

    def draw(self, img, t):
        for b in self.items:
            span = H + 2 * b["r"] + 40
            prog = (b["off"] + b["cyc"] * t / T) % 1.0
            cy = H + b["r"] + 20 - prog * span
            cx = b["x0"] + b["wob"] * math.sin(TAU * b["m"] * t / T + b["p"])
            self.bubble(img, cx, cy, b["r"], b["s"])


def glow_sprite(r):
    s = int(r * 2 + 1)
    Y, X = np.mgrid[0:s, 0:s].astype(np.float32)
    d = np.sqrt((X - r) ** 2 + (Y - r) ** 2) / r
    core = np.exp(-(d / 0.18) ** 2)
    halo = 0.45 * np.exp(-(d / 0.55) ** 2)
    ray = 0.5 * (np.exp(-((X - r) / (r * 0.05 + 0.6)) ** 2) + np.exp(-((Y - r) / (r * 0.05 + 0.6)) ** 2)) * np.exp(-d * 2.2)
    return np.clip(core + halo + ray, 0, 1)


def stamp(img, sprite, cx, cy, k, color, add=True):
    s = sprite.shape[0]
    x0, y0 = int(cx - s // 2), int(cy - s // 2)
    x1, y1 = x0 + s, y0 + s
    sx0, sy0 = max(0, -x0), max(0, -y0)
    x0c, y0c, x1c, y1c = max(0, x0), max(0, y0), min(W, x1), min(H, y1)
    if x1c <= x0c or y1c <= y0c:
        return
    a = sprite[sy0:sy0 + (y1c - y0c), sx0:sx0 + (x1c - x0c)] * k
    if add:
        screen(img, y0c, y1c, x0c, x1c, a, color)
    else:
        blend(img, y0c, y1c, x0c, x1c, a, color)


class Sparkles(Layer):
    def setup(self):
        n = int(14 + 50 * self.amount)
        self.sprites = {r: glow_sprite(r) for r in (6, 9, 13, 18)}
        self.items = []
        for _ in range(n):
            self.items.append(dict(x=float(self.rng.uniform(0, W)), y=float(self.rng.uniform(0, H)),
                                   r=int(self.rng.choice([6, 9, 13, 18], p=[.4, .3, .2, .1])),
                                   f=int(self.rng.integers(1, 4)) * self.cyc, p=float(self.rng.uniform(0, 1)),
                                   dx=float(self.rng.uniform(4, 18)), dy=float(self.rng.uniform(3, 12)),
                                   white=bool(self.rng.random() < 0.55)))

    def draw(self, img, t):
        for s in self.items:
            ph = TAU * (s["f"] * t / T + s["p"])
            k = max(0.0, math.sin(ph)) ** 3 * (0.6 + 0.4 * self.amount)
            if k < 0.02:
                continue
            cx = s["x"] + s["dx"] * math.sin(TAU * self.cyc * t / T + s["p"] * 6)
            cy = s["y"] + s["dy"] * math.cos(TAU * self.cyc * t / T + s["p"] * 6)
            stamp(img, self.sprites[s["r"]], cx, cy, k, self.pal["white"] if s["white"] else self.pal["glow"])


class Aurora(Layer):
    LW, LH = 384, 216

    def setup(self):
        self.bands = []
        for i in range(2 + int(round(self.amount * 2))):
            self.bands.append(dict(y=float(self.rng.uniform(0.22, 0.48)), amp=float(self.rng.uniform(0.03, 0.08)),
                                   lam=float(self.rng.uniform(0.7, 1.5)), k=int(self.rng.choice([-1, 1])) * self.cyc,
                                   ph=float(self.rng.uniform(0, TAU)), hue=float(self.rng.uniform(-30, 30)),
                                   up=float(self.rng.uniform(0.12, 0.22))))
        self.xs = np.linspace(0, 1, self.LW, dtype=np.float32)
        self.ys = np.linspace(0, 1, self.LH, dtype=np.float32)[:, None]
        n = self.rng.random(self.LW).astype(np.float32)
        sm = np.zeros_like(n)
        for o in range(-4, 5):
            sm += np.roll(n, o) * math.exp(-(o / 2.0) ** 2)
        sm = (sm - sm.min()) / max(1e-6, sm.max() - sm.min())
        self.rays = np.tile(sm, 3)

    def draw(self, img, t):
        acc = np.zeros((self.LH, self.LW, 3), np.float32)
        tau = TAU * t / T
        for j, b in enumerate(self.bands):
            c = (b["y"] + b["amp"] * np.sin(TAU * self.xs / b["lam"] + b["k"] * tau + b["ph"])
                 + 0.015 * np.sin(TAU * self.xs * 3.3 - b["k"] * tau * 2 + b["ph"]))[None, :]
            d = self.ys - c
            curtain = np.where(d < 0, np.exp(d / b["up"]) * (1 - np.exp(d / 0.012)) + np.exp(-(d / 0.01) ** 2) * 0.6,
                               np.exp(-(d / 0.012) ** 2))
            off = int(round(b["k"] * t / T * self.LW + j * 97)) % self.LW
            rays = 0.35 + 0.65 * self.rays[off:off + self.LW][None, :] ** 1.5
            col = hsl(self.pal["hue"] + b["hue"], min(1.0, 0.45 + self.pal["sat"] * 0.55), 0.6)
            acc += (curtain * rays)[..., None] * col
        big = Image.fromarray((np.clip(acc, 0, 1) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
        a = np.asarray(big).astype(np.float32) / 255.0 * ((0.6 if self.night else 0.32) * (0.5 + 0.5 * self.amount))
        np.copyto(img, 1 - (1 - img) * (1 - a))


class Rain(Layer):
    def setup(self):
        n = int(10 + 36 * self.amount)
        self.items = []
        for _ in range(n):
            self.items.append(dict(x=float(self.rng.uniform(0, W)), off=float(self.rng.uniform(0, 1)),
                                   r=float(self.rng.uniform(3.5, 8.0)), trail=float(self.rng.uniform(40, 160)),
                                   cyc=self.cyc * int(self.rng.choice([1, 2])), sway=float(self.rng.uniform(2, 8)),
                                   p=float(self.rng.uniform(0, TAU))))

    def draw(self, img, t):
        for d in self.items:
            prog = (d["off"] + d["cyc"] * t / T) % 1.0
            ease = prog ** 1.4
            cy = -40 + ease * (H + 80)
            cx = d["x"] + d["sway"] * math.sin(TAU * 2 * t / T + d["p"])
            r = d["r"]
            x0, x1 = int(cx - r - 2), int(cx + r + 3)
            y0, y1 = int(cy - d["trail"]), int(cy + r * 1.4 + 2)
            cx0, cy0, cx1, cy1 = max(0, x0), max(0, y0), min(W, x1), min(H, y1)
            if cx1 <= cx0 or cy1 <= cy0:
                continue
            Y, X = np.mgrid[cy0:cy1, cx0:cx1].astype(np.float32)
            dx = (X - cx) / r
            dy = (Y - cy) / (r * 1.35)
            rho = np.sqrt(dx * dx + dy * dy)
            drop = np.clip(1 - rho, 0, 1) ** 0.6
            above = np.clip((cy - Y) / d["trail"], 0, 1)
            trail = np.where(Y < cy, (1 - above) * np.exp(-(dx / 0.35) ** 2) * 0.35, 0)
            hi = np.exp(-(((dx + 0.35) / 0.25) ** 2 + ((dy + 0.35) / 0.25) ** 2))
            k = 0.5 + 0.5 * self.amount
            blend(img, cy0, cy1, cx0, cx1, drop * 0.22 * k, self.pal["deep"] if not self.night else self.pal["pale"])
            screen(img, cy0, cy1, cx0, cx1, np.clip(trail + hi * drop, 0, 1) * 0.75 * k, self.pal["white"])


class Hud(Layer):
    def setup(self):
        y = np.arange(H, dtype=np.float32)
        self.lines = ((y % 3) < 1).astype(np.float32)[:, None] * (0.05 + 0.05 * self.amount)
        g = np.zeros((H, W), np.float32)
        g[::64, :] = 1
        g[:, ::64] = 1
        self.grid = Image.fromarray((g * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.6))
        self.grid = np.asarray(self.grid).astype(np.float32) / 255.0

    def draw(self, img, t):
        col = self.pal["glow"] if self.night else self.pal["mid"]
        blend(img, 0, H, 0, W, np.broadcast_to(self.lines, (H, W)), self.pal["night"] if self.night else self.pal["deep"])
        pos = ((self.cyc * t / T) % 1.0) * (H + 300) - 150
        y0, y1 = int(max(0, pos - 150)), int(min(H, pos + 12))
        if y1 > y0:
            d = np.arange(y0, y1, dtype=np.float32)[:, None] - pos
            band = np.where(d < 0, np.exp(d / 60.0) * 0.12, np.exp(-(d / 3.0) ** 2) * 0.55) * (0.5 + 0.5 * self.amount)
            band = np.broadcast_to(band, (y1 - y0, W))
            screen(img, y0, y1, 0, W, band, col)
            gy0, gy1 = max(0, y0), min(H, y1)
            screen(img, gy0, gy1, 0, W, self.grid[gy0:gy1] * np.broadcast_to(np.where(d < 0, np.exp(d / 60.0), 1.0), (y1 - y0, W)) * 0.35, col)


def tile_noise(rng, w, h, blur):
    a = rng.random((h, w)).astype(np.float32)
    big = np.tile(a, (1, 3))
    im = Image.fromarray((big * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(blur))
    out = np.asarray(im).astype(np.float32)[:, w:2 * w] / 255.0
    out = (out - out.min()) / max(1e-6, out.max() - out.min())
    return out


class Mist(Layer):
    def setup(self):
        self.layers = []
        for i, (w, h, blur, sp) in enumerate([(64, 36, 3, 1), (96, 54, 4, -2)]):
            n = tile_noise(self.rng, w, h, blur)
            im = Image.fromarray((n * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
            self.layers.append((np.asarray(im).astype(np.float32) / 255.0, sp * self.cyc))
        y = np.linspace(0, 1, H, dtype=np.float32)[:, None]
        self.fall = 0.35 + 0.65 * y

    def draw(self, img, t):
        tot = np.zeros((H, W), np.float32)
        for tex, sp in self.layers:
            shift = int(round((sp * t / T) * W)) % W
            tot += np.roll(tex, shift, axis=1) ** 2.2
        a = np.clip(tot * 0.42, 0, 1) * self.fall * ((0.22 if self.night else 0.26) * (0.4 + 0.6 * self.amount))
        screen(img, 0, H, 0, W, a, self.pal["pale"] if not self.night else self.pal["deep"] * 1.4)


class Snow(Layer):
    def setup(self):
        n = int(20 + 70 * self.amount)
        self.sprites = {r: None for r in (3, 5, 8)}
        for r in self.sprites:
            s = r * 2 + 3
            Y, X = np.mgrid[0:s, 0:s].astype(np.float32)
            d = np.sqrt((X - s // 2) ** 2 + (Y - s // 2) ** 2) / r
            self.sprites[r] = np.clip(1.2 - d, 0, 1) ** 1.4
        self.items = []
        for _ in range(n):
            self.items.append(dict(x=float(self.rng.uniform(0, W)), off=float(self.rng.uniform(0, 1)),
                                   r=int(self.rng.choice([3, 5, 8], p=[.5, .35, .15])),
                                   cyc=self.cyc * int(self.rng.choice([1, 2])), sway=float(self.rng.uniform(10, 40)),
                                   m=int(self.rng.choice([1, 2, 3])), p=float(self.rng.uniform(0, TAU))))

    def draw(self, img, t):
        for s in self.items:
            prog = (s["off"] + s["cyc"] * t / T) % 1.0
            cy = -20 + prog * (H + 40)
            cx = s["x"] + s["sway"] * math.sin(TAU * s["m"] * t / T + s["p"])
            stamp(img, self.sprites[s["r"]], cx, cy, 0.55 + 0.4 * self.amount, self.pal["white"] if not self.night else self.pal["pale"], add=False)


def soft_disc(r, ring=0.0):
    s = int(r * 2 + 3)
    c = s / 2.0
    Y, X = np.mgrid[0:s, 0:s].astype(np.float32)
    d = np.sqrt((X + 0.5 - c) ** 2 + (Y + 0.5 - c) ** 2) / r
    body = np.clip((1 - d) * r / 5.0, 0, 1) * (0.55 + 0.25 * d ** 3)
    rim = ring * np.exp(-(((d - 0.93) * r) / 2.4) ** 2) * (d < 1.02)
    return np.clip(body + rim, 0, 1)


class Bokeh(Layer):
    def setup(self):
        n = int(8 + 16 * self.amount)
        self.sprites = {r: soft_disc(r, 0.45) for r in (34, 52, 74, 100)}
        cols = [self.pal["glow"], self.pal["pale"], self.pal["white"], hsl(self.pal["hue"] + 35, self.pal["sat"], 0.72)]
        self.items = []
        for _ in range(n):
            self.items.append(dict(x=float(self.rng.uniform(0, W)), y=float(self.rng.uniform(0, H)),
                                   r=int(self.rng.choice([34, 52, 74, 100], p=[.35, .3, .22, .13])),
                                   ax=float(self.rng.uniform(30, 140)), ay=float(self.rng.uniform(20, 90)),
                                   mx=int(self.rng.integers(1, 3)) * self.cyc, my=int(self.rng.integers(1, 3)) * self.cyc,
                                   f=int(self.rng.integers(1, 4)) * self.cyc, p=self.rng.uniform(0, TAU, 3),
                                   k=float(self.rng.uniform(0.18, 0.5)), c=cols[int(self.rng.integers(0, len(cols)))]))

    def draw(self, img, t):
        g = (0.5 + 0.5 * self.amount) * (1.25 if self.night else 0.85)
        for b in self.items:
            u = TAU * t / T
            cx = b["x"] + b["ax"] * math.sin(b["mx"] * u + b["p"][0])
            cy = b["y"] + b["ay"] * math.sin(b["my"] * u + b["p"][1])
            k = b["k"] * (0.55 + 0.45 * math.sin(b["f"] * u + b["p"][2])) * g
            stamp(img, self.sprites[b["r"]], cx, cy, k, b["c"])


class LowRes(Layer):
    LW, LH = 480, 270

    def coords(self):
        X, Y = np.meshgrid(np.linspace(0, 1, self.LW, dtype=np.float32), np.linspace(0, 1, self.LH, dtype=np.float32))
        return X, Y

    def apply(self, img, a, color):
        big = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
        screen(img, 0, H, 0, W, np.asarray(big).astype(np.float32) / 255.0, color)


class Rays(LowRes):
    def setup(self):
        X, Y = self.coords()
        ox, oy = 0.84, -0.14
        dx, dy = (X - ox) * (W / H), Y - oy
        self.ang = np.arctan2(dy, dx)
        self.dist = np.sqrt(dx * dx + dy * dy)
        self.comp = []
        for _ in range(5):
            self.comp.append((int(self.rng.integers(7, 26)), int(self.rng.choice([-1, 1])) * self.cyc,
                              float(self.rng.uniform(0, TAU)), float(self.rng.uniform(0.5, 1.0))))
        self.fall = np.exp(-self.dist / 1.1) * np.clip((self.dist - 0.05) / 0.25, 0, 1)

    def draw(self, img, t):
        u = TAU * t / T
        v = np.zeros_like(self.ang)
        tot = 0.0
        for f, sp, ph, w in self.comp:
            v += w * (0.5 + 0.5 * np.sin(f * self.ang + sp * u + ph))
            tot += w
        v = (v / tot) ** 3.2
        a = v * self.fall * ((0.55 if self.night else 0.42) * (0.45 + 0.55 * self.amount))
        self.apply(img, a, self.pal["glow"] if self.night else hsl(self.pal["hue"] + 25, self.pal["sat"] * 0.35, 0.92))


class Caustics(LowRes):
    def setup(self):
        X, Y = self.coords()
        self.X, self.Y = X * 9.0, Y * 5.2
        self.ph = self.rng.uniform(0, TAU, 4)
        y = np.linspace(0, 1, self.LH, dtype=np.float32)[:, None]
        self.mask = np.broadcast_to(0.35 + 0.65 * y ** 1.4, (self.LH, self.LW))

    def draw(self, img, t):
        u = TAU * t / T * self.cyc
        a1 = np.sin(self.X * 1.7 + 1.3 * np.sin(self.Y * 1.1 + u + self.ph[0]) + u + self.ph[1])
        a2 = np.sin(self.Y * 1.9 + 1.2 * np.sin(self.X * 0.9 - u + self.ph[2]) - 2 * u + self.ph[3])
        r1 = np.exp(-(a1 + a2) ** 2 * 5.0)
        r2 = np.exp(-(a1 - a2) ** 2 * 7.0) * 0.6
        a = (r1 + r2) * self.mask * ((0.34 if self.night else 0.26) * (0.45 + 0.55 * self.amount))
        self.apply(img, a, self.pal["glow"] if self.night else self.pal["pale"])


class Petals(Layer):
    def setup(self):
        n = int(10 + 30 * self.amount)
        self.items = []
        tones = [hsl(self.pal["hue"] + 15, min(1.0, self.pal["sat"] * 0.7 + 0.2), 0.84),
                 hsl(self.pal["hue"] - 20, min(1.0, self.pal["sat"] * 0.6 + 0.2), 0.78), self.pal["pale"]]
        for _ in range(n):
            self.items.append(dict(x=float(self.rng.uniform(-200, W)), off=float(self.rng.uniform(0, 1)),
                                   a=float(self.rng.uniform(13, 24)), b=float(self.rng.uniform(7, 12)),
                                   cyc=self.cyc * int(self.rng.choice([1, 2])), drift=float(self.rng.uniform(80, 360)),
                                   spin=int(self.rng.choice([-2, -1, 1, 2])) * self.cyc,
                                   tum=int(self.rng.integers(1, 4)) * self.cyc, p=self.rng.uniform(0, TAU, 3),
                                   c=tones[int(self.rng.integers(0, len(tones)))]))

    def draw(self, img, t):
        u = TAU * t / T
        for d in self.items:
            prog = (d["off"] + d["cyc"] * t / T) % 1.0
            cy = -30 + prog * (H + 60)
            cx = d["x"] + d["drift"] * prog + 26 * math.sin(2 * u * d["cyc"] + d["p"][0])
            rot = d["spin"] * u + d["p"][1]
            fa = d["a"]
            fb = d["b"] * (0.25 + 0.75 * abs(math.cos(d["tum"] * u + d["p"][2])))
            ext = fa + 3
            x0, x1 = int(cx - ext), int(cx + ext + 1)
            y0, y1 = int(cy - ext), int(cy + ext + 1)
            cx0, cy0, cx1, cy1 = max(0, x0), max(0, y0), min(W, x1), min(H, y1)
            if cx1 <= cx0 or cy1 <= cy0:
                continue
            Y, X = np.mgrid[cy0:cy1, cx0:cx1].astype(np.float32)
            dx, dy = X + 0.5 - cx, Y + 0.5 - cy
            pu = dx * math.cos(rot) + dy * math.sin(rot)
            pv = -dx * math.sin(rot) + dy * math.cos(rot)
            q = (pu / fa) ** 2 + (pv / fb) ** 2 * (1.0 + 0.35 * (pu / fa))
            body = np.clip((1 - q) * 3.0, 0, 1)
            hi = np.exp(-(((pu + fa * 0.25) / (fa * 0.45)) ** 2 + ((pv + fb * 0.3) / (fb * 0.5)) ** 2)) * body
            k = 0.55 + 0.4 * self.amount
            blend(img, cy0, cy1, cx0, cx1, body * 0.85 * k, d["c"])
            screen(img, cy0, cy1, cx0, cx1, hi * 0.5 * k, self.pal["white"])


class Stars(Layer):
    def setup(self):
        n = int(60 + 140 * self.amount)
        self.sprites = {r: glow_sprite(r) for r in (3, 5, 8)}
        self.items = []
        for _ in range(n):
            self.items.append(dict(x=float(self.rng.uniform(0, W)), y=float(self.rng.uniform(0, H * 0.7)),
                                   r=int(self.rng.choice([3, 5, 8], p=[.6, .3, .1])), f=int(self.rng.integers(1, 6)) * self.cyc,
                                   p=float(self.rng.uniform(0, TAU)), k=float(self.rng.uniform(0.35, 1.0))))
        self.shots = []
        for i in range(2 + int(round(3 * self.amount))):
            ang = math.radians(float(self.rng.uniform(200, 222)))
            self.shots.append(dict(s=(i + float(self.rng.uniform(0.1, 0.8))) / (2 + int(round(3 * self.amount))),
                                   x=float(self.rng.uniform(W * 0.35, W * 1.05)), y=float(self.rng.uniform(-20, H * 0.3)),
                                   dx=math.cos(ang), dy=-math.sin(ang), travel=float(self.rng.uniform(500, 900)),
                                   length=float(self.rng.uniform(180, 380))))
        self.dur = 0.045

    def streak(self, img, hx, hy, d, length, k):
        tx, ty = hx - d["dx"] * length, hy - d["dy"] * length
        x0, x1 = int(min(hx, tx) - 4), int(max(hx, tx) + 5)
        y0, y1 = int(min(hy, ty) - 4), int(max(hy, ty) + 5)
        cx0, cy0, cx1, cy1 = max(0, x0), max(0, y0), min(W, x1), min(H, y1)
        if cx1 <= cx0 or cy1 <= cy0:
            return
        Y, X = np.mgrid[cy0:cy1, cx0:cx1].astype(np.float32)
        vx, vy = X - tx, Y - ty
        L = max(1.0, length)
        along = np.clip((vx * d["dx"] + vy * d["dy"]) / L, 0, 1)
        px, py = tx + along * d["dx"] * L, ty + along * d["dy"] * L
        dist = np.sqrt((X - px) ** 2 + (Y - py) ** 2)
        a = np.exp(-(dist / (0.6 + 1.4 * along)) ** 2) * along ** 1.6 * k
        screen(img, cy0, cy1, cx0, cx1, np.clip(a, 0, 1), self.pal["white"])

    def draw(self, img, t):
        base = (1.0 if self.night else 0.32) * (0.6 + 0.4 * self.amount)
        for s in self.items:
            k = s["k"] * base * (0.45 + 0.55 * (0.5 + 0.5 * math.sin(TAU * s["f"] * t / T + s["p"])))
            stamp(img, self.sprites[s["r"]], s["x"], s["y"], k, self.pal["white"] if s["r"] < 8 else self.pal["pale"])
        loop = (self.cyc * t / T) % 1.0
        for d in self.shots:
            local = (loop - d["s"]) % 1.0
            if local >= self.dur:
                continue
            p = local / self.dur
            hx, hy = d["x"] + d["dx"] * d["travel"] * p, d["y"] + d["dy"] * d["travel"] * p
            fade = math.sin(math.pi * p) ** 0.7
            self.streak(img, hx, hy, d, d["length"] * min(1.0, p * 2.5 + 0.2), fade * (0.95 if self.night else 0.6))
            stamp(img, self.sprites[5], hx, hy, fade, self.pal["white"])


def ring_sprite(r, w):
    s = int(r * 2 + 3)
    c = s / 2.0
    Y, X = np.mgrid[0:s, 0:s].astype(np.float32)
    d = np.sqrt((X + 0.5 - c) ** 2 + (Y + 0.5 - c) ** 2)
    return np.clip(np.exp(-((d - r * 0.9) / w) ** 2) * 0.8 + np.clip(1 - d / r, 0, 1) * 0.12, 0, 1)


class Flare(Layer):
    def setup(self):
        self.core = glow_sprite(60)
        s2 = 321
        Y, X = np.mgrid[0:s2, 0:s2].astype(np.float32)
        self.halo = np.exp(-(np.sqrt((X - 160) ** 2 + (Y - 160) ** 2) / 70.0) ** 2)
        self.star = glow_sprite(22)
        h, s = self.pal["hue"], self.pal["sat"]
        self.ghosts = [(-0.35, soft_disc(26, 0.3), hsl(h + 40, s, 0.75), 0.35), (0.3, soft_disc(14, 0.5), self.pal["pale"], 0.5),
                       (0.55, ring_sprite(48, 3.5), hsl(h - 50, s, 0.7), 0.45), (0.85, soft_disc(36, 0.4), self.pal["glow"], 0.3),
                       (1.25, soft_disc(70, 0.25), hsl(h + 80, s * 0.8, 0.75), 0.18), (1.6, ring_sprite(90, 6.0), self.pal["pale"], 0.22)]
        self.ph = float(self.rng.uniform(0, TAU))

    def draw(self, img, t):
        u = TAU * self.cyc * t / T + self.ph
        sx, sy = W * (0.74 + 0.11 * math.cos(u)), H * (0.17 + 0.07 * math.sin(u))
        g = (0.42 if self.night else 0.34) * (0.45 + 0.55 * self.amount)
        stamp(img, self.halo, sx, sy, g * 1.3, self.pal["pale"])
        stamp(img, self.core, sx, sy, g * 1.8, self.pal["white"])
        stamp(img, self.star, sx, sy, g * 1.5, self.pal["glow"])
        y0, y1 = int(max(0, sy - 10)), int(min(H, sy + 11))
        if y1 > y0:
            dy = np.arange(y0, y1, dtype=np.float32)[:, None] - sy
            dx = np.arange(W, dtype=np.float32)[None, :] - sx
            band = np.exp(-(dy / 2.2) ** 2) * np.exp(-np.abs(dx) / (W * 0.28)) * g * 1.3
            screen(img, y0, y1, 0, W, band, self.pal["pale"])
        cx, cy = W / 2, H / 2
        for f, spr, col, k in self.ghosts:
            gx, gy = sx + (cx - sx) * (1 + f), sy + (cy - sy) * (1 + f)
            stamp(img, spr, gx, gy, k * g * 2.4, col)


class Grid(Layer):
    def setup(self):
        self.hy = int(H * 0.62)
        rows = np.arange(self.hy, H, dtype=np.float32) + 0.5 - self.hy
        self.depth = 260.0 / (rows + 6.0)
        self.ddepth = 260.0 / (rows + 6.0) ** 2
        xs = np.arange(W, dtype=np.float32) + 0.5 - W / 2
        self.xp = xs[None, :] / (rows[:, None] + 6.0) * 2.4
        self.dxp = 2.4 / (rows + 6.0)
        r = (rows / (H - self.hy))[:, None]
        self.fade = np.clip(r * 6.0, 0, 1) * (0.55 + 0.45 * r)

    def draw(self, img, t):
        ph = (self.cyc * 3 * t / T) % 1.0
        v = self.depth[:, None] + ph
        dh = np.abs(v - np.round(v))
        wh = np.clip(self.ddepth[:, None] * 1.3, 0.004, 0.5)
        lh = np.exp(-(dh / wh) ** 2)
        dv = np.abs(self.xp - np.round(self.xp))
        wv = np.clip(self.dxp[:, None] * 1.1, 0.004, 0.5)
        lv = np.exp(-(dv / wv) ** 2)
        a = np.clip(lh + lv, 0, 1) * self.fade * ((0.6 if self.night else 0.55) * (0.45 + 0.55 * self.amount))
        screen(img, self.hy, H, 0, W, a, self.pal["glow"] if self.night else self.pal["mid"])
        d = np.arange(max(0, self.hy - 40), min(H, self.hy + 40), dtype=np.float32)[:, None] - self.hy
        hz = np.broadcast_to(np.exp(-(d / (6.0 if d.size else 1)) ** 2) * 0.5 * (0.5 + 0.5 * self.amount), (d.shape[0], W))
        screen(img, max(0, self.hy - 40), min(H, self.hy + 40), 0, W, hz, self.pal["glow"])


CLASSES = {"bubbles": Bubbles, "waves": Waves, "sparkles": Sparkles, "aurora": Aurora, "rain": Rain, "hud": Hud,
           "mist": Mist, "snow": Snow, "bokeh": Bokeh, "rays": Rays, "petals": Petals, "stars": Stars,
           "caustics": Caustics, "flare": Flare, "grid": Grid}
ORDER = ["rays", "aurora", "caustics", "mist", "grid", "hud", "waves", "rain", "petals", "snow", "stars", "bokeh",
         "sparkles", "flare", "bubbles"]


def build_layers(spec, night):
    pal = palette_for(spec.get("accent", "blue"))
    out = []
    specs = [l for l in spec.get("layers", []) if l.get("type") in CLASSES]
    specs.sort(key=lambda l: ORDER.index(l["type"]))
    for i, l in enumerate(specs):
        out.append(CLASSES[l["type"]](l, pal, night, 11 + i * 7))
    return out


def frame(base, layers, t):
    img = base.copy()
    for l in layers:
        l.draw(img, t)
    return (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8)


def bases(spec):
    pal = palette_for(spec.get("accent", "blue"))
    day = load_base(spec["image"])
    night = night_from(day, pal)
    return day, night


def encode(base_img, layers, out, frames):
    arr = np.asarray(base_img).astype(np.float32) / 255.0
    ff = subprocess.Popen([
        "ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS),
        "-i", "-", "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p", "-g", str(FPS * 4),
        "-movflags", "+faststart", out + ".part.mp4"], stdin=subprocess.PIPE)
    for i in range(frames):
        ff.stdin.write(frame(arr, layers, i / FPS).tobytes())
        if i % 12 == 0:
            print(json.dumps({"part": i / frames}), flush=True)
    ff.stdin.close()
    if ff.wait() != 0:
        raise RuntimeError("ffmpeg falló")
    os.replace(out + ".part.mp4", out)


def cmd_encode(spec_path, outdir, mode):
    spec = json.load(open(spec_path))
    night = mode == "night"
    base = Image.open(os.path.join(outdir, f"{mode}.jpg")).convert("RGB")
    encode(base, build_layers(spec, night), os.path.join(outdir, f"{mode}.mp4"), int(spec.get("frames", FRAMES)))


def cmd_render(spec_path, outdir):
    import threading
    spec = json.load(open(spec_path))
    os.makedirs(outdir, exist_ok=True)
    day, night = bases(spec)
    day.save(os.path.join(outdir, "day.jpg"), quality=95)
    night.save(os.path.join(outdir, "night.jpg"), quality=95)
    parts = {"day": 0.0, "night": 0.0}
    lock = threading.Lock()
    procs = {}
    for mode in ("day", "night"):
        procs[mode] = subprocess.Popen([sys.executable, os.path.abspath(__file__), "encode", spec_path, outdir, mode],
                                       stdout=subprocess.PIPE, text=True)

    def pump(mode):
        for line in procs[mode].stdout:
            try:
                v = json.loads(line).get("part")
            except ValueError:
                continue
            if v is None:
                continue
            with lock:
                parts[mode] = v
                print(json.dumps({"progress": round((parts["day"] + parts["night"]) / 2 * 0.98, 4)}), flush=True)

    threads = [threading.Thread(target=pump, args=(m,)) for m in procs]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    if any(p.wait() != 0 for p in procs.values()):
        print(json.dumps({"error": "No pude generar el video"}), flush=True)
        return 1
    thumb = Image.fromarray(frame(np.asarray(day).astype(np.float32) / 255.0, build_layers(spec, False), 7.0))
    thumb.resize((480, 270), Image.LANCZOS).save(os.path.join(outdir, "thumb.jpg"), quality=88)
    json.dump(spec, open(os.path.join(outdir, "spec.json"), "w"), ensure_ascii=False, indent=2)
    print(json.dumps({"progress": 1.0, "done": outdir}), flush=True)
    return 0


def cmd_preview(spec_path, out_day, out_night, t=7.0):
    spec = json.load(open(spec_path))
    day, night = bases(spec)
    for img, layers, out in ((day, build_layers(spec, False), out_day), (night, build_layers(spec, True), out_night)):
        f = Image.fromarray(frame(np.asarray(img).astype(np.float32) / 255.0, layers, t))
        f.resize((960, 540), Image.LANCZOS).save(out, quality=90)
    print(json.dumps({"preview": [out_day, out_night]}), flush=True)


def cmd_palette(path):
    img = load_base(path).resize((192, 108), Image.LANCZOS)
    a = np.asarray(img).astype(np.float32).reshape(-1, 3) / 255.0
    hls = np.array([colorsys.rgb_to_hls(*p) for p in a])
    h, l, s = hls[:, 0] * 360, hls[:, 1], hls[:, 2]
    keep = (s > 0.22) & (l > 0.15) & (l < 0.88)
    out = []
    if keep.sum() > 30:
        hist, edges = np.histogram(h[keep], bins=36, range=(0, 360), weights=s[keep])
        hist = hist + 0.5 * np.roll(hist, 1) + 0.5 * np.roll(hist, -1)
        order = np.argsort(hist)[::-1]
        for b in order:
            if hist[b] <= 0:
                break
            hue = int((edges[b] + 5) % 360)
            if any(min(abs(hue - o), 360 - abs(hue - o)) < 25 for o, _ in out):
                continue
            sel = keep & (np.abs(((h - hue + 180) % 360) - 180) < 15)
            sat = float(np.clip(np.median(s[sel]) * 1.15 if sel.any() else 0.8, 0.35, 1.3))
            out.append((hue, sat))
            if len(out) >= 4:
                break
    res = []
    for hue, sat in out:
        r, g, b = colorsys.hls_to_rgb(hue / 360, 0.56, min(1.0, 0.82 * sat))
        res.append({"accent": f"c-{hue}-{int(round(sat * 100))}", "hex": "#%02x%02x%02x" % (int(r * 255), int(g * 255), int(b * 255))})
    lum = float((0.2126 * a[:, 0] + 0.7152 * a[:, 1] + 0.0722 * a[:, 2]).mean())
    res.append({"accent": "c-210-5", "hex": "#9aa3ae", "mono": True})
    print(json.dumps({"suggest": res, "bright": lum}), flush=True)


def main(argv):
    if len(argv) >= 3 and argv[0] == "render":
        return cmd_render(argv[1], argv[2])
    if len(argv) >= 4 and argv[0] == "encode":
        cmd_encode(argv[1], argv[2], argv[3])
        return 0
    if len(argv) >= 4 and argv[0] == "preview":
        cmd_preview(argv[1], argv[2], argv[3], float(argv[4]) if len(argv) > 4 else 7.0)
        return 0
    if len(argv) >= 2 and argv[0] == "palette":
        cmd_palette(argv[1])
        return 0
    print("uso: aero-wallgen.py render SPEC.json CARPETA | preview SPEC.json DIA.jpg NOCHE.jpg [t] | palette IMAGEN")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
