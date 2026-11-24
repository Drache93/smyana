"""The forest's own sound, built from sine waves and noise with numpy like the flintlock's: no samples, all ours.

Beds, each a loop that joins its own start without a seam (the game fades them up and down by what is on the screen):

    amb_wind_1     the wind in the crowns: a low breath that swells and sinks, leaves hissing on the gusts
    amb_birds_1    small birds by day: a chaffinch's falling run, tits' two notes, a warbler's chatter, far and near
    amb_night_1    a summer night: crickets, each at its own pace, and the dark between them
    amb_rain_1     rain on leaves: a steady hiss, nearer drops on broad leaves, a drip now and then
    amb_stream_1   a mountain stream over stones: a wash of water with bubbling in it
    amb_fire_1     a camp fire: the low flutter of the flame, the wood cracking and spitting

Calls, each heard now and then on its own:

    cuckoo_N       spring: the two notes, a few times over, from far off
    woodpecker_N   spring and summer: a drum roll on a dead bough
    jay_N          autumn: the harsh screech
    raven_N        winter: two or three deep croaks over the snow
    owl_N          night: a tawny owl's long wavering hoot

All of these live in the Rhodopes' woods (the common cuckoo, the great spotted and black woodpeckers, the jay, the
raven and the tawny owl are all resident or summer birds of Bulgaria's mountain forests).

Run from the repo:  python3 sound/forest.py   (writes assets/audio/sfx/). The same code always gives the same sound.
Uses the flintlock's tools (sound/flintlock.py). Needs numpy.
"""
import pathlib
import sys
import wave

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from flintlock import SFX, SR, band, env, highpass, in_place, lowpass, noise, secs, tt, write  # noqa: E402

TAKES = 3


def put(dst, src, at):
    """Adds src into dst at sample `at`, running round the end into the start (so a loop has no seam)."""
    n = dst.shape[-1]
    idx = (at + np.arange(src.shape[-1])) % n
    np.add.at(dst, (..., idx), src)


def seamless(x, fade=1.0):
    """A stretch of steady sound made into a loop: its last `fade` seconds laid under its first."""
    f = secs(fade)
    n = x.shape[-1] - f
    out = x[..., :n].copy()
    k = np.linspace(0, 1, f)
    out[..., :f] = out[..., :f] * np.sqrt(k) + x[..., n:] * np.sqrt(1 - k)
    return out


def swell(n, rng, cycles, depth):
    """A slow rise and fall that comes back to where it began after n samples: a few sines with whole turns."""
    t = np.arange(n) / n
    s = np.zeros(n)
    for c in cycles:
        s += np.sin(2 * np.pi * (c * t + rng.uniform(0, 1))) / len(cycles)
    return 1 + depth * s


