"""01 Summer day: the second track made through the design stage (docs/music-design.md, "Sheet: summer day").

The first music a player hears, at the village edge on the first morning, and the track heard most: a first-time
player heard the first draft's nine times in 22 minutes (2026-11-23). The first draft was a kaval running up and down
over a rocking lute, like most of that draft ("all the music though is basically pipe going up and down quick",
Dominic, 2026-11-11).

The one idea: the lute walks. A tambura plays the tune at the men's own pace, plucked, with notes said twice and
leaps of a fifth; when it stops to rest, a kaval far off answers with one long phrase. The pipe never runs.

    0:00  the wood; the lute's two low strings find the pace (G and D, 80 steps a minute)
    0:08  line A twice: from home up a fifth and back by steps, the second time all the way home
    0:35  the walk stops. Far off, the kaval: a held note, a leap up a fourth, down again
    0:50  line B twice: higher, climbing to the top G, home the second time
    1:17  the kaval again, the lute's low strings still walking under it
    1:33  line A once more, slowing, and the low G left to ring
    1:53  gone

    python3 music/pieces/song_01_summer_day.py          the track
    python3 music/pieces/song_01_summer_day.py pencil   the tune alone on one plain sound
Writes music/out/01_summer_day.wav and .mp3, the game's assets/audio/music/01_summer_day.ogg and
music/tracks/01_summer_day.mid; then measures it beside the first draft's.
"""
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import synth as s  # noqa: E402

E = s.midi_of
BPM = 80
BEAT = 60 / BPM
TOTAL = 116.0

# The lute's tune, in beats. Two beats to a bar. Home is G; the leap is home to D, a fifth.
A1 = "G3/1 G3/1 | D4/2 | B3/1 A3/1 | G3/2 | G3/1 G3/1 | D4/1 E4/1 | D4/1 B3/1 | A3/2"
A2 = "G3/1 G3/1 | D4/2 | B3/1 A3/1 | G3/2 | G3/1 G3/1 | D4/1 E4/1 | D4/1 B3/1 | G3/2"
B1 = "B3/1 D4/1 | E4/2 | E4/1 E4/1 | G4/2 | E4/1 D4/1 | B3/2 | A3/1 B3/1 | D4/2"
B2 = "B3/1 D4/1 | E4/2 | E4/1 E4/1 | G4/2 | E4/1 D4/1 | B3/1 A3/1 | G3/2 | G3/2"
A3 = "G3/1 G3/1 | D4/2 | B3/1 A3/1 | G3/2 | G3/1.1 G3/1.1 | D4/1.2 E4/1.3 | D4/1.4 B3/1.6 | G3/4"
# (where each line starts, seconds)
T_A1, T_A2, T_B1, T_B2, T_A3 = 8.0, 20.0, 50.0, 62.0, 93.0
LUTE = [(T_A1, A1), (T_A2, A2), (T_B1, B1), (T_B2, B2), (T_A3, A3)]
# The low strings: G on the first beat of a bar, D on the second, where the walk goes on.
WALKS = [(2.0, 32.0), (47.0, 108.0)]
# The kaval, across the valley, in seconds and free of the beat. Each answer has one leap up a fourth.
KAVAL = [
    (35.0, "D5/3.5~ G5/4.5~ E5/1.5 D5/4.0~"),
    (77.0, "B4/2.5~ E5/4.0~ D5/1.5 B4/1.5 G4/5.0~"),
]
KAVAL_SPANS = [(35.0, 49.0), (77.0, 92.0)]


def lute_notes():
    return [e for start, text in LUTE for e in s.parse(text, start, BPM)]


def low_strings(rng):
    out = []
    for a, b in WALKS:
        t, i = a, 0
        while t < b:
            # (slowing with the last line)
            step = BEAT * (1.0 if t < T_A3 + 8 * BEAT else 1.3)
            out.append((t + rng.normal(0, 0.01), step * 1.6, E("G2") if i % 2 == 0 else E("D3"), False))
            t += step
            i += 1
    out.append((110.0, 5.0, E("G2"), False))
    return out


def kaval_notes():
    return [e for start, text in KAVAL for e in s.parse(text, start)]


