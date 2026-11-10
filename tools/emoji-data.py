#!/usr/bin/env python3

import os
import sys
import json
import emoji

out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "dotfiles", ".config", "quickshell", "aero-phone", "emoji.json")
emoji.config.load_language("es")

PEOPLE = ("hand", "person", "man", "woman", "people", "family", "boy", "girl", "baby", "kiss", "couple", "finger", "thumbs",
          "fist", "palm", "clap", "pray", "muscle", "leg", "foot", "ear", "nose", "eyes", "eye", "tongue", "mouth", "tooth",
          "brain", "lungs", "heart_hands", "selfie", "nail_polish", "writing", "prince", "princess", "pregnant", "breast",
          "detective", "guard", "construction_worker", "superhero", "supervillain", "mage", "fairy", "vampire", "merperson",
          "elf", "genie", "zombie", "troll", "santa", "ninja", "older", "child", "adult", "bust", "speaking_head", "footprints")
RANGES = [
    ("naturaleza", [(0x1F300, 0x1F344), (0x1F400, 0x1F43F), (0x1F980, 0x1F9AE), (0x1FAB0, 0x1FABF), (0x1F490, 0x1F490), (0x2600, 0x2604), (0x2614, 0x2614), (0x26A1, 0x26A1), (0x2744, 0x2744), (0x26C4, 0x26C5), (0x1F54A, 0x1F54A), (0x1F577, 0x1F578), (0x1FA70, 0x1FA70)]),
    ("comida", [(0x1F345, 0x1F37F), (0x1F950, 0x1F96F), (0x1F9C0, 0x1F9CB), (0x1FAD0, 0x1FADF), (0x2615, 0x2615)]),
    ("actividades", [(0x1F380, 0x1F3CF), (0x1F93A, 0x1F94F), (0x26BD, 0x26BE), (0x26F3, 0x26F3), (0x26F8, 0x26F8), (0x1F3AE, 0x1F3B3), (0x1FA80, 0x1FA8F), (0x1F9E9, 0x1F9E9), (0x265F, 0x265F)]),
    ("viajes", [(0x1F680, 0x1F6FF), (0x1F3D4, 0x1F3F0), (0x1F5FA, 0x1F5FF), (0x26E9, 0x26FD), (0x2708, 0x2708), (0x1F30D, 0x1F310)]),
    ("objetos", [(0x1F4A1, 0x1F4FF), (0x1F500, 0x1F5F9), (0x1F9E0, 0x1F9FF), (0x1FA90, 0x1FAAF), (0x231A, 0x231B), (0x2328, 0x2328), (0x23F0, 0x23F3), (0x260E, 0x260E), (0x2702, 0x2702), (0x2709, 0x2709), (0x270F, 0x2712), (0x1F3F7, 0x1F3F7)]),
]


def category(e, en):
    if len(e) >= 2 and 0x1F1E6 <= ord(e[0]) <= 0x1F1FF:
        return "banderas"
    if ord(e[0]) == 0x1F3F4 or ord(e[0]) == 0x1F3F3:
        return "banderas"
    if "face" in en and "clock" not in en:
        return "caras"
    if any(w in en for w in PEOPLE):
        return "gente"
    cp = ord(e[0])
    for name, ranges in RANGES:
        for a, b in ranges:
            if a <= cp <= b:
                return name
    return "simbolos"


rows = []
for e, d in emoji.EMOJI_DATA.items():
    if d.get("status") != emoji.STATUS["fully_qualified"]:
        continue
    if any(0x1F3FB <= ord(c) <= 0x1F3FF for c in e):
        continue
    en = d["en"].strip(":").replace("_", " ").lower()
    es = d.get("es", "").strip(":").replace("_", " ").lower()
    rows.append({"e": e, "n": en, "s": es, "c": category(e, d["en"].lower())})
order = ["caras", "gente", "naturaleza", "comida", "actividades", "viajes", "objetos", "simbolos", "banderas"]
rows.sort(key=lambda r: (order.index(r["c"]), [ord(c) for c in r["e"]]))
with open(out, "w", encoding="utf-8") as f:
    json.dump(rows, f, ensure_ascii=False, separators=(",", ":"))
print(len(rows))
