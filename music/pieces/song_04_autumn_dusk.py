"""04 Autumn dusk: the first track made through the design stage (docs/music-design.md, D-073).

Dominic, 2026-11-11 21:13 UTC: "for the music for phase 1, lets focus on just getting that music creation solid. So we
make one good song for that demo." This is that song, the one the demo plays while the men make camp at dusk in
autumn. Its sheet is "Autumn dusk" in docs/music-design.md; this file is the third step, the track.

The one idea: one piper at the camp plays as slowly as he can. The pipe holds, it does not run.

    0:00  the wood at dusk; the drone fills the bag and settles
    0:10  three phrases, each climbing one step further than the last (to G, then A, then B) and sinking home
    1:19  the one leap: up a fifth from home, to the top of the pipe (D5), held, and down by steps
    2:00  the drone stops; wind; at 2:04 a low kaval far off answers with two notes, a leap down a fifth
    2:26  gone

    python3 music/pieces/song_04_autumn_dusk.py          the track (about a minute to render)
    python3 music/pieces/song_04_autumn_dusk.py pencil   the pencil sketch again: the tune on one plain sound
Writes music/out/04_autumn_dusk.wav and .mp3, the game's assets/audio/music/04_autumn_dusk.ogg, and
music/tracks/04_autumn_dusk.mid; then measures it beside its neighbours (music/measure.py, moves()).
"""
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import synth as s  # noqa: E402

E = s.midi_of
TOTAL = 146.0

# The pipe. A rest between phrases is the piper taking the bag under his arm again. Repeated notes are parted by the
# bip (the flick to B a piper uses, since he can't tongue), as in 'B4 A4.
PIPE = [
    # 1: home, up to G, home
    (10.0, "'B4 E4/4.5~ G4/3.5~ 'B4 E4/5.5~"),
    # 2: home, G, up to A and said twice, down to G, home
    (28.0, "'B4 E4/2.5 G4/2.0 A4/4.0~ 'B4 A4/2.5 G4/2.5 'B4 E4/5.5~"),
    # 3: G, A, up to B and held, down past home to D, and home
    (51.0, "'B4 G4/2.0 A4/2.0 B4/5.5~ A4/3.0 'B4 G4/3.0 D4/2.5 'B4 E4/7.0~"),
    # 4: the leap. From home straight to B, on up to the pipe's top note, held as long as he has air, then down by
    # steps the whole way, resting on each, to a long home.
    (79.0, "E4/2.0 B4/4.5~ D5/6.5~ 'E5 D5/2.0 B4/3.0 A4/3.5~ 'B4 A4/1.5 G4/3.0 'B4 E4/2.0 D4/2.5 'B4 E4/9.0~"),
]
# The kaval, far off across the valley: the only other player, and only once the pipe has stopped.
KAVAL = [(124.0, "B3/4.5~ E3/8.0~")]
KAVAL_SPAN = (124.0, 136.5)
DRONE_OFF = 120.0     # the drone stops a few seconds after the pipe's last note


def level_over(x, db, a, b):
    """synth.level, measured only between a and b seconds: for a part that plays for a short while."""
    part = x[:, int(a * s.SR):int(b * s.SR)]
    return x * (s.level(part, db).max() / (np.abs(part).max() + 1e-12))


def lines(phrases):
    return [e for start, text in phrases for e in s.parse(text, start)]


