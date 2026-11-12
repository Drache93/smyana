"""Set 03: the whole score, first draft. Every track of the plan (docs/music-tracks.md) but the ruins.

Dominic, 2026-11-11: "it's time to also start an agent ... on putting together all the music that we
planned. So we can get first draft of that." These are drafts: every one is there to be heard in the
game and then changed. The ruins (17) stay parked, as he left them on 2026-11-10.

What is new here:
  the main theme (THEME below): four slow lines on five notes, a song about leaving. Tracks 7, 9, 19,
    20, 22, 23 and 24 are made of it.
  loops: a danger track is cut to on its first sound and goes round with no seam (synth.fold, synth.seam).
  levels: each track is brought to a loudness of its own (LOUD), so the game plays them all at one volume.

Run all:    python3 music/pieces/set_03_score.py            (four at a time; about ten minutes)
Run some:   python3 music/pieces/set_03_score.py summer_day bandits
Then:       python3 music/pieces/set_03_score.py index      (writes data/music_tracks.json: each track's length)

Each track is written to music/out/ (WAV, MP3), to assets/audio/music/ (the Ogg Vorbis file the game
plays) and, where it has a tune, to music/tracks/ (MIDI).
"""
import json
import pathlib
import subprocess
import sys
import wave

import numpy as np

HERE = pathlib.Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import synth as s  # noqa: E402
import set_02_tracks as set_02  # noqa: E402

ROOT = HERE.parents[2]
OUT = HERE.parents[1] / "out"
GAME = ROOT / "assets" / "audio" / "music"
MIDI = HERE.parents[1] / "tracks"
E = s.midi_of

# The main theme, at the kaval's pitch (home note E4). A man sings it an octave down.
#   1 the call: up to the fifth, and it stays there, unanswered
#   2 the answer: over the top and down to rest on the fourth, not yet home
#   3 the turn: the highest line, the thought of home
#   4 home: down through the same steps to the home note
THEME = [
    "E4/0.6 G4/0.6 A4/2.6~ 'B4 A4/0.5 G4/0.8 A4/0.5 B4/3.0~",
    "B4/0.6 D5/2.2~ 'E5 D5/0.4 B4/0.9 A4/0.5 G4/0.6 A4/3.2~",
    "A4/0.5 B4/0.5 D5/0.7 E5/2.8~ D5/0.5 B4/1.0 'D5 B4/0.4 A4/0.6 G4/2.4~",
    "G4/0.6 A4/0.6 B4/1.8~ A4/0.5 G4/0.7 'A4 G4/0.3 E4/0.9 D4/0.7 E4/4.5~",
]
# The same four lines walked, in beats, for the homecoming.
THEME_WALKED = [
    "E4/1 G4/1 A4/2 | 'B4 A4/1 G4/1 A4/1 B4/1 | B4/4~",
    "B4/1 D5/2 'E5 D5/1 | B4/1 A4/1 G4/1 A4/1 | A4/4~",
    "A4/1 B4/1 D5/1 E5/1 | E5/2~ D5/1 B4/1 | 'D5 B4/1 A4/1 G4/2~",
    "G4/1 A4/1 B4/2 | A4/1 G4/1 'A4 G4/1 E4/1 | D4/1 E4/3~ | E4/4~",
]

# How loud each track is where it plays (synth.loudness, dB). Calm music sits under the wind; danger is in front.
LOUD = {"calm": -27, "tense": -26, "danger": -20, "moment": -26, "frame": -24, "homecoming": -19, "menu": -31, "stroke": -17}


def lines(phrases, bpm=None):
    return [e for start, text in phrases for e in s.parse(text, start, bpm)]


def theme(start, which=(0, 1, 2, 3), gap=1.8, semis=0, slow=1.0):
    """Lines of the theme one after another. Returns the notes and the time the last one ends."""
    out, t = [], start
    for i in which:
        notes = [(t + a * slow, d * slow, m, v) for a, d, m, v in s.parse(THEME[i])]
        out += notes
        t = s.end_of(notes) + gap
    return s.shift(out, semis), t - gap


def late(events, seconds):
    return [(a + seconds, d, m, v) for a, d, m, v in events]


def scattered(rng, first, last, lo, hi, pick):
    """Things at uneven times between first and last, lo..hi seconds apart: (time, pick())."""
    out, t = [], first
    while t < last:
        out.append((t, pick()))
        t += rng.uniform(lo, hi)
    return out


def plucks(rng, first, last, lo, hi, names, length=0.3):
    return [(t, length, E(n), False) for t, n in scattered(rng, first, last, lo, hi, lambda: rng.choice(names))]


def rocking(first, last, step, chord_at, rng):
    """A tambura rocking over a chord, one note every `step` seconds. chord_at(t) -> four note names."""
    out, t, i = [], first, 0
    while t < last:
        out.append((t + rng.normal(0, 0.012), step, E(chord_at(t)[i % 4]), False))
        t += step
        i += 1
    return out


def flock(rng, first, last, every, names=("B5", "D6", "E6", "A5")):
    return [(t, E(n) + rng.uniform(-0.4, 0.4), rng.uniform(0.3, 1.0))
            for t, n in scattered(rng, first, last, every * 0.2, every * 1.8, lambda: rng.choice(names))]


def done(name, mix, kind, fade_in=1.0, fade_out=5.0, midi=None, loop=False):
    """Write one track: out/<name>.wav and .mp3, the game's .ogg, and its MIDI."""
    OUT.mkdir(exist_ok=True)
    GAME.mkdir(parents=True, exist_ok=True)
    wav = OUT / f"{name}.wav"
    if loop:
        fade_in = fade_out = 0
    s.write_wav(wav, mix, fade_in, fade_out, loud=LOUD[kind])
    s.encode(wav, OUT / f"{name}.mp3", "-b:a", "160k")
    s.encode(wav, GAME / f"{name}.ogg", "-c:a", "libvorbis", "-q:a", "2")
    if midi:
        s.write_midi(MIDI / f"{name}.mid", midi)
    print("wrote", name, f"{mix.shape[1] / s.SR:.1f} s")


