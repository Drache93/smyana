"""The flintlock's sounds, built from noise and sine waves with numpy: no samples, no recordings, all ours.

A shot is two sounds, so the game can put the hang-fire between them (src/smyana/guns.lobster):

    pan_N        the lock and the flash in the pan: the cock snaps down, the flint scrapes the frizzen, the priming
                 goes off with a fizzing hiss
    boom_S_N     the charge going off and the place answering it, one set for each kind of place S:
                   wood   close fir or beech wood: a thick, short, muffled roll, no clear echo
                   valley a wooded valley: one slap back off the far side, then a roll
                   gorge  rock walls close on both sides: hard echoes back and forth, a long ring
                   open   the bare ridge: dry, and a long way off, low, the valleys rolling it back
    far_S_N      the same shot heard from a long way off: no crack, only the low boom and the place
    cock_N, pour_N, rod_N, ram_N   the reload: half and full cock, powder down the barrel, the rod drawn and
                 put back, the ball rammed home

Run from the repo:  python3 sound/flintlock.py [listen]   (writes assets/audio/sfx/; "listen" also writes
sound/out/ with one reel of every sound in turn, as MP3, for listening). The same code always gives the same
sound. Needs numpy (and ffmpeg for the reel).
"""
import pathlib
import subprocess
import sys
import wave

import numpy as np

SR = 22050  # Lobster's own rate: anything else is converted when it's loaded
ROOT = pathlib.Path(__file__).resolve().parent.parent
SFX = ROOT / "assets" / "audio" / "sfx"
TAKES = 3


# ---------- tools

def secs(s):
    return int(round(s * SR))


def tt(n):
    return np.arange(n) / SR


def eq(x, gain):
    """A filter as a gain curve over frequency: gain(f) -> factor."""
    size = 1 << (len(x) + 1).bit_length()
    spec = np.fft.rfft(x, size)
    f = np.fft.rfftfreq(size, 1 / SR)
    return np.fft.irfft(spec * gain(f), size)[: len(x)]


def lowpass(x, cut, order=2):
    return eq(x, lambda f: 1 / np.sqrt(1 + (f / cut) ** (2 * order)))


def highpass(x, cut, order=2):
    return eq(x, lambda f: 1 / np.sqrt(1 + (cut / np.maximum(f, 1e-3)) ** (2 * order)))


def band(x, lo, hi, order=2):
    return highpass(lowpass(x, hi, order), lo, order)


def noise(n, rng):
    return rng.standard_normal(n)


def env(n, attack, decay):
    """Rises in `attack` seconds, then falls away exponentially, 60 dB in `decay` seconds."""
    t = tt(n)
    up = np.clip(t / max(attack, 1e-4), 0, 1)
    down = 10 ** (-3 * np.maximum(t - attack, 0) / decay)
    return up * down


def place(dst, src, at):
    """Adds src into dst at sample `at` (either may be mono or stereo)."""
    a = max(0, at)
    n = min(dst.shape[-1] - a, src.shape[-1])
    if n > 0:
        dst[..., a:a + n] += src[..., :n]


def modal(n, partials, rng):
    """A struck bit of steel: partials (Hz, level, decay seconds), each a damped sine, a little detuned."""
    out = np.zeros(n)
    t = tt(n)
    for hz, lvl, dec in partials:
        f = hz * rng.uniform(0.97, 1.03)
        out += lvl * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * 10 ** (-3 * t / dec)
    return out


def convolve(x, ir):
    size = 1 << (len(x) + len(ir)).bit_length()
    return np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x) + len(ir) - 1]


def soft(x, drive):
    return np.tanh(x * drive) / np.tanh(drive)


# ---------- the shot itself, dry, a metre from the muzzle

