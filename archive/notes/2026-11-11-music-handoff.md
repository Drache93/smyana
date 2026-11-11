# The music: where it stands, 2026-11-11 10:20 UTC

Written by Claude when Dominic asked the threads to pause: "Yes we need to pace ourselves, have them document current
state and stop" (10:18 UTC, chat).

## Done

- **A first draft of the score**, 23 of the 24 planned tracks (the ruins are parked), 33 minutes:
  `music/pieces/set_03_score.py`, files in `assets/audio/music/`. Journal:
  [the whole score in first draft](../journal/2026-11-11-the-whole-score-in-first-draft.md).
- **Music in the game**: `src/smyana/music.lobster`, driven by `data/music.json`. A calm track by season and hour,
  danger loops cut in and out with an end stroke, the homecoming at the end (D-059). Works; no Creel change.
- All of it is in pull request #63, open, merged up to main at 10:06 UTC, lint and `./check.sh` passing.

## What Dominic said on hearing it (10:10 UTC)

Samey (autumn dusk and the fire), "the same tones across them all", the pipes and the "trumpet type instrument"
overused or flat, the Ottomans "too synth", "basically pipe going up and down quick", and: "each song needs a clear
design stage. Like we did for 2D before 3D" (D-060). His words are in
[`2026-11-11-dominic-in-his-own-words.md`](2026-11-11-dominic-in-his-own-words.md).

Measured afterwards, he was right: every move in every tune was a step to the next note, two thirds of the notes
were under a second, and 22 of 23 tracks had the same home note.

## The plan now

[`docs/music-design.md`](../../docs/music-design.md), a proposal he has not read yet:

1. A sheet per song, in plain words with a picture of the tune's shape.
2. A "pencil" sketch: the tune alone, under a minute.
3. The track, only once the sketch is liked.

Two sheets and two pencil sketches exist, for autumn dusk and the fire (`archive/audio/2026-11-11/`, pictures 63
and 64). Nobody has heard them.

## Next, when work starts again

1. Dominic reads the two sheets and hears the two sketches. Is the stage right? Are the shapes?
2. Decide whether #63 merges as it is (the first draft as placeholders, plus the working music system) or waits.
3. A sheet for the main theme, since seven tracks borrow it.
4. Then one song at a time. Open across all of them: real voices for the sung tracks, and an idea for the Ottomans
   that isn't a synthesised pipe.

Nothing is running and nothing is half done.
