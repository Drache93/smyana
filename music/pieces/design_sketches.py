"""Design sketches: the shape of a song before it is made (docs/music-design.md).

Dominic, 2026-11-11, on the first draft: "each song needs a clear design stage. Like we did for 2D before 3D".
For each designed song this draws its sheet (the tune's shape over time, beside the first draft's) and renders a
"pencil" sketch: the tune alone on one plain sound, with no arrangement, so the shape can be judged by itself.

    python3 music/pieces/design_sketches.py            both sheets and both sketches
Writes music/out/design_<name>.png, .wav, .mp3 and .ogg.
"""
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
import synth as s  # noqa: E402

OUT = HERE.parents[1] / "out"
E = s.midi_of


def lines(phrases, bpm=None):
    return [e for start, text in phrases for e in s.parse(text, start, bpm)]


# ---------------------------------------------------------------- autumn dusk
# One kaba gaida, close. It holds, it does not run: a note every three seconds or so, each phrase reaching one step
# higher than the last (G, then A, then B) before it sinks home. The only ornament is the "bip", the flick of the
# fifth a piper uses to part two notes. A low kaval closes with two notes, a leap down a fifth: the one leap in it.
DUSK_GAIDA = [
    (2.0, "'B4 E4/4.5~ G4/3.0 'B4 E4/5.0~"),
    (17.0, "'B4 E4/2.5 G4/2.0 A4/4.5~ 'B4 G4/2.5 'B4 E4/5.0~"),
    (36.0, "'B4 G4/2.0 A4/2.0 B4/5.5~ A4/3.0 'B4 G4/3.0 D4/2.5 'B4 E4/7.0~"),
]
DUSK_KAVAL = [(63.0, "B3/4.5~ E3/7.0~")]
# the first draft's opening, for the sheet (set_03_score.py, autumn_dusk)
DUSK_WAS = [
    (5.0, "B4/3.0~ 'D5 B4/0.5 A4/0.9 B4/0.5 D5/2.4~ 'E5 D5/0.4 B4/0.9 A4/0.5 G4/0.5 A4/3.2~"),
    (20.5, "'B4 E4/2.6~ 'B4 E4/0.4 D4/0.5 E4/0.5 G4/0.9 A4/2.4~ 'B4 A4/0.4 G4/0.8 'B4 G4/0.3 E4/0.5 D4/0.5 E4/3.2~"),
    (34.5, "E5/2.4~ D5/0.5 B4/0.6 D5/2.6~"),
    (41.0, "G4/0.5 A4/0.5 B4/2.6~ A4/0.08 B4/0.5 A4/0.9 'B4 G4/1.2 'B4 G4/0.3 E4/0.5 D4/0.6 E4/0.5 D4/0.5 B3/1.0 'B4 D4/0.6 'B4 E4/4.2~"),
    (57.5, "G4/0.8 A4/0.8 B4/2.8~ 'D5 B4/0.4 A4/0.7 G4/0.9 E4/1.1 D4/0.8 E4/5.0~"),
]

# ---------------------------------------------------------------- the fire
# A song with a beat, sung in the world. One man sings a line and the rest sing it back, the way a Rhodope song is
# led. One note to a syllable, notes said twice, a range of five notes, a tone lower than the dusk (D, not E). Somebody
# knocks a stick on a log. 66 beats a minute; a line is eight beats.
FIRE_BPM = 66
FIRE_LINES = [
    "D3/.9 -/.1 D3/1 F3/1 G3/.9 -/.1 | G3/1.5 F3/.5 D3/2",
    "F3/1 G3/1 A3/.9 -/.1 A3/1 | G3/1.5 F3/.5 G3/2",
    "A3/.9 -/.1 A3/1 C4/1.5 A3/.5 | G3/1 F3/1 G3/2",
    "F3/1 G3/1 F3/1 D3/1 | C3/1 D3/3",
]
# the first draft's fire was the main theme, hummed (set_03_score.py, THEME, an octave down)
FIRE_WAS = [
    (3.0, "E3/0.6 G3/0.6 A3/2.6~ 'B3 A3/0.5 G3/0.8 A3/0.5 B3/3.0~"),
    (13.9, "B3/0.6 D4/2.2~ 'E4 D4/0.4 B3/0.9 A3/0.5 G3/0.6 A3/3.2~"),
    (24.6, "A3/0.5 B3/0.5 D4/0.7 E4/2.8~ D4/0.5 B3/1.0 'D4 B3/0.4 A3/0.6 G3/2.4~"),
    (36.3, "G3/0.6 A3/0.6 B3/1.8~ A3/0.5 G3/0.7 'A3 G3/0.3 E3/0.9 D3/0.7 E3/4.5~"),
]


def fire_parts():
    beat = 60 / FIRE_BPM
    leader, rest, knocks = [], [], []
    for k, text in enumerate(FIRE_LINES):
        at = 2.0 + k * 16 * beat
        leader += s.parse(text, at, FIRE_BPM)
        rest += s.parse(text, at + 8 * beat, FIRE_BPM)
        knocks += [(at + b * beat, "heart", 0.6 if b % 8 == 0 else 0.35) for b in range(0, 16, 4)]
    return leader, rest, knocks


