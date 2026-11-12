"""Smyana's little music bench: a text score in, sound and MIDI out.

No samples and no recordings: every sound is built from sine waves and noise with numpy,
so everything it makes is ours. It is a sketching tool. The voices only hint at the real
instruments (kaba gaida, kaval, low strings), enough to judge melody, pace and mood.

Score notation, one line per phrase:
    A4/3.2~   the note A4 held 3.2 seconds, "~" lets a slow vibrato grow on it
    'C5       a grace note, a quick flick before the next note
    -/1.5     1.5 seconds of silence
Time is in seconds, not beats, because slow Rhodope song has no steady beat.
"""
import struct
import subprocess
import wave

import numpy as np

SR = 44100
CR = 1000  # control rate for pitch and loudness curves
GRACE = 0.07
NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi_of(name):
    step = NAMES[name[0]]
    rest = name[1:]
    while rest[0] in "#b":
        step += 1 if rest[0] == "#" else -1
        rest = rest[1:]
    return 12 * (int(rest) + 1) + step


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def parse(line, start=0.0, bpm=None):
    """Text phrase -> list of (start, seconds, midi or None, vibrato?).

    With bpm, lengths are beats instead of seconds and a grace note takes its time out of
    the note after it, so the tune stays locked to the drum. "|" may be used to mark bars.
    """
    out, t, owed = [], start, 0.0
    unit = 60 / bpm if bpm else 1.0
    for tok in line.split():
        if tok == "|":
            continue
        if tok.startswith("'"):
            out.append((t, GRACE, midi_of(tok[1:]), False))
            t += GRACE
            owed = GRACE if bpm else 0.0
            continue
        vib = tok.endswith("~")
        name, dur = tok.rstrip("~").split("/")
        dur = float(dur) * unit - owed
        owed = 0.0
        out.append((t, dur, None if name == "-" else midi_of(name), vib))
        t += dur
    return out


def end_of(events):
    return max(s + d for s, d, _, _ in events)


# ---------- curves ----------

def _smooth(x, seconds):
    n = max(3, int(seconds * CR) | 1)
    k = np.hanning(n)
    k /= k.sum()
    pad = n // 2
    return np.convolve(np.pad(x, pad, mode="edge"), k, mode="valid")


def _up(x, total):
    n = int(total * SR)
    return np.interp(np.arange(n) / SR, np.arange(len(x)) / CR, x)


def wander(total, rate, rng):
    """Slow random drift between -1 and 1, so nothing sits perfectly still."""
    pts = rng.uniform(-1, 1, int(total * rate) + 3)
    return _up(np.interp(np.arange(int(total * CR)) / CR, np.arange(len(pts)) / rate, pts), total)


def curves(events, total, glide, attack, release, vib_cents, vib_hz, rng, swell=0.0):
    """Events -> per-sample frequency and loudness (0..1)."""
    n = int(total * CR)
    semis = np.full(n, np.nan)
    gate = np.zeros(n)
    vib = np.zeros(n)
    expr = np.ones(n)
    for s, d, m, v in events:
        if m is None:
            continue
        a, b = int(s * CR), min(n, int((s + d) * CR))
        semis[a:b] = m
        gate[a:b] = 1
        t = np.arange(b - a) / CR
        if v:
            vib[a:b] = np.clip((t - 0.5) / 0.9, 0, 1)
        if swell and d > 1.2:
            x = t / d  # breathe: grow into the long note, then let it go
            expr[a:b] = 1 - swell + swell * np.sin(np.pi * np.clip(x * 1.25, 0, 1)) ** 0.7
    # hold the pitch through silences so glides start from the last note
    idx = np.where(~np.isnan(semis), np.arange(n), 0)
    np.maximum.accumulate(idx, out=idx)
    first = np.argmax(~np.isnan(semis))
    semis = semis[idx]
    semis[:first] = semis[first]
    semis = _smooth(semis, glide)
    up = _smooth(gate, attack)
    down = _smooth(gate, release)
    amp = np.maximum(up * gate, down * (1 - gate)) * _smooth(expr, 0.15)
    amp = _smooth(amp, 0.02)
    tt = np.arange(int(total * SR)) / SR
    rate = vib_hz * (1 + 0.06 * wander(total, 0.7, rng))
    vibrato = vib_cents * _up(_smooth(vib, 0.1), total) * np.sin(2 * np.pi * np.cumsum(rate) / SR)
    drift = 4 * wander(total, 1.5, rng)
    f = hz(_up(semis, total)) * 2 ** ((vibrato + drift) / 1200)
    return f, _up(amp, total), tt