def looped(name, length, events, bed, rng, echo=3.0, dark=3000, wet=0.8, cross=4.0, kind="danger", midi=None):
    """A loop of `length` seconds. events(total) and bed(total) each return mixdown parts.

    What happens (notes, hits) may only start inside the loop; its echo is folded over the start.
    What never stops (drone, wind) is made a little longer and faded across the seam.
    """
    tail = echo * 1.3 + 1.5
    mix = s.fold(s.mixdown(events(length + tail), rng, echo=echo, dark=dark, wet=wet), length)
    parts = bed(length + cross)
    if parts:
        mix = mix + s.seam(s.mixdown(parts, rng, echo=echo, dark=dark, wet=wet), length, cross)
    done(name, mix, kind, loop=True, midi=midi)


def steady_drone(note, total, rng, dark):
    """A drone already sounding before the track starts (no sag as the bag fills), for loops."""
    return s.gaida_drone(E(note), -10, 0, total, rng, dark=dark, shape=([0, total], [1, 1]))


# ================================================================ calm: by season and time of day

def summer_day():
    """01. Kaval and tambura, unhurried, on the bright notes (it rests on G and D, not E). A flock far off."""
    rng = np.random.default_rng(1101)
    total = 126.0
    kaval = lines([
        (7.5, "D5/2.6~ 'E5 D5/0.4 B4/0.6 A4/0.5 B4/0.6 G4/3.0~"),
        (21.0, "G4/0.5 A4/0.5 B4/0.6 D5/0.6 E5/2.8~ D5/0.5 B4/0.8 'D5 B4/0.3 A4/0.6 B4/3.2~"),
        (40.0, "B4/0.6 D5/2.0~ B4/0.5 A4/0.5 G4/0.6 A4/0.6 B4/0.5 A4/0.5 G4/3.4~"),
        (60.0, "E5/2.2~ 'G5 E5/0.4 D5/0.8 E5/0.5 D5/0.5 B4/2.6~ A4/0.5 B4/0.5 D5/3.6~"),
        (82.0, "D5/0.6 B4/0.6 A4/0.6 G4/2.4~ 'A4 G4/0.4 E4/0.6 G4/0.6 A4/0.6 B4/3.0~"),
        (100.0, "A4/0.5 B4/0.5 D5/2.4~ 'E5 D5/0.4 B4/0.7 A4/0.6 G4/5.5~"),
    ])

    def chord(t):
        if 52 < t < 59 or 93 < t < 99:
            return None
        return ["D2", "A2", "D3", "A2"] if 30 < t < 37 or 71 < t < 78 else ["G2", "D3", "G3", "D3"]
    lute = [e for e in rocking(0.5, 112.0, 0.9, lambda t: chord(t) or ["G2"] * 4, rng) if chord(e[0])]
    lute.append((113.0, 3.0, E("G2"), False))
    mix = s.mixdown([
        (s.kaval(kaval, total, rng, breath_level=0.14), -20, 0.3, 0.5, 0.8),
        (s.tambura(lute, total, rng), -25, -0.3, 0.8, 0.4),
        (s.bells(flock(rng, 2.0, total - 6, 2.5), total, rng), -38, 0.6, 0.1, 1.0),
        (s.wind(total, rng), -41, 0, 1.0, 0.0),
    ], rng, echo=4.0, dark=4500, wet=0.9)
    done("01_summer_day", mix, "calm", fade_in=0.3, fade_out=6.0, midi=[("Kaval", 75, kaval), ("Tambura", 25, lute)])


def summer_dusk():
    """02. A gadulka alone over a soft drone. Warm, a little homesick: it ends on the theme's last line."""
    rng = np.random.default_rng(1102)
    fiddle = lines([
        (4.0, "B3/2.8~ 'D4 B3/0.4 A3/0.7 B3/0.5 D4/2.4~ E4/0.6 D4/0.5 B3/3.2~"),
        (22.0, "E4/2.6~ 'G4 E4/0.4 D4/0.8 'E4 D4/0.3 B3/0.9 A3/0.5 G3/0.6 A3/3.6~"),
        (41.0, "G3/0.6 A3/0.6 B3/0.6 D4/0.7 E4/1.0 G4/2.8~ E4/0.5 D4/0.6 E4/3.4~"),
        (60.0, "D4/0.5 E4/0.5 D4/0.5 B3/2.2~ A3/0.5 G3/0.7 'A3 G3/0.3 E3/3.8~"),
    ])
    home, end = theme(78.0, which=(3,), semis=-12, slow=1.1)
    fiddle += home
    total = end + 9.0
    drone = s.gaida_drone(E("E3"), 0.5, total - 2, total, rng, dark=600)
    mix = s.mixdown([
        (s.gadulka(fiddle, total, rng), -20, 0.15, 0.55, 0.75),
        (drone, -31, -0.1, 0.7, 0.5),
        (s.wind(total, rng), -42, 0, 1.0, 0.0),
    ], rng, echo=4.5, predelay=0.04, dark=3200)
    done("02_summer_dusk", mix, "calm", fade_in=1.5, fade_out=6.0, midi=[("Gadulka", 110, fiddle)])


