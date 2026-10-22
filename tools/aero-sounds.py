#!/usr/bin/env python3

import os
import sys
import wave

import numpy as np

RATE = 48000


def note(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def bell(freq, dur, decay=3.0, bright=0.35, detune=1.003):
    t = np.arange(int(RATE * dur)) / RATE
    env = np.exp(-decay * t) * np.minimum(1, t / 0.006)
    tone = (np.sin(2 * np.pi * freq * t)
            + 0.5 * np.sin(2 * np.pi * freq * detune * t)
            + bright * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-decay * 2.2 * t)
            + bright * 0.5 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-decay * 4 * t))
    return tone * env


def pad(freqs, dur, attack=0.5, release=1.2):
    t = np.arange(int(RATE * dur)) / RATE
    env = np.minimum(1, t / attack) * np.clip((dur - t) / release, 0, 1)
    out = np.zeros_like(t)
    for f in freqs:
        for d in (0.997, 1.0, 1.004):
            out += np.sin(2 * np.pi * f * d * t + np.sin(2 * np.pi * 0.3 * t))
    return out * env / (len(freqs) * 3)


def place(buf, sig, at):
    i = int(at * RATE)
    j = min(len(buf), i + len(sig))
    buf[i:j] += sig[: j - i]


def echo(sig, delay=0.11, fb=0.35, taps=4):
    out = sig.copy()
    d = int(delay * RATE)
    for k in range(1, taps + 1):
        out[d * k:] += sig[: len(sig) - d * k] * fb ** k
    return out


def stereo(sig, width=0.012):
    d = int(width * RATE)
    left = sig
    right = np.concatenate([np.zeros(d), sig[:-d]]) if d else sig
    return np.stack([left, right], axis=1)


def finish(sig, gain=0.8):
    peak = np.max(np.abs(sig)) or 1
    sig = sig / peak * gain
    fade = int(0.02 * RATE)
    sig[-fade:] *= np.linspace(1, 0, fade)[:, None] if sig.ndim == 2 else np.linspace(1, 0, fade)
    return sig


def write(path, sig):
    if sig.ndim == 1:
        sig = stereo(sig)
    data = (np.clip(sig * 0.38, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def notify():
    dur = 1.0
    buf = np.zeros(int(RATE * dur))
    place(buf, bell(note(84), 0.9, 5.0), 0)
    place(buf, bell(note(91), 0.8, 5.5), 0.09)
    return finish(echo(buf, 0.09, 0.25, 3), 0.7)


def lock():
    dur = 0.8
    buf = np.zeros(int(RATE * dur))
    for k, n in enumerate((79, 74, 67)):
        place(buf, bell(note(n), 0.6, 6.0, 0.25), k * 0.08)
    return finish(buf, 0.65)


def unlock():
    dur = 0.9
    buf = np.zeros(int(RATE * dur))
    for k, n in enumerate((67, 74, 79, 86)):
        place(buf, bell(note(n), 0.7, 5.5, 0.3), k * 0.07)
    return finish(echo(buf, 0.08, 0.2, 2), 0.7)


def critical():
    dur = 1.1
    buf = np.zeros(int(RATE * dur))
    for k in range(3):
        place(buf, bell(note(81), 0.35, 9.0, 0.6, 1.02), k * 0.17)
        place(buf, bell(note(76), 0.35, 9.0, 0.6, 1.02), k * 0.17 + 0.06)
    return finish(echo(buf, 0.12, 0.25, 2), 0.75)


def main(argv):
    out = argv[0] if argv else os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                                             "dotfiles", ".config", "hyper-aero", "sounds")
    os.makedirs(out, exist_ok=True)
    for name, fn in (("notify", notify), ("lock", lock), ("unlock", unlock), ("critical", critical)):
        write(os.path.join(out, name + ".wav"), fn())
        print(name)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
