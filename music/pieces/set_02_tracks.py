"""Set 02: five separate tracks, each a file of its own, to try the other instruments.

Dominic, after the first three spikes: the game swaps whole tracks ("playing calm, then sudden
swap to fight music and back again"), so nothing here blends two moods in one file. Each track
starts at once and ends cleanly so it can be cut to and from.

    04 fight        tapan, gaida, tambura, gadulka. Fast, low, hammering, with a dark F natural.
    05 hiding       nothing regular: a low gadulka, single damped plucks, a stray heartbeat.
    06 morning      the bright quick tune he heard as "spring or morning": kaval, tambura, bells.
    07 autumn dusk  between spikes 01 and 02: the bagpipes back, in some mist.
    08 ruins        two women's voices a step apart over a held note, in a stone echo.
    08 ruins2       second take, "more mystic and ancient": a deep held note, overtones, bronze.
    09 song         a man's voice on a vowel over the drone, answered by the gaida. No words.

Run all:   python3 music/pieces/set_02_tracks.py
Run some:  python3 music/pieces/set_02_tracks.py fight ruins
"""
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
import synth as s  # noqa: E402


def lines(phrases, bpm=None):
    return [e for start, text in phrases for e in s.parse(text, start, bpm)]


def ramp(total, times, levels):
    return np.interp(np.arange(int(total * s.SR)) / s.SR, times, levels)


# ---------------------------------------------------------------- 04 fight

def fight():
    rng = np.random.default_rng(1864)
    bpm, beat = 152, 60 / 152
    # E F G A B D: the F natural, a half step over the home note, is what makes it threaten.
    P = "E4/.5 'B4 E4/.5 F4/.5 E4/.5 | G4/.5 F4/.5 E4/1 | E4/.5 'B4 E4/.5 F4/.5 G4/.5 | A4/.5 G4/.5 F4/.5 E4/.5"
    Q = "B4/1 A4/.5 G4/.5 | A4/1 G4/.5 F4/.5 | G4/.5 F4/.5 E4/.5 D4/.5 | 'B4 E4/2"
    R = "D4/.5 E4/.5 D4/.5 E4/.5 | F4/.5 E4/.5 D4/.5 E4/.5 | G4/.5 F4/.5 E4/.5 F4/.5 | 'B4 E4/2"
    order = [P, P, Q, P, R, R, Q, P, P, Q, R, P]
    lead_in = 2 * 2 * beat                       # two bars of drum before the pipes
    bars = 2 + 4 * len(order)
    end = bars * 2 * beat
    total = end + 5.0

    tune = [e for i, text in enumerate(order) for e in s.parse(text, lead_in + i * 8 * beat, bpm)]
    low = s.shift([e for e in tune if e[0] >= lead_in + 4 * 8 * beat], -12)   # gadulka joins, an octave under

    hits, strum = [], []
    for bar in range(bars):
        t0 = bar * 2 * beat
        last = bar % 4 == 1                      # the fourth bar of each phrase
        hits += [(t0, "boom", 1.0), (t0 + 1.5 * beat, "boom", 0.7)]
        if last:
            hits += [(t0 + 1.0 * beat, "boom", 0.6)]
        for i in range(8):                       # the switch never lets up
            hits.append((t0 + i * 0.25 * beat + rng.normal(0, 0.003), "tick", 0.85 if i % 2 == 0 else 0.45))
        chord = ["F2", "C3", "F3"] if last and bar > 2 else ["E2", "B2", "E3"]
        for i in range(4):
            for j, name in enumerate(chord[(i % 2):]):
                strum.append((t0 + i * 0.5 * beat + j * 0.012, 0.5 * beat, s.midi_of(name), False))
    hits.append((end, "boom", 1.4))

    drone = s.gaida_drone(s.midi_of("E2"), 0, 0, total, rng, shape=([0, 0.08, end, end + 0.08], [0, 1, 1, 0]))
    mix = s.mixdown([
        (s.drums(hits, total, rng), -17, 0.1, 1.0, 0.25),
        (drone, -24, -0.15, 0.9, 0.2),
        (s.gaida_chanter(tune, total, rng), -16, -0.25, 0.9, 0.25),
        (s.gadulka(low, total, rng), -20, 0.3, 0.8, 0.25),
        (s.tambura(strum, total, rng), -21, 0.35, 0.9, 0.2),
    ], rng, echo=2.5, dark=3000, wet=0.8)
    s.finish("track_04_fight", mix, fade_in=0.005, fade_out=2.0,
             midi=[("Kaba gaida", 109, tune), ("Gadulka", 110, low), ("Tambura", 25, strum)])


# ---------------------------------------------------------------- 05 hiding

