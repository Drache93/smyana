"""12 Wolves and bears: made through the design stage (docs/music-design.md, "Sheet: wolves and bears").

Heard when wolves rush a man on his own, or the bear is up on its hind legs and coming. The first draft was the big
drum in uneven twos and threes over two drones. Measured, 0.2% of it sat between 600 and 1300 Hz (a laptop would play
almost none of it), its loop clicked at the seam, and its uneven groups are the rhythms of Thrace and the Shope
country, which docs/rhodope-music-style.md says not to borrow.

The one idea: the men's own dance drum, played too fast, that keeps stopping dead. A plain hard 2/4 as the Rhodope
horo has it, the heavy skin on the beat and the switch between, six bars at a run and then two bars of nothing, over
and over. No tune (animals have no music) and no drone that holds.

A loop of 48 bars of 2/4 at 152 beats a minute (38 s), in six eights, each six bars played and two silent:
    1  the plain beat
    2  heavier: a second blow in every other bar, the switch ruffling
    3  the switch alone, soft; one low string scraped under it, a half step over home
    4  as 2
    5  the heaviest: the heavy skin on every beat; the string again, falling home
    6  as 1, with the string dying under it

    python3 music/pieces/song_12_beasts.py          the track
    python3 music/pieces/song_12_beasts.py pencil   the drum alone, dry, one eight of each kind
"""
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import synth as s  # noqa: E402

BPM = 152
BEAT = 60 / BPM
BAR = 2 * BEAT
EIGHTS = ["plain", "heavy", "switch", "heavy", "heaviest", "plain"]
LENGTH = len(EIGHTS) * 8 * BAR
# (the string: which eight, the bar it starts in, the notes with their lengths in seconds)
STRING = [(2, 0.5, "F2/2.2 E2/1.0 F2/1.4"), (4, 0.0, "F2/1.6 F2/1.2 E2/1.9"), (5, 2.0, "E2/3.0")]


def drum(rng, eights=EIGHTS):
    hits = []
    for k, kind in enumerate(eights):
        for bar in range(6):                       # (bars seven and eight of each eight are left empty)
            t0 = (k * 8 + bar) * BAR
            soft = 0.55 if kind == "switch" else 1.0
            if kind != "switch":
                hits.append((t0, "boom", 1.0))
                if kind == "heaviest" or (kind == "heavy" and bar % 2 == 1):
                    hits.append((t0 + BEAT, "boom", 0.8))
            # the switch on the halves between, and a ruffle into the next bar when it is heavy or alone
            hits += [(t0 + 0.5 * BEAT, "tick", 0.7 * soft), (t0 + 1.5 * BEAT, "tick", 0.75 * soft)]
            if kind == "switch":
                hits += [(t0, "tick", 0.45), (t0 + BEAT, "tick", 0.4)]
            if kind != "plain" and bar % 2 == 1:
                hits += [(t0 + (1.5 + 0.125 * j) * BEAT, "tick", (0.3 + 0.12 * j) * soft) for j in range(1, 4)]
        # (the last blow of the six bars lands on the seventh's first beat, and then nothing)
        hits.append(((k * 8 + 6) * BAR, "boom" if kind != "switch" else "tick", 1.0 if kind != "switch" else 0.6))
    return [(max(0.0, t + rng.normal(0, 0.004)), kind, v * rng.uniform(0.9, 1.0)) for t, kind, v in hits]


def string():
    return [e for k, bar, text in STRING for e in s.parse(text, (k * 8 + bar) * BAR, None)]


def track():
    rng = np.random.default_rng(1212)
    import set_03_score as score
    import song_14_ottomans as ottomans
    hits, low = drum(rng), string()
    tail = 2.0 * 1.3 + 1.5
    # (the beater's knock, an octave and more over the boom, is the part of the drum a small speaker can carry)
    # and the switch is in front: the bench's drum has it a quarter as loud as the heavy skin
    switch = s.drums([h for h in hits if h[1] == "tick"], LENGTH + tail, rng)
    skin = s.drums(hits, LENGTH + tail, rng) + 2.2 * ottomans.beater(hits, LENGTH + tail, rng) + 5.0 * switch
    mix = s.fold(s.mixdown([(skin, -16, 0.0, 1.0, 0.25), (s.gadulka(low, LENGTH + tail, rng), -21, -0.25, 0.8, 0.5)],
                           rng, echo=2.0, predelay=0.015, dark=2800, wet=0.6), LENGTH)
    score.done("12_beasts", mix, "danger", loop=True, midi=[("Gadulka, low string", 110, low)])


def pencil():
    rng = np.random.default_rng(1213)
    kinds = ["plain", "heavy", "switch", "heaviest"]
    hits = drum(rng, kinds)
    total = len(kinds) * 8 * BAR + 2
    s.finish("pencil_12_beasts", s.mixdown([(s.drums(hits, total, rng), -16, 0.0, 1.0, 0.0)], rng, echo=0.5, wet=0.1))


def report():
    rng = np.random.default_rng(1)
    hits = drum(rng)
    quiet = len(EIGHTS) * 2 * BAR - sum(0.3 for _ in EIGHTS)
    print(f"designed: {len(hits)} blows in {LENGTH:.1f} s, {sum(k == 'boom' for _, k, _ in hits)} of them the heavy skin; "
          f"about {quiet:.1f} s of the loop is the six silences")
    import song_04_autumn_dusk as dusk
    dusk.sound("12_beasts")


if __name__ == "__main__":
    if "pencil" in sys.argv:
        pencil()
    else:
        track()
    report()
