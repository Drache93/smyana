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


def parse(line, start=0.0):
    """Text phrase -> list of (start, seconds, midi or None, vibrato?)."""
    out, t = [], start
    for tok in line.split():
        if tok.startswith("'"):
            out.append((t, GRACE, midi_of(tok[1:]), False))
            t += GRACE
            continue
        vib = tok.endswith("~")
        name, dur = tok.rstrip("~").split("/")
        dur = float(dur)
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

def kaval(events, total, rng):
    """Shepherd's flute: nearly a pure tone, with breath around it."""
    f, amp, _ = curves(events, total, glide=0.06, attack=0.18, release=0.35,
                       vib_cents=14, vib_hz=4.8, rng=rng, swell=0.35)
    tone = harmonics(f, [1.0, 0.22, 0.10, 0.03, 0.015])
    breath = noise(total, 1200, 5000, rng) * (0.5 + 0.5 * wander(total, 9, rng) ** 2)
    onset = np.clip(np.gradient(amp) * SR / 6, 0, 1)  # a puff of air as each breath starts
    out = amp ** 1.3 * tone + breath * (0.10 * amp + 0.25 * onset)
    return out * (1 + 0.05 * wander(total, 6, rng))


def gaida_chanter(events, total, rng):
    """The melody pipe: reedy, steady in loudness, ornaments do the phrasing."""
    f, amp, _ = curves(events, total, glide=0.012, attack=0.25, release=0.3,
                       vib_cents=16, vib_hz=5.6, rng=rng)
    tone = harmonics(f, reed_weights(36, 0.17))
    tone = eq(tone, bumps([(600, 300, 1.0), (1900, 500, 1.0)], 4200))
    return amp * tone


def gaida_drone(midi, start, stop, total, rng):
    """The long low pipe. It sags flat as the bag fills, then settles."""
    t = np.arange(int(total * SR)) / SR
    sag = -70 * np.exp(-np.clip(t - start, 0, None) / 1.2)
    out = np.zeros(len(t))
    # a second, quieter copy a hair sharp makes the tone shimmer slowly instead of sitting dead still
    for detune, share in ((-1, 1.0), (5, 0.3)):
        cents = sag + detune + 3 * wander(total, 0.8, rng)
        out += share * harmonics(hz(midi) * 2 ** (cents / 1200), reed_weights(48, 0.22))
    out = eq(out, bumps([(420, 160, 1.6), (1150, 300, 0.9)], 2600))
    env = np.interp(t, [start, start + 5, stop - 9, stop], [0, 1, 1, 0])
    return out * env * (1 + 0.04 * wander(total, 2.5, rng))


def strings(chords, total, rng):
    """Low strings as a soft pad. chords: (start, stop, [note names], level)."""
    t = np.arange(int(total * SR)) / SR
    out = np.zeros(len(t))
    k = np.arange(1, 25)
    for start, stop, names, level in chords:
        env = np.interp(t, [start, start + 5, stop - 5, stop], [0, level, level, 0])
        for name in names:
            for detune in (-7, 0, 6):
                cents = detune + 5 * wander(total, 0.6, rng)
                out += env * harmonics(hz(midi_of(name)) * 2 ** (cents / 1200), 1 / k ** 1.6)
    return eq(out, bumps([(300, 200, 0.6)], 1400))


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


def write_wav(path, stereo, fade_in=0.5, fade_out=4.0):
    n = stereo.shape[1]
    t = np.arange(n) / SR
    stereo = stereo * np.clip(t / fade_in, 0, 1) * np.clip((t[-1] - t) / fade_out, 0, 1)
    stereo = np.stack([eq(ch, lambda f: 1 / (1 + (30 / np.maximum(f, 1)) ** 4)) for ch in stereo])  # no rumble
    stereo = stereo / np.abs(stereo).max() * 10 ** (-1.5 / 20)
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