def track():
    rng = np.random.default_rng(2204)
    pipe, kaval = lines(PIPE), lines(KAVAL)
    # the drone two octaves under the home note, dark and low in the mix, so it is a floor and not a roar ("a little
    # too Viking" was a loud bright drone); it breathes with the bag, and stops before the kaval
    drone = s.gaida_drone(E("E2"), 1.5, DRONE_OFF, TOTAL, rng, dark=900,
                          shape=([1.5, 8.0, 50.0, 79.0, 86.0, 104.0, DRONE_OFF - 4, DRONE_OFF],
                                 [0.0, 0.6, 0.75, 0.9, 1.6, 1.6, 0.9, 0.0]))
    near = s.mixdown([                      # at this fire: close, a little echo off the trees
        (s.kaba_chanter(pipe, TOTAL, rng), -20, -0.15, 0.85, 0.35),
        (drone, -27, -0.05, 0.85, 0.25),
        (s.wind(TOTAL, rng), -39, 0.0, 1.0, 0.0),
    ], rng, echo=2.2, predelay=0.02, dark=2800, wet=0.6)
    # the mist: the same pipe heard again in a long, dark echo far under it, so each held note leaves a haze behind
    haze = s.mixdown([(s.kaba_chanter(pipe, TOTAL, np.random.default_rng(2205)), -20, 0.0, 0.0, 1.0)],
                     rng, echo=9.0, predelay=0.12, dark=900, wet=1.0)
    far = s.mixdown([                       # across the valley
        (s.kaval(kaval, TOTAL, rng, breath_level=0.3), -22, 0.35, 0.25, 1.0),
    ], rng, echo=6.5, predelay=0.08, dark=2400, wet=1.0)
    # the haze thickens for the leap and thins after it: the one swell in the piece, since the pipe itself can't swell
    t = np.arange(haze.shape[1]) / s.SR
    haze = haze * np.interp(t, [0, 70, 88, 112, 125], [0.6, 0.8, 2.2, 2.2, 0.8])
    # the kaval is set by where it plays (synth.level over the whole track would count its two minutes of silence and
    # push it far too loud): softer than the pipe was, as it is across the valley
    mix = near + s.level(haze, -33) + level_over(far, -29, *KAVAL_SPAN)
    import set_03_score as score
    score.done("04_autumn_dusk", mix, "calm", fade_in=3.0, fade_out=6.0,
               midi=[("Kaba gaida", 109, pipe), ("Kaval", 75, kaval)])


def pencil():
    """The tune alone on one plain sound, so its shape can be judged without the arrangement."""
    rng = np.random.default_rng(2206)
    notes = lines(PIPE) + lines(KAVAL)
    mix = s.mixdown([(s.kaval(notes, TOTAL, rng, breath_level=0.05), -20, 0.0, 1.0, 0.2)], rng, echo=1.5, wet=0.4)
    s.finish("pencil_04_autumn_dusk", mix)


SCALE = [E(n) for n in ("D3", "E3", "G3", "A3", "B3", "D4", "E4", "G4", "A4", "B4", "D5", "E5")]


def report():
    """How the tune moves, beside the first draft's: the numbers the design sheet promised. A leap is a move past the
    next note of the five-note scale."""
    import design_sketches as d
    for label, ev in (("designed", lines(PIPE) + lines(KAVAL)), ("first draft", lines(d.DUSK_WAS))):
        notes = [e for e in ev if e[2] is not None and e[1] > s.GRACE]
        mids = [e[2] for e in notes]
        moves = [abs(SCALE.index(b) - SCALE.index(a)) for a, b in zip(mids, mids[1:])]
        mean, quick = d.moves(ev)
        print(f"{label:12s} {len(notes):3d} notes, {mean:.1f} s a note, {quick * 100:.0f}% under a second, "
              f"{sum(1 for x in moves if x > 1)} leaps, {moves.count(0)} notes said twice")
    sound("04_autumn_dusk")


def sound(name):
    """Where a render's energy sits (the first draft had two thirds of it in 300-600 Hz), and how far its quiet
    stretches fall below its loud ones (the first draft moved only 9 to 11 dB: "too flat")."""
    import wave
    path = HERE.parents[1] / "out" / f"{name}.wav"
    if not path.exists():
        return
    with wave.open(str(path)) as w:
        x = np.frombuffer(w.readframes(w.getnframes()), "<i2").reshape(-1, 2).T.mean(axis=0) / 32768
    spec = np.abs(np.fft.rfft(x)) ** 2
    freq = np.fft.rfftfreq(len(x), 1 / s.SR)
    edges = [40, 150, 300, 600, 1200, 2400, 8000]
    whole = spec[(freq > 40) & (freq < 8000)].sum()
    bands = "  ".join(f"{a}-{b} Hz {spec[(freq > a) & (freq < b)].sum() / whole * 100:.0f}%" for a, b in zip(edges, edges[1:]))
    win = 2 * s.SR
    db = 10 * np.log10((x[: len(x) // win * win].reshape(-1, win) ** 2).mean(axis=1) + 1e-12)
    db = db[3:-3]                                         # leave out the fades
    print(f"{name}: {bands}")
    print(f"{name}: quiet to loud {np.percentile(db, 90) - np.percentile(db, 10):.1f} dB (10th to 90th percentile of 2 s stretches)")


if __name__ == "__main__":
    if "pencil" in sys.argv:
        pencil()
    else:
        track()
    report()