def level_over(x, db, spans):
    """synth.level, measured only where the part plays."""
    part = np.concatenate([x[:, int(a * s.SR):int(b * s.SR)] for a, b in spans], axis=1)
    return x * (s.level(part, db).max() / (np.abs(part).max() + 1e-12))


def track():
    rng = np.random.default_rng(3101)
    lute, low, kaval = lute_notes(), low_strings(rng), kaval_notes()
    import set_03_score as score
    near = s.mixdown([                      # in the wood: some echo, the player close
        (s.tambura(lute, TOTAL, rng), -20, -0.1, 0.9, 0.35),
        (s.tambura(low, TOTAL, rng), -27, 0.15, 0.9, 0.3),
        (s.bells(score.flock(rng, 4.0, TOTAL - 8, 4.0), TOTAL, rng), -40, 0.6, 0.1, 1.0),
        (s.wind(TOTAL, rng), -42, 0.0, 1.0, 0.0),
    ], rng, echo=2.8, predelay=0.025, dark=4200, wet=0.6)
    far = s.mixdown([(s.kaval(kaval, TOTAL, rng, breath_level=0.25), -22, 0.4, 0.2, 1.0)],
                    rng, echo=6.5, predelay=0.09, dark=2800, wet=1.0)
    mix = near + level_over(far, -27, KAVAL_SPANS)
    score.done("01_summer_day", mix, "calm", fade_in=0.5, fade_out=5.0,
               midi=[("Tambura", 25, lute), ("Tambura low", 25, low), ("Kaval", 75, kaval)])


def pencil():
    rng = np.random.default_rng(3102)
    notes = lute_notes() + kaval_notes()
    mix = s.mixdown([(s.kaval(notes, TOTAL, rng, breath_level=0.05), -20, 0.0, 1.0, 0.2)], rng, echo=1.5, wet=0.4)
    s.finish("pencil_01_summer_day", mix)


SCALE = [E(n + str(o)) for o in (2, 3, 4, 5) for n in ("G", "A", "B", "D", "E")]
SCALE.sort()
WAS = [
    (7.5, "D5/2.6~ 'E5 D5/0.4 B4/0.6 A4/0.5 B4/0.6 G4/3.0~"),
    (21.0, "G4/0.5 A4/0.5 B4/0.6 D5/0.6 E5/2.8~ D5/0.5 B4/0.8 'D5 B4/0.3 A4/0.6 B4/3.2~"),
    (40.0, "B4/0.6 D5/2.0~ B4/0.5 A4/0.5 G4/0.6 A4/0.6 B4/0.5 A4/0.5 G4/3.4~"),
    (60.0, "E5/2.2~ 'G5 E5/0.4 D5/0.8 E5/0.5 D5/0.5 B4/2.6~ A4/0.5 B4/0.5 D5/3.6~"),
    (82.0, "D5/0.6 B4/0.6 A4/0.6 G4/2.4~ 'A4 G4/0.4 E4/0.6 G4/0.6 A4/0.6 B4/3.0~"),
    (100.0, "A4/0.5 B4/0.5 D5/2.4~ 'E5 D5/0.4 B4/0.7 A4/0.6 G4/5.5~"),
]


def report():
    """How the tune moves beside the first draft's. A leap is a move past the next note of the five-note scale."""
    was = [e for start, text in WAS for e in s.parse(text, start)]
    for label, ev in (("designed", sorted(lute_notes() + kaval_notes())), ("first draft", was)):
        notes = [e for e in ev if e[2] is not None and e[1] > s.GRACE]
        mids = [e[2] for e in notes]
        moves = [abs(SCALE.index(b) - SCALE.index(a)) for a, b in zip(mids, mids[1:])]
        print(f"{label:12s} {len(notes):3d} notes, {sum(e[1] for e in notes) / len(notes):.1f} s a note, "
              f"{sum(1 for x in moves if x > 1)} leaps, {moves.count(0)} notes said twice, "
              f"lowest {min(mids)}, highest {max(mids)} (midi)")
    import song_04_autumn_dusk as dusk
    dusk.sound("01_summer_day")


if __name__ == "__main__":
    if "pencil" in sys.argv:
        pencil()
    else:
        track()
    report()