def hiding():
    rng = np.random.default_rng(1865)
    total = 52.0
    # A low fiddle that barely moves: home note, the half step above it, back. Long gaps.
    fiddle = lines([(2.0, "E3/5.5 F3/3.0 E3/4.0"), (18.5, "B2/4.5 C3/2.5 B2/1.0 E3/5.0"),
                    (36.0, "F3/2.5 E3/2.0 D3/1.5 E3/6.5")])
    plucks, hits = [], []
    t = 6.0
    while t < total - 6:                          # single damped notes, never evenly spaced
        plucks.append((t, 0.25, s.midi_of(rng.choice(["E2", "B2", "F2", "E3"])), False))
        t += rng.uniform(2.2, 6.5)
    t = 9.0
    while t < total - 5:                          # the heart is heard now and then, not as a clock
        for _ in range(rng.integers(2, 5)):
            hits += [(t, "heart", 0.8), (t + 0.25, "heart", 0.5)]
            t += rng.uniform(0.78, 0.95)
        t += rng.uniform(4.0, 8.0)
    drone = s.gaida_drone(s.midi_of("E2"), 0, 0, total, rng, dark=350,
                          shape=([0, 4, total - 5, total], [0, 1, 1, 0]))
    air = s.wind(total, rng) * ramp(total, [0, 10, 25, 40, total], [1, 1.6, 1.1, 1.8, 1])
    mix = s.mixdown([
        (drone, -30, 0.0, 0.8, 0.5),
        (s.gadulka(fiddle, total, rng), -27, -0.2, 0.4, 0.9),
        (s.tambura(plucks, total, rng), -27, 0.4, 0.5, 0.9),
        (s.drums(hits, total, rng), -24, 0.0, 1.0, 0.2),
        (air, -31, 0, 1.0, 0.0),
    ], rng, echo=5.0, dark=2200)
    s.finish("track_05_hiding", mix, fade_in=1.5, fade_out=4.0)


# ---------------------------------------------------------------- 06 morning

def morning():
    rng = np.random.default_rng(1866)
    bpm, beat = 104, 60 / 104
    A = "E4/.5 'B4 E4/.5 G4/.5 A4/.5 | B4/1 A4/.5 G4/.5 | A4/.5 G4/.5 E4/.5 D4/.5 | E4/1 'B4 E4/1"
    B = "B4/.5 A4/.5 B4/1 | 'D5 A4/.5 G4/.5 A4/1 | G4/.5 A4/.5 G4/.5 E4/.5 | D4/.5 E4/.5 'G4 E4/1"
    C = "D5/1 B4/.5 A4/.5 | B4/.5 D5/.5 E5/1 | D5/.5 B4/.5 A4/.5 G4/.5 | A4/2"
    order = [A, A, B, A, C, B, A]
    lead_in = 4 * 2 * beat                        # four bars of tambura alone
    bars = 4 + 4 * len(order)
    end = bars * 2 * beat
    total = end + 6.0
    tune = [e for i, text in enumerate(order) for e in s.parse(text, lead_in + i * 8 * beat, bpm)]
    pluck, hits, flock = [], [], []
    for bar in range(bars):
        t0 = bar * 2 * beat
        for i, name in enumerate(["E2", "E3", "B2", "E3"]):       # a rocking figure, not a strum
            pluck.append((t0 + i * 0.5 * beat, 0.5 * beat, s.midi_of(name), False))
        if bar >= 4:
            hits += [(t0 + 0.5 * beat, "tick", 0.4), (t0 + 1.5 * beat, "tick", 0.5)]
    pluck += s.shift([e for e in tune if e[1] > s.GRACE], -12)    # tambura doubles the tune below
    t = 0.5
    while t < total - 2:                          # a flock somewhere up the slope
        flock.append((t, s.midi_of(rng.choice(["B5", "D6", "E6", "A5"])) + rng.uniform(-0.4, 0.4), rng.uniform(0.3, 1.0)))
        t += rng.exponential(0.9)
    drone = s.gaida_drone(s.midi_of("E3"), 0, 0, total, rng, dark=700, shape=([0, 3, end, end + 4], [0, 1, 1, 0]))
    mix = s.mixdown([
        (s.kaval(tune, total, rng, breath_level=0.14), -20, 0.25, 0.6, 0.7),
        (s.tambura(pluck, total, rng), -22, -0.3, 0.9, 0.35),
        (s.drums(hits, total, rng), -30, 0.1, 1.0, 0.3),
        (s.bells(flock, total, rng), -34, 0.6, 0.15, 1.0),
        (drone, -33, 0.0, 0.7, 0.4),
        (s.wind(total, rng), -40, 0, 1.0, 0.0),
    ], rng, echo=3.5, dark=4500, wet=0.8)
    s.finish("track_06_morning", mix, fade_in=0.05, fade_out=4.0,
             midi=[("Kaval", 75, tune), ("Tambura", 25, pluck)])


