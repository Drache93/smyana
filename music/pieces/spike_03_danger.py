"""Spike 03: "Danger". How the music could follow the game, in 80 seconds.

    0s   calm      the mist music from spike 02
   18s   hiding    something is seen. The tune stops mid-breath. A heartbeat, a low clash
                   of two notes a half step apart, a thin high whine, and it tightens.
   38s   battle    found. Tapan and gaida, a fast plain 2/4, the drone at full buzz.
   60s   over      one last blow and it all stops dead. Only the echo and the wind.
   65s   after     the kaval alone, finishing the tune it never got to finish.

In the game these would be separate loops the game switches between. Here they are laid
end to end so the changes can be heard and judged.

Run:  python3 music/pieces/spike_03_danger.py
"""
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
import synth as s  # noqa: E402

TOTAL = 82.0
SEEN, FOUND = 18.0, 38.0
BPM = 132
BEAT = 60 / BPM
BARS = 24
OVER = FOUND + BARS * 2 * BEAT   # the last blow

KAVAL = [
    (3.0, "G4/2.8~ A4/0.5 B4/2.2~ 'D5 B4/0.4 A4/0.6 G4/0.5 E4/3.6~"),
    (15.0, "B4/0.7 D5/2.3"),                                        # cut off when danger is seen
    (OVER + 5.0, "A4/0.7 G4/0.7 E4/2.6~ 'G4 E4/0.5 D4/1.0 E4/6.0~"),
]

# The fight tune: four bars each, two beats to the bar, inside the gaida's range.
A = "E4/.5 'B4 E4/.5 G4/.5 A4/.5 | B4/1 A4/.5 G4/.5 | A4/.5 G4/.5 E4/.5 D4/.5 | E4/1 'B4 E4/1"
B = "B4/.5 A4/.5 B4/1 | 'B4 A4/.5 G4/.5 A4/1 | G4/.5 A4/.5 G4/.5 E4/.5 | D4/.5 E4/.5 'B4 E4/1"
C = "'B4 D4/.5 E4/.5 G4/.5 E4/.5 | 'B4 D4/.5 E4/.5 G4/.5 A4/.5 | B4/.5 A4/.5 G4/.5 A4/.5 | B4/2"
FIGHT = [A, A, B, A, C, B]


def lines(phrases):
    return [e for start, text in phrases for e in s.parse(text, start)]


def tapan(rng):
    hits = [(SEEN, "boom", 0.55)]                                    # the moment it is seen
    t, gap = SEEN + 1.6, 1.15                                        # heartbeat, slowly quickening
    while t < FOUND - 0.6:
        hits += [(t, "heart", 0.8), (t + 0.26, "heart", 0.5)]
        t += gap
        gap = max(0.74, gap * 0.955)
    for bar in range(BARS):
        t0 = FOUND + bar * 2 * BEAT
        fill = bar % 4 == 3
        hits.append((t0, "boom", 1.0))
        hits.append((t0 + 1.0 * BEAT, "boom", 0.45))
        steps = [0.5, 1.0, 1.25, 1.5, 1.75] if fill else [0.5, 1.0, 1.5]
        for step in steps:
            hits.append((t0 + step * BEAT + rng.normal(0, 0.004), "tick", 0.9 if step == 1.0 else 0.6))
    hits.append((OVER, "boom", 1.3))
    return hits


def main():
    out = pathlib.Path(__file__).resolve().parents[1] / "out"
    out.mkdir(exist_ok=True)
    rng = np.random.default_rng(1863)
    kaval_ev = lines(KAVAL)
    fight_ev = [e for i, text in enumerate(FIGHT) for e in s.parse(text, FOUND + i * 8 * BEAT, bpm=BPM)]

    kaval = s.level(s.kaval(kaval_ev, TOTAL, rng, breath_level=0.22), -26)
    haze = s.level(s.mist([(0.0, SEEN + 3, ["B4", "E5", "G5", "A5"]), (OVER + 3, TOTAL, ["B4", "E5", "G5"])], TOTAL, rng), -38)
    soft_drone = s.level(s.gaida_drone(s.midi_of("E3"), 0, 0, TOTAL, rng, dark=600, shape=(  # quiet, like spike 02
        [1.0, 5.0, SEEN, SEEN + 0.5, OVER + 4, OVER + 9, TOTAL - 6, TOTAL], [0, 1, 1, 0, 0, 1, 1, 0])), -39)
    # hiding: two low notes a half step apart, and a high pair the same, growing
    dread = s.level(s.strings([(SEEN + 1, FOUND + 0.3, ["E2", "F2"], 1.0)], TOTAL, rng, rise=17.0, fall=0.3), -31)
    whine = s.level(s.mist([(SEEN + 4, FOUND + 4, ["B5", "C6"])], TOTAL, rng)
                    * np.interp(np.arange(int(TOTAL * s.SR)) / s.SR, [SEEN + 4, FOUND, FOUND + 0.2], [0.2, 1, 0]), -36)
    # battle
    war_drone = s.level(s.gaida_drone(s.midi_of("E2"), FOUND - 10, 0, TOTAL, rng, shape=(
        [FOUND - 0.05, FOUND + 0.1, OVER, OVER + 0.08], [0, 1, 1, 0])), -24)
    chanter = s.level(s.gaida_chanter(fight_ev, TOTAL, rng), -19)
    drum = s.level(s.drums(tapan(rng), TOTAL, rng), -17)
    air = s.wind(TOTAL, rng)
    air = s.level(air, -35) * np.interp(np.arange(air.shape[1]) / s.SR, [0, SEEN, FOUND, OVER, OVER + 6, TOTAL], [1, 1, 1.8, 1.4, 1, 1])

    dry = (0.25 * s.pan(kaval, 0.3) + 0.6 * s.pan(soft_drone, -0.1) + 0.2 * s.pan(haze, 0.0)
           + 0.8 * s.pan(dread, 0.0) + 0.3 * s.pan(whine, 0.2)
           + 0.9 * s.pan(war_drone, -0.15) + 0.9 * s.pan(chanter, -0.2) + 1.0 * s.pan(drum, 0.1) + air)
    send = (1.0 * s.pan(kaval, 0.45) + 0.5 * s.pan(soft_drone, 0.0) + 1.0 * s.pan(haze, 0.1)
            + 0.5 * s.pan(dread, 0.0) + 1.0 * s.pan(whine, 0.2)
            + 0.25 * s.pan(war_drone, -0.2) + 0.3 * s.pan(chanter, -0.25) + 0.35 * s.pan(drum, 0.15))
    mix = dry + 1.0 * s.reverb(send, 5.0, rng, predelay=0.05, dark=2800)

    wav = out / "spike_03_danger.wav"
    s.write_wav(wav, mix, fade_in=2.0, fade_out=5.0)
    s.encode(wav, out / "spike_03_danger.mp3", "-b:a", "192k")
    s.encode(wav, out / "spike_03_danger.ogg", "-c:a", "libopus", "-b:a", "72k")
    print("wrote", wav, "battle ends at", round(OVER, 2))


if __name__ == "__main__":
    main()
