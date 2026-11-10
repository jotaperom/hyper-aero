#!/usr/bin/env python3

import os
import sys
import math
import random
from PIL import Image, ImageDraw, ImageFilter


def inside(path, roots):
    p = os.path.realpath(path)
    for r in roots:
        r = os.path.realpath(r)
        if p == r or p.startswith(r + os.sep):
            return p
    sys.exit("ruta no permitida: " + path)


out = inside(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "dotfiles", ".config", "quickshell", "aero-desk", "fx"), [os.path.dirname(os.path.dirname(os.path.abspath(__file__))), os.path.expanduser("~")])
os.makedirs(out, exist_ok=True)

s = 64
im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
px = im.load()
for x in range(s):
    a = (x / (s - 1)) ** 1.5
    for y in range(s // 2 - 2, s // 2 + 2):
        edge = 1 - abs(y - (s / 2 - 0.5)) / 2.0
        px[x, y] = (225, 240, 255, int(255 * a * max(0, edge) * 0.9))
im.save(os.path.join(out, "rain.png"))

s = 48
im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
dr = ImageDraw.Draw(im)
dr.ellipse((6, 4, s - 6, s - 2), fill=(200, 225, 255, 70), outline=(255, 255, 255, 170), width=2)
dr.ellipse((14, 10, 26, 18), fill=(255, 255, 255, 210))
dr.arc((10, 8, s - 10, s - 6), 20, 160, fill=(40, 70, 120, 110), width=2)
im.filter(ImageFilter.GaussianBlur(0.6)).save(os.path.join(out, "drop.png"))

s = 32
im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
px = im.load()
for y in range(s):
    for x in range(s):
        r = math.hypot(x - s / 2 + 0.5, y - s / 2 + 0.5) / (s / 2)
        px[x, y] = (255, 255, 255, int(255 * max(0, 1 - r) ** 1.4))
im.save(os.path.join(out, "flake.png"))

w, h = 1024, 384
im = Image.new("RGBA", (w, h), (255, 255, 255, 0))
dr = ImageDraw.Draw(im)
random.seed(7)
for _ in range(46):
    r = random.randint(60, 140)
    cx = random.randint(r + 40, w - r - 40)
    cy = random.randint(int(r * 0.6) + 60, h - int(r * 0.6) - 60)
    dr.ellipse((cx - r, cy - r * 0.6, cx + r, cy + r * 0.6), fill=(255, 255, 255, 40))
im = im.filter(ImageFilter.GaussianBlur(34))
px = im.load()
for y in range(h):
    for x in range(w):
        fx = min(x, w - 1 - x) / (w * 0.18)
        fy = min(y, h - 1 - y) / (h * 0.3)
        k = max(0.0, min(1.0, fx)) * max(0.0, min(1.0, fy))
        r, g, b, a = px[x, y]
        px[x, y] = (255, 255, 255, int(a * k))
im.save(os.path.join(out, "fog.png"))
print("ok")
