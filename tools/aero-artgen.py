#!/usr/bin/env python3

import os
import sys
import math

import numpy as np
from PIL import Image, ImageFilter

W, H = 1920, 1080
Y, X = np.mgrid[0:H, 0:W].astype(np.float32)
U, V = X / W, Y / H


def hexc(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)], np.float32)


def vgrad(stops):
    out = np.zeros((H, W, 3), np.float32)
    pos = [p for p, _ in stops]
    cols = [hexc(c) for _, c in stops]
    v = V[:, :1]
    for ch in range(3):
        out[..., ch] = np.interp(v, pos, [c[ch] for c in cols])
    return out


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def noise(seed, scales=((8, 1.0), (16, 0.5), (32, 0.25), (64, 0.125))):
    rng = np.random.default_rng(seed)
    acc = np.zeros((H, W), np.float32)
    tot = 0.0
    for n, amp in scales:
        small = rng.random((max(2, n * 9 // 16), n)).astype(np.float32)
        big = Image.fromarray((small * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
        acc += np.asarray(big).astype(np.float32) / 255.0 * amp
        tot += amp
    acc /= tot
    return (acc - acc.min()) / max(1e-6, acc.max() - acc.min())


def over(img, alpha, color):
    a = np.clip(alpha, 0, 1)[..., None]
    return img * (1 - a) + color * a


def add(img, alpha, color):
    a = np.clip(alpha, 0, 1)[..., None] * color
    return 1 - (1 - img) * (1 - a)


def glow(cx, cy, r, power=2.0):
    d = np.sqrt(((X - cx) / r) ** 2 + ((Y - cy) / r) ** 2)
    return np.exp(-d ** power)


def ridge(base, waves):
    xs = np.arange(W, dtype=np.float32)
    y = np.full(W, base * H, np.float32)
    for amp, lam, ph in waves:
        y += amp * H * np.sin(2 * math.pi * xs / (lam * W) + ph)
    return y


def hill(img, crest, top, bottom, gloss=0.5, rim="#ffffff", seed=1):
    below = Y - crest[None, :]
    mask = smooth(-1.5, 1.5, below)
    depth = np.clip(below / (H * 0.35), 0, 1)
    body = top * (1 - depth[..., None]) + bottom * depth[..., None]
    tex = noise(seed, ((60, 1.0), (140, 0.6)))
    body = body * (0.94 + 0.08 * tex[..., None])
    img = img * (1 - mask[..., None]) + body * mask[..., None]
    shine = np.exp(-((below - H * 0.012) / (H * 0.009)) ** 2) * mask * gloss * 0.7
    img = add(img, shine, hexc(rim))
    edge = np.exp(-(below / 1.6) ** 2) * 0.55
    img = add(img, edge, hexc(rim))
    return img


def ribbon(img, y0, amp, lam, ph, width, color, alpha, tilt=0.0):
    xs = np.arange(W, dtype=np.float32)
    c = y0 * H + amp * H * np.sin(2 * math.pi * xs / (lam * W) + ph) + tilt * H * (xs / W - 0.5)
    d = Y - c[None, :]
    w = width * H * (0.6 + 0.4 * np.sin(2 * math.pi * xs / (lam * W * 0.7) + ph * 1.7))[None, :]
    body = np.exp(-(d / w) ** 2) * alpha
    core = np.exp(-((d + w * 0.35) / (w * 0.18)) ** 2) * alpha * 0.9
    img = add(img, body, hexc(color))
    return add(img, core, np.array([1, 1, 1], np.float32))


def rays(img, cx, cy, count, alpha, color, seed=3):
    rng = np.random.default_rng(seed)
    ang = np.arctan2(Y - cy, X - cx)
    v = np.zeros_like(ang)
    for _ in range(4):
        f = int(rng.integers(count // 2, count))
        v += 0.5 + 0.5 * np.sin(f * ang + rng.uniform(0, 6.28))
    v = (v / 4) ** 3
    d = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2) / math.hypot(W, H)
    return add(img, v * np.exp(-d * 2.2) * alpha, hexc(color))


def clouds(img, seed, y0, y1, density=0.55, alpha=0.9):
    n = noise(seed, ((6, 1.0), (12, 0.6), (24, 0.35), (48, 0.2), (96, 0.1)))
    band = smooth(y0 - 0.1, y0 + 0.05, V) * (1 - smooth(y1 - 0.05, y1 + 0.12, V))
    c = smooth(density, density + 0.22, n) * band
    shade = 0.82 + 0.18 * (1 - smooth(0.3, 0.9, n))
    img = over(img, c * alpha * 0.92, np.array([1, 1, 1], np.float32) * 1.0)
    under = smooth(density + 0.05, density + 0.35, np.roll(n, -14, axis=0)) * band
    return over(img, (c - under * 0.6).clip(0, 1) * 0.0 + c * (1 - shade) * 0.8, hexc("#b9d7f2"))


def sky():
    img = vgrad([(0.0, "#1659d6"), (0.38, "#4fa3f0"), (0.62, "#a9dcfb"), (0.72, "#e3f6ff"), (1.0, "#e3f6ff")])
    img = add(img, glow(W * 0.76, H * 0.16, W * 0.22, 1.6) * 0.85, hexc("#fffbe8"))
    img = rays(img, W * 0.76, H * 0.16, 30, 0.22, "#ffffff")
    img = clouds(img, 11, 0.08, 0.52)
    img = hill(img, ridge(0.66, [(0.025, 1.3, 0.4), (0.012, 0.45, 1.3)]), hexc("#6fc7c9"), hexc("#3f9fb3"), 0.25, seed=2)
    img = hill(img, ridge(0.74, [(0.035, 1.1, 2.2), (0.01, 0.3, 0.2)]), hexc("#7fdc5c"), hexc("#2e8f3c"), 0.55, seed=3)
    img = hill(img, ridge(0.84, [(0.04, 0.9, 4.1), (0.012, 0.33, 1.0)]), hexc("#9ef06a"), hexc("#2c8a34"), 0.7, seed=4)
    img = ribbon(img, 0.56, 0.05, 1.4, 0.6, 0.012, "#bfe6ff", 0.55, -0.12)
    img = ribbon(img, 0.6, 0.04, 1.1, 2.3, 0.008, "#ffffff", 0.45, -0.08)
    return img


def coral():
    img = vgrad([(0.0, "#2a0a3a"), (0.3, "#8e1d5c"), (0.5, "#e2486a"), (0.62, "#ff9a6b"), (0.66, "#ffd9a8"), (1.0, "#ffd9a8")])
    sx, sy = W * 0.5, H * 0.62
    img = add(img, glow(sx, sy, W * 0.35, 1.4) * 0.65, hexc("#ffe0b0"))
    disc = smooth(1.0, 0.97, np.sqrt((X - sx) ** 2 + (Y - sy) ** 2) / (H * 0.11))
    img = over(img, disc, hexc("#fff3dc"))
    img = clouds(img, 21, 0.12, 0.5, 0.6, 0.35)
    sea = smooth(0.655, 0.665, V)
    water = vgrad([(0.0, "#c2405e"), (0.66, "#b23a5c"), (0.8, "#5e1747"), (1.0, "#2a0a32")])
    img = img * (1 - sea[..., None]) + water * sea[..., None]
    n = noise(5, ((40, 1.0), (120, 0.5)))
    lines = (0.5 + 0.5 * np.sin(Y * (0.18 + 0.5 * (V - 0.66).clip(0)) + n * 9)) ** 6
    path = np.exp(-((X - sx) / (W * (0.035 + (V - 0.66).clip(0) * 0.4))) ** 2)
    img = add(img, np.exp(-((V - 0.66) / 0.012) ** 2) * 0.5, hexc("#ffd9b8"))
    img = add(img, lines * path * sea * 0.9, hexc("#ffd9b0"))
    for cx, wd, ht in [(0.12, 0.22, 0.09), (0.86, 0.26, 0.11), (0.95, 0.12, 0.06)]:
        top = 0.655 * H - ht * H * np.exp(-((X[:1] - cx * W) / (wd * W)) ** 2)[0]
        m = smooth(-1.0, 1.0, Y - top[None, :]) * (1 - smooth(0.654, 0.656, V))
        img = over(img, m, hexc("#5a1848"))
    img = ribbon(img, 0.42, 0.05, 1.3, 1.1, 0.01, "#ffd0e0", 0.4, 0.1)
    return img


def lagoon():
    img = vgrad([(0.0, "#a6fbe9"), (0.12, "#4fe0c4"), (0.45, "#11a28c"), (0.8, "#06614f"), (1.0, "#033a33")])
    img = rays(img, W * 0.45, -H * 0.25, 22, 0.55, "#e9fff8", seed=9)
    n1 = noise(31, ((40, 1.0), (80, 0.6)))
    n2 = noise(32, ((40, 1.0), (80, 0.6)))
    caust = np.exp(-((n1 - n2) * 10) ** 2) * (1 - smooth(0.02, 0.28, V))
    img = add(img, caust * 0.32, hexc("#f2fffb"))
    floor = ridge(0.82, [(0.03, 1.2, 0.6), (0.012, 0.4, 2.1)])
    img = hill(img, floor, hexc("#e9d9a6"), hexc("#9c8c5a"), 0.35, "#fff7d6", 12)
    for i, (x0, hgt, ph) in enumerate([(0.12, 0.42, 0.0), (0.18, 0.3, 1.0), (0.83, 0.38, 2.0), (0.9, 0.26, 0.6), (0.64, 0.2, 1.7)]):
        t = np.clip((floor[int(x0 * W)] / H - V) / hgt, 0, 1)
        cx = x0 * W + 26 * np.sin(t * 6.0 + ph) * t
        wdt = 26 * (1 - t) ** 0.7 + 6
        stem = np.exp(-((X - cx) / wdt) ** 2) * (t > 0) * (t < 1)
        img = over(img, stem * 0.9, hexc("#0f6b4c" if i % 2 else "#169460"))
        img = add(img, np.exp(-((X - cx + wdt * 0.35) / (wdt * 0.22)) ** 2) * (t > 0) * (t < 1) * 0.35, hexc("#b8ffd8"))
    img = ribbon(img, 0.35, 0.04, 1.2, 0.3, 0.014, "#bff7ec", 0.35, 0.05)
    return img


def chrome():
    img = vgrad([(0.0, "#f7fafd"), (0.5, "#e2e9f1"), (1.0, "#b9c6d4")])
    img = add(img, glow(W * 0.8, H * 0.85, W * 0.45, 1.3) * 0.35, hexc("#9fb4cc"))
    img = add(img, glow(W * 0.3, H * 0.3, W * 0.5, 1.5) * 0.5, hexc("#ffffff"))
    for y0, amp, lam, ph, w, col, a in [(0.58, 0.08, 1.3, 0.4, 0.05, "#7f8ea3", 0.6), (0.62, 0.07, 1.0, 2.0, 0.03, "#4b5768", 0.55),
                                         (0.5, 0.06, 1.6, 4.0, 0.02, "#a9b6c6", 0.5)]:
        xs = np.arange(W, dtype=np.float32)
        c = y0 * H + amp * H * np.sin(2 * math.pi * xs / (lam * W) + ph)
        d = Y - c[None, :]
        body = np.exp(-(d / (w * H)) ** 2) * a
        img = over(img, body, hexc(col))
        hi = np.exp(-((d + w * H * 0.45) / (w * H * 0.12)) ** 2) * a
        img = add(img, hi, np.array([1, 1, 1], np.float32))
    g = ((np.abs(((X / 72) % 1) - 0.5) < 0.012) | (np.abs(((Y / 72) % 1) - 0.5) < 0.012)).astype(np.float32)
    img = over(img, g * 0.06 * (1 - smooth(0.3, 1.0, V)), hexc("#6b7a8f"))
    img = ribbon(img, 0.4, 0.05, 1.5, 1.4, 0.01, "#ffffff", 0.6, -0.1)
    return img


ARTS = {"blue": sky, "red": coral, "green": lagoon, "black": chrome}


def finish(img):
    vign = 1 - 0.18 * (((U - 0.5) * 2) ** 2 + ((V - 0.5) * 2) ** 2) * 0.5
    img = img * vign[..., None]
    out = Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8))
    return out.filter(ImageFilter.GaussianBlur(0.6))


def main(argv):
    out = argv[0] if argv else "."
    names = argv[1:] or list(ARTS)
    os.makedirs(out, exist_ok=True)
    for n in names:
        p = os.path.join(out, f"base-{n}.png")
        finish(ARTS[n]()).save(p)
        print(p, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