# ---------- tone ----------

def harmonics(f, weights):
    """Sum of sine partials on a moving pitch. weights[k-1] is the level of partial k."""
    phase = 2 * np.pi * np.cumsum(f) / SR
    top = f.max()
    out = np.zeros(len(f))
    for k, w in enumerate(weights, 1):
        if w == 0 or k * top > SR * 0.45:
            continue
        out += w * np.sin(k * phase)
    return out


def reed_weights(n, duty):
    """A narrow pulse: the buzzy, nasal spectrum of a single reed."""
    k = np.arange(1, n + 1)
    return np.sin(np.pi * k * duty) / k


def eq(x, gain):
    """Shape a sound's colour: gain(freqs) -> multiplier. Done in one FFT."""
    n = 1 << (len(x) - 1).bit_length()
    spec = np.fft.rfft(x, n)
    spec *= gain(np.fft.rfftfreq(n, 1 / SR))
    return np.fft.irfft(spec, n)[: len(x)]


def bumps(peaks, lowpass):
    def gain(f):
        g = np.ones_like(f)
        for centre, width, lift in peaks:
            g += lift * np.exp(-(((f - centre) / width) ** 2))
        return g / (1 + (f / lowpass) ** 4)
    return gain


def noise(total, lo, hi, rng):
    x = rng.standard_normal(int(total * SR))
    return eq(x, lambda f: (1 / (1 + (lo / np.maximum(f, 1)) ** 4)) / (1 + (f / hi) ** 4))


# ---------- the voices ----------

def kaval(events, total, rng, breath_level=0.10):
    """Shepherd's flute: nearly a pure tone, with breath around it."""
    f, amp, _ = curves(events, total, glide=0.06, attack=0.18, release=0.35,
                       vib_cents=14, vib_hz=4.8, rng=rng, swell=0.35)
    tone = harmonics(f, [1.0, 0.22, 0.10, 0.03, 0.015])
    breath = noise(total, 1200, 5000, rng) * (0.5 + 0.5 * wander(total, 9, rng) ** 2)
    onset = np.clip(np.gradient(amp) * SR / 6, 0, 1)  # a puff of air as each breath starts
    out = amp ** 1.3 * tone + breath * (breath_level * amp + 0.25 * onset)
    return out * (1 + 0.05 * wander(total, 6, rng))


def gaida_chanter(events, total, rng):
    """The melody pipe: reedy, steady in loudness, ornaments do the phrasing."""
    f, amp, _ = curves(events, total, glide=0.012, attack=0.25, release=0.3,
                       vib_cents=16, vib_hz=5.6, rng=rng)
    tone = harmonics(f, reed_weights(36, 0.17))
    tone = eq(tone, bumps([(600, 300, 1.0), (1900, 500, 1.0)], 4200))
    return amp * tone


def kaba_chanter(events, total, rng):
    """The kaba gaida's melody pipe, played slowly: deep and round, not bright, and never quite still.

    Made for the designed autumn dusk (docs/music-design.md) after "the pipes are over used or just too flat". A piper
    can't play louder or softer, but the bag's pressure wanders as he squeezes and breathes: the note leans a few
    cents sharp and grows a little brighter, then sinks back. That slow movement is what keeps a held note alive. A
    phrase starts flat and rises into tune as the bag fills, and a little air rasps in the reed.
    """
    f, amp, _ = curves(events, total, glide=0.018, attack=0.3, release=0.35,
                       vib_cents=9, vib_hz=4.6, rng=rng)
    n = len(f)
    t = np.arange(n) / SR
    press = wander(total, 0.35, rng)                      # the squeeze on the bag, -1..1, a few times a minute
    # a phrase (a note after a rest of over a second) starts flat and settles
    fill = np.zeros(n)
    prev_end = -10.0
    for a, d, m, _ in events:
        if m is None:
            continue
        if a - prev_end > 1.0:
            k = t >= a
            fill[k] += -35 * np.exp(-(t[k] - a) / 0.35) * (t[k] - a < 3)
        prev_end = a + d
    f = f * 2 ** ((6 * press + fill) / 1200)
    dark = eq(harmonics(f, reed_weights(30, 0.31)), bumps([(470, 220, 1.4), (1150, 350, 0.6), (2300, 600, 0.3)], 3000))
    bright = eq(harmonics(f, reed_weights(30, 0.22)), bumps([(520, 240, 1.0), (1700, 450, 0.9), (2900, 700, 0.4)], 4600))
    mix = 0.5 + 0.35 * press
    tone = (1 - mix) * dark / (np.abs(dark).max() + 1e-9) + mix * bright / (np.abs(bright).max() + 1e-9)
    rasp = noise(total, 900, 3200, rng) * (0.6 + 0.4 * wander(total, 5, rng))
    return amp * (tone + 0.025 * rasp) * (1 + 0.03 * press)


