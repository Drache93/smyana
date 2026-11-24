"""06 Winter day: the sixth track made through the design stage (docs/music-design.md, "Sheet: winter day").

Heard by day in the snow: the pass, the ridge, the long way home. The first draft scattered lute notes at random and
ran a kaval over them three times.

The one idea: the cold slows it. A lute plucks home and the fifth above, one note at a time, each left to die; the
wait between them grows from three and a half seconds to nine, until it has all but stopped. Once, in the middle, a
kaval far off plays four notes.

    0:04  D, A, D, A: a slow step, three and a half seconds apart
    0:30  other notes come among them, and the step is slower
    0:52  the kaval, once, far off: up a fourth and down
    1:10  the lute again, seven, eight, nine seconds apart
    1:38  the low D, and nothing

    python3 music/pieces/song_06_winter_day.py          the track
    python3 music/pieces/song_06_winter_day.py pencil   the tune alone on one plain sound
"""
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import synth as s  # noqa: E402

E = s.midi_of
TOTAL = 112.0
# (when each note is plucked, and which: the gaps grow)
LUTE = [(4.0, "D3"), (7.5, "A3"), (11.0, "D3"), (14.7, "A3"), (18.6, "D3"), (22.8, "E3"), (27.3, "A3"), (32.1, "D3"),
        (37.2, "G3"), (42.6, "A3"), (48.3, "D3"),
        (70.0, "A3"), (76.5, "D3"), (83.5, "E3"), (91.0, "A2"), (99.5, "D2")]
KAVAL = [(53.0, "A4/3.5~ D5/4.5~ B4/2.5 A4/5.0~")]
KAVAL_SPAN = (53.0, 69.0)


def lute_notes():
    return [(t, 5.0, E(n), False) for t, n in LUTE]


def kaval_notes():
    return [e for start, text in KAVAL for e in s.parse(text, start)]


def track():
    rng = np.random.default_rng(3601)
    import set_03_score as score
    import song_01_summer_day as day
    near = s.mixdown([                      # in the open, in snow: a long cold echo
        (s.tambura(lute_notes(), TOTAL, rng), -20, -0.15, 0.6, 0.8),
        (s.wind(TOTAL, rng), -36, 0.0, 1.0, 0.0),
    ], rng, echo=6.0, predelay=0.06, dark=3000, wet=1.0)
    far = s.mixdown([(s.kaval(kaval_notes(), TOTAL, rng, breath_level=0.3), -22, 0.35, 0.2, 1.0)],
                    rng, echo=7.0, predelay=0.1, dark=2400, wet=1.0)
    mix = near + day.level_over(far, -29, [KAVAL_SPAN])
    score.done("06_winter_day", mix, "calm", fade_in=1.0, fade_out=7.0, midi=[("Tambura", 25, lute_notes()), ("Kaval", 75, kaval_notes())])


def pencil():
    rng = np.random.default_rng(3602)
    notes = [(t, 2.0, m, v) for t, _, m, v in lute_notes()] + kaval_notes()
    mix = s.mixdown([(s.kaval(notes, TOTAL, rng, breath_level=0.05), -20, 0.0, 1.0, 0.2)], rng, echo=1.5, wet=0.4)
    s.finish("pencil_06_winter_day", mix)


def report():
    gaps = [b[0] - a[0] for a, b in zip(LUTE, LUTE[1:])]
    print(f"designed     {len(LUTE)} plucked notes, {len(kaval_notes())} on the kaval; the wait between plucks from {min(gaps):.1f} s to {max(gaps[:10] + gaps[11:]):.1f} s "
          f"(and {gaps[10]:.1f} s round the kaval)")
    import song_04_autumn_dusk as dusk
    dusk.sound("06_winter_day")


if __name__ == "__main__":
    if "pencil" in sys.argv:
        pencil()
    else:
        track()
    report()
