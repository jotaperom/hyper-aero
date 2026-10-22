#!/usr/bin/env python3

import os
import sys
import math

import numpy as np
from PIL import Image

CELL = 320
COLS = 10
ROWS = 6
FRAMES = COLS * ROWS
RADIUS = 142
SS = 2

PRESETS = {
    "blue": {"sea": (119, 215, 254), "land": (186, 238, 255), "line": (225, 248, 255)},
    "green": {"sea": (86, 226, 152), "land": (160, 242, 198), "line": (220, 255, 236)},
    "red": {"sea": (254, 180, 208), "land": (255, 220, 236), "line": (255, 240, 248)},
    "black": {"sea": (85, 216, 236), "land": (160, 246, 252), "line": (220, 252, 255)},
}

rng = np.random.default_rng(7)
PERM = rng.permutation(256)
PERM = np.concatenate([PERM, PERM])
GRAD = rng.normal(size=(256, 3))
GRAD /= np.linalg.norm(GRAD, axis=1, keepdims=True)


def fade(t):
    return t * t * t * (t * (t * 6 - 15) + 10)


def perlin(x, y, z):
    xi, yi, zi = np.floor(x).astype(int) & 255, np.floor(y).astype(int) & 255, np.floor(z).astype(int) & 255
    xf, yf, zf = x - np.floor(x), y - np.floor(y), z - np.floor(z)
    u, v, w = fade(xf), fade(yf), fade(zf)

    def g(ix, iy, iz, dx, dy, dz):
        h = PERM[PERM[PERM[ix] + iy] + iz]
        gr = GRAD[h]
        return gr[..., 0] * dx + gr[..., 1] * dy + gr[..., 2] * dz

    n000 = g(xi, yi, zi, xf, yf, zf)
    n100 = g(xi + 1, yi, zi, xf - 1, yf, zf)
    n010 = g(xi, yi + 1, zi, xf, yf - 1, zf)
    n110 = g(xi + 1, yi + 1, zi, xf - 1, yf - 1, zf)
    n001 = g(xi, yi, zi + 1, xf, yf, zf - 1)
    n101 = g(xi + 1, yi, zi + 1, xf - 1, yf, zf - 1)
    n011 = g(xi, yi + 1, zi + 1, xf, yf - 1, zf - 1)
    n111 = g(xi + 1, yi + 1, zi + 1, xf - 1, yf - 1, zf - 1)
    x1 = n000 + u * (n100 - n000)
    x2 = n010 + u * (n110 - n010)
    x3 = n001 + u * (n101 - n001)
    x4 = n011 + u * (n111 - n011)
    y1 = x1 + v * (x2 - x1)
    y2 = x3 + v * (x4 - x3)
    return y1 + w * (y2 - y1)


def fbm(x, y, z):
    total, amp, freq = 0.0, 1.0, 1.0
    for _ in range(5):
        total = total + amp * perlin(x * freq + 11.3, y * freq + 3.7, z * freq + 7.1)
        amp *= 0.5
        freq *= 2.03
    return total


def frame(angle, pal):
    n = CELL * SS
    c = (n - 1) / 2
    yy, xx = np.mgrid[0:n, 0:n].astype(float)
    px = (xx - c) / (RADIUS * SS)
    py = (yy - c) / (RADIUS * SS)
    r2 = px * px + py * py
    inside = r2 <= 1
    pz = np.sqrt(np.clip(1 - r2, 0, 1))
    tilt = math.radians(18)
    ty = py * math.cos(tilt) - pz * math.sin(tilt)
    tz = py * math.sin(tilt) + pz * math.cos(tilt)
    ca, sa = math.cos(angle), math.sin(angle)
    wx = px * ca + tz * sa
    wz = -px * sa + tz * ca
    wy = ty
    land = fbm(wx * 1.6, wy * 1.6, wz * 1.6) + 0.18 * (1 - np.abs(wy)) - 0.12
    coast = np.clip((land - 0.02) / 0.05, 0, 1)
    lat = np.degrees(np.arcsin(np.clip(wy, -1, 1)))
    lon = np.degrees(np.arctan2(wz, wx))
    grid = np.maximum(np.clip(1 - np.abs(((lat + 15) % 30) - 15) / 0.9, 0, 1),
                      np.clip(1 - np.abs(((lon + 15) % 30) - 15) / 0.9 * np.cos(np.radians(lat)), 0, 1))
    grid *= 0.35
    sea = np.array(pal["sea"], float)
    ground = np.array(pal["land"], float)
    line = np.array(pal["line"], float)
    rgb = sea[None, None] * (1 - coast[..., None]) + ground[None, None] * coast[..., None]
    rgb = rgb * (1 - grid[..., None]) + line[None, None] * grid[..., None]
    light = np.clip(0.55 + 0.45 * (-px * 0.45 - py * 0.6 + pz * 0.66), 0.35, 1.1)
    rgb = np.clip(rgb * (0.7 + 0.3 * light[..., None]), 0, 255)
    alpha = 100 + 135 * coast + 60 * grid
    rim = np.clip((np.sqrt(r2) - 0.86) / 0.14, 0, 1)
    alpha = alpha * (1 - 0.55 * rim)
    gloss = np.exp(-(((px + 0.32) / 0.42) ** 2 + ((py + 0.48) / 0.22) ** 2)) * 0.75
    rgb = rgb * (1 - gloss[..., None]) + 255 * gloss[..., None]
    alpha = np.clip(alpha + gloss * 120, 0, 255)
    edge = np.clip((1 - np.sqrt(r2)) * RADIUS * SS / 1.5, 0, 1)
    alpha = alpha * edge * inside
    img = np.dstack([rgb, alpha]).astype(np.uint8)
    return Image.fromarray(img, "RGBA").resize((CELL, CELL), Image.LANCZOS)


def build(name, out):
    pal = PRESETS[name]
    sheet = Image.new("RGBA", (CELL * COLS, CELL * ROWS), (0, 0, 0, 0))
    for i in range(FRAMES):
        img = frame(2 * math.pi * i / FRAMES, pal)
        sheet.paste(img, ((i % COLS) * CELL, (i // COLS) * CELL))
    sheet.save(os.path.join(out, f"globe-{name}.png"), optimize=True)
    print(name)


def main(argv):
    out = argv[0] if argv else os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                                             "dotfiles", ".config", "quickshell", "aero-phone", "globe")
    os.makedirs(out, exist_ok=True)
    for name in PRESETS:
        build(name, out)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
