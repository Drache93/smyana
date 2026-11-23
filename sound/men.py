"""The men's own sounds, built from sine waves and noise with numpy like the flintlock's: no samples, all ours.

Beds (loops with no seam; the game fades them by how many men in view are walking, so twenty men are one sound):

    amb_steps_leaf_1   a few men walking on leaf litter and earth
    amb_steps_snow_1   the same in snow: each step a dry creak and a soft thud
    amb_wade_1         men wading a ford: water pushed aside, sloshing back

Single sounds:

    ack_N         a man's answer to an order: a low short "hm", not a word
    gather_N      hands in leaves and stems: a rustle, a stem snapped
    knife_N       the knife at a carcass: two or three short rasps
    pack_down_N   a pack set down: the thud, the cloth, a tin cup knocking
    fire_light_N  flint on steel, twice or three times, then tinder catching and the first twigs

Run from the repo:  python3 sound/men.py   (writes assets/audio/sfx/). The same code always gives the same sound.
Uses the flintlock's and the forest's tools. Needs numpy.
"""
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from flintlock import SFX, SR, band, env, highpass, lowpass, modal, noise, secs, tt, write  # noqa: E402
from forest import put, seamless, two, write_loop  # noqa: E402

TAKES = 3


def leaf_step(rng):
    """A foot down in leaf litter: a soft thud under a brush of dry leaves, a twig now and then."""
    # (the first try kept the thud under 260 Hz and the brush between 900 and 5200 with nothing between or above, and
    # Dominic heard "the sound being cut a bit at high or low band", 2026-11-23: now the whole band, gently sloped.)
    n = secs(0.26)
    thud = lowpass(highpass(noise(n, rng), 45, 1), 420, 1) * env(n, 0.004, 0.1) * 0.9
    brush = lowpass(highpass(noise(n, rng), 500, 1), 9000, 1) * env(n, 0.012, rng.uniform(0.1, 0.18)) * 0.42
    x = thud + brush
    for k in range(int(rng.integers(2, 6))):
        cn = secs(0.008)
        c = highpass(noise(cn, rng), 2200) * env(cn, 0.0004, 0.006) * rng.uniform(0.2, 0.6)
        a = int(rng.integers(0, n - cn))
        x[a:a + cn] += c
    return x


def snow_step(rng):
    """A foot down in snow: the dry creak as it packs, then the dull thud."""
    n = secs(0.3)
    t = tt(n)
    creak = lowpass(highpass(noise(n, rng), 600, 1), 8000, 1) * env(n, 0.03, 0.16) * (1 + 0.6 * np.sin(2 * np.pi * rng.uniform(55, 90) * t))
    thud = lowpass(highpass(noise(n, rng), 40, 1), 320, 1) * env(n, 0.01, 0.1) * 0.8
    return creak * 0.5 + thud


def drop(rng, lo, hi):
    """One bubble or drop: a damped sine whose pitch climbs as it closes. Water is these, not noise."""
    f = rng.uniform(lo, hi)
    bn = secs(rng.uniform(0.015, 0.06))
    t = tt(bn)
    curve = f * (1 + rng.uniform(0.15, 0.7) * (t / (bn / SR)) ** 2)
    return np.sin(2 * np.pi * np.cumsum(curve) / SR) * env(bn, 0.0015, bn / SR)


def slosh(rng):
    """A leg through knee-deep water: a plunge, a crowd of bubbles gurgling up behind it, drops falling back.
    (The first try was a push of mid noise, and Dominic heard "pushing sand around", 2026-11-23: noise is sand.)"""
    n = secs(0.9)
    t = tt(n)
    x = np.zeros(n)
    # (the plunge: a low hollow knock of water closing, one or two big bubbles)
    for k in range(int(rng.integers(1, 3))):
        put(x, drop(rng, 180, 420) * rng.uniform(0.5, 0.9), secs(rng.uniform(0.0, 0.08)))
    # (the gurgle: many bubbles, thick just after the plunge, thinning out)
    for k in range(int(rng.integers(28, 44))):
        at = 0.03 + rng.exponential(0.16)
        if at < 0.82:
            put(x, drop(rng, 450, 2600) * rng.uniform(0.12, 0.5), secs(at))
    # (drops falling back from the leg: a few high and late)
    for k in range(int(rng.integers(3, 8))):
        put(x, drop(rng, 2200, 5200) * rng.uniform(0.08, 0.25), secs(rng.uniform(0.25, 0.8)))
    # (only a breath of spray, very high and short)
    spray = highpass(noise(n, rng), 3500) * env(n, 0.02, 0.22) * 0.05
    return x + spray


def walking(step, rng, length=10.0, men=4, pace=1.7):
    """A few men walking, each at his own pace and a little out of step, spread left to right."""
    n = secs(length)
    L = np.zeros(n)
    R = np.zeros(n)
    for m in range(men):
        rate = pace * rng.uniform(0.9, 1.1)
        count = max(1, round(length * rate))  # (a whole number of steps in the loop, so it joins)
        gap = length / count
        pan = -0.6 + 1.2 * m / max(1, men - 1)
        off = rng.uniform(0, gap)
        g = rng.uniform(0.6, 1.0)
        for k in range(count):
            x = step(rng) * g * rng.uniform(0.7, 1.1)
            at = secs(off + k * gap + rng.uniform(-0.03, 0.03))
            put(L, x * np.sqrt((1 - pan) / 2), at)
            put(R, x * np.sqrt((1 + pan) / 2), at)
    return two(L, R)