def gaida_drone(midi, start, stop, total, rng, shape=None, dark=2600):
    """The long low pipe. It sags flat as the bag fills, then settles.

    shape: optional (times, levels) to draw the loudness by hand. dark: lower is duller.
    """
    t = np.arange(int(total * SR)) / SR
    sag = -70 * np.exp(-np.clip(t - start, 0, None) / 1.2)
    out = np.zeros(len(t))
    # a second, quieter copy a hair sharp makes the tone shimmer slowly instead of sitting dead still
    for detune, share in ((-1, 1.0), (5, 0.3)):
        cents = sag + detune + 3 * wander(total, 0.8, rng)
        out += share * harmonics(hz(midi) * 2 ** (cents / 1200), reed_weights(48, 0.22))
    out = eq(out, bumps([(420, 160, 1.6), (1150, 300, 0.9)], dark))
    env = np.interp(t, *(shape or ([start, start + 5, stop - 9, stop], [0, 1, 1, 0])))
    return out * env * (1 + 0.04 * wander(total, 2.5, rng))


def strings(chords, total, rng, rise=5.0, fall=5.0):
    """Low strings as a soft pad. chords: (start, stop, [note names], level)."""
    t = np.arange(int(total * SR)) / SR
    out = np.zeros(len(t))
    k = np.arange(1, 25)
    for start, stop, names, level in chords:
        env = np.interp(t, [start, start + rise, stop - fall, stop], [0, level, level, 0])
        for name in names:
            for detune in (-7, 0, 6):
                cents = detune + 5 * wander(total, 0.6, rng)
                out += env * harmonics(hz(midi_of(name)) * 2 ** (cents / 1200), 1 / k ** 1.6)
    return eq(out, bumps([(300, 200, 0.6)], 1400))


def hum(events, total, rng, voices=3):
    """A few men humming the tune together, mouths closed, not quite in tune with each other."""
    out = np.zeros(int(total * SR))
    k = np.arange(1, 13)
    for _ in range(voices):
        f, amp, _ = curves(events, total, glide=0.11, attack=0.45, release=0.7,
                           vib_cents=9, vib_hz=4.4, rng=rng, swell=0.3)
        f = f * 2 ** ((rng.uniform(-9, 9) + 6 * wander(total, 0.9, rng)) / 1200)
        out += amp * harmonics(f, 1 / k ** 2.0)
    return eq(out, bumps([(330, 180, 1.2)], 1100))


def mist(spans, total, rng):
    """Haze: single soft high notes that drift in and out on their own, never together.

    spans: (start, stop, [note names]).
    """
    t = np.arange(int(total * SR)) / SR
    out = np.zeros(len(t))
    for start, stop, names in spans:
        env = np.interp(t, [start, start + 4, stop - 4, stop], [0, 1, 1, 0])
        for name in names:
            swell = np.clip(0.5 + 0.9 * wander(total, 0.12, rng), 0, 1) ** 2
            for detune in (-4, 5):
                f = np.full(len(t), hz(midi_of(name)) * 2 ** (detune / 1200))
                out += env * swell * harmonics(f, [1.0, 0.08])
    return out


def drums(hits, total, rng):
    """The tapan, a big two-headed drum. hits: (time, kind, strength 0..1).

    "boom" is the heavy beater on the low skin, "tick" the thin switch on the high skin,
    "heart" a muffled thud for when the men are hiding.
    """
    n = int(total * SR)
    low, high = np.zeros(n), np.zeros(n)
    for when, kind, strength in hits:
        a = max(0, int(when * SR))
        length = min(n - a, int(1.2 * SR))
        if length <= 0:
            continue
        t = np.arange(length) / SR
        if kind == "tick":
            high[a:a + length] += strength * (rng.standard_normal(length) * np.exp(-t / 0.022)
                                              + 0.4 * np.sin(2 * np.pi * 1150 * t) * np.exp(-t / 0.012))
            continue
        if kind == "boom":
            pitch, ring, slap = 68 + 90 * np.exp(-t / 0.03), 0.24, 0.4
        else:
            pitch, ring, slap = 58 + 30 * np.exp(-t / 0.05), 0.13, 0.0
        body = np.sin(2 * np.pi * np.cumsum(pitch) / SR) * np.exp(-t / ring)
        low[a:a + length] += strength * (body + slap * rng.standard_normal(length) * np.exp(-t / 0.006))
    high = eq(high, lambda f: (1 / (1 + (1800 / np.maximum(f, 1)) ** 4)) / (1 + (f / 7500) ** 4))
    low = eq(low, lambda f: 1 / (1 + (f / 1500) ** 2))
    return low + 0.25 * high


