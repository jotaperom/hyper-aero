#!/usr/bin/env bash

cd "$(dirname "$0")/.."
fail=0
step() { printf '\n◢ %s\n' "$1"; }
oops() { echo "  ✗ $1"; fail=1; }

step "bash"
while IFS= read -r f; do
    bash -n "$f" 2>/dev/null || oops "$f"
done < <(grep -rlE '^#!/usr/bin/env bash|^#!/bin/bash' install.sh uninstall.sh tools dotfiles system 2>/dev/null)

step "python"
while IFS= read -r f; do
    python3 -m py_compile "$f" 2>/dev/null || oops "$f"
done < <(grep -rlE '^#!/usr/bin/env python3' tools dotfiles 2>/dev/null; find tools dotfiles -name '*.py')
find . -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null

step "lua"
if command -v luac >/dev/null || command -v luac5.4 >/dev/null; then
    LUAC=$(command -v luac || command -v luac5.4)
    while IFS= read -r f; do
        "$LUAC" -p "$f" 2>/dev/null || oops "$f"
    done < <(find dotfiles -name '*.lua')
    rm -f luac.out
elif python3 -c "import lupa" 2>/dev/null; then
    while IFS= read -r f; do
        python3 - "$f" <<'PY' || oops "$f"
import sys
from lupa import LuaRuntime
L = LuaRuntime()
ok, err = L.eval("function(s) local f, e = load(s) return f ~= nil, e end")(open(sys.argv[1], encoding="utf-8").read())
if not ok:
    print("  " + str(err))
    sys.exit(1)
PY
    done < <(find dotfiles -name '*.lua')
else
    echo "  (luac no está instalado, salto)"
fi

step "json"
while IFS= read -r f; do
    python3 - "$f" <<'PY' || oops "$f"
import json, re, sys
t = open(sys.argv[1], encoding="utf-8").read()
if sys.argv[1].endswith(".jsonc"):
    t = re.sub(r"^\s*//.*$", "", t, flags=re.M)
t = re.sub(r"__[A-Z_]+__", "0", t)
json.loads(t)
PY
done < <(find dotfiles i18n -name '*.json' -o -name '*.jsonc' 2>/dev/null)

step "qml"
QMLLINT=$(command -v qmllint || command -v qmllint6 || python3 -c "import PySide6, os; print(os.path.join(os.path.dirname(PySide6.__file__), 'qmllint'))" 2>/dev/null)
if [ -n "$QMLLINT" ] && [ -x "$QMLLINT" ]; then
    while IFS= read -r f; do
        if LC_ALL=C.UTF-8 "$QMLLINT" "$f" 2>&1 | grep -q '\[syntax\]'; then
            oops "$f"
        fi
    done < <(find dotfiles -name '*.qml')
else
    echo "  (qmllint no está disponible, salto)"
fi

step "i18n"
python3 tools/i18n-check.py | tail -n 1
python3 tools/i18n-check.py | grep -q ' 0 missing' || oops "faltan traducciones"

step "lua tests"
if python3 -c "import lupa" 2>/dev/null; then
    python3 tools/tests/deskmove.py dotfiles/.config/hypr/aero-deskmove.lua | tail -n 1 | grep -q "ALL OK" || oops "aero-deskmove"
    python3 tools/tests/fx.py dotfiles/.config/hypr/aero-fx.lua | tail -n 1 | grep -q "ALL OK" || oops "aero-fx"
else
    echo "  (falta lupa: pip install lupa)"
fi

echo
if [ "$fail" = 0 ]; then echo "◢ todo bien"; else echo "◢ hay errores"; fi
exit "$fail"
