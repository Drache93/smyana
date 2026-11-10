"""Spike 01: "Autumn dusk". A first try at how Smyana could sound. Not final, not the theme.

A kaba gaida drone comes up out of the wind. A kaval sings two slow phrases with no beat.
The gaida's melody pipe takes its own, lower turn of the tune while low strings open under it,
the kaval answers, and the kaval is left alone to bring it home.

Run:  python3 music/pieces/spike_01_autumn_dusk.py
"""
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
import synth as s  # noqa: E402

TOTAL = 104.0
DRONE = "E2"  # the kaba gaida's drone is most often E, two octaves under its home note

# The tune uses five notes only (E G A B D), the scale old Rhodope songs live in.
# Each phrase hangs on a long note, falls by step, and the piece closes D -> E,
# the step up from below to the home note.
KAVAL = [
    (10.0, "B4/3.2~ 'D5 B4/0.5 A4/0.9 B4/0.5 D5/2.6~ 'E5 D5/0.4 B4/0.9 A4/0.5 G4/0.5 A4/3.4~"),
    (26.5, "B4/0.6 D5/0.6 E5/3.4~ 'G5 E5/0.5 D5/0.9 'E5 D5/0.3 B4/1.3 A4/0.5 B4/0.4 A4/0.4 G4/0.7 E4/4.4~"),
    (58.0, "E5/2.4~ D5/0.5 B4/0.6 D5/2.6~"),                       # answers the gaida
    (70.9, "B4/3.9~ A4/0.6 G4/0.7 E4/3.6~"),                       # holds over its last fall, then lands with it
    (82.5, "G4/0.8 A4/0.8 B4/3.0~ 'D5 B4/0.4 A4/0.7 G4/0.9 E4/1.1 D4/0.8 E4/7.0~"),
]
# The gaida's melody pipe only reaches a fifth either side of its home note (A3 to B4 around
# E4), so its version of the tune sits lower and turns around E. The 'B4 flicks are the "bip":
# pipers can't stop the sound, so they separate notes with a quick touch of the fifth.
GAIDA = [
    (44.0, "'B4 E4/2.6~ 'B4 E4/0.4 D4/0.5 E4/0.5 G4/0.9 A4/2.4~ 'B4 A4/0.4 G4/0.8 'B4 G4/0.3 E4/0.5 D4/0.5 E4/3.2~"),
    (64.5, "G4/0.5 A4/0.5 B4/2.6~ A4/0.08 B4/0.5 A4/0.9 'B4 G4/1.2 'B4 G4/0.3 E4/0.5 D4/0.6 E4/0.5 D4/0.5 B3/1.0 'B4 D4/0.6 'B4 E4/4.2~"),
]
# Low strings: an open fifth on E, one step down to D and A under the kaval's answer, and back.
STRINGS = [
    (40.0, 59.5, ["E3", "B3"], 1.0),
    (56.5, 67.0, ["D3", "A3"], 0.9),
    (64.0, 96.0, ["E3", "B3", "E4"], 1.0),
]


def lines(phrases):
    return [e for start, text in phrases for e in s.parse(text, start)]


def main():
    out = pathlib.Path(__file__).resolve().parents[1] / "out"
    out.mkdir(exist_ok=True)
    rng = np.random.default_rng(1861)
    kaval_ev, gaida_ev = lines(KAVAL), lines(GAIDA)

    kaval = s.level(s.kaval(kaval_ev, TOTAL, rng), -19)
    chanter = s.level(s.gaida_chanter(gaida_ev, TOTAL, rng), -24)
    drone = s.level(s.gaida_drone(s.midi_of(DRONE), 2.0, 101.0, TOTAL, rng), -25)
    pad = s.level(s.strings(STRINGS, TOTAL, rng), -23)
    air = s.level(s.wind(TOTAL, rng), -38)

    # Where each sits: the gaida close and a little left, the kaval far off to the right,
    # as if it comes from across the valley.
    dry = (0.45 * s.pan(kaval, 0.35) + 0.8 * s.pan(chanter, -0.25)
           + 0.85 * s.pan(drone, -0.15) + 0.7 * s.pan(pad, 0.0) + air)
    send = (1.0 * s.pan(kaval, 0.5) + 0.45 * s.pan(chanter, -0.3)
            + 0.3 * s.pan(drone, -0.2) + 0.6 * s.pan(pad, 0.0))
    mix = dry + 0.9 * s.reverb(send, 4.5, rng)

    wav = out / "spike_01_autumn_dusk.wav"
    s.write_wav(wav, mix)
    s.encode(wav, out / "spike_01_autumn_dusk.mp3", "-b:a", "192k")
    s.encode(wav, out / "spike_01_autumn_dusk.ogg", "-c:a", "libopus", "-b:a", "72k")
    s.write_midi(out / "spike_01_autumn_dusk.mid", [
        ("Kaval", 75, kaval_ev),
        ("Kaba gaida", 109, gaida_ev),
        ("Gaida drone", 109, [(2.0, 99.0, s.midi_of(DRONE), False)]),
        ("Low strings", 48, [(a, b - a, s.midi_of(n), False) for a, b, names, _ in STRINGS for n in names]),
    ])
    print("wrote", wav)


if __name__ == "__main__":
    main()