def autumn_day():
    """03. Kaval in mist, men humming far off. Spike 02 was "too soft now": the kaval is nearer and a
    quiet low gaida drone gives it a body."""
    rng = np.random.default_rng(1103)
    total = 126.0
    kaval = lines([
        (8.0, "G4/2.8~ A4/0.5 B4/2.2~ 'D5 B4/0.4 A4/0.6 G4/0.5 E4/3.6~"),
        (24.0, "B4/0.7 D5/2.6~ 'E5 D5/0.4 B4/1.0 A4/0.5 G4/0.6 A4/3.8~"),
        (53.0, "E5/3.0~ D5/0.5 B4/0.8 A4/0.5 B4/3.5~"),
        (78.0, "A4/0.7 G4/0.7 E4/2.6~ 'G4 E4/0.5 D4/1.0 E4/5.0~"),
        (101.0, "B4/0.6 A4/0.6 G4/2.2~ A4/0.5 B4/0.6 D5/2.4~ B4/0.6 A4/0.6 G4/0.6 E4/6.0~"),
    ])
    men = lines([
        (39.0, "E3/3.0~ G3/0.6 A3/2.4~ G3/0.6 E3/0.6 D3/0.6 E3/3.8~"),
        (63.0, "G3/0.6 A3/0.6 B3/3.0~ A3/0.6 G3/0.7 A3/0.5 G3/0.5 E3/4.8~"),
        (90.0, "E3/2.6~ D3/0.6 E3/0.6 G3/2.8~ A3/0.6 G3/0.6 E3/4.0~"),
    ])
    drone = s.gaida_drone(E("E2"), 2.0, total - 3, total, rng, dark=1000)
    mix = s.mixdown([
        (s.kaval(kaval, total, rng, breath_level=0.2), -20, 0.3, 0.45, 0.9),
        (s.hum(men, total, rng, voices=4), -23, -0.3, 0.4, 0.8),
        (drone, -29, -0.1, 0.7, 0.4),
        (s.mist([(0.0, total - 3, ["B4", "E5", "G5", "A5"])], total, rng), -35, 0.0, 0.2, 1.0),
        (s.wind(total, rng), -37, 0, 1.0, 0.0),
    ], rng, echo=6.0, predelay=0.06, dark=2600)
    done("03_autumn_day", mix, "calm", fade_in=3.0, fade_out=7.0, midi=[("Kaval", 75, kaval), ("Men humming", 53, men)])


def autumn_dusk():
    """04. Made through the design stage now (2026-11-11 evening): see song_04_autumn_dusk.py and the sheet in
    docs/music-design.md. The first draft's version (gaida and kaval answering, quick) is in git history."""
    import song_04_autumn_dusk
    song_04_autumn_dusk.track()


def autumn_night():
    """05. A low gadulka, long gaps, the drone barely there."""
    rng = np.random.default_rng(1105)
    total = 102.0
    fiddle = lines([
        (5.0, "E3/3.6~ G3/0.7 A3/2.6~ G3/0.6 E3/4.0~"),
        (27.0, "B3/3.0~ A3/0.6 G3/0.8 A3/0.5 G3/0.6 E3/0.8 D3/0.7 E3/4.5~"),
        (52.0, "A3/0.7 B3/0.7 D4/3.2~ B3/0.8 A3/2.8~"),
        (72.0, "G3/0.8 E3/0.8 D3/2.6~ E3/0.7 G3/0.7 E3/6.0~"),
    ])
    drone = s.gaida_drone(E("E2"), 0.5, total - 2, total, rng, dark=350)
    mix = s.mixdown([
        (s.gadulka(fiddle, total, rng), -22, -0.15, 0.35, 1.0),
        (drone, -32, 0.0, 0.8, 0.4),
        (s.mist([(10.0, total - 6, ["B4", "E5"])], total, rng), -40, 0.2, 0.1, 1.0),
        (s.wind(total, rng), -36, 0, 1.0, 0.0),
    ], rng, echo=7.0, predelay=0.07, dark=2000, wet=1.1)
    done("05_autumn_night", mix, "calm", fade_in=3.0, fade_out=7.0, midi=[("Gadulka", 110, fiddle)])


def winter_day():
    """06. Almost nothing: wind, single tambura notes, a kaval phrase now and then."""
    rng = np.random.default_rng(1106)
    total = 106.0
    kaval = lines([
        (18.0, "B4/3.0~ A4/0.6 G4/0.7 E4/3.5~"),
        (52.0, "E5/2.4~ D5/0.6 B4/3.6~"),
        (84.0, "G4/0.7 A4/0.7 B4/2.0~ A4/0.6 G4/0.6 E4/5.0~"),
    ])
    lute = plucks(rng, 4.0, total - 10, 4.0, 9.0, ["E3", "B3", "E4", "G3", "A3", "B2"], length=1.5)
    air = s.wind(total, rng) * set_02.ramp(total, [0, 20, 45, 70, total], [1, 1.5, 0.9, 1.6, 1])
    mix = s.mixdown([
        (s.kaval(kaval, total, rng, breath_level=0.28), -23, 0.3, 0.25, 1.0),
        (s.tambura(lute, total, rng), -25, -0.25, 0.5, 0.9),
        (air, -30, 0, 1.0, 0.0),
    ], rng, echo=6.5, predelay=0.07, dark=2800, wet=1.1)
    done("06_winter_day", mix, "calm", fade_in=3.0, fade_out=7.0, midi=[("Kaval", 75, kaval), ("Tambura", 25, lute)])