def tambura(events, total, rng):
    """Long-necked lute with doubled strings: a bright pluck that dies away."""
    n = int(total * SR)
    out = np.zeros(n)
    for start, dur, midi, _ in events:
        if midi is None:
            continue
        a = int(start * SR)
        length = min(n - a, int(min(max(dur * 1.5, 0.5), 3.0) * SR))
        if length <= 0:
            continue
        t = np.arange(length) / SR
        note = np.zeros(length)
        for detune in (-5, 6):  # the two strings of a pair are never quite together
            f = hz(midi) * 2 ** (detune / 1200)
            for k in range(1, 21):
                if k * f > SR * 0.45:
                    break
                note += k ** -0.9 * np.exp(-t * (1.2 + 0.5 * k)) * np.sin(2 * np.pi * k * f * t + rng.uniform(0, 6.28))
        note *= np.minimum(1, t / 0.002) * np.clip((length / SR - t) / 0.05, 0, 1)
        out[a:a + length] += note * rng.uniform(0.8, 1.0)
    return eq(out, bumps([(900, 400, 0.8), (2500, 800, 0.6)], 6000))


def gadulka(events, total, rng):
    """Bowed fiddle held on the knee: hoarse, close, with a quick wide vibrato."""
    f, amp, _ = curves(events, total, glide=0.04, attack=0.09, release=0.18,
                       vib_cents=20, vib_hz=5.6, rng=rng, swell=0.25)
    tone = harmonics(f, 1 / np.arange(1, 31))
    tone = eq(tone, bumps([(520, 200, 1.5), (1400, 400, 1.2), (2700, 600, 0.8)], 5000))
    scrape = noise(total, 2000, 6000, rng) * 0.04  # rosin on the string
    return amp * (tone + scrape * np.abs(tone).max())


VOWELS = {
    "ah": ([(850, 160, 3.0), (1250, 200, 2.5), (2900, 400, 2.0)], 4500),   # hard and bright
    "oh": ([(450, 150, 3.0), (800, 180, 2.0), (2600, 400, 0.6)], 2600),    # rounder, darker, further off
}


def voice(events, total, rng, singers=2, vowel="ah"):
    """Open-throated singing, a few singers as one. "ah" is the bright village sound."""
    out = np.zeros(int(total * SR))
    k = np.arange(1, 31)
    for _ in range(singers):
        f, amp, _ = curves(events, total, glide=0.07, attack=0.12, release=0.4,
                           vib_cents=5, vib_hz=5.0, rng=rng, swell=0.15)
        f = f * 2 ** ((rng.uniform(-7, 7) + 5 * wander(total, 1.1, rng)) / 1200)
        out += amp * harmonics(f, 1 / k ** 1.1)
    return eq(out, bumps(*VOWELS[vowel]))


def bells(hits, total, rng):
    """Sheep and goat bells, far off. hits: (time, midi, strength). Dull clanks, not chimes."""
    n = int(total * SR)
    out = np.zeros(n)
    for when, midi, strength in hits:
        a = max(0, int(when * SR))
        length = min(n - a, int(0.9 * SR))
        if length <= 0:
            continue
        t = np.arange(length) / SR
        for ratio, lvl, ring in ((1, 1.0, 0.22), (2.09, 0.6, 0.15), (2.83, 0.5, 0.11), (5.3, 0.25, 0.06)):
            out[a:a + length] += strength * lvl * np.sin(2 * np.pi * hz(midi) * ratio * t) * np.exp(-t / ring)
    return out