# ---------------------------------------------------------------- 07 autumn dusk, second take

def dusk():
    rng = np.random.default_rng(1867)
    total = 76.0
    kaval = lines([
        (5.0, "B4/3.0~ 'D5 B4/0.5 A4/0.9 B4/0.5 D5/2.4~ 'E5 D5/0.4 B4/0.9 A4/0.5 G4/0.5 A4/3.2~"),
        (34.5, "E5/2.4~ D5/0.5 B4/0.6 D5/2.6~"),
        (57.5, "G4/0.8 A4/0.8 B4/2.8~ 'D5 B4/0.4 A4/0.7 G4/0.9 E4/1.1 D4/0.8 E4/6.5~"),
    ])
    gaida = lines([
        (20.5, "'B4 E4/2.6~ 'B4 E4/0.4 D4/0.5 E4/0.5 G4/0.9 A4/2.4~ 'B4 A4/0.4 G4/0.8 'B4 G4/0.3 E4/0.5 D4/0.5 E4/3.2~"),
        (41.0, "G4/0.5 A4/0.5 B4/2.6~ A4/0.08 B4/0.5 A4/0.9 'B4 G4/1.2 'B4 G4/0.3 E4/0.5 D4/0.6 E4/0.5 D4/0.5 B3/1.0 'B4 D4/0.6 'B4 E4/4.2~"),
    ])
    # The drone is the full low pipe again, but duller and further back than in spike 01.
    drone = s.gaida_drone(s.midi_of("E2"), 1.0, total - 2, total, rng, dark=1300)
    mix = s.mixdown([
        (s.kaval(kaval, total, rng, breath_level=0.16), -23, 0.35, 0.35, 1.0),
        (s.gaida_chanter(gaida, total, rng), -20, -0.25, 0.7, 0.6),
        (drone, -28, -0.15, 0.7, 0.45),
        (s.mist([(0.0, total - 2, ["B4", "E5", "G5", "A5"])], total, rng), -35, 0.0, 0.2, 1.0),
        (s.wind(total, rng), -37, 0, 1.0, 0.0),
    ], rng, echo=5.5, predelay=0.05, dark=3000)
    s.finish("track_07_autumn_dusk", mix, fade_in=2.0, fade_out=6.0,
             midi=[("Kaval", 75, kaval), ("Kaba gaida", 109, gaida)])


# ---------------------------------------------------------------- 08 ruins

def ruins():
    rng = np.random.default_rng(1868)
    total = 54.0
    # One voice holds A and only stops to breathe. The other leans on the notes next to it,
    # so the two rub a step apart, the way the drone singing of Nedelino and Pirin does.
    held = lines([(3.0, "A4/8.5 -/0.7 A4/9.5 -/0.7 A4/8.0 -/0.8 A4/9.0 -/0.7 A4/7.0")])
    moving = lines([
        (4.5, "A4/1.5 B4/3.2~ A4/1.0 G4/2.2 A4/3.0~ C5/1.2 B4/3.4~ A4/3.5"),
        (26.5, "B4/2.6~ C5/0.8 B4/2.2 A4/1.0 G4/2.8~ A4/1.0 B4/4.0~ A4/6.0"),
    ])
    stones = s.gaida_drone(s.midi_of("A2"), 0, 0, total, rng, dark=300, shape=([0, 6, total - 6, total], [0, 1, 1, 0]))
    mix = s.mixdown([
        (s.voice(held, total, rng, singers=3), -22, -0.3, 0.35, 1.0),
        (s.voice(moving, total, rng, singers=1), -21, 0.3, 0.35, 1.0),
        (stones, -36, 0.0, 0.5, 0.8),
        (s.wind(total, rng), -38, 0, 1.0, 0.0),
    ], rng, echo=7.0, predelay=0.08, dark=3200, wet=1.1)
    s.finish("track_08_ruins", mix, fade_in=1.5, fade_out=6.0,
             midi=[("Held voices", 52, held), ("Moving voice", 52, moving)])


# ---------------------------------------------------------------- 08b ruins, second take