def winter_night():
    """07. One man's voice, alone: the theme, slow. The deepest point of the run. A vowel stands in for
    the words until there is a singer (docs/music-tracks.md, "Singing")."""
    rng = np.random.default_rng(1107)
    man, end = theme(3.0, gap=3.5, semis=-12, slow=1.15)
    total = end + 9.0
    mix = s.mixdown([
        (s.voice(man, total, rng, singers=1, vowel="oh"), -21, 0.05, 0.5, 0.9),
        (s.wind(total, rng), -36, 0, 1.0, 0.0),
    ], rng, echo=7.0, predelay=0.08, dark=2400, wet=1.0)
    done("07_winter_night", mix, "calm", fade_in=2.0, fade_out=7.0, midi=[("Voice", 52, man)])


def spring_morning():
    """08. The quick bright tune Dominic heard as "spring or morning time" (set 02's "morning"), as it was."""
    set_02.morning(lambda mix, midi: done("08_spring_morning", mix, "calm", fade_in=0.05, fade_out=4.0, midi=midi))


def spring_day():
    """09. The theme, hinted, on kaval, with women's voices far off as home nears."""
    rng = np.random.default_rng(1109)
    k1, t = theme(6.0, which=(0, 1), gap=2.5)
    women1, t = theme(t + 4.0, which=(0,), semis=0)
    k2, t = theme(t + 2.0, which=(2,))
    women2, t = theme(t + 3.0, which=(3,))
    k3, end = theme(t - 4.0, which=(3,), slow=1.05)
    total = end + 10.0
    kaval, women = k1 + k2 + k3, women1 + women2
    lute = rocking(0.5, end - 3, 0.8, lambda t: ["E3", "B3", "E4", "B3"], rng)
    lute.append((end - 2.0, 3.0, E("E3"), False))
    mix = s.mixdown([
        (s.kaval(kaval, total, rng, breath_level=0.15), -20, 0.3, 0.5, 0.8),
        (s.voice(women, total, rng, singers=3, vowel="oh"), -29, -0.45, 0.05, 1.0),
        (s.tambura(lute, total, rng), -27, -0.2, 0.8, 0.4),
        (s.bells(flock(rng, 20.0, total - 6, 3.0), total, rng), -39, 0.6, 0.1, 1.0),
        (s.wind(total, rng), -41, 0, 1.0, 0.0),
    ], rng, echo=5.0, predelay=0.05, dark=4000)
    done("09_spring_day", mix, "calm", fade_in=0.5, fade_out=7.0,
         midi=[("Kaval", 75, kaval), ("Women, far off", 52, women), ("Tambura", 25, lute)])


# ================================================================ danger: cut to at once, looping

def wary():
    """10. The tune gone. A low drone and single damped tambura notes, never evenly spaced. For tracks in
    the mud, a howl, smoke on a ridge."""
    rng = np.random.default_rng(1110)
    length = 56.0
    notes = [(0.0, 0.3, E("E2"), False)] + plucks(rng, 3.5, length - 2, 2.5, 7.0, ["E2", "B2", "E3", "F3", "F2"])
    looped("10_wary", length,
           lambda total: [(s.tambura(notes, total, rng), -24, 0.3, 0.6, 0.9)],
           lambda total: [(steady_drone("E2", total, rng, 500), -26, 0.0, 0.8, 0.4),
                          (s.wind(total, rng), -32, 0, 1.0, 0.0)],
           rng, echo=5.0, dark=2200, wet=1.0, kind="tense")


def hiding():
    """11. Nothing regular, so it can't get repetitive: a low gadulka that barely moves, a stray heartbeat,
    single plucks, wind. The men and the carts are in the undergrowth, and somebody is passing."""
    rng = np.random.default_rng(1111)
    length = 74.0
    fiddle = lines([(2.0, "E3/5.5 F3/3.0 E3/4.0"), (21.0, "B2/4.5 C3/2.5 B2/1.0 E3/5.0"),
                    (43.0, "F3/2.5 E3/2.0 D3/1.5 E3/6.5"), (62.0, "B2/3.0 C3/2.0 B2/4.0")])
    notes = plucks(rng, 6.0, length - 3, 2.2, 6.5, ["E2", "B2", "F2", "E3"], length=0.25)
    hits, t = [], 9.0
    while t < length - 6:                         # the heart is heard now and then, not as a clock
        for _ in range(rng.integers(2, 5)):
            hits += [(t, "heart", 0.8), (t + 0.25, "heart", 0.5)]
            t += rng.uniform(0.78, 0.95)
        t += rng.uniform(4.0, 8.0)
    looped("11_hiding", length,
           lambda total: [(s.gadulka(fiddle, total, rng), -27, -0.2, 0.4, 0.9),
                          (s.tambura(notes, total, rng), -27, 0.4, 0.5, 0.9),
                          (s.drums(hits, total, rng), -24, 0.0, 1.0, 0.2)],
           lambda total: [(steady_drone("E2", total, rng, 350), -30, 0.0, 0.8, 0.5),
                          (s.wind(total, rng), -30, 0, 1.0, 0.0)],
           rng, echo=5.0, dark=2200, wet=1.0, kind="tense")


def beasts():
    """12. Wolves and bears. The drum and the drone only, no tune: animals have no music. The hits come
    fast in uneven twos and threes, with holes in them, so nobody can settle into it."""
    rng = np.random.default_rng(1112)
    eighth = 60 / 168 / 2
    hits, n = [], 0
    while n < 256:
        group = int(rng.choice([2, 3, 3]))
        hole = n and rng.random() < 0.12          # now and then the drum holds its breath
        if not hole:
            hits.append((n * eighth, "boom", 1.0 if group == 3 else 0.75))
            for i in range(1, group):
                hits.append(((n + i) * eighth + rng.normal(0, 0.004), "tick", 0.6))
                if rng.random() < 0.2:            # a ruffle
                    hits.append(((n + i + 0.5) * eighth, "tick", 0.4))
        n += group
    length = n * eighth

    def bed(total):
        growl = steady_drone("F2", total, rng, 500) * np.clip(0.2 + 1.2 * s.wander(total, 0.15, rng), 0, 1)
        return [(steady_drone("E2", total, rng, 700), -24, -0.2, 0.9, 0.3), (growl, -27, 0.3, 0.9, 0.3)]
    looped("12_beasts", length, lambda total: [(s.drums(hits, total, rng), -16, 0.0, 1.0, 0.3)], bed,
           rng, echo=2.5, dark=2500, wet=0.8)


