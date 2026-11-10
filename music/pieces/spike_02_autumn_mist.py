"""Spike 02: "Autumn mist". A second take after the first sounded "a little too Viking".

What made spike 01 sound Norse, and what changed here:
  - the low buzzing drone (a war horn)      -> an octave higher, dull and quiet, half hidden
  - bare fifths in low strings (power)      -> gone; single high notes drift in and out as haze
  - the gaida's nasal melody pipe up close  -> gone; men hum the answer, far off
  - a tune built on E, B and D (heroic)     -> a tune that leans on G and A and falls more
  - a clear, close flute                    -> breathier, further away, a longer echo

Run:  python3 music/pieces/spike_02_autumn_mist.py
"""
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
import synth as s  # noqa: E402

TOTAL = 102.0

# Same five notes (E G A B D), but the phrases start on G or B and sink, with long gaps.
KAVAL = [
    (8.0, "G4/2.8~ A4/0.5 B4/2.2~ 'D5 B4/0.4 A4/0.6 G4/0.5 E4/3.6~"),
    (24.0, "B4/0.7 D5/2.6~ 'E5 D5/0.4 B4/1.0 A4/0.5 G4/0.6 A4/3.8~"),
    (53.0, "E5/3.0~ D5/0.5 B4/0.8 A4/0.5 B4/3.5~"),                  # floats over the men's hum
    (78.0, "A4/0.7 G4/0.7 E4/2.6~ 'G4 E4/0.5 D4/1.0 E4/7.0~"),
]
HUM = [
    (39.0, "E3/3.0~ G3/0.6 A3/2.4~ G3/0.6 E3/0.6 D3/0.6 E3/3.8~"),
    (63.0, "G3/0.6 A3/0.6 B3/3.0~ A3/0.6 G3/0.7 A3/0.5 G3/0.5 E3/4.8~"),
]
MIST = [(0.0, 100.0, ["B4", "E5", "G5", "A5", "D6"])]


def lines(phrases):
    return [e for start, text in phrases for e in s.parse(text, start)]


def main():
    out = pathlib.Path(__file__).resolve().parents[1] / "out"
    out.mkdir(exist_ok=True)
    rng = np.random.default_rng(1862)
    kaval_ev, hum_ev = lines(KAVAL), lines(HUM)

    kaval = s.level(s.kaval(kaval_ev, TOTAL, rng, breath_level=0.22), -21)
    hum = s.level(s.hum(hum_ev, TOTAL, rng), -25)
    drone = s.level(s.gaida_drone(s.midi_of("E3"), 3.0, 99.0, TOTAL, rng, dark=600), -34)
    haze = s.level(s.mist(MIST, TOTAL, rng), -33)
    air = s.level(s.wind(TOTAL, rng), -35)

    # Almost everything is echo: little of the direct sound, a long dull tail.
    dry = (0.25 * s.pan(kaval, 0.3) + 0.3 * s.pan(hum, -0.3)
           + 0.6 * s.pan(drone, -0.1) + 0.2 * s.pan(haze, 0.0) + air)
    send = (1.0 * s.pan(kaval, 0.45) + 0.9 * s.pan(hum, -0.4)
            + 0.5 * s.pan(drone, 0.0) + 1.0 * s.pan(haze, 0.1))
    mix = dry + 1.1 * s.reverb(send, 6.5, rng, predelay=0.06, dark=2400)

    wav = out / "spike_02_autumn_mist.wav"
    s.write_wav(wav, mix, fade_in=3.0, fade_out=6.0)
    s.encode(wav, out / "spike_02_autumn_mist.mp3", "-b:a", "192k")
    s.encode(wav, out / "spike_02_autumn_mist.ogg", "-c:a", "libopus", "-b:a", "72k")
    s.write_midi(out / "spike_02_autumn_mist.mid", [
        ("Kaval", 75, kaval_ev),
        ("Men humming", 53, hum_ev),
        ("Drone", 109, [(3.0, 96.0, s.midi_of("E3"), False)]),
    ])
    print("wrote", wav)


if __name__ == "__main__":
    main()