def ack(rng):
    """A low short "hm" behind closed lips: a man's voice falling a little, soft at both ends."""
    n = secs(rng.uniform(0.22, 0.32))
    t = tt(n)
    f0 = rng.uniform(98, 128)
    curve = f0 * (1.06 - 0.14 * t / (n / SR)) * (1 + 0.01 * np.sin(2 * np.pi * 5.5 * t))
    ph = 2 * np.pi * np.cumsum(curve) / SR
    x = sum(np.sin(k * ph + rng.uniform(0, 6.28)) / k ** 1.3 for k in range(1, 14))
    # (closed lips: the nose's low hum, little above 500 Hz)
    x = lowpass(x, 420, order=2) + band(x, 900, 1300) * 0.12
    e = np.clip(t / 0.05, 0, 1) * np.clip((n / SR - t) / 0.09, 0, 1)
    return x * e


def gather(rng):
    n = secs(1.1)
    t = tt(n)
    x = np.zeros(n)
    for k in range(int(rng.integers(3, 6))):
        at = rng.uniform(0, 0.8)
        d = rng.uniform(0.08, 0.2)
        sw = np.exp(-((t - at - d) / (d * 0.6)) ** 2)
        x += band(noise(n, rng), rng.uniform(1200, 2500), 7000) * sw * rng.uniform(0.4, 1.0)
    # (a stem snapped)
    cn = secs(0.02)
    a = int(rng.integers(secs(0.2), n - cn))
    x[a:a + cn] += (highpass(noise(cn, rng), 1500) * env(cn, 0.0005, 0.012)) * 1.6
    return x


def knife(rng):
    n = secs(1.0)
    x = np.zeros(n)
    at = 0.0
    for k in range(int(rng.integers(2, 4))):
        d = rng.uniform(0.12, 0.22)
        m = secs(d)
        t = tt(m)
        rasp = band(noise(m, rng), 1800, 6500) * np.sin(np.pi * t / d) ** 0.7 * (1 + 0.5 * np.sin(2 * np.pi * rng.uniform(70, 120) * t))
        wet = band(noise(m, rng), 200, 700) * np.sin(np.pi * t / d) * 0.6
        a = secs(at)
        x[a:a + m] += rasp * 0.7 + wet
        at += d + rng.uniform(0.08, 0.16)
    return x


def pack_down(rng):
    n = secs(0.8)
    thud = band(noise(n, rng), 45, 190) * env(n, 0.006, 0.16) * 1.6
    cloth = band(noise(n, rng), 600, 3500) * env(n, 0.03, 0.22) * 0.35
    x = thud + cloth
    cup = modal(secs(0.4), [(1650, 0.5, 0.12), (2870, 0.3, 0.09), (4100, 0.2, 0.06)], rng) * 0.22
    a = secs(rng.uniform(0.06, 0.12))
    x[a:a + len(cup)] += cup
    return x


def fire_light(rng):
    n = secs(3.2)
    t = tt(n)
    x = np.zeros(n)
    at = 0.1
    for k in range(int(rng.integers(2, 4))):  # (the steel on the flint)
        m = secs(0.12)
        strike = modal(m, [(3100, 0.6, 0.05), (4700, 0.5, 0.04), (6800, 0.3, 0.03)], rng) + highpass(noise(m, rng), 3000) * env(m, 0.0005, 0.02) * 0.8
        a = secs(at)
        x[a:a + m] += strike * 0.5
        at += rng.uniform(0.28, 0.42)
    # (the tinder catches: a breath of flame that grows, and the first twigs snapping in it)
    grow = np.clip((t - at) / 1.4, 0, 1) ** 1.5 * np.clip((n / SR - t) / 0.5, 0, 1)
    x += band(noise(n, rng), 60, 500) * grow * 0.7 + band(noise(n, rng), 500, 2500) * grow * 0.12
    for k in range(14):
        cn = secs(0.012)
        a = int(rng.integers(secs(at + 0.2), n - cn))
        x[a:a + cn] += highpass(noise(cn, rng), 2500) * env(cn, 0.0003, 0.006) * rng.uniform(0.2, 0.5) * grow[a]
    return x


def main():
    SFX.mkdir(parents=True, exist_ok=True)
    made = 0
    for k, (name, step, db, men, pace) in enumerate((("steps_leaf", leaf_step, -10, 4, 1.7), ("steps_snow", snow_step, -10, 4, 1.5),
                                                      ("wade", slosh, -9, 3, 1.1))):
        rng = np.random.default_rng(9000 + k)
        write_loop(SFX / f"amb_{name}_1.wav", walking(step, rng, men=men, pace=pace), db)
        made += 1
    for j, (name, fn, db) in enumerate((("ack", ack, -14), ("gather", gather, -14), ("knife", knife, -13),
                                        ("pack_down", pack_down, -10), ("fire_light", fire_light, -9))):
        for k in range(1, TAKES + 1):
            write(SFX / f"{name}_{k}.wav", fn(np.random.default_rng(9500 + j * 10 + k)), db)
            made += 1
    print(f"wrote {made} of the men's sounds to {SFX}")


if __name__ == "__main__":
    main()