# The fight tunes: E F G A B D. The F natural, a half step over the home note, is what makes them threaten.
P = "E4/.5 'B4 E4/.5 F4/.5 E4/.5 | G4/.5 F4/.5 E4/1 | E4/.5 'B4 E4/.5 F4/.5 G4/.5 | A4/.5 G4/.5 F4/.5 E4/.5"
Q = "B4/1 A4/.5 G4/.5 | A4/1 G4/.5 F4/.5 | G4/.5 F4/.5 E4/.5 D4/.5 | 'B4 E4/2"
R = "D4/.5 E4/.5 D4/.5 E4/.5 | F4/.5 E4/.5 D4/.5 E4/.5 | G4/.5 F4/.5 E4/.5 F4/.5 | 'B4 E4/2"
S = "B4/.5 'D5 B4/.5 A4/.5 B4/.5 | D5/1 B4/.5 A4/.5 | B4/.5 A4/.5 G4/.5 F4/.5 | 'B4 E4/2"


def drive(name, seed, bpm, order, fiddle_from, drums_db, pipes_db, heavy=False):
    """A fight in hard 2/4: two bars of drum, then the pipes. It goes round with no seam and no ending:
    the game stops it with an end stroke."""
    rng = np.random.default_rng(seed)
    beat = 60 / bpm
    lead_in = 2 * 2 * beat
    bars = 2 + 4 * len(order)
    length = bars * 2 * beat
    tune = [e for i, text in enumerate(order) for e in s.parse(text, lead_in + i * 8 * beat, bpm)]
    low = s.shift([e for e in tune if e[0] >= lead_in + fiddle_from * 8 * beat], -12)
    hits, strum = [], []
    for bar in range(bars):
        t0 = bar * 2 * beat
        last = bar % 4 == 1                      # the fourth bar of each phrase
        hits += [(t0, "boom", 1.0), (t0 + 1.5 * beat, "boom", 0.7)]
        if last or (heavy and bar % 2 == 1):
            hits += [(t0 + 1.0 * beat, "boom", 0.6)]
        for i in range(8):                       # the switch never lets up
            hits.append((t0 + i * 0.25 * beat + abs(rng.normal(0, 0.003)), "tick", 0.85 if i % 2 == 0 else 0.45))
        chord = ["F2", "C3", "F3"] if last and bar > 2 else ["E2", "B2", "E3"]
        for i in range(4):
            for j, note in enumerate(chord[(i % 2):]):
                strum.append((t0 + i * 0.5 * beat + j * 0.012, 0.5 * beat, E(note), False))
    looped(name, length,
           lambda total: [(s.drums(hits, total, rng), drums_db, 0.1, 1.0, 0.25),
                          (s.gaida_chanter(tune, total, rng), pipes_db, -0.25, 0.9, 0.25),
                          (s.gadulka(low, total, rng), pipes_db - 4, 0.3, 0.8, 0.25),
                          (s.tambura(strum, total, rng), -21, 0.35, 0.9, 0.2)],
           lambda total: [(steady_drone("E2", total, rng, 2600), -24, -0.15, 0.9, 0.2)],
           rng, echo=2.5, dark=3000, wet=0.8, cross=1.0,
           midi=[("Kaba gaida", 109, tune), ("Gadulka", 110, low), ("Tambura", 25, strum)])


def bandits():
    """13. Tapan, kaba gaida, tambura, gadulka: fast plain 2/4, low, hammering (set 02's "fight", longer)."""
    drive("13_bandits", 1113, 152, [P, P, Q, P, R, R, Q, P, P, Q, R, P, S, S, Q, P, R, Q, P, P], 4, -17, -16)


def ottomans():
    """14. Their own sound, so the player hears who is coming: a zurna over a second one holding the home
    note, and the davul, slower and heavier than the bandits' drum. Their own scale too (E F G# A B C D:
    the wide step from F to G# is the sound of it)."""
    rng = np.random.default_rng(1114)
    bpm, beat = 100, 0.6
    z1 = "E4/1 'F4 E4/.5 F4/.5 G#4/1 A4/1 | G#4/.5 F4/.5 G#4/.5 A4/.5 B4/2~ | A4/.5 G#4/.5 F4/.5 G#4/.5 A4/1 G#4/.5 F4/.5 | 'F4 E4/4~"
    z2 = "B4/1.5 C5/.5 B4/1 A4/1 | G#4/.5 A4/.5 B4/.5 C5/.5 D5/2~ | C5/.5 B4/.5 A4/.5 G#4/.5 A4/.5 G#4/.5 F4/1 | 'F4 E4/4~"
    z3 = "E5/2~ D5/.5 C5/.5 B4/1 | C5/.5 B4/.5 A4/.5 G#4/.5 A4/2~ | B4/.5 A4/.5 G#4/.5 F4/.5 G#4/.5 F4/.5 E4/1 | F4/.5 G#4/.5 F4/.5 'F4 E4/2.5"
    order = [z1, z1, z2, z1, z3, z2, z1]
    bars = 2 + 4 * len(order)
    length = bars * 4 * beat
    tune = [e for i, text in enumerate(order) for e in s.parse(text, (2 + 4 * i) * 4 * beat, bpm)]
    hits = []
    for bar in range(bars):
        t0 = bar * 4 * beat                      # dum . tek tek dum . tek(tek)
        hits += [(t0, "boom", 1.0), (t0 + 1.0 * beat, "tick", 0.8), (t0 + 1.5 * beat, "tick", 0.6),
                 (t0 + 2.0 * beat, "boom", 0.8), (t0 + 3.0 * beat, "tick", 0.8)]
        if bar % 2:
            hits += [(t0 + 3.5 * beat, "tick", 0.5), (t0 + 3.75 * beat, "tick", 0.4)]
    held = [(0.0, 400.0, E("E4"), False)]
    looped("14_ottomans", length,
           lambda total: [(s.drums(hits, total, rng), -16, 0.0, 1.0, 0.3),
                          (s.zurna(tune, total, rng), -19, 0.25, 0.8, 0.4)],
           lambda total: [(s.zurna(held, total, rng), -29, -0.3, 0.7, 0.5)],
           rng, echo=3.0, dark=3500, wet=0.8, cross=1.0,
           midi=[("Zurna", 111, tune), ("Zurna, held", 111, [(0.0, length, E("E4"), False)])])


