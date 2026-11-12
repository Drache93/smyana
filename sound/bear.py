"""The bear's sounds, built from sine waves and noise with numpy like the wolves' and the flintlock's: all ours.

    bear_huff_N    reared up: short hard breaths out through the nose, and the jaws clacking
    bear_roar_N    charging: a deep rough roar, rising and breaking
    bear_swipe_N   a blow: a heavy thump and a rough grunt

Run from the repo:  python3 sound/bear.py   (writes assets/audio/sfx/). The same code always gives the same sound.
"""
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from flintlock import SFX, TAKES, band, env, in_place, lowpass, noise, place, secs, soft, tt, write  # noqa: E402
from wolves import glide, voice  # noqa: E402


def huff(rng):
    """Three or four hard breaths out, each a burst of breathy noise with a low body under it, and a clack."""
    out = np.zeros(secs(2.2))
    at = 0.05
    for k in range(rng.integers(3, 5)):
        ln = rng.uniform(0.22, 0.34)
        n = secs(ln)
        t = tt(n)
        breath = band(noise(n, rng), 180, 1600) * env(n, 0.012, ln * 0.9)
        body = np.sin(2 * np.pi * rng.uniform(70, 95) * t) * env(n, 0.01, ln * 0.7) * 0.6
        place(out, soft(breath + body, 1.8), secs(at))
        if k % 2 == 1:
            m = secs(0.04)
            place(out, band(noise(m, rng), 900, 5000) * env(m, 0.001, 0.025) * 0.8, secs(at + ln * 0.8))
        at += ln + rng.uniform(0.18, 0.32)
    return out


def roar(rng):
    """A deep roar: a rough low voice that swells, rises and breaks off, with a lot of breath in it."""
    length = rng.uniform(1.4, 1.9)
    n = secs(length)
    curve = glide([(0, 85), (0.35, 120), (length * 0.6, 150 * rng.uniform(0.9, 1.1)), (length, 95)], n)
    x = voice(curve, rng, breath=0.9, rough=1.2)
    t = tt(n)
    x = soft(lowpass(x, 1400) * np.clip(t / 0.12, 0, 1) * np.clip((length - t) / 0.3, 0, 1), 3.0)
    return x


def swipe(rng):
    """A heavy blow: a dull thump, and a short grunt after it."""
    out = np.zeros(secs(0.8))
    m = secs(0.12)
    thump = lowpass(noise(m, rng), 300) * env(m, 0.003, 0.09)
    place(out, thump * 2.0, 0)
    ln = 0.35
    g = voice(glide([(0, 110), (ln, 80)], secs(ln)), rng, breath=0.8, rough=1.0)
    g *= env(secs(ln), 0.02, 0.3)
    place(out, soft(g, 2.0) * 0.7, secs(0.08))
    return out


def main():
    SFX.mkdir(parents=True, exist_ok=True)
    for k in range(1, TAKES + 1):
        rng = np.random.default_rng(6000 + k)
        write(SFX / f"bear_huff_{k}.wav", in_place(huff(rng), "wood", rng), -7)
        rng = np.random.default_rng(6100 + k)
        write(SFX / f"bear_roar_{k}.wav", in_place(roar(rng), "valley", rng), -3)
        write(SFX / f"bear_swipe_{k}.wav", swipe(np.random.default_rng(6200 + k)), -6)
    print("wrote the bear to", SFX)


if __name__ == "__main__":
    main()