def overtones(fundamental, partials, start, stop, total, rng):
    """The natural overtones of one low note, each fading in and out by itself.

    These are not notes of any scale: the 7th and 11th fall between the keys of a piano,
    which is why they sound old and strange. Throat singers and long pipes make them.
    """
    t = np.arange(int(total * SR)) / SR
    env = np.interp(t, [start, start + 6, stop - 6, stop], [0, 1, 1, 0])
    out = np.zeros(len(t))
    for k in partials:
        swell = np.clip(0.35 + 1.0 * wander(total, 0.1, rng), 0, 1) ** 2
        f = np.full(len(t), fundamental * k) * 2 ** (3 * wander(total, 0.3, rng) / 1200)
        out += env * swell * harmonics(f, [1.0]) / k ** 0.5
    return out


def struck(hits, total, rng):
    """Something big struck once and left to ring: bronze, or a stone slab. hits: (time, midi, strength)."""
    n = int(total * SR)
    out = np.zeros(n)
    for when, midi, strength in hits:
        a = max(0, int(when * SR))
        length = min(n - a, int(14 * SR))
        t = np.arange(length) / SR
        for ratio, lvl, ring in ((1, 1.0, 4.5), (1.48, 0.5, 3.5), (2.41, 0.6, 2.4), (3.07, 0.3, 1.6), (4.6, 0.25, 0.8)):
            beat = 1 + 0.3 * np.sin(2 * np.pi * rng.uniform(0.3, 0.9) * t)   # the slow wobble of a big bell
            out[a:a + length] += strength * lvl * beat * np.sin(2 * np.pi * hz(midi) * ratio * t) * np.exp(-t / ring)
        out[a:a + length] *= np.minimum(1, np.arange(length) / (0.004 * SR)) if a else 1
    return out


def zurna(events, total, rng):
    """The Ottomans' shrill reed pipe: a hard, bright buzz that cuts across a valley. Theirs only."""
    f, amp, _ = curves(events, total, glide=0.02, attack=0.03, release=0.08,
                       vib_cents=26, vib_hz=6.4, rng=rng)
    tone = harmonics(f, reed_weights(40, 0.08))
    tone = eq(tone, bumps([(1500, 400, 2.5), (2900, 700, 2.0)], 6500))
    return amp * tone * (1 + 0.06 * wander(total, 7, rng))


def shift(events, semitones):
    return [(s, d, None if m is None else m + semitones, v) for s, d, m, v in events]


def wind(total, rng):
    """A little air in the trees. Left and right are different."""
    def side():
        gusts = 0.55 + 0.45 * wander(total, 0.25, rng)
        return noise(total, 150, 700, rng) * gusts + 0.3 * noise(total, 2500, 7000, rng) * gusts ** 3
    return np.stack([side(), side()])


# ---------- space and output ----------

def pan(x, where):
    """where: -1 left .. 1 right. Returns 2 x n."""
    a = (where + 1) * np.pi / 4
    return np.stack([x * np.cos(a), x * np.sin(a)])


def reverb(stereo, seconds, rng, predelay=0.03, dark=3500):
    """A valley's worth of echo: decaying noise, duller as it dies."""
    n = int(seconds * 1.3 * SR)
    t = np.arange(n) / SR
    out = []
    for ch in stereo:
        ir = rng.standard_normal(n) * 10 ** (-3 * t / seconds)
        ir = eq(ir, lambda f: 1 / (1 + (f / dark) ** 2))
        ir = np.concatenate([np.zeros(int(predelay * SR)), ir])
        size = 1 << (len(ch) + len(ir)).bit_length()
        wet = np.fft.irfft(np.fft.rfft(ch, size) * np.fft.rfft(ir, size), size)[: len(ch)]
        out.append(wet / np.sqrt(np.sum(ir ** 2)))
    return np.stack(out)


