#!/usr/bin/env python3

import os
import re
import sys
import json
import colorsys

ACCENTS = ["blue", "red", "green", "black"]

NAMES = {"blue": "AZUL", "red": "ROJO", "green": "VERDE", "black": "NEGRO"}

PARAMS = {
    "red": {"hue": 350, "spread": 0.85, "sat": 1.0},
    "green": {"hue": 162, "spread": 0.8, "sat": 0.72},
    "black": {"mono": True, "glow": 188},
}

CUSTOM_RE = re.compile(r"^c-(\d{1,3})-(\d{1,3})$")


def params(accent):
    if accent in PARAMS:
        return PARAMS[accent]
    m = CUSTOM_RE.match(accent or "")
    if not m:
        return None
    hue = max(0, min(359, int(m.group(1))))
    sat = max(0, min(140, int(m.group(2)))) / 100.0
    if sat < 0.12:
        return {"mono": True, "glow": hue}
    return {"hue": hue, "spread": 0.85, "sat": sat}


def valid(accent):
    return accent == "blue" or params(accent) is not None


HEX_RE = re.compile(r"(?<![0-9A-Za-z_&])#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{4}|[0-9a-fA-F]{3})(?![0-9A-Za-z_-])")
RGB_RE = re.compile(r"(rgba?\(\s*)(\d{1,3})(\s*,\s*)(\d{1,3})(\s*,\s*)(\d{1,3})")
HYPR_RE = re.compile(r"\b(rgba?)\(([0-9a-fA-F]{6})([0-9a-fA-F]{2})?\)")
ANSI_RE = re.compile(r"([34]8;2;)(\d{1,3});(\d{1,3});(\d{1,3})")


def tint(r, g, b, accent):
    p = params(accent)
    if not p:
        return r, g, b
    h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
    deg = h * 360.0
    if s < 0.035 or not (180.0 <= deg <= 246.0):
        return r, g, b
    if p.get("mono"):
        if s > 0.88 and l > 0.55:
            deg, s = p["glow"], s * 0.85
        else:
            s = s * 0.07
    else:
        deg = (p["hue"] + (deg - 215.0) * p["spread"]) % 360.0
        s = s * p["sat"]
        if l > 0.88 or l < 0.12:
            s *= 0.6
    s = min(1.0, max(0.0, s))
    target = luminance(r / 255.0, g / 255.0, b / 255.0)
    lo, hi = 0.0, 1.0
    for _ in range(22):
        mid = (lo + hi) / 2
        if luminance(*colorsys.hls_to_rgb(deg / 360.0, mid, s)) < target:
            lo = mid
        else:
            hi = mid
    nr, ng, nb = colorsys.hls_to_rgb(deg / 360.0, (lo + hi) / 2, s)
    return int(round(nr * 255)), int(round(ng * 255)), int(round(nb * 255))