def charge(rng, far=False):
    """The main charge: a crack (the ball breaking the sound barrier, and the gas leaving), a deep low thump
    (black powder is slow and boomy, much lower than a modern rifle), and the hot gas still roaring out after."""
    n = secs(0.9)
    t = tt(n)
    out = np.zeros(n)
    if not far:
        crack = highpass(noise(secs(0.012), rng), 1800) * env(secs(0.012), 0.0004, 0.006)
        place(out, crack * 1.4, 0)
    # the blast: broadband noise, very fast up, about a tenth of a second down, its top softened
    blast = lowpass(noise(n, rng), rng.uniform(2600, 3400)) * env(n, 0.0015, rng.uniform(0.16, 0.22))
    out += blast * 1.0
    # the thump: a sine falling from ~110 to ~45 Hz as the pressure wave spreads
    f0 = rng.uniform(95, 120)
    f = 45 + (f0 - 45) * np.exp(-t / 0.05)
    phase = 2 * np.pi * np.cumsum(f) / SR
    out += np.sin(phase) * env(n, 0.002, rng.uniform(0.32, 0.42)) * 1.3
    # the gas: a darker roar, rising a little after the blast and dying over half a second
    gas = lowpass(noise(n, rng), 900) * env(n, 0.03, 0.5) * 0.35
    out += gas
    out = soft(out, 1.8)
    if far:
        # a long way off the air takes the top off, and a little of the middle
        out = lowpass(out, 700, 2) * 1.6
    return out


def lock(rng):
    """The lock and the pan: the cock snaps down onto the frizzen (two hard metal clicks a few ms apart: the flint
    striking, the frizzen flying open), the scrape of flint on steel, then the priming flashing off: a fizzing
    hiss, quick up, a tenth of a second or so, with a soft puff under it."""
    n = secs(0.45)
    out = np.zeros(n)
    click = modal(secs(0.06), [(2900, 1.0, 0.025), (4700, 0.7, 0.018), (6900, 0.5, 0.012), (1400, 0.4, 0.03)], rng)
    click *= env(secs(0.06), 0.0003, 0.03)
    place(out, click * 0.6, 0)
    place(out, click[::-1][::-1] * 0.45, secs(rng.uniform(0.004, 0.008)))
    scrape = band(noise(secs(0.02), rng), 3500, 9000) * env(secs(0.02), 0.001, 0.015)
    place(out, scrape * 0.5, secs(0.002))
    at = secs(rng.uniform(0.028, 0.045))  # (the sparks land in the pan)
    m = secs(0.32)
    hiss = band(noise(m, rng), 1200, 7500) * env(m, 0.006, rng.uniform(0.11, 0.16))
    # a powder flash crackles: grains going off unevenly
    grain = (rng.random(m) < 0.004) * rng.uniform(0.5, 1.5, m)
    grain = band(convolve(grain, np.exp(-tt(secs(0.003)) / 0.0006)), 2000, 9000)[:m] * env(m, 0.004, 0.12)
    puff = lowpass(noise(m, rng), 400) * env(m, 0.008, 0.1)
    place(out, hiss * 0.55 + grain * 0.8 + puff * 0.7, at)
    return soft(out, 1.3)


# ---------- the reload's small sounds

def cock(rng):
    """Half cock or full cock: the tumbler's two clicks."""
    n = secs(0.25)
    out = np.zeros(n)
    c = modal(secs(0.05), [(2400, 1.0, 0.02), (4100, 0.6, 0.015), (5800, 0.4, 0.01)], rng) * env(secs(0.05), 0.0003, 0.025)
    place(out, c * 0.7, 0)
    place(out, c * 0.9, secs(rng.uniform(0.07, 0.11)))
    return out


def pour(rng):
    """Powder down the barrel from the horn: a short dry rush, like sand, narrowed by the bore."""
    n = secs(0.7)
    t = tt(n)
    dur = rng.uniform(0.35, 0.5)
    shape = np.clip(t / 0.05, 0, 1) * np.clip((dur - t) / 0.1, 0, 1)
    grains = (rng.random(n) < 0.08) * rng.uniform(0.3, 1.0, n)
    x = band(convolve(grains, np.exp(-tt(secs(0.002)) / 0.0004))[:n], 1500, 6000) * shape
    x += band(noise(n, rng), 2500, 5000) * shape * 0.15
    return x * 0.5


