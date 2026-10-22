#!/usr/bin/env python3

import os
import re
import sys
import json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EN = os.path.join(ROOT, "dotfiles", ".config", "hyper-aero", "i18n", "en.json")

STR = r'"((?:[^"\\]|\\.)*)"'
PATTERNS = {
    (".qml", ".js"): [re.compile(r'L\.[tf]\(' + STR)],
    (".py", ""): [re.compile(r'_t\(' + STR)],
    (".sh",): [re.compile(r'\$\(tf? ' + STR), re.compile(r"\$\(tf? '([^']*)'"), re.compile(r'\bt ' + STR + r'\s*$', re.M)],
}


def unescape(s, kind):
    if kind == "sh":
        return s.replace('\\"', '"').replace("\\$", "$").replace("\\`", "`")
    return json.loads('"' + s + '"')


def kind_of(path):
    name = os.path.basename(path)
    if name.endswith((".qml", ".js")):
        return "qml"
    if name.endswith(".sh"):
        return "sh"
    if name.endswith(".py"):
        return "py"
    try:
        with open(path, encoding="utf-8") as f:
            head = f.readline()
    except (OSError, UnicodeDecodeError):
        return None
    if "python" in head:
        return "py"
    if "bash" in head or head.startswith("#!/bin/sh"):
        return "sh"
    return None


def collect():
    used = {}
    for base, _, files in os.walk(ROOT):
        if "/.git" in base or "/build" in base:
            continue
        for name in files:
            if name == "Lang.js":
                continue
            path = os.path.join(base, name)
            kind = kind_of(path)
            if not kind:
                continue
            pats = {"qml": PATTERNS[(".qml", ".js")], "py": PATTERNS[(".py", "")], "sh": PATTERNS[(".sh",)]}[kind]
            try:
                text = open(path, encoding="utf-8").read()
            except UnicodeDecodeError:
                continue
            for p in pats:
                for m in p.finditer(text):
                    key = unescape(m.group(1), kind)
                    if key.startswith("$"):
                        continue
                    used.setdefault(key, os.path.relpath(path, ROOT))
    return used


def main():
    table = json.load(open(EN, encoding="utf-8"))
    used = collect()
    missing = {k: v for k, v in used.items() if k not in table}
    unused = [k for k in table if k not in used]
    for k, where in sorted(missing.items(), key=lambda x: x[1]):
        print(f"MISSING  {where}: {k}")
    for k in sorted(unused):
        print(f"UNUSED   {k}")
    print(f"{len(used)} used · {len(table)} translated · {len(missing)} missing · {len(unused)} unused")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
