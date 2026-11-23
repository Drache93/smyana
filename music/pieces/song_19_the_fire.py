"""19 The fire: made from its sheet of 2026-11-11 (docs/music-design.md, "Sheet: the fire").

Heard at night with a fire lit, taking turns with the season's night track. The first draft was the main theme
hummed by five men with no beat and no answer. The sheet asked for the men's own song: one man starts a line, the
others sing it back, somebody knocks a stick on a log.

The one idea: one man starts and the others answer. No instrument at all. The fire's crackle is the game's own and
is not in the track.

    0:03  four lines, each hummed by one man and then by all (66 beats a minute, a knock every four beats)
    1:02  the knocking goes on alone for a bar
    1:05  the last two lines once more, all together from the first note, the last one slowing
    1:27  the low D held, and gone

    python3 music/pieces/song_19_the_fire.py          the track
    python3 music/pieces/song_19_the_fire.py pencil   the tune alone on one plain sound
"""
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import synth as s  # noqa: E402
import design_sketches as sketch  # noqa: E402

BPM = sketch.FIRE_BPM
BEAT = 60 / BPM
START = 3.0
LAST_SLOW = "F3/1.1 G3/1.1 F3/1.2 D3/1.3 | C3/1.5 D3/7~"


def parts():
    """The leader's lines, the men's, and the knocks, as (start, length, midi, slur) and (time, kind, strength)."""
    leader, men, knocks = [], [], []
    for k, text in enumerate(sketch.FIRE_LINES):
        at = START + k * 16 * BEAT
        leader += s.parse(text, at, BPM)
        men += s.parse(text, at + 8 * BEAT, BPM)
    again = START + 68 * BEAT                       # a bar of knocking alone, then all together
    men += s.parse(sketch.FIRE_LINES[2], again, BPM)
    men += s.parse(LAST_SLOW, again + 8 * BEAT, BPM)
    leader += s.parse(sketch.FIRE_LINES[2], again, BPM)
    leader += s.parse(LAST_SLOW, again + 8 * BEAT, BPM)
    for b in range(0, 80, 4):                       # the knock stops as the last line slows
        knocks.append((START + b * BEAT, "tick" if b % 8 else "heart", 0.6 if b % 8 == 0 else 0.4))
    return leader, men, knocks


def knock(hits, total, rng):
    """A stick on a log: a short dry knock with a little wood in it, not a drum."""
    n = int(total * s.SR)
    out = np.zeros(n)
    for when, kind, strength in hits:
        when += rng.normal(0, 0.012)
        a = int(when * s.SR)
        length = int(0.25 * s.SR)
        t = np.arange(length) / s.SR
        pitch = (310 if kind == "heart" else 370) * (1 + rng.normal(0, 0.02))
        body = np.sin(2 * np.pi * pitch * t) * np.exp(-t / 0.035) + 0.5 * np.sin(2 * np.pi * pitch * 2.4 * t) * np.exp(-t / 0.018)
        click = rng.standard_normal(length) * np.exp(-t / 0.004)
        out[a:a + length] += strength * (body + 0.5 * click)
    return s.eq(out, lambda f: 1 / (1 + (f / 3500) ** 2))


def track():
    rng = np.random.default_rng(3191)
    leader, men, knocks = parts()
    total = s.end_of(men) + 5.0
    import set_03_score as score
    mix = s.mixdown([                      # at the fire: close and dry
        (s.hum(leader, total, rng, voices=1), -25, -0.3, 0.9, 0.25),
        (s.hum(men, total, rng, voices=5), -20, 0.2, 0.9, 0.3),
        (knock(knocks, total, rng), -30, 0.45, 1.0, 0.15),
        (s.wind(total, rng), -40, 0.0, 1.0, 0.0),
    ], rng, echo=1.6, predelay=0.02, dark=2400, wet=0.5)
    score.done("19_the_fire", mix, "moment", fade_in=1.0, fade_out=5.0,
               midi=[("Leader", 53, leader), ("Men", 53, men)])


def pencil():
    rng = np.random.default_rng(3192)
    leader, men, _ = parts()
    total = s.end_of(men) + 5.0
    notes = sorted(set(leader + men))
    mix = s.mixdown([(s.kaval(s.shift(notes, 12), total, rng, breath_level=0.05), -20, 0.0, 1.0, 0.2)], rng, echo=1.5, wet=0.4)
    s.finish("pencil_19_the_fire", mix)


def report():
    leader, men, _ = parts()
    for label, ev in (("designed", leader), ("first draft", [e for at, text in sketch.FIRE_WAS for e in s.parse(text, at)])):
        notes = [e for e in ev if e[2] is not None and e[1] > s.GRACE]
        mids = [e[2] for e in notes]
        print(f"{label:12s} {len(notes):3d} notes, {sum(e[1] for e in notes) / len(notes):.1f} s a note, "
              f"{sum(1 for a, b in zip(mids, mids[1:]) if a == b)} said twice, range {max(mids) - min(mids)} semitones")
    import song_04_autumn_dusk as dusk
    dusk.sound("19_the_fire")


if __name__ == "__main__":
    if "pencil" in sys.argv:
        pencil()
    else:
        track()
    report()