def level(x, db):
    """Set a part's loudness (RMS of its loud half) so the mix is written in dB."""
    mono = x if x.ndim == 1 else x.mean(axis=0)
    loud = np.sort(np.abs(mono))[len(mono) // 2:]
    return x * (10 ** (db / 20) / (np.sqrt(np.mean(loud ** 2)) + 1e-12))


def mixdown(parts, rng, echo=4.5, predelay=0.03, dark=3500, wet=1.0):
    """parts: (sound, loudness in dB, left-right -1..1, how much direct, how much echo)."""
    dry = send = 0
    for sound, db, where, direct, far in parts:
        sound = level(sound, db)
        st = sound if sound.ndim == 2 else pan(sound, where)
        dry = dry + direct * st
        send = send + far * st
    return dry + wet * reverb(send, echo, rng, predelay, dark)


def fold(stereo, seconds):
    """Make a loop of things that happen (notes, drum hits): what rings on past the end is laid over the start."""
    n = int(round(seconds * SR))
    out, extra = stereo[:, :n].copy(), stereo[:, n:]
    out[:, :extra.shape[1]] += extra
    return out


def seam(stereo, seconds, cross=4.0):
    """Make a loop of things that never stop (a drone, the wind): the end is faded across into the start."""
    n = int(round(seconds * SR))
    x = min(int(cross * SR), stereo.shape[1] - n)
    out = stereo[:, :n].copy()
    a = np.linspace(0, np.pi / 2, x)
    out[:, :x] = out[:, :x] * np.sin(a) + stereo[:, n:n + x] * np.cos(a)
    return out


def loudness(stereo):
    """How loud a track is where it is playing, in dB: the loudest third of its 0.4 s stretches."""
    mono = stereo.mean(axis=0)
    w = int(0.4 * SR)
    power = np.sort((mono[: len(mono) // w * w].reshape(-1, w) ** 2).mean(axis=1))
    return 10 * np.log10(power[-max(1, len(power) // 3):].mean() + 1e-12)


def finish(name, stereo, fade_in=0.5, fade_out=4.0, midi=None):
    """Write out/<name>.wav, .mp3 and .ogg (and .mid when given tracks)."""
    import pathlib
    out = pathlib.Path(__file__).resolve().parent / "out"
    out.mkdir(exist_ok=True)
    write_wav(out / f"{name}.wav", stereo, fade_in, fade_out)
    encode(out / f"{name}.wav", out / f"{name}.mp3", "-b:a", "192k")
    encode(out / f"{name}.wav", out / f"{name}.ogg", "-c:a", "libopus", "-b:a", "72k")
    if midi:
        write_midi(out / f"{name}.mid", midi)
    print("wrote", name)


def write_wav(path, stereo, fade_in=0.5, fade_out=4.0, loud=None):
    """fade_in and fade_out of 0 leave the ends alone (a loop). loud: the loudness() to bring it to, in dB,
    so tracks made apart sit at the right levels beside each other; without it the peak is brought to the top."""
    n = stereo.shape[1]
    t = np.arange(n) / SR
    if fade_in:
        stereo = stereo * np.clip(t / fade_in, 0, 1)
    if fade_out:
        stereo = stereo * np.clip((t[-1] - t) / fade_out, 0, 1)
    if fade_in or fade_out:  # (a loop is left whole: this would put a click at its seam)
        stereo = np.stack([eq(ch, lambda f: 1 / (1 + (30 / np.maximum(f, 1)) ** 4)) for ch in stereo])  # no rumble
    top = 10 ** (-1.5 / 20)
    if loud is None:
        stereo = stereo / np.abs(stereo).max() * top
    else:
        stereo = stereo * 10 ** ((loud - loudness(stereo)) / 20)
        stereo = stereo * min(1.0, top / np.abs(stereo).max())
    pcm = (stereo.T * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def encode(wav, out, *args):
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), *args, str(out)], check=True)


# ---------- MIDI, so the same notes open in any music program ----------

def _varlen(n):
    out = [n & 0x7F]
    while n > 0x7F:
        n >>= 7
        out.append((n & 0x7F) | 0x80)
    return bytes(reversed(out))


def write_midi(path, tracks):
    """tracks: (name, General MIDI program, events). 60 bpm, so one beat is one second."""
    tpq = 480
    chunks = []
    for ch, (name, program, events) in enumerate(tracks):
        msgs = [(0, 0, bytes([0xC0 | ch, program]))]
        for s, d, m, _ in events:
            if m is None:
                continue
            msgs.append((round(s * tpq), 1, bytes([0x90 | ch, m, 80])))
            msgs.append((round((s + d) * tpq), 0, bytes([0x80 | ch, m, 0])))
        msgs.sort(key=lambda x: (x[0], x[1]))
        label = name.encode()
        data = b"\x00\xff\x03" + _varlen(len(label)) + label
        if ch == 0:
            data += b"\x00\xff\x51\x03" + (1000000).to_bytes(3, "big")
        now = 0
        for tick, _, msg in msgs:
            data += _varlen(tick - now) + msg
            now = tick
        data += b"\x00\xff\x2f\x00"
        chunks.append(b"MTrk" + struct.pack(">I", len(data)) + data)
    with open(path, "wb") as f:
        f.write(b"MThd" + struct.pack(">IHHH", 6, 1, len(chunks), tpq) + b"".join(chunks))