def ruins2():
    """After "ruins generally need more mystic and ancient feel".

    Older than the village's music, so it steps outside it: no pipes, no five-note tune.
    Men hold one deep note. Its natural overtones glint above it. Something bronze is struck
    and left to ring. One far voice chants on three notes, the middle one pitched between the
    piano's keys. A low kaval speaks once at the end, the men's own world looking in.
    """
    rng = np.random.default_rng(1869)
    total = 84.0
    deep = lines([(1.0, "A2/11 -/1.2 A2/12 -/1.2 A2/11.5 -/1.2 A2/12 -/1.2 A2/13 -/1.2 A2/10")])
    deeper = s.shift(lines([(4.0, "A2/13 -/1.5 A2/14 -/1.5 A2/13 -/1.5 A2/14 -/1.5 A2/12")]), -12)
    chant = lines([
        (16.0, "A3/3.0 B3/2.2 A3/1.2 G3/2.5 A3/5.0~"),
        (36.0, "A3/1.5 B3/2.0 C4/3.5~ B3/1.6 A3/1.2 G3/2.0 A3/5.5~"),
        (58.0, "C4/3.0~ B3/2.4 A3/6.0~"),
    ])
    quarter = s.midi_of("B3")
    chant = [(a, d, m - 0.5 if m == quarter else m, v) for a, d, m, v in chant]   # B, a quarter-tone flat
    kaval = lines([(68.0, "E4/3.2~ D4/0.8 E4/0.7 A3/7.5~")])
    hits = [(0.3, s.midi_of("A2"), 1.0), (30.0, s.midi_of("E2"), 0.7), (54.5, s.midi_of("A2"), 0.9)]
    mix = s.mixdown([
        (s.hum(deep, total, rng, voices=4), -24, -0.2, 0.5, 0.8),
        (s.hum(deeper, total, rng, voices=3), -27, 0.2, 0.6, 0.6),
        (s.overtones(110.0, [6, 7, 8, 9, 10, 11, 12], 6.0, total - 4, total, rng), -29, 0.0, 0.15, 1.0),
        (s.struck(hits, total, rng), -24, 0.1, 0.5, 1.0),
        (s.voice(chant, total, rng, singers=2, vowel="oh"), -23, 0.35, 0.1, 1.0),
        (s.kaval(kaval, total, rng, breath_level=0.3), -27, -0.4, 0.2, 1.0),
        (s.wind(total, rng), -40, 0, 1.0, 0.0),
    ], rng, echo=10.0, predelay=0.09, dark=2600, wet=1.2)
    s.finish("track_08_ruins_take2", mix, fade_in=0.02, fade_out=8.0)


# ---------------------------------------------------------------- 09 a sung line, without words

def song():
    """After "What about singing?": what this bench can do, and where it stops.

    One man sings the autumn dusk tune on an open vowel over the gaida's drone, and the gaida
    answers him, as the pipe does for a singer in the Rhodopes. There are no words: the bench
    can hold a vowel and slide between notes, but it cannot form consonants or the catches in
    the throat that make this singing what it is. It shows where a voice would sit.
    """
    rng = np.random.default_rng(1870)
    total = 62.0
    man = lines([
        (4.0, "B3/3.0~ 'D4 B3/0.5 A3/0.8 B3/0.5 D4/2.6~ 'E4 D4/0.4 B3/1.0 A3/0.5 G3/0.6 A3/3.4~"),
        (33.0, "B3/0.6 D4/0.6 E4/3.2~ 'G4 E4/0.5 D4/0.9 'E4 D4/0.3 B3/1.2 A3/0.5 G3/0.7 A3/0.5 G3/0.5 E3/5.0~"),
    ])
    gaida = lines([
        (19.0, "'B4 E4/2.4~ 'B4 E4/0.4 D4/0.5 E4/0.5 G4/0.9 A4/2.2~ 'B4 A4/0.4 G4/0.8 'B4 G4/0.3 E4/0.5 D4/0.5 E4/2.8~"),
        (49.0, "'B4 G4/0.5 'B4 E4/0.5 D4/0.6 'B4 E4/5.0~"),
    ])
    drone = s.gaida_drone(s.midi_of("E2"), 0.5, total - 1, total, rng, dark=1500)
    mix = s.mixdown([
        (s.voice(man, total, rng, singers=1, vowel="ah"), -20, 0.1, 0.6, 0.8),
        (s.gaida_chanter(gaida, total, rng), -23, -0.3, 0.7, 0.5),
        (drone, -27, -0.2, 0.7, 0.4),
        (s.wind(total, rng), -40, 0, 1.0, 0.0),
    ], rng, echo=5.0, predelay=0.05, dark=3200)
    s.finish("track_09_song_without_words", mix, fade_in=1.0, fade_out=5.0,
             midi=[("Voice", 52, man), ("Kaba gaida", 109, gaida)])


TRACKS = {"fight": fight, "hiding": hiding, "morning": morning, "dusk": dusk, "ruins": ruins, "ruins2": ruins2, "song": song}

if __name__ == "__main__":
    for name in sys.argv[1:] or TRACKS:
        TRACKS[name]()