def moves(events):
    """How a tune moves: seconds a note on average, and the share of its notes shorter than a second."""
    notes = [e for e in events if e[2] is not None and e[1] > s.GRACE]
    return sum(e[1] for e in notes) / len(notes), sum(1 for e in notes if e[1] < 1.0) / len(notes)


def write(name, mix):
    OUT.mkdir(exist_ok=True)
    wav = OUT / f"{name}.wav"
    s.write_wav(wav, mix, 0.5, 4.0)
    s.encode(wav, OUT / f"{name}.mp3", "-b:a", "160k")
    s.encode(wav, OUT / f"{name}.ogg", "-c:a", "libopus", "-b:a", "64k")
    print("wrote", name)


def pencil_dusk():
    rng = np.random.default_rng(2104)
    gaida, kaval = lines(DUSK_GAIDA), lines(DUSK_KAVAL)
    total = 80.0
    mix = s.mixdown([
        (s.gaida_chanter(gaida, total, rng), -20, -0.1, 0.9, 0.3),
        (s.gaida_drone(E("E2"), 0.5, total - 2, total, rng, dark=1300), -28, -0.1, 0.9, 0.25),
        (s.kaval(kaval, total, rng, breath_level=0.25), -22, 0.3, 0.6, 0.6),
    ], rng, echo=2.0, dark=3000, wet=0.6)
    write("design_autumn_dusk", mix)


def pencil_fire():
    rng = np.random.default_rng(2119)
    leader, rest, knocks = fire_parts()
    total = s.end_of(rest) + 6.0
    mix = s.mixdown([
        (s.hum(leader, total, rng, voices=1), -20, -0.3, 1.0, 0.2),
        (s.hum(rest, total, rng, voices=5), -19, 0.2, 1.0, 0.25),
        (s.drums(knocks, total, rng), -27, 0.5, 1.0, 0.15),
    ], rng, echo=1.2, dark=2500, wet=0.5)
    write("design_the_fire", mix)


def sheet(name, title, now, was, span, note_names, caption):
    """The sheet's picture: each voice's notes as bars over time, the new shape above the first draft's."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    ink, paper = "#2b2118", "#f3ead8"
    fig, axes = plt.subplots(2, 1, figsize=(12, 6.2), sharex=True, facecolor=paper)
    ticks = [E(n) for n in note_names]
    for ax, voices, label in ((axes[0], now, "the design"), (axes[1], was, "the first draft")):
        ax.set_facecolor(paper)
        for voice, colour, events in voices:
            first = True
            for a, d, m, _ in events:
                if m is None or a > span:
                    continue
                grace = d <= s.GRACE
                ax.plot([a, a + d], [m, m], color=colour, lw=2 if grace else 7, solid_capstyle="butt",
                        alpha=0.5 if grace else 1, label=voice if first and not grace else None)
                first = first and grace
            ax.step([e[0] for e in events if e[2] is not None and e[0] <= span],
                    [e[2] for e in events if e[2] is not None and e[0] <= span], where="post", color=colour, lw=0.6, alpha=0.5)
        every = [e for _, _, ev in voices for e in ev]
        mean, quick = moves(every)
        ax.set_title(f"{label}: a note lasts {mean:.1f} s on average, {quick * 100:.0f}% of notes are under a second",
                     loc="left", color=ink, fontsize=11)
        ax.set_yticks(ticks, note_names, color=ink)
        ax.set_ylim(min(ticks) - 2, max(ticks) + 2)
        ax.grid(axis="y", color=ink, alpha=0.15)
        ax.legend(loc="upper right", frameon=False, labelcolor=ink, fontsize=9)
        for side in ax.spines.values():
            side.set_color(ink)
            side.set_alpha(0.3)
        ax.tick_params(colors=ink)
    axes[1].set_xlabel("seconds", color=ink)
    axes[1].set_xlim(0, span)
    fig.suptitle(title, color=ink, fontsize=14, x=0.01, ha="left")
    fig.text(0.01, 0.01, caption, color=ink, fontsize=9, ha="left")
    fig.tight_layout(rect=(0, 0.03, 1, 0.97))
    fig.savefig(OUT / f"{name}.png", dpi=110, facecolor=paper)
    print("drew", name)


def sheets():
    sheet("design_autumn_dusk", "Autumn dusk: the shape of the tune",
          [("kaba gaida", "#8a3b1e", lines(DUSK_GAIDA)), ("low kaval", "#3d5a6c", lines(DUSK_KAVAL))],
          [("kaval", "#3d5a6c", lines(DUSK_WAS[0::2])), ("kaba gaida", "#8a3b1e", lines(DUSK_WAS[1::2]))],
          76, ["E3", "B3", "D4", "E4", "G4", "A4", "B4", "D5", "E5"],
          "The pipe holds and climbs one step further each phrase (G, A, B). Thin marks are the bip, the piper's flick between notes.")
    leader, rest, _ = fire_parts()
    sheet("design_the_fire", "The fire: the shape of the song",
          [("one man", "#8a3b1e", leader), ("the rest answer", "#3d5a6c", rest)],
          [("men humming the theme", "#3d5a6c", lines(FIRE_WAS))],
          62, ["C3", "D3", "F3", "G3", "A3", "C4", "D4", "E4"],
          "Line and answer, on a beat, a tone lower than the dusk. The first draft had no beat, no answer and a wider, wandering line.")


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    sheets()
    if "sheets" not in sys.argv:
        pencil_dusk()
        pencil_fire()
