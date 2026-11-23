"""05 Autumn night: the fifth track made through the design stage (docs/music-design.md, "Sheet: autumn night").

Heard on autumn nights, in turn with the men's own song when a fire is lit. The first draft was a low fiddle wandering
by steps over a drone that never stopped.

The one idea: the fiddle sinks. One line goes down the whole piece like a stair: each phrase falls, climbs back one
step, and rests; the next begins where that one rested. An octave and a half lower than it began, it reaches the
bottom, and only there does a drone come up under it.

    0:05  from B: down a third, back a step, rest on A
    0:22  from A: down a fourth, back a step, rest on G
    0:40  from G: down a fourth, back a step, rest on E
    1:00  from E: down, and down, to the low E, held; the drone rises under it
    1:36  gone

    python3 music/pieces/song_05_autumn_night.py          the track
    python3 music/pieces/song_05_autumn_night.py pencil   the tune alone on one plain sound
"""
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import synth as s  # noqa: E402

E = s.midi_of
TOTAL = 96.0
FIDDLE = [
    (5.0, "B3/3.5~ G3/2.5 A3/4.5~"),
    (22.0, "A3/3.0~ E3/2.5 G3/5.0~"),
    (40.0, "G3/3.0~ D3/2.5 E3/5.5~"),
    (60.0, "E3/3.0~ B2/3.0 D3/2.0 B2/2.5 A2/3.0 E2/11.0~"),
]
DRONE = (72.0, 88.0)
WAS = [
    (5.0, "E3/3.6~ G3/0.7 A3/2.6~ G3/0.6 E3/4.0~"),
    (27.0, "B3/3.0~ A3/0.6 G3/0.8 A3/0.5 G3/0.6 E3/0.8 D3/0.7 E3/4.5~"),
    (52.0, "A3/0.7 B3/0.7 D4/3.2~ B3/0.8 A3/2.8~"),
    (72.0, "G3/0.8 E3/0.8 D3/2.6~ E3/0.7 G3/0.7 E3/6.0~"),
]


def lines(phrases):
    return [e for start, text in phrases for e in s.parse(text, start)]


def track():
    rng = np.random.default_rng(3501)
    fiddle = lines(FIDDLE)
    import set_03_score as score
    import song_01_summer_day as day
    near = s.mixdown([                      # in the wood at night: dark, some echo
        (s.gadulka(fiddle, TOTAL, rng), -20, -0.1, 0.7, 0.6),
        (s.wind(TOTAL, rng), -40, 0.0, 1.0, 0.0),
    ], rng, echo=4.0, predelay=0.04, dark=2200, wet=0.8)
    drone = s.gaida_drone(E("E2"), DRONE[0], DRONE[1], TOTAL, rng, dark=500,
                          shape=([DRONE[0], DRONE[0] + 8.0, DRONE[1] - 6.0, DRONE[1]], [0.0, 1.0, 1.0, 0.0]))
    low = s.mixdown([(drone, -20, 0.0, 0.8, 0.5)], rng, echo=4.0, dark=1200, wet=0.6)
    mix = near + day.level_over(low, -31, [DRONE])
    score.done("05_autumn_night", mix, "calm", fade_in=1.0, fade_out=6.0, midi=[("Gadulka", 110, fiddle)])


def pencil():
    rng = np.random.default_rng(3502)
    mix = s.mixdown([(s.kaval(lines(FIDDLE), TOTAL, rng, breath_level=0.05), -20, 0.0, 1.0, 0.2)], rng, echo=1.5, wet=0.4)
    s.finish("pencil_05_autumn_night", mix)


SCALE = sorted(E(n + str(o)) for o in (2, 3, 4, 5) for n in ("E", "G", "A", "B", "D"))


def report():
    for label, ev in (("designed", lines(FIDDLE)), ("first draft", lines(WAS))):
        notes = [e for e in ev if e[2] is not None and e[1] > s.GRACE]
        mids = [e[2] for e in notes]
        moves = [SCALE.index(b) - SCALE.index(a) for a, b in zip(mids, mids[1:])]
        print(f"{label:12s} {len(notes):3d} notes, {sum(e[1] for e in notes) / len(notes):.1f} s a note, {sum(1 for x in moves if abs(x) > 1)} leaps, "
              f"{sum(1 for x in moves if x < 0)} moves down and {sum(1 for x in moves if x > 0)} up, from {mids[0]} to {mids[-1]} (midi)")
    import song_04_autumn_dusk as dusk
    dusk.sound("05_autumn_night")


if __name__ == "__main__":
    if "pencil" in sys.argv:
        pencil()
    else:
        track()
    report()