def rod(rng):
    """The ramrod drawn out of its pipes under the barrel (or put back): a long metal-on-wood scrape, ending in
    a click as it clears."""
    n = secs(0.8)
    t = tt(n)
    dur = rng.uniform(0.45, 0.6)
    shape = np.clip(t / 0.04, 0, 1) * np.clip((dur - t) / 0.05, 0, 1)
    # the rod's ring sweeps a little as it slides
    ring = modal(n, [(1900, 0.5, 0.6), (3300, 0.3, 0.4)], rng) * 0.25
    x = (band(noise(n, rng), 1500, 5000) * (0.6 + 0.4 * np.sin(2 * np.pi * 7 * t)) + ring) * shape * 0.5
    tick = modal(secs(0.05), [(3100, 1.0, 0.02), (5200, 0.5, 0.012)], rng) * env(secs(0.05), 0.0003, 0.02)
    place(x, tick * 0.5, secs(dur))
    return x


def ram(rng):
    """The ball rammed home: two or three strokes down the bore, each a dull thud with the rod ringing over it,
    the last one firmer."""
    strokes = int(rng.integers(2, 4))
    n = secs(0.5 + 0.38 * strokes)
    out = np.zeros(n)
    at = 0.02
    for k in range(strokes):
        m = secs(0.35)
        thud = lowpass(noise(m, rng), 500) * env(m, 0.002, 0.06)
        ring = modal(m, [(1250, 0.5, 0.18), (2350, 0.4, 0.12), (3900, 0.25, 0.08)], rng)
        # the rod rushing down the bore before it hits
        slide = band(noise(secs(0.12), rng), 2000, 6000) * np.linspace(0, 1, secs(0.12)) ** 2 * 0.12
        place(out, slide, secs(at))
        hit = (thud * 1.0 + ring * 0.6) * (1.3 if k == strokes - 1 else rng.uniform(0.7, 1.0))
        place(out, hit, secs(at + 0.12))
        at += rng.uniform(0.32, 0.42)
    return out * 0.5


# ---------- places: what the woods and the rock give back

def tail(n, rng, decay_lo, decay_hi, dark):
    """A diffuse tail: noise that dies away, the lows lasting longer than the highs, darker as it goes."""
    t = tt(n)
    lo = lowpass(noise(n, rng), 300) * 10 ** (-3 * t / decay_lo)
    hi = highpass(noise(n, rng), 300) * 10 ** (-3 * t / decay_hi)
    x = lo * 1.4 + hi
    # darker as it dies: split into two halves by time and filter the later harder
    k = np.clip(t / (decay_lo * 0.6), 0, 1)
    return lowpass(x, dark) * (1 - k) + lowpass(x, dark * 0.35) * k


def slap(dry, delay, gain, cut, n, rng):
    """One echo off something big: the shot again, later, quieter, duller, and smeared a little (rock and slope
    aren't a mirror: the echo comes back off a whole face, over a few hundredths of a second)."""
    out = np.zeros(n)
    smear = noise(secs(0.03), rng) * env(secs(0.03), 0.004, 0.025)
    e = lowpass(convolve(dry, smear), cut, 2)
    e = e / (np.abs(e).max() + 1e-12) * np.abs(dry).max() * gain
    place(out, e, secs(delay))
    return out