def chase():
    """15. The chase through the pass: the fastest track. The bandits' tunes at full speed, the fiddle
    under them from the start, the drums in front."""
    drive("15_chase", 1115, 184, [P, R, P, Q, R, R, P, Q, S, P, R, Q, S, S, R, P, P, Q, R, R, S, P, Q, P], 0, -14, -17, heavy=True)


def end_strokes():
    """16. Four single drum blows with their echo. The game plays one over the cut when danger ends."""
    blows = [
        [(0.0, "boom", 1.4)],
        [(0.0, "boom", 1.3), (0.42, "boom", 0.45)],
        [(0.0, "heart", 1.4), (0.0, "boom", 0.9), (0.02, "tick", 0.5)],
        [(0.0, "boom", 1.0), (0.16, "boom", 1.4)],
    ]
    for k, hits in enumerate(blows, 1):
        rng = np.random.default_rng(1116 + k)
        total = 4.5
        mix = s.mixdown([(s.drums(hits, total, rng), -14, 0.05, 1.0, 0.6)], rng, echo=3.2, dark=2600, wet=1.0)
        done(f"16_end_stroke_{k}", mix, "stroke", fade_in=0.002, fade_out=2.5)


# ================================================================ moments

def lament():
    """18. A man dies. One voice, half sung and half spoken: a few quick notes on one pitch, as if said,
    then the fall. A vowel stands in for the words."""
    rng = np.random.default_rng(1118)
    man = lines([
        (2.0, "B3/0.3 -/0.08 B3/0.25 -/0.08 B3/0.3 -/0.08 B3/0.45 D4/1.6~ B3/0.4 A3/0.4 G3/2.4~"),
        (12.5, "A3/0.25 -/0.08 A3/0.25 -/0.08 A3/0.35 B3/0.4 A3/0.5 G3/0.4 E3/3.0~"),
        (23.0, "E4/2.2~ D4/0.4 B3/0.5 -/0.08 B3/0.25 -/0.08 B3/0.3 A3/0.5 G3/0.4 A3/2.8~"),
        (35.0, "G3/0.25 -/0.08 G3/0.25 -/0.08 G3/0.35 A3/0.5 G3/0.4 E3/0.5 D3/0.6 E3/5.0~"),
    ])
    total = 52.0
    mix = s.mixdown([
        (s.voice(man, total, rng, singers=1, vowel="oh"), -21, 0.0, 0.6, 0.7),
        (s.wind(total, rng), -38, 0, 1.0, 0.0),
    ], rng, echo=5.0, predelay=0.06, dark=2400)
    done("18_a_man_dies", mix, "moment", fade_in=0.5, fade_out=6.0, midi=[("Voice", 52, man)])


def the_fire():
    """19. The fire at night. The men hum the theme together, roughly; the second time round two of them
    open their mouths, not quite together. It could be sung in the world, by the men at the fire."""
    rng = np.random.default_rng(1119)
    first, t = theme(3.0, gap=2.2, semis=-12)
    second, end = theme(t + 6.0, gap=2.0, semis=-12)
    total = end + 9.0
    mix = s.mixdown([
        (s.hum(first + second, total, rng, voices=5), -22, -0.1, 0.7, 0.5),
        (s.voice(second, total, rng, singers=1, vowel="oh"), -26, 0.3, 0.6, 0.5),
        (s.voice(late(second, 0.14), total, rng, singers=1, vowel="oh"), -28, -0.4, 0.6, 0.5),
        (s.wind(total, rng), -40, 0, 1.0, 0.0),
    ], rng, echo=3.0, predelay=0.03, dark=2600, wet=0.7)
    done("19_the_fire", mix, "moment", fade_in=1.0, fade_out=6.0, midi=[("Men", 53, first + second)])


# ================================================================ the frame

