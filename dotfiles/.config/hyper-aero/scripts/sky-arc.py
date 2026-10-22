#!/usr/bin/env python3

import os
import sys
import json
import math
import time
import glob
import random
import datetime

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
try:
    import aero_tint
except ImportError:
    aero_tint = None

HOME = os.path.expanduser("~")
THEME = os.path.join(HOME, ".config", "hyper-aero", "theme")
RUN = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
OUT = os.path.join(RUN, "aero-sky")
W, H = 338, 120
SS = 4
SYNODIC = 29.530588853
NEW_MOON = datetime.datetime(2000, 1, 6, 18, 14, tzinfo=datetime.timezone.utc).timestamp()

PALETTE = {
    "day": {
        "track": (90, 98, 112, 95), "trail": (20, 70, 194, 255), "glow": (61, 155, 233, 120),
        "horizon": (11, 13, 18, 110), "tick": (90, 98, 112, 150), "star": (20, 70, 194, 110),
        "moon_lit": (214, 226, 244, 255), "moon_dark": (90, 98, 112, 60), "moon_rim": (20, 70, 194, 200),
    },
    "night": {
        "track": (139, 151, 171, 85), "trail": (111, 211, 255, 255), "glow": (111, 211, 255, 130),
        "horizon": (230, 238, 251, 95), "tick": (139, 151, 171, 160), "star": (230, 238, 251, 170),
        "moon_lit": (236, 242, 252, 255), "moon_dark": (139, 151, 171, 45), "moon_rim": (111, 211, 255, 200),
    },
}

MOON_NAMES = ["NEW MOON", "WAXING CRESCENT", "FIRST QUARTER", "WAXING GIBBOUS",
              "FULL MOON", "WANING GIBBOUS", "LAST QUARTER", "WANING CRESCENT"]


def accent():
    if not aero_tint:
        return "blue"
    return aero_tint.current_accent()


def tc(rgb, acc):
    if acc == "blue" or not aero_tint:
        return rgb
    return tuple(aero_tint.tint(rgb[0], rgb[1], rgb[2], acc)) + tuple(rgb[3:])


def config():
    cfg = {"lat": 0.0, "lon": round(-time.timezone / 3600.0 * 15.0, 2)}
    try:
        with open(os.path.join(THEME, "config.json"), encoding="utf-8") as f:
            cfg.update(json.load(f))
    except (OSError, ValueError):
        pass
    return cfg


def theme_mode():
    try:
        with open(os.path.join(THEME, "mode"), encoding="utf-8") as f:
            return "night" if f.read().strip() == "night" else "day"
    except OSError:
        return "day"


def sun_times(day, lat, lon):
    n = day.timetuple().tm_yday
    g = 2 * math.pi / 365 * (n - 1)
    eqtime = 229.18 * (0.000075 + 0.001868 * math.cos(g) - 0.032077 * math.sin(g)
                       - 0.014615 * math.cos(2 * g) - 0.040849 * math.sin(2 * g))
    decl = (0.006918 - 0.399912 * math.cos(g) + 0.070257 * math.sin(g) - 0.006758 * math.cos(2 * g)
            + 0.000907 * math.sin(2 * g) - 0.002697 * math.cos(3 * g) + 0.00148 * math.sin(3 * g))
    phi = math.radians(lat)
    x = math.cos(math.radians(90.833)) / (math.cos(phi) * math.cos(decl)) - math.tan(phi) * math.tan(decl)
    ha = math.degrees(math.acos(max(-1.0, min(1.0, x))))
    midnight = datetime.datetime(day.year, day.month, day.day, tzinfo=datetime.timezone.utc).timestamp()
    return midnight + (720 - 4 * (lon + ha) - eqtime) * 60, midnight + (720 - 4 * (lon - ha) - eqtime) * 60


def span(seconds):
    m = max(0, int(round(seconds / 60)))
    return f"{m // 60}h {m % 60:02d}m"


def hm(ts):
    return datetime.datetime.fromtimestamp(ts).strftime("%H:%M")


