"""07 Winter night: the seventh track made through the design stage (docs/music-design.md, "Sheet: winter night").

Heard on winter nights, the deepest point of the run. The first draft was the bench's open voice singing the whole
main theme, and the open voice is where the bench fails (Dominic heard a "trumpet type instrument").

The one idea: a man hums the song of home and cannot finish it. Lips closed, alone, slow and low. He hums the first
line and stops. He begins again and gets through two. The third time he reaches the third line's high note, holds
it, and stops there. The last line, the one that comes home, is not heard: it is kept for the spring.

    0:04  the first line, and quiet
    0:25  again: the first and the second
    1:03  again: the first, the second, and the climb of the third, held, and left
    1:50  gone

    python3 music/pieces/song_07_winter_night.py          the track
    python3 music/pieces/song_07_winter_night.py pencil   the tune alone on one plain sound
"""
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import synth as s  # noqa: E402

E = s.midi_of
SLOW = 1.6
DOWN = -14   # an octave and a tone under the theme as written: on D, the men's own note
# the third line, only as far as its top note
THIRD_BROKEN = "A4/0.5 B4/0.5 D5/0.7 E5/4.2~"


def man():
    import set_03_score as score
    out, t = [], 4.0
    for attempt in ([score.THEME[0]], [score.THEME[0], score.THEME[1]], [score.THEME[0], score.THEME[1], THIRD_BROKEN]):
        for text in attempt:
            notes = [(t + a * SLOW, d * SLOW, m, v) for a, d, m, v in s.parse(text)]
            out += notes
            t = s.end_of(notes) + 2.2
        t += 5.0
    return s.shift(out, DOWN), t


def track():
    rng = np.random.default_rng(3701)
    notes, end = man()
    total = end + 4.0
    import set_03_score as score
    mix = s.mixdown([                      # at the fire, close: almost no echo, a man beside you
        (s.hum(notes, total, rng, voices=1), -20, 0.05, 0.9, 0.25),
        (s.wind(total, rng), -38, 0.0, 1.0, 0.0),
    ], rng, echo=2.0, predelay=0.02, dark=2000, wet=0.5)
    score.done("07_winter_night", mix, "calm", fade_in=1.0, fade_out=6.0, midi=[("Humming", 53, notes)])


def pencil():
    rng = np.random.default_rng(3702)
    notes, end = man()
    mix = s.mixdown([(s.kaval(notes, end + 4.0, rng, breath_level=0.05), -20, 0.0, 1.0, 0.2)], rng, echo=1.5, wet=0.4)
    s.finish("pencil_07_winter_night", mix)


def report():
    notes, end = man()
    real = [e for e in notes if e[2] is not None and e[1] > s.GRACE]
    print(f"designed     {len(real)} notes, {sum(e[1] for e in real) / len(real):.1f} s a note, from {min(e[2] for e in real)} to {max(e[2] for e in real)} (midi), {end + 4.0:.0f} s")
    import song_04_autumn_dusk as dusk
    dusk.sound("07_winter_night")


if __name__ == "__main__":
    if "pencil" in sys.argv:
        pencil()
    else:
        track()
    report()
