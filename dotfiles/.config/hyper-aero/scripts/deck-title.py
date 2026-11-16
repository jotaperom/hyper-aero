#!/usr/bin/env python3

import base64
import io
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HOME = os.path.expanduser("~")
FONT = os.path.join(HOME, ".config", "hyper-aero", "fonts", "TenorSans-Regular.ttf")
TEXT = "HYPER·AERO"
CELL = 0.465


def rgb(s, default):
    try:
        parts = [int(x) for x in s.split(";")]
    except ValueError:
        return default
    if len(parts) != 3 or any(v < 0 or v > 255 for v in parts):
        return default
    return tuple(parts)


def target(night, accent):
    name = "deck-title3-%s-%d-%d-%d.b64" % ("night" if night else "day", accent[0], accent[1], accent[2])
    return os.path.join(HOME, ".cache", "hyper-aero", name)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def render(night, accent):
    size = 120
    font = ImageFont.truetype(FONT, size)
    track = int(size * 0.06)
    widths = [font.getlength(c) for c in TEXT]
    width = int(sum(widths) + track * (len(TEXT) - 1))
    asc, desc = font.getmetrics()
    pad = 64
    W, H = width + pad * 2, asc + desc + pad * 2
    mask = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(mask)
    x = pad
    for c, w in zip(TEXT, widths):
        d.text((x, pad), c, font=font, fill=255)
        x += w + track
    box = mask.getbbox()
    if night:
        top, bottom, glow, glow_a = (246, 251, 255), mix((246, 251, 255), accent, 0.35), accent, 0.85
    else:
        top, bottom, glow, glow_a = mix(accent, (255, 255, 255), 0.15), accent, mix(accent, (255, 255, 255), 0.55), 0.6
    fill = Image.new("RGB", (W, H))
    fd = ImageDraw.Draw(fill)
    y0, y1 = box[1], box[3]
    for y in range(H):
        t = min(1.0, max(0.0, (y - y0) / max(1, y1 - y0)))
        fd.line([(0, y), (W, y)], fill=mix(top, bottom, t))
    out = Image.new("RGBA", (W, H), glow + (0,))
    halo = mask.filter(ImageFilter.GaussianBlur(14)).point(lambda a: int(min(255, a * glow_a * 1.6)))
    soft = mask.filter(ImageFilter.GaussianBlur(4)).point(lambda a: int(a * glow_a))
    for m in (halo, soft):
        layer = Image.new("RGBA", (W, H), glow + (0,))
        layer.putalpha(m)
        out.alpha_composite(layer)
    text = fill.convert("RGBA")
    text.putalpha(mask)
    out.alpha_composite(text)
    bb = out.getbbox() or (0, 0, W, H)
    top, bottom = max(0, bb[1] - 4), min(H, bb[3] + 4)
    left = max(0, box[0] - round((bottom - top) * CELL / 2))
    img = out.crop((left, top, min(W, bb[2] + 4), bottom))
    edge = Image.new("L", img.size, 255)
    ed = ImageDraw.Draw(edge)
    for x in range(min(12, img.width)):
        ed.line([(x, 0), (x, img.height)], fill=int(255 * x / 12))
    alpha = img.getchannel("A")
    img.putalpha(ImageChops.multiply(alpha, edge))
    return img


def main(argv):
    if len(argv) < 2:
        print("uso: deck-title.py day|night R;G;B")
        return 1
    night = argv[0] == "night"
    accent = rgb(argv[1], (111, 211, 255) if night else (20, 70, 194))
    dest = target(night, accent)
    img = render(night, accent)
    buf = io.BytesIO()
    img.save(buf, "PNG", optimize=True)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = dest + ".tmp"
    with open(tmp, "w", encoding="ascii") as f:
        f.write("%d %d\n" % img.size)
        f.write(base64.b64encode(buf.getvalue()).decode("ascii"))
    os.replace(tmp, dest)
    print(dest)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
