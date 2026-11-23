"""14 Ottomans: the first danger track made through the design stage (docs/music-design.md, "Sheet: the Ottomans").

Heard when a patrol has seen the men. The first draft was a zurna running over a second zurna and a drum:
"ottomans sounds too synth" (Dominic, 2026-11-11). The bench's zurna is a bare buzz and no better buzz will pass.

The one idea: the drum is here and the pipe is not. Their big drum is close and dry, slow and heavy, in the
player's chest. Their pipe is somewhere behind them across the valley: two short calls of long notes, dark with
distance, more echo than pipe. The wide step from F to G sharp still says whose pipe it is.

A loop of sixteen bars at 92 beats a minute (42 s):
    bars 1 to 4    the drum alone
    bars 5 to 8    the pipe far off: a long B falling to E
    bars 9 to 12   the drum alone, heavier
    bars 13 to 16  the pipe again: up from E over the wide step and back

    python3 music/pieces/song_14_ottomans.py          the track
    python3 music/pieces/song_14_ottomans.py pencil   the pipe's calls alone on one plain sound
"""
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import synth as s  # noqa: E402

BPM = 92
BEAT = 60 / BPM
BARS = 16
LENGTH = BARS * 4 * BEAT
CALLS = [
    (4, "B4/6~ C5/1 B4/1 | G#4/2 F4/2 E4/4~"),
    (12, "E4/2 F4/2 G#4/4~ | A4/2 G#4/2 F4/1 'F4 E4/3~"),
]
# the first draft's pipe, for the count
WAS = "E4/1 'F4 E4/.5 F4/.5 G#4/1 A4/1 | G#4/.5 F4/.5 G#4/.5 A4/.5 B4/2~ | A4/.5 G#4/.5 F4/.5 G#4/.5 A4/1 G#4/.5 F4/.5 | 'F4 E4/4~"


def pipe():
    return [e for bar, text in CALLS for e in s.parse(text, bar * 4 * BEAT, BPM)]


def drum(rng):
    """dum . tek tek dum . tek .  Every fourth bar ends in a short roll; the second half is heavier."""
    hits = []
    for bar in range(BARS):
        t0 = bar * 4 * BEAT
        heavy = bar >= 8
        hits += [(t0, "boom", 1.0), (t0 + 1.0 * BEAT, "tick", 0.7), (t0 + 1.5 * BEAT, "tick", 0.5),
                 (t0 + 2.0 * BEAT, "boom", 0.8), (t0 + 3.0 * BEAT, "tick", 0.7)]
        if heavy:
            hits.append((t0 + 2.5 * BEAT, "boom", 0.55))
        if bar % 4 == 3:
            hits += [(t0 + (3.25 + 0.25 * k) * BEAT, "tick", 0.35 + 0.12 * k) for k in range(3)]
    return [(t + rng.normal(0, 0.006), kind, v * rng.uniform(0.9, 1.0)) for t, kind, v in hits]


def beater(hits, total, rng):
    """The knock of the heavy beater on the skin, an octave and more over the boom: the part of a big drum that a
    small speaker can carry."""
    out = np.zeros(int(total * s.SR))
    for when, kind, strength in hits:
        if kind != "boom":
            continue
        a = int(max(0.0, when) * s.SR)
        length = int(0.3 * s.SR)
        t = np.arange(length) / s.SR
        pitch = 130 + 120 * np.exp(-t / 0.02)
        knock = np.sin(2 * np.pi * np.cumsum(pitch) / s.SR) * np.exp(-t / 0.07)
        slap = rng.standard_normal(length) * np.exp(-t / 0.012)
        out[a:a + length] += strength * (knock + 0.5 * slap)
    return s.eq(out, lambda f: 1 / (1 + (f / 900) ** 2))


def track():
    rng = np.random.default_rng(3141)
    import set_03_score as score
    tune, hits = pipe(), drum(rng)
    near_tail, far_tail = 1.2 * 1.3 + 1.5, 7.0 * 1.3 + 1.5
    skin = s.drums(hits, LENGTH + near_tail, rng) + 1.6 * beater(hits, LENGTH + near_tail, rng)
    near = s.fold(s.mixdown([(skin, -16, 0.0, 1.0, 0.2)],
                            rng, echo=1.2, predelay=0.01, dark=3000, wet=0.5), LENGTH)
    # (the valley's air takes the top off the reed before the echo does: what arrives is a horn's worth of it)
    reed = s.eq(s.zurna(tune, LENGTH + far_tail, rng), lambda f: 1 / (1 + (f / 1100) ** 4))
    far = s.fold(s.mixdown([(reed, -20, -0.4, 0.0, 1.0)], rng, echo=7.0, predelay=0.12, dark=1500, wet=1.0), LENGTH)
    far = far * (10 ** (-29 / 20) / (np.sqrt(np.mean(far ** 2)) + 1e-12))
    score.done("14_ottomans", near + far, "danger", loop=True, midi=[("Zurna, far", 111, tune)])


def pencil():
    rng = np.random.default_rng(3142)
    mix = s.mixdown([(s.kaval(pipe(), LENGTH + 4, rng, breath_level=0.05), -20, 0.0, 1.0, 0.2)], rng, echo=1.5, wet=0.4)
    s.finish("pencil_14_ottomans", mix)


def report():
    for label, ev in (("designed", pipe()), ("first draft", s.parse(WAS, 0, 100))):
        notes = [e for e in ev if e[2] is not None and e[1] > s.GRACE]
        print(f"{label:12s} {len(notes):3d} notes of pipe in {'the loop' if label == 'designed' else 'one line of seven'}, "
              f"{sum(e[1] for e in notes) / len(notes):.1f} s a note")
    import song_04_autumn_dusk as dusk
    dusk.sound("14_ottomans")


if __name__ == "__main__":
    if "pencil" in sys.argv:
        pencil()
    else:
        track()
    report()
