"""09 Spring day: the eighth track made through the design stage (docs/music-design.md, "Sheet: spring day").

Heard by day in spring, as the men come down toward home. The first draft was the kaval running through the theme
over a rocking lute with the bench's open voice for women far off.

The one idea: the walk again, and the song finished. The lute's walking tune from the first summer morning comes
back a fourth higher and a little quicker; and over it the kaval plays the two lines of the home song that the man
in the winter night could not reach: the climb, and then the last line, the one that comes home.

    0:00  the low strings find the pace (88 steps a minute; the summer's were 80)
    0:06  the summer's line A, twice, a fourth up
    0:30  the kaval over the walking strings: the home song's third line, the climb
    0:46  the summer's line B, twice
    1:10  the kaval: the last line, down and home, heard for the first time since the men left
    1:27  line A once more, the kaval holding home over it; the low string left to ring
    1:48  gone

    python3 music/pieces/song_09_spring_day.py          the track
    python3 music/pieces/song_09_spring_day.py pencil   the tune alone on one plain sound
"""
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import synth as s  # noqa: E402
import song_01_summer_day as summer  # noqa: E402

E = s.midi_of
BPM = 88
BEAT = 60 / BPM
UP = 5            # a fourth above the summer and the home song as written: home is A
TOTAL = 110.0
LINE = 16 * BEAT
T = [6.0, 6.0 + LINE + 0.6, 46.0, 46.0 + LINE + 0.6, 87.0]
LUTE = [(T[0], summer.A1), (T[1], summer.A2), (T[2], summer.B1), (T[3], summer.B2), (T[4], summer.A2)]
WALKS = [(1.0, 104.0)]
# the home song's third and fourth lines, in long notes (docs/music-design.md; set_03_score.THEME), as written on E
THIRD = (30.0, "A4/1.2 B4/1.2 D5/1.6 E5/4.5~ D5/1.4 B4/1.8 A4/1.2 G4/3.5~")
FOURTH = (70.0, "G4/1.3 A4/1.3 B4/3.2~ A4/1.2 G4/1.6 E4/1.8 D4/1.4 E4/6.0~")
HOLD = (91.0, "E4/10.0~")


def lute_notes():
    return s.shift([e for start, text in LUTE for e in s.parse(text, start, BPM)], UP)


def low_strings(rng):
    out = []
    for a, b in WALKS:
        t, i = a, 0
        while t < b:
            out.append((t + rng.normal(0, 0.01), BEAT * 1.6, E("C3") if i % 2 == 0 else E("G3"), False))
            t += BEAT
            i += 1
    out.append((105.0, 5.0, E("C3"), False))
    return out


def kaval_notes():
    # (an octave under the lute's fourth up: a low, warm kaval beneath the bright lute. A first render had it above,
    # with a third of the track's energy between 600 and 1300 Hz, the band Dominic once heard as a phone's alarm.)
    return s.shift([e for start, text in (THIRD, FOURTH, HOLD) for e in s.parse(text, start)], UP - 12)


def track():
    rng = np.random.default_rng(3901)
    lute, low, kaval = lute_notes(), low_strings(rng), kaval_notes()
    import set_03_score as score
    mix = s.mixdown([                      # in the open, near home: the kaval is with the men now, not across the valley
        (s.tambura(lute, TOTAL, rng), -20, -0.15, 0.9, 0.35),
        (s.tambura(low, TOTAL, rng), -27, 0.1, 0.9, 0.3),
        (s.kaval(kaval, TOTAL, rng, breath_level=0.16), -21, 0.3, 0.7, 0.6),
        (s.bells(score.flock(rng, 2.0, TOTAL - 8, 2.5), TOTAL, rng), -37, 0.6, 0.1, 1.0),
        (s.wind(TOTAL, rng), -43, 0.0, 1.0, 0.0),
    ], rng, echo=3.5, predelay=0.03, dark=4500, wet=0.7)
    score.done("09_spring_day", mix, "calm", fade_in=0.5, fade_out=6.0,
               midi=[("Tambura", 25, lute), ("Tambura low", 25, low), ("Kaval", 75, kaval)])


def pencil():
    rng = np.random.default_rng(3902)
    mix = s.mixdown([(s.kaval(sorted(lute_notes() + kaval_notes()), TOTAL, rng, breath_level=0.05), -20, 0.0, 1.0, 0.2)], rng, echo=1.5, wet=0.4)
    s.finish("pencil_09_spring_day", mix)


def report():
    lute, kaval = lute_notes(), [e for e in kaval_notes() if e[1] > s.GRACE]
    print(f"designed     {len(lute)} lute notes and {len(kaval)} on the kaval ({sum(e[1] for e in kaval) / len(kaval):.1f} s a note); "
          f"lute {min(e[2] for e in lute)} to {max(e[2] for e in lute)}, kaval {min(e[2] for e in kaval)} to {max(e[2] for e in kaval)} (midi)")
    import song_04_autumn_dusk as dusk
    dusk.sound("09_spring_day")


if __name__ == "__main__":
    if "pencil" in sys.argv:
        pencil()
    else:
        track()
    report()
