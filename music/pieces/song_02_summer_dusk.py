"""02 Summer dusk: the third track made through the design stage (docs/music-design.md, "Sheet: summer dusk").

Heard when the light goes on a summer evening ("The light is going. We should make camp.") and on into the night
until a fire is lit. The first draft was a fiddle running by steps over a bagpipe's drone.

The one idea: the fiddle asks and is not answered. Three phrases each end somewhere that is not home (on D, on B,
on A), and after each there is a long quiet in which the crickets are heard; the fourth comes home. One low lute
string is touched before each phrase, nothing else.

    0:02  a low G on the lute; the fiddle: home, up a fifth, and left on D
    0:20  the string; up a fourth to the top G, down, left on B
    0:41  the string; a short falling line, left on A
    1:01  the string; home, the fifth, the top G held, and down by steps all the way to a long home
    1:36  gone

    python3 music/pieces/song_02_summer_dusk.py          the track
    python3 music/pieces/song_02_summer_dusk.py pencil   the tune alone on one plain sound
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
    (4.0, "G3/3.0~ D4/3.5~ E4/2.0 D4/4.5~"),
    (22.0, "D4/2.0 G4/4.0~ E4/2.5 D4/1.5 B3/5.0~"),
    (43.0, "B3/2.0 D4/2.5 'E4 D4/1.5 A3/5.5~"),
    (63.0, "G3/2.5~ D4/3.0~ G4/5.0~ E4/2.0 D4/2.0 B3/2.5 G3/8.0~"),
]
STRING = [(2.0, 4.0, E("G2"), False), (20.5, 4.0, E("G2"), False), (41.5, 4.0, E("G2"), False), (61.5, 4.0, E("G2"), False)]
WAS = [
    (4.0, "B3/2.8~ 'D4 B3/0.4 A3/0.7 B3/0.5 D4/2.4~ E4/0.6 D4/0.5 B3/3.2~"),
    (22.0, "E4/2.6~ 'G4 E4/0.4 D4/0.8 'E4 D4/0.3 B3/0.9 A3/0.5 G3/0.6 A3/3.6~"),
    (41.0, "G3/0.6 A3/0.6 B3/0.6 D4/0.7 E4/1.0 G4/2.8~ E4/0.5 D4/0.6 E4/3.4~"),
    (60.0, "D4/0.5 E4/0.5 D4/0.5 B3/2.2~ A3/0.5 G3/0.7 'A3 G3/0.3 E3/3.8~"),
]


def lines(phrases):
    return [e for start, text in phrases for e in s.parse(text, start)]


def track():
    rng = np.random.default_rng(3201)
    fiddle = lines(FIDDLE)
    import set_03_score as score
    mix = s.mixdown([                      # near, in the wood at the day's end: a little echo, no drone under it
        (s.gadulka(fiddle, TOTAL, rng), -20, 0.1, 0.8, 0.45),
        (s.tambura(STRING, TOTAL, rng), -30, -0.2, 0.8, 0.5),
        (s.wind(TOTAL, rng), -44, 0.0, 1.0, 0.0),
    ], rng, echo=3.2, predelay=0.03, dark=3000, wet=0.7)
    score.done("02_summer_dusk", mix, "calm", fade_in=0.5, fade_out=6.0, midi=[("Gadulka", 110, fiddle), ("Tambura", 25, STRING)])


def pencil():
    rng = np.random.default_rng(3202)
    mix = s.mixdown([(s.kaval(lines(FIDDLE), TOTAL, rng, breath_level=0.05), -20, 0.0, 1.0, 0.2)], rng, echo=1.5, wet=0.4)
    s.finish("pencil_02_summer_dusk", mix)


SCALE = sorted(E(n + str(o)) for o in (2, 3, 4, 5) for n in ("G", "A", "B", "D", "E"))


def report():
    for label, ev in (("designed", lines(FIDDLE)), ("first draft", lines(WAS))):
        notes = [e for e in ev if e[2] is not None and e[1] > s.GRACE]
        mids = [e[2] for e in notes]
        moves = [abs(SCALE.index(b) - SCALE.index(a)) for a, b in zip(mids, mids[1:])]
        sounding = sum(e[1] for e in notes)
        print(f"{label:12s} {len(notes):3d} notes, {sounding / len(notes):.1f} s a note, {sum(1 for x in moves if x > 1)} leaps, "
              f"{sum(1 for e in notes if e[1] < 1.0)} under a second")
    import song_04_autumn_dusk as dusk
    dusk.sound("02_summer_dusk")


if __name__ == "__main__":
    if "pencil" in sys.argv:
        pencil()
    else:
        track()
    report()