def intro():
    """20. The intro: the theme sung by one man alone, then opening out (kaval, the gaida, the men, the
    women far off) and left hanging on the call, for the run to answer. This is the fallback: the first
    choice is a real folk song we record ourselves."""
    rng = np.random.default_rng(1120)
    solo, t = theme(2.5, gap=2.0, semis=-12)
    k1, t = theme(t + 4.0, which=(0, 1), gap=2.0)
    turn, t2 = theme(t + 2.5, which=(2, 3), gap=1.8)
    call, end = theme(t2 + 2.5, which=(0,), slow=1.1)
    total = end + 16.0
    kaval = k1 + call
    pipe = turn + call
    men = s.shift(turn + call, -12)
    women = [e for e in turn if e[0] > t + 12] + call        # the women come in on the last line
    drone = s.gaida_drone(E("E2"), k1[0][0] - 3.0, total - 1, total, rng, dark=1400,
                          shape=([k1[0][0] - 3.0, k1[0][0] + 4, end + 3, total - 1], [0, 1, 1, 0]))
    mix = s.mixdown([
        (s.voice(solo, total, rng, singers=1, vowel="ah"), -20, 0.0, 0.7, 0.6),
        (s.kaval(kaval, total, rng, breath_level=0.15), -22, 0.35, 0.4, 0.9),
        (s.gaida_chanter(pipe, total, rng), -21, -0.3, 0.7, 0.6),
        (s.voice(men, total, rng, singers=3, vowel="ah"), -21, 0.1, 0.6, 0.7),
        (s.voice(women, total, rng, singers=3, vowel="oh"), -26, -0.4, 0.1, 1.0),
        (drone, -27, -0.1, 0.7, 0.45),
        (s.wind(total, rng), -40, 0, 1.0, 0.0),
    ], rng, echo=6.0, predelay=0.06, dark=3000)
    done("20_intro", mix, "frame", fade_in=0.3, fade_out=12.0,
         midi=[("Solo voice", 52, solo), ("Kaval", 75, kaval), ("Kaba gaida", 109, pipe), ("Men", 52, men), ("Women", 52, women)])


def leaving():
    """21. Leaving the village. Women's voices in unison, no instruments, a song of parting. One group
    sings two lines and a second, further off, sings them back; they join for the last two."""
    rng = np.random.default_rng(1121)
    w1 = "E4/0.7 G4/0.7 A4/2.4~ G4/0.6 A4/0.6 B4/2.8~ A4/0.6 G4/2.6~"
    w2 = "A4/0.6 B4/0.6 A4/0.6 G4/0.8 E4/2.4~ 'G4 E4/0.4 D4/0.8 E4/3.4~"
    w3 = "B4/2.4~ 'D5 B4/0.5 A4/0.7 B4/0.6 D5/2.2~ B4/0.6 A4/0.6 G4/2.8~"
    w4 = "A4/0.6 G4/0.6 E4/0.8 G4/0.6 A4/2.2~ G4/0.5 E4/0.6 D4/0.8 E4/5.0~"

    def sung(start, texts, gap=1.6):
        out, t = [], start
        for text in texts:
            notes = s.parse(text, t)
            out += notes
            t = s.end_of(notes) + gap
        return out, t
    near, t = sung(2.5, [w1, w2])
    far, t = sung(t + 0.6, [w1, w2])
    both, t = sung(t + 1.0, [w3, w4])
    total = t + 8.0
    mix = s.mixdown([
        (s.voice(near + both, total, rng, singers=4, vowel="ah"), -21, -0.3, 0.55, 0.8),
        (s.voice(far + both, total, rng, singers=3, vowel="oh"), -24, 0.4, 0.2, 1.0),
        (s.wind(total, rng), -40, 0, 1.0, 0.0),
    ], rng, echo=5.5, predelay=0.06, dark=3000)
    done("21_leaving_the_village", mix, "frame", fade_in=0.5, fade_out=7.0,
         midi=[("Women, near", 52, near + both), ("Women, far", 52, far + both)])


