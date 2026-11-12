"""The wolves' sounds, built from sine waves and noise with numpy like the flintlock's: no samples, all ours.

    howl_N       one wolf near, then the pack joining in: a long voice that rises, holds with a slow waver and
                 falls away, the wood giving it back
    far_howl_N   the same heard from a long way off through the firs: dull, thin, mostly the wood's echo
    snarl_N      a wolf going for a man: a rough growl and the snap of the jaws
    yelp_N       a wolf hit by a ball: a short high cry, broken off

Run from the repo:  python3 sound/wolves.py   (writes assets/audio/sfx/). The same code always gives the same sound.
Uses the flintlock's tools (sound/flintlock.py). Needs numpy.
"""
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from flintlock import PLACES, SFX, TAKES, band, env, in_place, lowpass, highpass, noise, place, secs, soft, tt, write  # noqa: E402


# the places the howls are heard in: the flintlock's, held long enough for a howl to finish in
PLACES["fir"] = dict(PLACES["wood"], length=9.5)
PLACES["far"] = dict(PLACES["valley"], length=11.0)


def glide(points, n):
    """A pitch curve through (seconds, Hz) points, smoothed between them."""
    t = tt(n)
    ts = np.array([p[0] for p in points])
    hz = np.array([p[1] for p in points])
    f = np.interp(t, ts, hz)
    k = secs(0.08)
    return np.convolve(np.pad(f, (k, k), mode="edge"), np.ones(k) / k, mode="same")[k:-k]


def voice(curve, rng, breath=0.18, rough=0.0):
    """A throat on a pitch curve: a few harmonics through a soft formant, a slow waver, breath over it."""
    n = len(curve)
    t = tt(n)
    wav = 1 + 0.012 * np.sin(2 * np.pi * rng.uniform(4.5, 6.0) * t + rng.uniform(0, 6.28))
    drift = 1 + 0.01 * lowpass(noise(n, rng), 1.5) / 0.05
    f = curve * wav * np.clip(drift, 0.97, 1.03)
    ph = 2 * np.pi * np.cumsum(f) / 22050
    x = np.sin(ph) + 0.32 * np.sin(2 * ph + 0.4) + 0.12 * np.sin(3 * ph + 1.1) + 0.05 * np.sin(4 * ph)
    if rough:
        x *= 1 + rough * np.sin(2 * np.pi * rng.uniform(26, 34) * t) * lowpass(noise(n, rng), 40) / 0.15
    b = band(noise(n, rng), 300, 2400) * breath
    return lowpass(x + b, 2600)


def one_howl(rng, length, base):
    """A single wolf: up from low in half a second, holding long with the pitch easing, then down and out."""
    n = secs(length)
    up = rng.uniform(0.4, 0.7)
    top = base * rng.uniform(1.45, 1.65)
    pts = [(0, base), (up, top), (length * 0.45, top * rng.uniform(0.96, 1.04)), (length * 0.8, top * 0.94),
           (length, base * 0.82)]
    x = voice(glide(pts, n), rng)
    t = tt(n)
    shape = np.clip(t / 0.25, 0, 1) ** 1.5 * np.clip((length - t) / (length * 0.25), 0, 1) ** 1.2
    return x * shape


def pack_howl(rng, voices):
    """The first wolf, then the others joining in, each a little higher or lower, never quite together."""
    length = 7.5
    out = np.zeros(secs(length))
    at = 0.0
    for v in range(voices):
        ln = rng.uniform(3.0, 4.4) if v == 0 else rng.uniform(2.2, 3.4)
        base = rng.uniform(300, 360) * (1 if v == 0 else rng.uniform(0.9, 1.25))
        h = one_howl(rng, ln, base) * (1.0 if v == 0 else rng.uniform(0.45, 0.75))
        place(out, h, secs(at))
        at += rng.uniform(1.2, 2.2) if v == 0 else rng.uniform(0.4, 1.1)
    return out


def snarl(rng):
    """A growl, rough and low, rising, and the jaws snapping shut."""
    length = 0.9
    n = secs(length)
    curve = glide([(0, 105), (0.5, 140), (0.75, 190), (length, 160)], n)
    g = voice(curve, rng, breath=0.5, rough=0.9)
    t = tt(n)
    g = soft(g * np.clip(t / 0.08, 0, 1) * np.clip((length - t) / 0.2, 0, 1), 2.5)
    out = np.zeros(secs(1.1))
    place(out, g, 0)
    for at in (0.72, 0.86):
        m = secs(0.05)
        snap = highpass(noise(m, rng), 900) * env(m, 0.001, 0.03)
        place(out, snap * 1.4, secs(at + rng.uniform(-0.02, 0.02)))
    return out


def yelp(rng):
    """A short high cry, sliding down, cut off; a second, weaker, after it."""
    out = np.zeros(secs(0.9))
    at = 0.0
    for k in range(2):
        ln = rng.uniform(0.18, 0.28) if k == 0 else rng.uniform(0.12, 0.2)
        n = secs(ln)
        hi = rng.uniform(950, 1150) * (1 if k == 0 else 0.85)
        x = voice(glide([(0, hi * 0.8), (0.04, hi), (ln, hi * 0.6)], n), rng, breath=0.3)
        t = tt(n)
        x *= np.clip(t / 0.015, 0, 1) * np.clip((ln - t) / 0.04, 0, 1)
        place(out, x * (1.0 if k == 0 else 0.5), secs(at))
        at += ln + rng.uniform(0.15, 0.3)
    return out


def main():
    SFX.mkdir(parents=True, exist_ok=True)
    for k in range(1, TAKES + 1):
        rng = np.random.default_rng(5000 + k)
        dry = pack_howl(rng, 2 + k)
        write(SFX / f"howl_{k}.wav", in_place(dry, "fir", rng), -4)
        rng = np.random.default_rng(5100 + k)
        far = lowpass(pack_howl(rng, 2 + (k % 3)), 1100, 2)
        write(SFX / f"far_howl_{k}.wav", in_place(far, "far", rng, far=True), -10)
        write(SFX / f"snarl_{k}.wav", snarl(np.random.default_rng(5200 + k)), -6)
        write(SFX / f"yelp_{k}.wav", yelp(np.random.default_rng(5300 + k)), -7)
    print("wrote the wolves to", SFX)


if __name__ == "__main__":
    main()