def write_loop(path, st, peak_db):
    """A loop as a WAV at that peak, nothing trimmed or faded (its end runs into its start)."""
    st = st if st.ndim == 2 else st[None, :]
    st = st - st.mean(axis=1, keepdims=True)
    st = st / (np.abs(st).max() + 1e-12) * 10 ** (peak_db / 20)
    pcm = (np.clip(st, -1, 1).T * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(st.shape[0])
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    return st


def two(L, R):
    return np.stack([L, R])


# ---------- the beds

def wind(rng, length=18.0):
    n = secs(length + 1.0)

    def side(seed):
        r = np.random.default_rng(seed)
        low = band(noise(n, r), 90, 520) * 1.0
        mid = band(noise(n, r), 400, 1500) * 0.35
        hiss = band(noise(n, r), 2200, 6500) * 0.16
        return low, mid, hiss
    out = []
    m = n - secs(1.0)
    gust = swell(m, rng, (1, 2, 3, 5), 0.55)
    leaf = np.clip(swell(m, rng, (2, 3, 7), 0.9), 0.15, None) ** 2
    for seed in (rng.integers(1 << 30), rng.integers(1 << 30)):
        low, mid, hiss = side(seed)
        x = seamless(low) * gust + seamless(mid) * gust ** 1.5 + seamless(hiss) * leaf * gust
        out.append(x)
    return two(*out)


def slur(points, dur, rng, rough=0.0):
    """One note of a small bird: a whistle sliding through (place 0..1, Hz) points, never quite steady: the pitch
    wanders and shivers, the breath behind it flutters, and no two are alike. (The first try, 2026-11-23, was pure
    tones at set pitches in set rhythms, and Dominic heard it at once: "very robotic, like data, not like birds".)"""
    n = max(secs(dur), 32)
    x = np.arange(n) / n
    f = np.interp(x, [p[0] for p in points], [p[1] for p in points])
    k = max(3, n // 12)
    f = np.convolve(np.pad(f, (k, k), mode="edge"), np.hanning(k * 2 + 1) / np.hanning(k * 2 + 1).sum(), mode="same")[k:-k]
    wander = lowpass(noise(n + 256, rng), 60)[128:128 + n]
    f = f * (1 + 0.02 * wander / (np.abs(wander).max() + 1e-9)) * (1 + rng.uniform(0.0, 0.025) * np.sin(2 * np.pi * rng.uniform(18, 60) * tt(n) + rng.uniform(0, 6.28)))
    ph = 2 * np.pi * np.cumsum(f) / SR
    flutter = lowpass(noise(n + 256, rng), 90)[128:128 + n]
    amp = np.clip(1 + (0.25 + rough) * flutter / (np.abs(flutter).max() + 1e-9), 0.1, None)
    up = rng.uniform(0.08, 0.3)
    e = np.clip(x / up, 0, 1) ** rng.uniform(0.7, 1.6) * np.clip((1 - x) / (1 - up), 0, 1) ** rng.uniform(0.6, 2.0)
    tone_ = np.sin(ph) + rng.uniform(0.03, 0.14) * np.sin(2 * ph + rng.uniform(0, 6.28))
    air = band(noise(n + 512, rng), 2500, 7500)[256:256 + n] * rng.uniform(0.02, 0.06)
    return (tone_ * amp + air) * e


def phrase(kind, rng):
    """A bird's phrase as (seconds in, note, loudness) triples. Each bird has its own way, but loosely: lengths,
    gaps and pitches all wander, a note is dropped now and then, and it trails off when it likes."""
    notes = []
    at = 0.0
    if kind == "finch":  # a chaffinch: a falling, quickening rattle of down-slurs and a flourish at the end
        f = rng.uniform(3900, 5000)
        count = int(rng.integers(6, 13))
        for k in range(count):
            d = rng.uniform(0.05, 0.085) * (1 - 0.3 * k / count)
            top = f * rng.uniform(0.97, 1.05)
            notes.append((at, slur([(0, top * rng.uniform(1.0, 1.12)), (0.35, top), (1, top * rng.uniform(0.72, 0.86))], d, rng), rng.uniform(0.6, 1.0)))
            at += d + rng.uniform(0.02, 0.05)
            f *= rng.uniform(0.94, 0.985)
        if rng.uniform() < 0.8:
            notes.append((at + rng.uniform(0, 0.04), slur([(0, f * 0.9), (0.3, f * 1.35), (0.6, f * 0.8), (1, f * 1.1)], rng.uniform(0.14, 0.22), rng, 0.2), 1.0))
    elif kind == "tit":  # a great tit: two notes, high then low, a few times, never quite the same twice
        hi = rng.uniform(4000, 5400)
        ratio = rng.uniform(0.7, 0.8)
        for k in range(int(rng.integers(2, 6))):
            h = hi * rng.uniform(0.985, 1.015)
            notes.append((at, slur([(0, h * 0.96), (0.2, h), (1, h * rng.uniform(0.95, 0.99))], rng.uniform(0.09, 0.14), rng), rng.uniform(0.7, 1.0)))
            at += rng.uniform(0.15, 0.2)
            notes.append((at, slur([(0, h * ratio * 1.04), (0.3, h * ratio), (1, h * ratio * 0.97)], rng.uniform(0.1, 0.16), rng), rng.uniform(0.6, 0.95)))
            at += rng.uniform(0.2, 0.3)
    elif kind == "warbler":  # a blackcap: a hurried, rambling warble, up and down with no pattern to it
        f = rng.uniform(3000, 4500)
        for k in range(int(rng.integers(7, 18))):
            f = float(np.clip(f * rng.uniform(0.75, 1.35), 2400, 6200))
            d = rng.uniform(0.035, 0.13)
            g = f * rng.uniform(0.8, 1.25)
            notes.append((at, slur([(0, f), (rng.uniform(0.3, 0.7), (f + g) / 2 * rng.uniform(0.92, 1.1)), (1, g)], d, rng, 0.15), rng.uniform(0.4, 1.0)))
            at += d + (rng.uniform(0.01, 0.05) if rng.uniform() < 0.85 else rng.uniform(0.1, 0.25))
    elif kind == "robin":  # a robin: a few long thin wistful notes, then a quick ripple
        f = rng.uniform(4300, 5800)
        for k in range(int(rng.integers(2, 4))):
            d = rng.uniform(0.18, 0.4)
            notes.append((at, slur([(0, f * rng.uniform(0.95, 1.05)), (0.5, f * rng.uniform(0.9, 1.1)), (1, f * rng.uniform(0.8, 1.0))], d, rng), rng.uniform(0.5, 0.9)))
            at += d + rng.uniform(0.06, 0.2)
            f *= rng.uniform(0.8, 1.2)
        for k in range(int(rng.integers(0, 7))):
            d = rng.uniform(0.03, 0.06)
            g = f * rng.uniform(0.7, 1.4)
            notes.append((at, slur([(0, g), (1, g * rng.uniform(0.8, 1.2))], d, rng), rng.uniform(0.4, 0.8)))
            at += d + rng.uniform(0.01, 0.03)
    else:  # a single thin call, "tsip" or "hweet"
        f = rng.uniform(4800, 7000)
        if rng.uniform() < 0.5:
            notes.append((0.0, slur([(0, f * 1.15), (0.4, f), (1, f * 0.8)], rng.uniform(0.04, 0.08), rng, 0.2), 1.0))
        else:
            notes.append((0.0, slur([(0, f * 0.7), (0.6, f * 0.95), (1, f)], rng.uniform(0.12, 0.22), rng), 0.9))
    return notes


def birds(rng, length=32.0):
    """Small birds in a wood, most of them a way off: each sings, waits, sings again from the same perch a little
    differently; there are stretches with only a call or two in them."""
    n = secs(length)
    L = np.zeros(n)
    R = np.zeros(n)
    tail = lowpass(noise(secs(1.3), rng), 3500) * env(secs(1.3), 0.02, 1.1)
    tail /= np.sqrt((tail ** 2).sum())
    singers = [("finch", 0.55), ("tit", 0.75), ("warbler", 0.35), ("robin", 0.85), ("call", 0.2), ("call", 0.6), ("tit", 0.95), ("finch", 0.9)]
    for kind, far in singers:
        far = float(np.clip(far + rng.uniform(-0.1, 0.1), 0.05, 1.0))  # 0 near, 1 far off
        pan = rng.uniform(-0.9, 0.9)
        gain = 10 ** (-(6 + far * 18) / 20)
        at = rng.uniform(0, length)
        sung = 0.0
        while sung < length:
            dry = np.zeros(secs(4.0))
            for t0, note, loud in phrase(kind, rng):
                a = secs(t0)
                if a + len(note) < len(dry):
                    dry[a:a + len(note)] += note * loud
            # (the wood between: the further off, the duller, and the more of it is the wood's own answer)
            wet = np.convolve(dry, tail)[: len(dry)]
            x = lowpass(dry * (1 - far * 0.7) + wet * (0.25 + far * 0.9), 8000 - far * 4500) * gain
            put(L, x * np.sqrt((1 - pan) / 2), secs(at))
            put(R, x * np.sqrt((1 + pan) / 2), secs(at + rng.uniform(0, 0.0006)))
            wait = rng.uniform(3.5, 9.0) if kind != "call" else rng.uniform(1.5, 7.0)
            if rng.uniform() < 0.25: wait += rng.uniform(4, 10)  # (he falls silent a while)
            at += wait
            sung += wait
    return two(L, R)


def night(rng, length=16.0):
    n = secs(length)
    L = np.zeros(n)
    R = np.zeros(n)
    for k in range(7):
        hz = rng.uniform(3900, 5100)
        rate = rng.uniform(2.1, 3.4)       # chirps a second
        pulses = int(rng.integers(3, 5))   # strokes in a chirp
        far = rng.uniform(0.2, 1.0)
        pan = rng.uniform(-1, 1)
        # (a whole number of chirps in the loop, so it joins)
        count = max(1, round(length * rate))
        step = length / count
        one = np.zeros(secs(step))
        for p in range(pulses):
            m = secs(0.016)
            s = np.sin(2 * np.pi * hz * tt(m)) * np.sin(np.pi * np.arange(m) / m)
            a = secs(p * 0.024)
            one[a:a + m] += s
        x = np.tile(one, count)[:n]
        x = np.pad(x, (0, n - len(x)))
        # (it stops and starts: a cricket falls silent a while)
        x *= np.clip(swell(n, rng, (1, 2, 3), 1.6), 0, 1)
        x = np.roll(x, int(rng.integers(n))) * 10 ** (-(6 + far * 16) / 20)
        L += x * np.sqrt((1 - pan) / 2)
        R += x * np.sqrt((1 + pan) / 2)
    air = seamless(band(noise(n + secs(1.0), rng), 120, 700)) * 0.004
    return two(L + air, R + air[::-1])


def rain(rng, length=14.0):
    n = secs(length + 1.0)
    m = n - secs(1.0)
    out = []
    for side in range(2):
        hiss = seamless(band(noise(n, rng), 1800, 8000)) * 0.5
        leaves = seamless(band(noise(n, rng), 350, 1600)) * 0.3
        x = (hiss + leaves) * swell(m, rng, (1, 3, 4), 0.2)
        # (nearer drops on broad leaves, and a drip into a puddle now and then)
        for k in range(int(length * 34)):
            d = secs(rng.uniform(0.004, 0.012))
            drop = band(noise(d * 6, rng), rng.uniform(900, 3500), 7000) * env(d * 6, 0.0005, rng.uniform(0.01, 0.04))
            put(x, drop * rng.uniform(0.3, 1.4), int(rng.integers(m)))
        for k in range(int(length * 1.3)):
            f = rng.uniform(700, 1500)
            dn = secs(0.07)
            drip = np.sin(2 * np.pi * np.cumsum(np.linspace(f, f * 1.7, dn)) / SR) * env(dn, 0.002, 0.06)
            put(x, drip * rng.uniform(0.6, 1.2), int(rng.integers(m)))
        out.append(x)
    return two(*out)


def stream(rng, length=16.0):
    """A small mountain stream over stones: a steady bright wash, a quick light ripple in it, and many small
    bubbles. (The first try had slow loud surges of low water in it, and Dominic heard "lightning"; 2026-11-23.)"""
    n = secs(length + 1.0)
    m = n - secs(1.0)
    out = []
    for side in range(2):
        wash = seamless(band(noise(n, rng), 700, 4200)) * 0.5 + seamless(band(noise(n, rng), 4200, 9000)) * 0.18
        low = seamless(band(noise(n, rng), 250, 700)) * 0.12
        # (the ripple: quick and shallow, never a surge)
        ripple = lowpass(noise(m + 2048, rng), 14)[1024:1024 + m]
        ripple = 1 + 0.18 * ripple / (np.abs(ripple).max() + 1e-9)
        x = (wash + low) * ripple * swell(m, rng, (1, 2, 3), 0.06)
        # (bubbles: many, small, each a short rising blip, a few a little bigger)
        for k in range(int(length * 45)):
            f = rng.uniform(900, 3600)
            bn = secs(rng.uniform(0.008, 0.03))
            blip = np.sin(2 * np.pi * np.cumsum(np.linspace(f, f * rng.uniform(1.15, 1.6), bn)) / SR) * env(bn, 0.001, 0.02)
            put(x, blip * rng.uniform(0.05, 0.35), int(rng.integers(m)))
        out.append(x)
    return two(*out)


def fire(rng, length=14.0):
    n = secs(length + 1.0)
    m = n - secs(1.0)
    # (the flame: a low flutter; the wood: cracks, each a click with a dull knock under it, and spitting between)
    # (the flame is nearly silent: a camp fire is its wood. The first try's low flutter was loud, and Dominic heard
    # "something blow hard on the fire", 2026-11-23.)
    flutter = seamless(band(noise(n, rng), 50, 220)) * swell(m, rng, (7, 11, 17, 23), 0.3) * 0.07
    breath = seamless(band(noise(n, rng), 400, 1500)) * 0.012 * swell(m, rng, (3, 5, 9), 0.3)
    x = flutter + breath
    L = x.copy()
    R = x.copy()
    for k in range(int(length * 11)):
        big = rng.uniform() < 0.08
        cn = secs(0.05 if big else 0.012)
        click = highpass(noise(cn, rng), 1500 if big else 2500) * env(cn, 0.0003, 0.03 if big else 0.006)
        if big:
            click = click * 1.8 + band(noise(cn, rng), 150, 700) * env(cn, 0.001, 0.04) * 1.5
        g = rng.uniform(0.5, 1.6) * (1.5 if big else 1.0) * 0.22
        pan = rng.uniform(-0.5, 0.5)
        at = int(rng.integers(m))
        put(L, click * g * np.sqrt((1 - pan) / 2), at)
        put(R, click * g * np.sqrt((1 + pan) / 2), at)
    # (spitting: a short burst of small clicks close together)
    for k in range(int(length * 0.9)):
        at = int(rng.integers(m))
        for j in range(int(rng.integers(4, 10))):
            cn = secs(0.006)
            c = highpass(noise(cn, rng), 3000) * env(cn, 0.0003, 0.004) * rng.uniform(0.3, 0.9) * 0.22
            put(L, c, at + secs(j * rng.uniform(0.012, 0.03)))
            put(R, c, at + secs(j * rng.uniform(0.012, 0.03)))
    return two(L, R)


# ---------- the calls

def tone(curve, harmonics, breath, rng):
    ph = 2 * np.pi * np.cumsum(curve) / SR
    x = sum(a * np.sin(k * ph + rng.uniform(0, 6.28)) for k, a in harmonics)
    return x + band(noise(len(curve), rng), 400, 2500) * breath


def cuckoo(rng):
    hi = rng.uniform(640, 690)
    lo = hi * 0.8  # (a falling minor third, near enough)
    x = np.zeros(secs(6.0))
    at = 0.0
    for k in range(int(rng.integers(3, 6))):
        for f, d, off in ((hi, 0.17, 0.0), (lo, 0.26, 0.33)):
            n = secs(d)
            e = np.sin(np.pi * np.arange(n) / n) ** 0.6
            note = tone(np.full(n, f), ((1, 1.0), (2, 0.25), (3, 0.06)), 0.01, rng) * e
            a = secs(at + off)
            x[a:a + n] += note
        at += rng.uniform(1.05, 1.2)
    return in_place(lowpass(x, 2200) * 0.5, "valley", rng, far=True)


def woodpecker(rng):
    x = np.zeros(secs(1.4))
    strokes = int(rng.integers(11, 16))
    gap = rng.uniform(0.045, 0.055)
    for k in range(strokes):
        n = secs(0.035)
        t = tt(n)
        knock = (np.sin(2 * np.pi * 950 * t) + 0.6 * np.sin(2 * np.pi * 1630 * t) + 0.5 * band(noise(n, rng), 600, 3000)) * env(n, 0.0005, 0.03)
        a = secs(k * gap * (1 - k * 0.012))
        x[a:a + n] += knock * (1 - 0.6 * k / strokes)
    return in_place(x * 0.6, "wood", rng, far=True)


def jay(rng):
    x = np.zeros(secs(1.6))
    at = 0.0
    for k in range(int(rng.integers(1, 3))):
        n = secs(rng.uniform(0.32, 0.45))
        t = tt(n)
        rasp = band(noise(n, rng), 1500, 5200) * (1 + 0.8 * np.sin(2 * np.pi * rng.uniform(55, 75) * t))
        e = np.clip(t / 0.02, 0, 1) * np.clip((n / SR - t) / 0.12, 0, 1)
        a = secs(at)
        x[a:a + n] += rasp * e
        at += n / SR + rng.uniform(0.12, 0.25)
    return in_place(x * 0.5, "wood", rng, far=True)


def raven(rng):
    x = np.zeros(secs(2.6))
    at = 0.0
    base = rng.uniform(250, 300)
    for k in range(int(rng.integers(2, 4))):
        n = secs(rng.uniform(0.24, 0.33))
        t = tt(n)
        curve = base * (1 + 0.12 * np.sin(np.pi * t / (n / SR)))
        v = tone(curve, ((1, 1.0), (2, 0.8), (3, 0.6), (4, 0.4), (5, 0.25), (6, 0.15)), 0.3, rng)
        v *= 1 + 0.7 * np.sin(2 * np.pi * rng.uniform(42, 55) * t)  # (the croak's rattle)
        e = np.clip(t / 0.03, 0, 1) * np.clip((n / SR - t) / 0.1, 0, 1)
        a = secs(at)
        x[a:a + n] += lowpass(v, 2600) * e
        at += n / SR + rng.uniform(0.22, 0.4)
    return in_place(x * 0.45, "open", rng, far=True)


def owl(rng):
    """A tawny owl's hoot: one long note, a pause, a short one, then the long wavering fall."""
    x = np.zeros(secs(4.6))
    f = rng.uniform(560, 640)

    def hoot(at, dur, waver):
        n = secs(dur)
        t = tt(n)
        curve = f * (1 - 0.05 * t / dur) * (1 + waver * np.sin(2 * np.pi * 9 * t) * np.clip(t / dur * 2 - 0.4, 0, 1))
        e = np.clip(t / 0.08, 0, 1) * np.clip((dur - t) / 0.25, 0, 1)
        a = secs(at)
        x[a:a + n] += tone(curve, ((1, 1.0), (2, 0.12)), 0.015, rng) * e
    hoot(0.0, 0.75, 0.0)
    hoot(1.55, 0.22, 0.0)
    hoot(1.95, 1.5, 0.035)
    return in_place(lowpass(x, 1800) * 0.5, "valley", rng, far=True)


def main():
    SFX.mkdir(parents=True, exist_ok=True)
    made = 0
    # each sound's peak sets how loud it is beside the others (the game's own dB go on top: data/audio.json)
    for k, (name, fn, db) in enumerate((("wind", wind, -8), ("birds", birds, -9), ("night", night, -10), ("rain", rain, -6),
                                        ("stream", stream, -8), ("fire", fire, -5))):
        write_loop(SFX / f"amb_{name}_1.wav", fn(np.random.default_rng(7000 + k)), db)
        made += 1
    for j, (name, fn, db) in enumerate((("cuckoo", cuckoo, -10), ("woodpecker", woodpecker, -10), ("jay", jay, -12),
                                        ("raven", raven, -10), ("owl", owl, -10))):
        for k in range(1, TAKES + 1):
            write(SFX / f"{name}_{k}.wav", fn(np.random.default_rng(8000 + j * 10 + k)), db)
            made += 1
    print(f"wrote {made} forest sounds to {SFX}")


if __name__ == "__main__":
    main()