def luminance(r, g, b):
    def ch(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def tint_hex6(hx, accent):
    r, g, b = int(hx[0:2], 16), int(hx[2:4], 16), int(hx[4:6], 16)
    r, g, b = tint(r, g, b, accent)
    out = f"{r:02x}{g:02x}{b:02x}"
    return out.upper() if hx.isupper() else out


def _hex(m, accent):
    v = m.group(1)
    if len(v) in (3, 4):
        full = "".join(c * 2 for c in v[:3])
        new = tint_hex6(full, accent)
        if new.lower() == full.lower():
            return m.group(0)
        return "#" + new + ("".join(c * 2 for c in v[3:]) if len(v) == 4 else "")
    return "#" + tint_hex6(v[:6], accent) + v[6:]


def _rgb(m, accent):
    r, g, b = (min(255, int(m.group(i))) for i in (2, 4, 6))
    r, g, b = tint(r, g, b, accent)
    return f"{m.group(1)}{r}{m.group(3)}{g}{m.group(5)}{b}"


def _hypr(m, accent):
    return f"{m.group(1)}({tint_hex6(m.group(2), accent)}{m.group(3) or ''})"


def _ansi(m, accent):
    r, g, b = tint(int(m.group(2)), int(m.group(3)), int(m.group(4)), accent)
    return f"{m.group(1)}{r};{g};{b}"


def recolor(text, accent):
    if not params(accent):
        return text
    text = HYPR_RE.sub(lambda m: _hypr(m, accent), text)
    text = RGB_RE.sub(lambda m: _rgb(m, accent), text)
    text = HEX_RE.sub(lambda m: _hex(m, accent), text)
    text = ANSI_RE.sub(lambda m: _ansi(m, accent), text)
    return text


KITTY_KEYS = ("foreground", "background", "selection_", "cursor", "url_color", "active_tab_", "inactive_tab_",
              "tab_bar_", "active_border_color", "inactive_border_color", "bell_border_color", "mark1", "mark2",
              "mark3", "visual_bell_color")


def recolor_kitty(text, accent):
    out = []
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("include") or s.startswith("globinclude"):
            continue
        if any(s.startswith(k) for k in KITTY_KEYS):
            out.append(recolor(line, accent))
    return "\n".join(out) + "\n"


def recolor_ini(text, accent):
    if not params(accent):
        return text
    return re.sub(r"(=\s*)([0-9a-fA-F]{6})\b", lambda m: m.group(1) + tint_hex6(m.group(2), accent), text)


def read(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except (OSError, UnicodeDecodeError):
        return ""


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
    os.replace(tmp, path)


BANNER = {
    "day": {"cobalt": (20, 70, 194), "blue": (30, 111, 217), "graph": (90, 98, 112), "rule": (154, 163, 174)},
    "night": {"cobalt": (111, 211, 255), "blue": (61, 155, 233), "graph": (139, 151, 171), "rule": (74, 90, 120)},
}


IMPORT_RE = re.compile(r"""^\s*@import\s+(.+?);?\s*$""")


def inline_scss(path, seen=None):
    seen = seen if seen is not None else set()
    real = os.path.realpath(path)
    if real in seen or not os.path.isfile(path):
        return ""
    seen.add(real)
    base = os.path.dirname(path)
    out = []
    for line in read(path).splitlines():
        m = IMPORT_RE.match(line)
        if not m:
            out.append(line)
            continue
        names = re.findall(r"""["']([^"']+)["']""", m.group(1))
        for name in names:
            if "night-deck" in name or name.startswith("http") or name.startswith("url"):
                continue
            stem = os.path.join(base, name)
            cands = [stem, stem + ".scss", os.path.join(os.path.dirname(stem), "_" + os.path.basename(stem) + ".scss"),
                     stem + ".css"]
            for c in cands:
                if os.path.isfile(c):
                    out.append(inline_scss(c, seen))
                    break
    return "\n".join(out)


RASI_IMPORT = re.compile(r"""^\s*@(import|theme)\s+["']?([^"'\s]+)["']?""")


def inline_rasi(path, seen=None):
    seen = seen if seen is not None else set()
    real = os.path.realpath(path)
    if real in seen or not os.path.isfile(path):
        return ""
    seen.add(real)
    base = os.path.dirname(path)
    out = []
    for line in read(path).splitlines():
        m = RASI_IMPORT.match(line)
        if not m:
            out.append(line)
            continue
        name = os.path.expanduser(m.group(2))
        if "theme/current" in name or "hyper-aero/theme" in name:
            continue
        cands = [name, name + ".rasi", os.path.join(base, name), os.path.join(base, name + ".rasi"),
                 os.path.join(os.path.expanduser("~/.config/rofi/themes"), name + ".rasi"),
                 os.path.join("/usr/share/rofi/themes", name + ".rasi")]
        for c in cands:
            if os.path.isfile(c):
                out.append(inline_rasi(c, seen))
                break
    return "\n".join(out)


def build(accent, mode, home=None):
    home = home or os.path.expanduser("~")
    cfg = os.path.join(home, ".config")
    theme = os.path.join(cfg, "hyper-aero", "theme")
    layer = os.path.join(theme, mode)
    dest = os.path.join(theme, f"{accent}-{mode}")
    os.makedirs(dest, exist_ok=True)

    def overlay(name):
        return read(os.path.join(layer, name))

    def css_pair(base_file, name):
        text = read(base_file).rstrip() + "\n\n" + overlay(name)
        write(os.path.join(dest, name), recolor(text, accent))

    css_pair(os.path.join(cfg, "waybar", "aerobar-base.css"), "waybar.css")
    css_pair(os.path.join(cfg, "swaync", "aero-base.css"), "swaync.css")
    write(os.path.join(dest, "gtk3.css"), recolor(overlay("gtk3.css"), accent))

    gtk4 = os.path.join(theme, "base", "gtk4.css")
    if os.path.isfile(gtk4):
        write(os.path.join(dest, "gtk4.css"), recolor(read(gtk4), accent))

    eww_root = os.path.join(cfg, "eww", "eww.scss")
    eww = inline_scss(eww_root) + "\n\n" + overlay("eww.scss")
    write(os.path.join(dest, "eww.scss"), recolor(eww, accent))

    rofi_root = os.path.join(cfg, "rofi", "config.rasi")
    rasi = inline_rasi(rofi_root)
    rasi = re.sub(r"(?s)configuration\s*\{.*?\n\}", "", rasi)
    write(os.path.join(dest, "rofi.rasi"), recolor(rasi.rstrip() + "\n\n" + overlay("rofi.rasi"), accent))

    kitty = recolor_kitty(read(os.path.join(cfg, "kitty", "kitty.conf")), accent)
    kitty += recolor_kitty(overlay("kitty.conf"), accent)
    extra = []
    for l in overlay("kitty.conf").splitlines():
        m = re.match(r"\s*color(\d+)\s", l)
        if m:
            extra.append(recolor(l, accent) if m.group(1) in ("0", "7", "8", "15") else l)
    write(os.path.join(dest, "kitty.conf"), kitty + ("\n".join(extra) + "\n" if extra else ""))

    star = overlay("starship.toml") if mode == "night" else read(os.path.join(cfg, "starship.toml"))
    if star:
        write(os.path.join(dest, "starship.toml"), recolor(star, accent))

    lock = overlay("hyprlock.conf") if mode == "night" else read(os.path.join(cfg, "hypr", "hyprlock.conf"))
    if lock:
        write(os.path.join(dest, "hyprlock.conf"), recolor(lock, accent))

    for name in ("vesktop.css", "spotify-user.css"):
        if overlay(name):
            write(os.path.join(dest, name), recolor(overlay(name), accent))
    if overlay("spotify-color.ini"):
        write(os.path.join(dest, "spotify-color.ini"),
              recolor_ini(overlay("spotify-color.ini"), accent).replace("[night-deck]", f"[night-deck-{accent}]"))

    jsonc = None
    for n in ("config.jsonc", "config"):
        p = os.path.join(cfg, "waybar", n)
        if os.path.isfile(p):
            jsonc = p
            break
    if jsonc:
        src = os.path.join(layer, "waybar.jsonc") if mode == "night" and os.path.isfile(
            os.path.join(layer, "waybar.jsonc")) else jsonc
        write(os.path.join(dest, "waybar.jsonc"), recolor(read(src), accent))

    term = BANNER[mode]
    lines = []
    for key, rgb in term.items():
        r, g, b = tint(*rgb, accent)
        lines.append(f"{key}=$'\\e[38;2;{r};{g};{b}m'")
    write(os.path.join(dest, "banner.env"), "\n".join(lines) + "\n")

    write(os.path.join(dest, "accent"), accent + "\n")
    return dest


def current_accent(home=None):
    home = home or os.path.expanduser("~")
    v = read(os.path.join(home, ".config", "hyper-aero", "theme", "accent")).strip()
    return v if valid(v) else "blue"


def main(argv):
    if len(argv) >= 2 and argv[0] == "hex":
        accent = argv[1]
        for v in argv[2:]:
            print(v, "->", recolor(v, accent))
        return 0
    if len(argv) == 3 and argv[0] == "build":
        print(build(argv[1], argv[2]))
        return 0
    if len(argv) >= 2 and argv[0] == "text":
        sys.stdout.write(recolor(sys.stdin.read(), argv[1]))
        return 0
    print("uso: aero_tint.py build ACCENT MODE | hex ACCENT COLOR... | text ACCENT < archivo")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
