#!/usr/bin/env python3

import os
import re
import sys
import json
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor

MAC_RE = re.compile(r"^([0-9A-F]{2}[:-]){5}[0-9A-F]{2}$", re.I)


def run(args, timeout=20, stdin=None):
    if not shutil.which(args[0]):
        return 127, ""
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=timeout, input=stdin)
        return r.returncode, (r.stdout or "") + (r.stderr or "")
    except subprocess.TimeoutExpired:
        return 124, ""
    except OSError:
        return 127, ""


def out(data):
    print(json.dumps(data, ensure_ascii=False), flush=True)


def split_terse(line):
    parts, cur, esc = [], [], False
    for ch in line:
        if esc:
            cur.append(ch)
            esc = False
        elif ch == "\\":
            esc = True
        elif ch == ":":
            parts.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
    parts.append("".join(cur))
    return parts


def wifi_iface():
    _, txt = run(["nmcli", "-t", "-f", "DEVICE,TYPE", "device"])
    for line in txt.splitlines():
        p = split_terse(line)
        if len(p) >= 2 and p[1] == "wifi":
            return p[0]
    return ""


def sec_label(sec):
    if not sec or sec == "--":
        return "OPEN"
    if "802.1X" in sec or "8021X" in sec.upper():
        return "ENTERPRISE"
    return "SECURED"