def homecoming():
    """22. Homecoming: the theme in full. One gaida calls it alone, free; then it is walked, three times
    round, with more each time: three gaidi and the drum, the men, then the women, kaval and fiddle.
    The loudest and warmest thing in the game. The only place the drum does not mean trouble."""
    rng = np.random.default_rng(1122)
    bpm, beat = 80, 0.75
    call, t = theme(3.0, which=(0, 1), gap=2.0)
    walk = t + 3.0
    verse_beats = 12 + 12 + 12 + 16

    def verse(k):
        out, at = [], walk + k * verse_beats * beat
        for text in THEME_WALKED:
            notes = s.parse(text, at, bpm)
            out += notes
            at = s.end_of(notes)
        return out
    v = [verse(0), verse(1), verse(2)]
    end = walk + 3 * verse_beats * beat
    total = end + 12.0
    tune = v[0] + v[1] + v[2]
    hits, strum = [], []
    for bar in range(3 * verse_beats // 4):
        t0 = walk + bar * 4 * beat
        big = bar >= 2 * verse_beats // 4
        hits += [(t0, "boom", 1.0), (t0 + 1.0 * beat, "tick", 0.6), (t0 + 2.0 * beat, "boom", 0.7),
                 (t0 + 3.0 * beat, "tick", 0.6), (t0 + 3.5 * beat, "tick", 0.45)]
        if big:
            hits += [(t0 + 1.5 * beat, "tick", 0.4), (t0 + 2.5 * beat, "boom", 0.5)]
        for i in range(4):
            for j, note in enumerate(["E2", "B2", "E3"][(i % 2):]):
                strum.append((t0 + i * beat + j * 0.015, beat, E(note), False))
    hits.append((end, "boom", 1.3))
    drone = s.gaida_drone(E("E2"), 0.5, 0, total, rng, shape=([0.5, 4, end + 4, total - 1], [0, 1, 1, 0]))
    pipes = (s.gaida_chanter(call + tune, total, rng) + 0.7 * s.gaida_chanter(late(tune, 0.02), total, rng)
             + 0.7 * s.gaida_chanter(late(tune, 0.035), total, rng))
    mix = s.mixdown([
        (pipes, -17, -0.2, 0.9, 0.4),
        (drone, -24, -0.1, 0.9, 0.3),
        (s.drums(hits, total, rng), -18, 0.1, 1.0, 0.3),
        (s.tambura(strum, total, rng), -23, 0.4, 0.9, 0.3),
        (s.voice(s.shift(v[1] + v[2], -12), total, rng, singers=4, vowel="ah"), -19, 0.15, 0.7, 0.6),
        (s.voice(v[2], total, rng, singers=4, vowel="ah"), -21, -0.35, 0.5, 0.8),
        (s.kaval(v[2], total, rng), -24, 0.5, 0.5, 0.7),
        (s.gadulka(s.shift(v[2], -12), total, rng), -23, 0.3, 0.7, 0.5),
    ], rng, echo=4.5, predelay=0.04, dark=3500, wet=0.9)
    done("22_homecoming", mix, "homecoming", fade_in=1.0, fade_out=9.0,
         midi=[("Kaba gaidi", 109, call + tune), ("Men", 52, s.shift(v[1] + v[2], -12)), ("Women", 52, v[2]), ("Tambura", 25, strum)])


def ending():
    """23. Ending and credits: the theme at rest. Kaval over a rocking tambura and soft low strings, then
    the fiddle takes it, then both together."""
    rng = np.random.default_rng(1123)
    k1, t = theme(5.0, gap=2.2)
    f1, t = theme(t + 4.0, which=(0, 1), gap=2.2, semis=-12)
    both, end = theme(t + 2.2, which=(2, 3), gap=2.2)
    total = end + 14.0
    kaval, fiddle = k1 + both, f1 + s.shift(both, -12)

    def chord(t):
        line2 = 14.0 < t < 24.5
        return ["G2", "D3", "G3", "D3"] if line2 else ["E2", "B2", "E3", "B2"]
    lute = rocking(0.5, end + 1, 1.0, chord, rng)
    lute.append((end + 2.0, 3.0, E("E2"), False))
    pad = s.strings([(3.0, end + 6, ["E2", "B2"], 1.0)], total, rng, rise=8.0, fall=8.0)
    mix = s.mixdown([
        (s.kaval(kaval, total, rng, breath_level=0.14), -20, 0.3, 0.5, 0.8),
        (s.gadulka(fiddle, total, rng), -22, -0.3, 0.5, 0.8),
        (s.tambura(lute, total, rng), -25, 0.1, 0.8, 0.4),
        (pad, -31, 0.0, 0.6, 0.6),
        (s.wind(total, rng), -42, 0, 1.0, 0.0),
    ], rng, echo=5.0, predelay=0.05, dark=3500)
    done("23_ending", mix, "frame", fade_in=0.5, fade_out=10.0,
         midi=[("Kaval", 75, kaval), ("Gadulka", 110, fiddle), ("Tambura", 25, lute)])


def menu():
    """24. Menu and pause: the theme very quietly. A drone, and the kaval far off with its first and
    last lines. A loop."""
    rng = np.random.default_rng(1124)
    length = 84.0
    first, _ = theme(8.0, which=(0,), slow=1.1)
    last, _ = theme(44.0, which=(3,), slow=1.1)
    notes = plucks(rng, 24.0, 40.0, 4.0, 7.0, ["E3", "B3"], length=1.5) + plucks(rng, 62.0, 78.0, 4.0, 7.0, ["E3", "B2"], length=1.5)
    looped("24_menu", length,
           lambda total: [(s.kaval(first + last, total, rng, breath_level=0.2), -22, 0.3, 0.25, 1.0),
                          (s.tambura(notes, total, rng), -28, -0.3, 0.5, 0.9)],
           lambda total: [(steady_drone("E2", total, rng, 700), -29, 0.0, 0.7, 0.5),
                          (s.mist([(-10.0, total + 10, ["B4", "E5", "G5"])], total, rng), -36, 0.0, 0.2, 1.0),
                          (s.wind(total, rng), -38, 0, 1.0, 0.0)],
           rng, echo=6.0, dark=2800, wet=1.0, kind="menu", midi=[("Kaval", 75, first + last)])


# ================================================================

def index():
    """data/music_tracks.json: how long each of the game's tracks is, for the game to know when one is over."""
    tracks = {}
    path = ROOT / "data" / "music_tracks.json"
    known = json.loads(path.read_text())["seconds"] if path.exists() else {}
    for ogg in sorted(GAME.glob("*.ogg")):
        wav = OUT / f"{ogg.stem}.wav"
        if not wav.exists():                      # not rendered in this checkout: keep the length written before
            tracks[ogg.stem] = known[ogg.stem]
            continue
        with wave.open(str(wav)) as w:
            tracks[ogg.stem] = round(w.getnframes() / w.getframerate(), 2)
    doc = {"_doc": "How long each track in assets/audio/music is, seconds. Written by music/pieces/set_03_score.py index.",
           "seconds": tracks}
    (ROOT / "data" / "music_tracks.json").write_text(json.dumps(doc, indent=1) + "\n")
    print(f"{len(tracks)} tracks, {sum(tracks.values()) / 60:.1f} minutes")


TRACKS = {f.__name__: f for f in (
    summer_day, summer_dusk, autumn_day, autumn_dusk, autumn_night, winter_day, winter_night, spring_morning,
    spring_day, wary, hiding, beasts, bandits, ottomans, chase, end_strokes, lament, the_fire, intro, leaving,
    homecoming, ending, menu)}

if __name__ == "__main__":
    names = sys.argv[1:]
    if names == ["index"]:
        index()
    elif names:
        for name in names:
            TRACKS[name]()
    else:                                         # each in a process of its own, four at a time
        running, waiting = [], list(TRACKS)
        while running or waiting:
            while waiting and len(running) < 4:
                running.append(subprocess.Popen([sys.executable, str(HERE), waiting.pop(0)]))
            running[0].wait()
            failed = [p for p in running if p.poll() not in (None, 0)]
            if failed:
                sys.exit(f"a track failed: {failed[0].args[-1]}")
            running = [p for p in running if p.poll() is None]
        index()
