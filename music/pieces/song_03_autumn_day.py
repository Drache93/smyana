"""03 Autumn day: the fourth track made through the design stage (docs/music-design.md, "Sheet: autumn day").

Heard by day in the autumn woods: the beech valley gone orange, the fir woods in mist. The first draft was a kaval
running by steps over a bagpipe's drone with the men humming their own tune under it.

The one idea: a call and its echo. A kaval calls across the valley, a few long notes with a fall of a fifth; after a
quiet the men answer with the same call, low and hummed, as if the valley gave it back. Each call is a little longer.
The third call climbs and is left open, and the men bring it home. The last they sound together.

    0:06  the call: two notes, a fall of a fifth          0:14  the men give it back
    0:26  four notes                                      0:39  the men
    0:56  six notes, climbing to the top and left open    1:15  the men turn it and bring it home
    1:35  the last call, and the men with it two seconds behind, down to a long home
    1:54  gone

    python3 music/pieces/song_03_autumn_day.py          the track
    python3 music/pieces/song_03_autumn_day.py pencil   the tune alone on one plain sound
"""
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import synth as s  # noqa: E402

E = s.midi_of
TOTAL = 116.0
CALL = [
    (6.0, "B4/3.0~ E4/4.0~"),
    (26.0, "B4/2.5 D5/3.0~ A4/2.0 E4/4.0~"),
    (56.0, "E4/2.0 A4/2.5 B4/3.0~ E5/4.0~ D5/2.0 B4/4.5~"),
    (95.0, "B4/3.0~ A4/2.0 G4/2.0 E4/7.5~"),
]
MEN = [
    (14.5, "B3/3.0~ E3/4.5~"),
    (39.0, "B3/2.5 D4/3.0~ A3/2.0 E3/4.5~"),
    (75.0, "E3/2.0 A3/2.5 B3/3.0~ A3/2.0 G3/2.0 E3/5.5~"),
    (97.0, "B3/3.0~ A3/2.0 G3/2.0 E3/6.5~"),
]
WAS = [
    (8.0, "G4/2.8~ A4/0.5 B4/2.2~ 'D5 B4/0.4 A4/0.6 G4/0.5 E4/3.6~"),
    (24.0, "B4/0.7 D5/2.6~ 'E5 D5/0.4 B4/1.0 A4/0.5 G4/0.6 A4/3.8~"),
    (53.0, "E5/3.0~ D5/0.5 B4/0.8 A4/0.5 B4/3.5~"),
    (78.0, "A4/0.7 G4/0.7 E4/2.6~ 'G4 E4/0.5 D4/1.0 E4/5.0~"),
    (101.0, "B4/0.6 A4/0.6 G4/2.2~ A4/0.5 B4/0.6 D5/2.4~ B4/0.6 A4/0.6 G4/0.6 E4/6.0~"),
]


def lines(phrases):
    return [e for start, text in phrases for e in s.parse(text, start)]


def track():
    rng = np.random.default_rng(3301)
    call, men = lines(CALL), lines(MEN)
    import set_03_score as score
    mix = s.mixdown([                      # across the valley: the long echo, the one track of the calm ones that has it
        (s.kaval(call, TOTAL, rng, breath_level=0.22), -20, 0.3, 0.4, 1.0),
        (s.hum(men, TOTAL, rng, voices=4), -24, -0.3, 0.45, 0.9),
        (s.mist([(0.0, TOTAL - 4, ["B4", "E5"])], TOTAL, rng), -40, 0.0, 0.2, 1.0),
        (s.wind(TOTAL, rng), -39, 0.0, 1.0, 0.0),
    ], rng, echo=6.5, predelay=0.08, dark=2600)
    score.done("03_autumn_day", mix, "calm", fade_in=2.0, fade_out=7.0, midi=[("Kaval", 75, call), ("Men humming", 53, men)])


def pencil():
    rng = np.random.default_rng(3302)
    mix = s.mixdown([(s.kaval(lines(CALL) + lines(MEN), TOTAL, rng, breath_level=0.05), -20, 0.0, 1.0, 0.2)], rng, echo=1.5, wet=0.4)
    s.finish("pencil_03_autumn_day", mix)


SCALE = sorted(E(n + str(o)) for o in (2, 3, 4, 5) for n in ("E", "G", "A", "B", "D"))


def report():
    for label, ev in (("designed", lines(CALL)), ("first draft", lines(WAS))):
        notes = [e for e in ev if e[2] is not None and e[1] > s.GRACE]
        mids = [e[2] for e in notes]
        moves = [abs(SCALE.index(b) - SCALE.index(a)) for a, b in zip(mids, mids[1:])]
        print(f"{label:12s} {len(notes):3d} notes (the kaval), {sum(e[1] for e in notes) / len(notes):.1f} s a note, "
              f"{sum(1 for x in moves if x > 1)} leaps, {sum(1 for e in notes if e[1] < 1.0)} under a second")
    import song_04_autumn_dusk as dusk
    dusk.sound("03_autumn_day")


if __name__ == "__main__":
    if "pencil" in sys.argv:
        pencil()
    else:
        track()
    report()