def known_wifi():
    _, txt = run(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"])
    names = set()
    for line in txt.splitlines():
        p = split_terse(line)
        if len(p) >= 2 and p[1] == "802-11-wireless":
            names.add(p[0])
    return names


def wifi_list(rescan):
    code, radio = run(["nmcli", "radio", "wifi"])
    if code == 127:
        return {"ok": False, "radio": False, "iface": "", "ip": "", "networks": [], "msg": "NetworkManager no está disponible"}
    on = radio.strip() == "enabled"
    iface = wifi_iface()
    data = {"ok": True, "radio": on, "iface": iface, "ip": "", "networks": []}
    if not on:
        return data
    _, txt = run(["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan",
                  "yes" if rescan else "auto"], timeout=25)
    known = known_wifi()
    seen = {}
    for line in txt.splitlines():
        p = split_terse(line)
        if len(p) < 4 or not p[3]:
            continue
        ssid = p[3]
        try:
            sig = int(p[1])
        except ValueError:
            sig = 0
        item = {"ssid": ssid, "signal": sig, "sec": sec_label(p[2]), "active": p[0] == "*", "known": ssid in known}
        prev = seen.get(ssid)
        if not prev or item["active"] or (not prev["active"] and sig > prev["signal"]):
            seen[ssid] = item
    nets = sorted(seen.values(), key=lambda n: (not n["active"], not n["known"], -n["signal"], n["ssid"].lower()))
    data["networks"] = nets[:30]
    if iface:
        _, ip = run(["ip", "-4", "-o", "addr", "show", "dev", iface])
        m = re.search(r"inet (\d+\.\d+\.\d+\.\d+)", ip)
        data["ip"] = m.group(1) if m else ""
    return data


def wifi_error(txt):
    t = txt.lower()
    if "secrets were required" in t or "802-11-wireless-security.psk" in t or "no secrets" in t or "invalid passphrase" in t:
        return "needpass", "Contraseña incorrecta o requerida"
    if "no network with ssid" in t:
        return "gone", "La red ya no está al alcance"
    if "timeout" in t or "timed out" in t:
        return "timeout", "La red no respondió a tiempo"
    return "fail", "No se pudo conectar"


def wifi_connect(ssid, password):
    known = ssid in known_wifi()
    if known and not password:
        code, txt = run(["nmcli", "connection", "up", "id", ssid], timeout=45)
        if code == 0:
            return {"ok": True, "msg": "Conectado a " + ssid}
        kind, msg = wifi_error(txt)
        return {"ok": False, "kind": kind if kind != "fail" else "needpass", "msg": msg}
    if known and password:
        run(["nmcli", "connection", "delete", "id", ssid])
    args = ["nmcli", "device", "wifi", "connect", ssid]
    if password:
        args += ["password", password]
    code, txt = run(args, timeout=45)
    if code == 0:
        return {"ok": True, "msg": "Conectado a " + ssid}
    if ssid in known_wifi():
        run(["nmcli", "connection", "delete", "id", ssid])
    kind, msg = wifi_error(txt)
    return {"ok": False, "kind": kind, "msg": msg}


def wifi_cmd(argv):
    sub = argv[0] if argv else "list"
    if sub == "list":
        return out(wifi_list("--rescan" in argv))
    if sub == "radio":
        on = len(argv) > 1 and argv[1] == "on"
        code, _ = run(["nmcli", "radio", "wifi", "on" if on else "off"])
        return out({"ok": code == 0})
    if sub == "connect" and len(argv) > 1:
        return out(wifi_connect(argv[1], os.environ.get("AERO_WIFI_PSK", "")))
    if sub == "disconnect":
        iface = wifi_iface()
        code, _ = run(["nmcli", "device", "disconnect", iface]) if iface else (1, "")
        return out({"ok": code == 0, "msg": "Desconectado" if code == 0 else "No se pudo desconectar"})
    if sub == "forget" and len(argv) > 1:
        code, _ = run(["nmcli", "connection", "delete", "id", argv[1]])
        return out({"ok": code == 0, "msg": "Red olvidada" if code == 0 else "No se pudo olvidar"})
    return out({"ok": False, "msg": "comando desconocido"})


def bt_info(mac):
    _, txt = run(["bluetoothctl", "info", mac], timeout=4)
    info = {"mac": mac, "name": "", "icon": "", "paired": False, "connected": False, "trusted": False,
            "battery": -1, "rssi": -999}
    for raw in txt.splitlines():
        line = raw.strip()
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        val = val.strip()
        if key == "Name":
            info["name"] = val
        elif key == "Alias" and not info["name"]:
            info["name"] = val
        elif key == "Icon":
            info["icon"] = val
        elif key == "Paired":
            info["paired"] = val == "yes"
        elif key == "Connected":
            info["connected"] = val == "yes"
        elif key == "Trusted":
            info["trusted"] = val == "yes"
        elif key == "Battery Percentage":
            m = re.search(r"\((\d+)\)", val)
            if m:
                info["battery"] = int(m.group(1))
        elif key == "RSSI":
            m = re.search(r"-?\d+", val.split("(")[-1])
            if m:
                info["rssi"] = int(m.group(0))
    return info


def bt_list():
    code, show = run(["bluetoothctl", "show"], timeout=4)
    if code == 127 or "No default controller" in show or not show.strip():
        return {"ok": False, "avail": False, "powered": False, "devices": [], "msg": "No hay adaptador Bluetooth"}
    powered = bool(re.search(r"Powered:\s*yes", show))
    discovering = bool(re.search(r"Discovering:\s*yes", show))
    data = {"ok": True, "avail": True, "powered": powered, "scanning": discovering, "devices": []}
    if not powered:
        return data
    _, txt = run(["bluetoothctl", "devices"], timeout=4)
    macs = []
    for line in txt.splitlines():
        parts = line.split(" ", 2)
        if len(parts) >= 2 and parts[0] == "Device" and MAC_RE.match(parts[1]):
            macs.append(parts[1])
    with ThreadPoolExecutor(max_workers=8) as pool:
        infos = list(pool.map(bt_info, macs[:40]))
    devs = []
    for d in infos:
        name = d["name"]
        if not d["paired"] and (not name or MAC_RE.match(name.replace(" ", ""))):
            continue
        if not name:
            d["name"] = d["mac"]
        devs.append(d)
    devs.sort(key=lambda d: (not d["connected"], not d["paired"], -d["rssi"], d["name"].lower()))
    data["devices"] = devs
    return data


def bt_ok(txt, words):
    t = txt.lower()
    return any(w in t for w in words)


def bt_connect(mac):
    info = bt_info(mac)
    if not info["paired"]:
        code, txt = run(["bluetoothctl", "--timeout", "25", "pair", mac], timeout=30)
        if not bt_ok(txt, ["pairing successful", "already paired", "alreadyexists"]):
            return {"ok": False, "msg": "No se pudo emparejar. ¿Está en modo de emparejamiento?"}
    if not info["trusted"]:
        run(["bluetoothctl", "trust", mac], timeout=6)
    code, txt = run(["bluetoothctl", "--timeout", "20", "connect", mac], timeout=25)
    if bt_ok(txt, ["connection successful", "already connected"]) or bt_info(mac)["connected"]:
        return {"ok": True, "msg": "Conectado a " + (info["name"] or mac)}
    return {"ok": False, "msg": "No se pudo conectar. ¿Está encendido y cerca?"}


def bt_cmd(argv):
    sub = argv[0] if argv else "list"
    if sub == "list":
        return out(bt_list())
    if sub == "power":
        on = len(argv) > 1 and argv[1] == "on"
        if on:
            run(["rfkill", "unblock", "bluetooth"], timeout=4)
        code, txt = run(["bluetoothctl", "power", "on" if on else "off"], timeout=8)
        return out({"ok": bt_ok(txt, ["succeeded"]) or code == 0})
    if sub == "connect" and len(argv) > 1:
        return out(bt_connect(argv[1]))
    if sub == "disconnect" and len(argv) > 1:
        code, txt = run(["bluetoothctl", "disconnect", argv[1]], timeout=10)
        return out({"ok": bt_ok(txt, ["successful"]), "msg": "Desconectado"})
    if sub == "forget" and len(argv) > 1:
        code, txt = run(["bluetoothctl", "remove", argv[1]], timeout=10)
        return out({"ok": bt_ok(txt, ["removed"]), "msg": "Dispositivo olvidado"})
    return out({"ok": False, "msg": "comando desconocido"})


def main():
    if len(sys.argv) < 2:
        print("uso: phone-net.py wifi [list [--rescan]|radio on|off|connect SSID|disconnect|forget SSID]")
        print("     phone-net.py bt [list|power on|off|connect MAC|disconnect MAC|forget MAC]")
        return 1
    if sys.argv[1] == "wifi":
        wifi_cmd(sys.argv[2:])
    elif sys.argv[1] == "bt":
        bt_cmd(sys.argv[2:])
    return 0


if __name__ == "__main__":
    sys.exit(main())
