import os
import json

AERO = os.path.join(os.path.expanduser("~"), ".config", "hyper-aero")
_table = None


def lang():
    try:
        with open(os.path.join(AERO, "lang"), encoding="utf-8") as f:
            v = f.read().strip()
    except OSError:
        v = ""
    return v if v in ("es", "en") else "es"


def table():
    global _table
    if _table is None:
        _table = {}
        if lang() == "en":
            try:
                with open(os.path.join(AERO, "i18n", "en.json"), encoding="utf-8") as f:
                    _table = json.load(f)
            except (OSError, ValueError):
                _table = {}
    return _table


def t(s):
    return table().get(s, s)