def state(now, cfg):
    today = datetime.datetime.fromtimestamp(now).date()
    one = datetime.timedelta(days=1)
    sr, ss = sun_times(today, cfg["lat"], cfg["lon"])
    if sr <= now < ss:
        return {"night": False, "start": sr, "end": ss, "frac": (now - sr) / (ss - sr)}
    if now >= ss:
        nsr, _ = sun_times(today + one, cfg["lat"], cfg["lon"])
        return {"night": True, "start": ss, "end": nsr, "frac": (now - ss) / (nsr - ss)}
    _, pss = sun_times(today - one, cfg["lat"], cfg["lon"])
    return {"night": True, "start": pss, "end": sr, "frac": (now - pss) / (sr - pss)}


def moon(now):
    age = ((now - NEW_MOON) / 86400) % SYNODIC
    phase = 2 * math.pi * age / SYNODIC
    lit = (1 - math.cos(phase)) / 2
    name = MOON_NAMES[int((age / SYNODIC) * 8 + 0.5) % 8]
    return phase, lit, name


def arc_point(t, cx, hy, rx, ry):
    a = math.pi * (1 - t)
    return cx + rx * math.cos(a), hy - ry * math.sin(a)


def draw_moon(layer, cx, cy, r, phase, pal):
    d = ImageDraw.Draw(layer)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=pal["moon_dark"])
    k = math.cos(phase)
    waxing = phase < math.pi
    steps = 64
    limb, term = [], []
    for i in range(steps + 1):
        v = -1 + 2 * i / steps
        w = math.sqrt(max(0.0, 1 - v * v))
        if waxing:
            limb.append((cx + r * w, cy + r * v))
            term.append((cx + r * k * w, cy + r * v))
        else:
            limb.append((cx - r * w, cy + r * v))
            term.append((cx - r * k * w, cy + r * v))
    d.polygon(limb + term[::-1], fill=pal["moon_lit"])
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=pal["moon_rim"], width=max(1, SS // 2))


def draw_sun(layer, cx, cy, r, acc="blue"):
    orb = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    stops = [(1.00, (20, 70, 194)), (0.78, (30, 111, 217)), (0.55, (61, 155, 233)), (0.30, (140, 198, 245)),
             (0.12, (235, 246, 255))]
    d = ImageDraw.Draw(orb)
    for frac, col in stops:
        col = tc(col, acc)
        rr = r * frac
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=col + (255,))
    orb = orb.filter(ImageFilter.GaussianBlur(r * 0.18))
    mask = Image.new("L", layer.size, 0)
    ImageDraw.Draw(mask).ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
    layer.paste(orb, (0, 0), mask)
    d = ImageDraw.Draw(layer)
    hl = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    ImageDraw.Draw(hl).ellipse((cx - r * 0.62, cy - r * 0.86, cx + r * 0.62, cy - r * 0.08), fill=(255, 255, 255, 170))
    hl = hl.filter(ImageFilter.GaussianBlur(r * 0.08))
    layer.alpha_composite(hl)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(11, 13, 18, 150), width=max(1, SS // 2))


def render(now, mode, st, acc="blue"):
    pal = {k: tc(v, acc) for k, v in PALETTE[mode].items()}
    w, h = W * SS, H * SS
    cx, hy = w / 2, h - 22 * SS
    rx, ry = w / 2 - 22 * SS, h - 36 * SS
    base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(base)
    g = ImageDraw.Draw(glow)

    if st["night"]:
        rnd = random.Random(int(st["start"]))
        for _ in range(26):
            sx, sy = rnd.uniform(0.04, 0.96) * w, rnd.uniform(0.05, 0.62) * h
            sr = rnd.choice([1.0, 1.0, 1.4, 1.8]) * SS * 0.55
            a = int(pal["star"][3] * rnd.uniform(0.4, 1.0))
            d.ellipse((sx - sr, sy - sr, sx + sr, sy + sr), fill=pal["star"][:3] + (a,))

    n = 140
    pts = [arc_point(i / n, cx, hy, rx, ry) for i in range(n + 1)]
    for i in range(0, n, 2):
        d.line([pts[i], pts[i + 1]], fill=pal["track"], width=int(1.2 * SS))
    cut = max(1, int(round(st["frac"] * n)))
    trail = pts[:cut + 1]
    if len(trail) > 1:
        g.line(trail, fill=pal["glow"], width=int(7 * SS), joint="curve")
        d.line(trail, fill=pal["trail"], width=int(2.2 * SS), joint="curve")

    d.line([(10 * SS, hy), (w - 10 * SS, hy)], fill=pal["horizon"], width=int(1 * SS))
    for t in (0.0, 1.0):
        x, y = arc_point(t, cx, hy, rx, ry)
        s = 4 * SS
        d.polygon([(x, y - s), (x + s, y), (x, y + s), (x - s, y)], fill=pal["trail"])
    for i in range(1, 12):
        x = 10 * SS + (w - 20 * SS) * i / 12
        d.line([(x, hy), (x, hy + 4 * SS)], fill=pal["tick"], width=max(1, SS // 2))

    ox, oy = arc_point(min(max(st["frac"], 0.0), 1.0), cx, hy, rx, ry)
    halo = 26 * SS
    g.ellipse((ox - halo, oy - halo, ox + halo, oy + halo), fill=pal["glow"][:3] + (90,))
    glow = glow.filter(ImageFilter.GaussianBlur(6 * SS))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.alpha_composite(glow)
    out.alpha_composite(base)
    r = 10 * SS
    if st["night"]:
        phase, _, _ = moon(now)
        draw_moon(out, ox, oy, r, phase, pal)
    else:
        draw_sun(out, ox, oy, r, acc)
    return out


def emit(now, mode, cfg):
    st = state(now, cfg)
    acc = accent()
    img = render(now, mode, st, acc)
    os.makedirs(OUT, exist_ok=True)
    stamp = f"{int(now)}-{mode}-{acc}"
    p2 = os.path.join(OUT, f"sky-{stamp}@2x.png")
    p1 = os.path.join(OUT, f"sky-{stamp}.png")
    for path, size in ((p2, (W * 2, H * 2)), (p1, (W, H))):
        tmp = os.path.join(OUT, ".tmp-" + os.path.basename(path))
        img.resize(size, Image.LANCZOS).save(tmp, format="PNG")
        os.replace(tmp, path)
    for old in sorted(glob.glob(os.path.join(OUT, "sky-*.png")))[:-4]:
        try:
            os.remove(old)
        except OSError:
            pass
    length = st["end"] - st["start"]
    left = now - st["end"]
    if st["night"]:
        _, lit, name = moon(now)
        data = {"tag": f"NIGHT {span(length)}", "left": f"▼ {hm(st['start'])}", "right": f"{hm(st['end'])} ▲",
                "next": f"SUNRISE IN {span(-left)}", "moon": f"{name}  ·  {round(lit * 100)}% LIT"}
    else:
        data = {"tag": f"DAYLIGHT {span(length)}", "left": f"▲ {hm(st['start'])}", "right": f"{hm(st['end'])} ▼",
                "next": f"SUNSET IN {span(-left)}", "moon": ""}
    data.update({"img1": p1, "img2": p2, "night": st["night"]})
    print(json.dumps(data, ensure_ascii=False), flush=True)


def main():
    if sys.argv[1:2] == ["once"]:
        emit(time.time(), sys.argv[2] if len(sys.argv) > 2 else theme_mode(), config())
        return 0
    last = None
    while True:
        now = time.time()
        key = (int(now // 60), theme_mode(), accent())
        if key != last:
            try:
                emit(now, key[1], config())
            except Exception as e:
                print(json.dumps({"tag": "SKY OFFLINE", "left": "", "right": "", "next": str(e)[:40], "moon": "",
                                  "img1": "", "img2": "", "night": False}), flush=True)
            last = key
        time.sleep(3)


if __name__ == "__main__":
    sys.exit(main())
