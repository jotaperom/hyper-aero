#!/usr/bin/env python3

import os
import sys
import json
import shutil
import tempfile
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ART = os.path.join(HERE, "aero-artgen.py")
GEN = os.path.join(ROOT, "dotfiles", ".config", "hyper-aero", "scripts", "aero-wallgen.py")

PRESETS = {
    "blue": {"day": "aero-motion", "night": "aero-motion-night",
             "layers": [("bubbles", 0.7, 1), ("waves", 0.6, 1), ("sparkles", 0.5, 1)]},
    "red": {"day": "aero-red-day", "night": "aero-red-night",
            "layers": [("bokeh", 0.6, 1), ("waves", 0.45, 1), ("sparkles", 0.4, 1)]},
    "green": {"day": "aero-green-day", "night": "aero-green-night",
              "layers": [("bubbles", 0.8, 1), ("caustics", 0.45, 1), ("rays", 0.55, 1)]},
    "black": {"day": "aero-black-day", "night": "aero-black-night",
              "layers": [("waves", 0.6, 1), ("grid", 0.4, 1), ("sparkles", 0.45, 1)]},
}


def run(args):
    print("+", " ".join(args), flush=True)
    subprocess.run(args, check=True)


def still(video, out, t=0.5):
    run(["ffmpeg", "-y", "-loglevel", "error", "-ss", str(t), "-i", video, "-frames:v", "1", "-q:v", "2", out])


def build(name, out, frames):
    cfg = PRESETS[name]
    work = tempfile.mkdtemp(prefix=f"aero-{name}-")
    try:
        run([sys.executable, ART, work, name])
        spec = {"image": os.path.join(work, f"base-{name}.png"), "accent": name, "name": name,
                "layers": [{"type": t, "amount": a, "speed": s} for t, a, s in cfg["layers"]]}
        if frames:
            spec["frames"] = frames
        sp = os.path.join(work, "spec.json")
        json.dump(spec, open(sp, "w"))
        dest = os.path.join(work, "out")
        run([sys.executable, GEN, "render", sp, dest])
        for mode in ("day", "night"):
            target = os.path.join(out, cfg[mode])
            shutil.copyfile(os.path.join(dest, f"{mode}.mp4"), target + ".mp4")
            still(target + ".mp4", target + ".jpg")
    finally:
        shutil.rmtree(work, ignore_errors=True)


def main(argv):
    out = argv[0] if argv else os.path.join(ROOT, "build", "wallpapers")
    names = [a for a in argv[1:] if a in PRESETS] or list(PRESETS)
    frames = int(os.environ.get("AERO_FRAMES", "0")) or None
    os.makedirs(out, exist_ok=True)
    for n in names:
        build(n, out, frames)
    if os.path.isfile(os.path.join(out, "aero-motion.jpg")):
        shutil.copyfile(os.path.join(out, "aero-motion.jpg"), os.path.join(out, "bg.jpg"))
        shutil.copyfile(os.path.join(out, "aero-motion-night.jpg"), os.path.join(out, "bg-night.jpg"))
    night = os.path.join(out, "aero-motion-night.mp4")
    if os.path.isfile(night):
        run(["ffmpeg", "-y", "-loglevel", "error", "-i", night, "-an",
             "-vf", "setpts=2.0*PTS,fps=24,eq=brightness=-0.08:saturation=1.15,vignette=PI/4",
             "-c:v", "libx264", "-preset", "slow", "-crf", "26", "-pix_fmt", "yuv420p",
             "-movflags", "+faststart", os.path.join(out, "aero-saver.mp4")])
    print("listo:", out)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