PLACES = {
    # the wood: trunks and boughs all round scatter it into a thick, short roll; the leaves eat the top
    "wood": dict(direct=1.0, wet=0.55, pre=0.012, decay=(1.6, 0.7), dark=1800, slaps=[], roll=None, length=2.6),
    # a wooded valley: the far side throws it back once, about 140 m away, then it rolls up and down the valley
    "valley": dict(direct=1.0, wet=0.4, pre=0.02, decay=(2.4, 0.9), dark=2200,
                   slaps=[(0.82, 0.38, 1400), (1.35, 0.16, 900)], roll=(1.0, 2.2, 0.18, 500), length=4.2),
    # the gorge: rock both sides, 30 to 50 m: hard echoes back and forth, then a long ring
    "gorge": dict(direct=1.0, wet=0.5, pre=0.008, decay=(3.0, 1.6), dark=3200,
                  slaps=[(0.19, 0.55, 3500), (0.31, 0.45, 3000), (0.42, 0.32, 2600), (0.56, 0.26, 2200),
                         (0.71, 0.18, 1800), (0.88, 0.12, 1500), (1.1, 0.08, 1200)], roll=None, length=4.4),
    # the open ridge: nothing near to give it back, so dry, then a long way off the valleys roll it back, low
    "open": dict(direct=1.0, wet=0.12, pre=0.03, decay=(0.9, 0.4), dark=1500,
                 slaps=[(1.9, 0.1, 500)], roll=(1.6, 4.5, 0.22, 380), length=6.0),
}


def in_place(dry, name, rng, far=False):
    """The dry shot in this place, as stereo: the direct sound, the place's tail, its slaps (each from one side
    or the other), and far off a roll like thunder."""
    p = PLACES[name]
    n = secs(p["length"])
    L = np.zeros(n)
    R = np.zeros(n)
    direct = p["direct"] * (0.35 if far else 1.0)
    place(L, dry * direct, 0)
    place(R, dry * direct, 0)
    wet = p["wet"] * (1.8 if far else 1.0)
    for ch in (L, R):
        ir = tail(secs(p["decay"][0] * 1.2), rng, p["decay"][0], p["decay"][1], p["dark"])
        ir = np.concatenate([np.zeros(secs(p["pre"])), ir])
        w = convolve(dry, ir)[:n]
        w = w / np.sqrt(np.sum(ir ** 2)) * wet
        place(ch, w, 0)
    for k, (d, g, cut) in enumerate(p["slaps"]):
        d *= rng.uniform(0.9, 1.1)
        side = rng.uniform(0.2, 1.0) * (1 if k % 2 == 0 else -1)  # (back and forth between the walls)
        e = slap(dry, d, g * (1.2 if far else 1.0), cut, n, rng)
        L += e * (1 - max(side, 0) * 0.7)
        R += e * (1 + min(side, 0) * 0.7)
    if p["roll"]:
        start, dur, g, cut = p["roll"]
        m = secs(dur)
        t = tt(m)
        # many small late echoes off far slopes, smeared together: thunder's roll, swelling and dying away
        hits = (rng.random(m) < 0.0016) * rng.uniform(0.2, 1.0, m)
        body = lowpass(convolve(hits, lowpass(dry, cut, 2)[: secs(0.4)])[:m], cut, 2)
        body *= np.sin(np.pi * np.minimum(t / (dur * 0.35), 1) / 2) * np.clip((dur - t) / (dur * 0.6), 0, 1) ** 1.5
        body = body / (np.abs(body).max() + 1e-12) * np.abs(dry).max() * g * (1.4 if far else 1.0)
        lean = rng.uniform(-0.5, 0.5)
        place(L, body * (1 - lean), secs(start))
        place(R, body * (1 + lean), secs(start))
    st = np.stack([L, R])
    fade = np.clip((n - np.arange(n)) / secs(0.4), 0, 1)
    return st * fade


# ---------- writing

