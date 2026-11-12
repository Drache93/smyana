"""Measure the rendered tracks, since Claude can't hear them: python3 music/measure.py [name ...]

For each WAV in music/out/ (or the ones named): its length, loudness (synth.loudness) and peak; the notes that sound
most, by how much of the track's energy sits on each (so a wrong note or key shows); how much of the energy is in
600-1300 Hz and how steady that band is (a long, pure, steady tone there is what Dominic heard as "emergency alarm
on phone"); and for a loop, the jump across its seam beside the track's ordinary sample-to-sample movement.
"""
import pathlib
import sys
import wave

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import synth as s  # noqa: E402

OUT = pathlib.Path(__file__).resolve().parent / "out"
NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def read(path):
    with wave.open(str(path)) as w:
        x = np.frombuffer(w.readframes(w.getnframes()), "<i2").reshape(-1, 2).T / 32768
    return x


def measure(path, loop):
    x = read(path)
    mono = x.mean(axis=0)
    spec = np.abs(np.fft.rfft(mono)) ** 2
    freq = np.fft.rfftfreq(len(mono), 1 / s.SR)
    keep = (freq > 100) & (freq < 1400)
    pitch = np.round(69 + 12 * np.log2(freq[keep] / 440)).astype(int) % 12
    by_note = np.bincount(pitch, weights=spec[keep], minlength=12)
    by_note /= by_note.sum()
    top = " ".join(f"{NOTES[k]} {by_note[k] * 100:.0f}%" for k in np.argsort(by_note)[::-1][:6] if by_note[k] > 0.02)
    band = (freq > 600) & (freq < 1300)
    share = spec[band].sum() / spec[freq > 30].sum()
    # how steady the 600-1300 Hz band is: the share of 0.5 s stretches within 3 dB of the band's loudest
    w = int(0.5 * s.SR)
    banded = s.eq(mono, lambda f: ((f > 600) & (f < 1300)).astype(float))
    power = (banded[: len(banded) // w * w].reshape(-1, w) ** 2).mean(axis=1)
    steady = np.mean(power > power.max() / 2)
    line = (f"{path.stem:26s} {x.shape[1] / s.SR:6.1f} s  loud {s.loudness(x):6.1f} dB  peak {20 * np.log10(np.abs(x).max()):5.1f} dB  "
            f"600-1300 Hz {share * 100:4.1f}% of it, at full {steady * 100:3.0f}% of the time  notes: {top}")
    if loop:
        jump = np.abs(x[:, 0] - x[:, -1]).max()
        usual = np.percentile(np.abs(np.diff(mono)), 99)
        line += f"  seam jump {jump:.4f} (99% of steps are under {usual:.4f})"
    print(line)


if __name__ == "__main__":
    names = sys.argv[1:] or sorted(p.stem for p in OUT.glob("[0-9][0-9]_*.wav"))
    for name in names:
        measure(OUT / f"{name}.wav", name[:2] in ("10", "11", "12", "13", "14", "15", "24"))
