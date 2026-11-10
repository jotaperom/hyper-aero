#!/usr/bin/env python3

import os
import re
import sys
import json
import time
import hashlib
import urllib.parse
import urllib.request
import urllib.error

API = "https://lrclib.net/api"
AGENT = "hyper-aero-desk/1.0"
CACHE = os.path.join(os.path.expanduser("~"), ".cache", "hyper-aero", "lyrics")
MISS_TTL = 6 * 3600


WORD_TAG = re.compile(r"<(\d+):(\d+(?:[.:]\d+)?)>")
VOWELS = re.compile(r"[aeiouyáéíóúüàèìòùâêîôûäëïöæøåœ]+", re.I)


def syllables(word):
    core = re.sub(r"[^\w']", "", word, flags=re.UNICODE)
    if not core:
        return 0.4
    if re.search(r"[\u3040-\u30ff\u4e00-\u9fff\uac00-\ud7af]", core):
        return float(len(core))
    n = len(VOWELS.findall(core))
    if n > 1 and core.lower().endswith("e") and not core.lower().endswith(("le", "ee")):
        n -= 1
    return float(max(1, n))


def tagged(text):
    marks = list(WORD_TAG.finditer(text))
    if not marks:
        return None
    words = []
    for i, m in enumerate(marks):
        t = int(m.group(1)) * 60 + float(m.group(2).replace(":", "."))
        chunk = text[m.end(): marks[i + 1].start() if i + 1 < len(marks) else len(text)]
        for j, w in enumerate(chunk.split()):
            words.append([round(t + j * 0.05, 2), w])
    return words


def wordify(lines, length):
    timed = [i for i, l in enumerate(lines) if l[0] >= 0]
    result = []
    for idx, line in enumerate(lines):
        t, text = line[0], line[1]
        if t < 0:
            result.append([t, WORD_TAG.sub("", text).strip(), [], -1])
            continue
        later = [lines[k][0] for k in timed if lines[k][0] > t]
        nxt = later[0] if later else (length if length > t else t + 5)
        tags = tagged(text)
        clean = " ".join(WORD_TAG.sub("", text).split())
        if tags:
            words = []
            for k, (wt, w) in enumerate(tags):
                end = tags[k + 1][0] if k + 1 < len(tags) else min(nxt, wt + 1.2)
                words.append([wt, round(max(wt + 0.05, end), 2), w])
            result.append([t, " ".join(w for _, w in tags), words, words[-1][1] if words else nxt])
            continue
        parts = clean.split()
        if not parts:
            result.append([t, clean, [], nxt])
            continue
        gap = max(0.2, nxt - t)
        weights = [syllables(w) + 0.35 for w in parts]
        total = sum(weights)
        sung = min(gap * 0.94, max(0.7, (total - 0.35 * len(parts)) * 0.27 + 0.25 * len(parts)))
        words = []
        acc = t
        for w, wt in zip(parts, weights):
            d = sung * wt / total
            words.append([round(acc, 2), round(acc + d, 2), w])
            acc += d
        result.append([t, clean, words, round(acc, 2)])
    return result


def out(key, status, lines=None, synced=False, length=0):
    rows = wordify(lines or [], length) if synced else [[l[0], WORD_TAG.sub("", l[1]).strip()] for l in (lines or [])]
    print(json.dumps({"key": key, "status": status, "synced": synced, "lines": rows}, ensure_ascii=False), flush=True)


def fetch(path, params):
    url = f"{API}/{path}?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": AGENT})
    try:
        with urllib.request.urlopen(req, timeout=8) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise


def clean(title):
    t = re.sub(r"\s*[\(\[][^\)\]]*(feat\.|ft\.|with |remaster|version|live|edit|mix|mono|stereo)[^\)\]]*[\)\]]", "", title, flags=re.I)
    t = re.sub(r"\s+-\s+.*(remaster|version|live|edit|mix|mono|stereo).*$", "", t, flags=re.I)
    return t.strip() or title


def parse_lrc(text):
    rows = []
    stamp = re.compile(r"\[(\d+):(\d+(?:[.:]\d+)?)\]")
    for raw in text.splitlines():
        marks = stamp.findall(raw)
        if not marks:
            continue
        words = stamp.sub("", raw).strip()
        for m, s in marks:
            rows.append([round(int(m) * 60 + float(s.replace(":", ".")), 2), words])
    rows.sort(key=lambda r: r[0])
    return rows


def parse_plain(text):
    return [[-1, l.strip()] for l in text.splitlines()]


def pick(results, length):
    best, score = None, None
    for r in results or []:
        if not (r.get("syncedLyrics") or r.get("plainLyrics") or r.get("instrumental")):
            continue
        d = abs((r.get("duration") or 0) - length) if length > 0 else 0
        if length > 0 and d > 6:
            continue
        s = d - (20 if r.get("syncedLyrics") else 0)
        if score is None or s < score:
            best, score = r, s
    return best


def shape(rec):
    if not rec:
        return {"status": "none", "synced": False, "lines": []}
    if rec.get("syncedLyrics"):
        lines = parse_lrc(rec["syncedLyrics"])
        if lines:
            return {"status": "ok", "synced": True, "lines": lines}
    if rec.get("plainLyrics"):
        return {"status": "ok", "synced": False, "lines": parse_plain(rec["plainLyrics"])}
    if rec.get("instrumental"):
        return {"status": "instrumental", "synced": False, "lines": []}
    return {"status": "none", "synced": False, "lines": []}


def main(argv):
    if len(argv) < 4:
        print("uso: desk-lyrics.py ARTISTA TITULO ALBUM DURACION_SEG")
        return 1
    artist, title, album = argv[0].strip(), argv[1].strip(), argv[2].strip()
    try:
        length = float(argv[3])
    except ValueError:
        length = 0
    key = f"{artist}␟{title}"
    if not title:
        out(key, "none")
        return 0
    os.makedirs(CACHE, exist_ok=True)
    cpath = os.path.join(CACHE, hashlib.sha256(f"{artist.lower()}|{title.lower()}|{round(length)}".encode()).hexdigest() + ".json")
    try:
        with open(cpath, encoding="utf-8") as f:
            c = json.load(f)
        if c.get("status") != "none" or time.time() - c.get("at", 0) < MISS_TTL:
            out(key, c["status"], c.get("lines"), c.get("synced", False), length)
            return 0
    except (OSError, ValueError, KeyError):
        pass
    rec = None
    try:
        if artist and length > 0:
            rec = fetch("get", {"track_name": title, "artist_name": artist, "album_name": album, "duration": round(length)})
        if not rec or not (rec.get("syncedLyrics") or rec.get("plainLyrics") or rec.get("instrumental")):
            q = {"track_name": clean(title)}
            if artist:
                q["artist_name"] = artist
            rec = pick(fetch("search", q), length)
        if not rec and artist:
            rec = pick(fetch("search", {"q": f"{artist} {clean(title)}"}), length)
    except (urllib.error.URLError, OSError, ValueError):
        out(key, "offline")
        return 0
    res = shape(rec)
    res["at"] = time.time()
    try:
        with open(cpath + ".tmp", "w", encoding="utf-8") as f:
            json.dump(res, f, ensure_ascii=False)
        os.replace(cpath + ".tmp", cpath)
    except OSError:
        pass
    out(key, res["status"], res["lines"], res["synced"], length)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