def write(path, x, peak_db):
    """A WAV at that peak, its silent end cut off (below -66 dB of the peak). A mono sound stays mono: the game
    pans it; a place's echoes are written in stereo."""
    st = x if x.ndim == 2 else x[None, :]
    st = st - st.mean(axis=1, keepdims=True)
    st = st / (np.abs(st).max() + 1e-12) * 10 ** (peak_db / 20)
    loud = np.nonzero(np.abs(st).max(axis=0) > 10 ** ((peak_db - 66) / 20))[0]
    end = min(st.shape[1], loud[-1] + secs(0.05)) if len(loud) else st.shape[1]
    st = st[:, :end] * np.clip((end - np.arange(end)) / secs(0.05), 0, 1)
    pcm = (np.clip(st, -1, 1).T * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(st.shape[0])
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    return st


def main():
    SFX.mkdir(parents=True, exist_ok=True)
    reel = []
    gap = np.zeros((2, secs(0.6)))
    # each sound's peak sets how loud it is beside the others (the game's own dB go on top: data/audio.json)
    for k in range(1, TAKES + 1):
        rng = np.random.default_rng(1000 + k)
        reel += [write(SFX / f"pan_{k}.wav", lock(rng), -9), gap]
        for name in PLACES:
            rng = np.random.default_rng(2000 + k * 10 + list(PLACES).index(name))
            dry = charge(rng)
            reel += [write(SFX / f"boom_{name}_{k}.wav", in_place(dry, name, rng), -1), gap]
            rng = np.random.default_rng(3000 + k * 10 + list(PLACES).index(name))
            reel += [write(SFX / f"far_{name}_{k}.wav", in_place(charge(rng, far=True), name, rng, far=True), -8), gap]
        for what, fn, db in (("cock", cock, -14), ("pour", pour, -18), ("rod", rod, -16), ("ram", ram, -12)):
            rng = np.random.default_rng(4000 + k * 10 + len(what))
            reel += [write(SFX / f"{what}_{k}.wav", fn(rng), db), gap]
    print(f"wrote {len(list(SFX.glob('*.wav')))} sounds to {SFX.relative_to(ROOT)}")
    if "listen" in sys.argv:
        listen()


def listen():
    """sound/out/: a reel for each place (a man fires three times, the hang-fire between lock and charge as the
    game plays it), and the reload in order, as the game spaces it."""
    out = ROOT / "sound" / "out"
    out.mkdir(exist_ok=True)

    def read(name):
        with wave.open(str(SFX / f"{name}.wav")) as w:
            ch = w.getnchannels()
            a = np.frombuffer(w.readframes(w.getnframes()), "<i2").reshape(-1, ch).T / 32767
        return a if ch == 2 else np.concatenate([a, a])

    def mp3(name, st):
        tmp = out / f"{name}.wav"
        write(tmp, st, -1)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(tmp), "-b:a", "160k", str(out / f"{name}.mp3")], check=True)
        tmp.unlink()

    rng = np.random.default_rng(7)
    for name in PLACES:
        n = secs(3 * 7.0 + 8)
        st = np.zeros((2, n))
        at = 0.5
        for k in range(1, TAKES + 1):
            place(st, read(f"pan_{k}") * 10 ** (-4 / 20), secs(at))
            place(st, read(f"boom_{name}_{k}"), secs(at + rng.uniform(0.07, 0.16)))
            at += 7.0
        place(st, read(f"far_{name}_1") * 10 ** (-6 / 20), secs(at))
        mp3(f"shots_{name}", st)
    # the reload: half cock, prime, powder, rod out, ram, rod back, full cock (about 20 s, as data/guns.json has it)
    n = secs(22)
    st = np.zeros((2, n))
    for at, name in ((0.3, "cock_1"), (2.0, "pour_2"), (5.0, "pour_1"), (8.0, "rod_1"), (9.6, "ram_1"),
                     (12.5, "ram_2"), (15.0, "rod_2"), (18.5, "cock_2")):
        place(st, read(name), secs(at))
    mp3("reload", st)
    print("wrote the reels to sound/out/")


if __name__ == "__main__":
    main()
