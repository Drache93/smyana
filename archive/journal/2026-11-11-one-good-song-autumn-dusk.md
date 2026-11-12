# 2026-11-11: One good song for the demo, autumn dusk

**Area:** audio
**Who:** Dominic asked; Claude chose the song and made it while he was away

## What happened

At 21:13 UTC, laying out the phases, Dominic narrowed the music for phase 1: "lets focus on just getting that music
creation solid. So we make one good song for that demo. We can then start on phase 2". At 21:55, as the work started:
"I won't.be available to review. So continue to next to next phase once done".
([his words](../notes/2026-11-11-dominic-in-his-own-words.md))

So this is the first song to go through the design stage he asked for that morning (D-073) from start to finish, with
Claude standing in for him at the step where he would have heard the sketch. Done by about 22:20 UTC.

**The song: autumn dusk** (D-074). The demo is the men round the camp, and the game plays this track there in autumn
between 18h and 21h (picture 108). Autumn is the poster boy, and the bagpipe is the sound he liked first. The fire
song, the other camp track, was the alternative, but it wants real men's voices, which the bench can't make.

**What was made.** The sheet from the morning held: one piper at the camp plays as slowly as he can, three phrases
each climbing one step further than the last. Claude added a fourth phrase with the piece's only leap, from home up a
fifth and on to the pipe's top note, held longest of all, then walked down by steps; the far kaval's two notes at
the end, a leap down a fifth, answer it (picture 107). 2 min 26 s.

What Dominic had said about the earlier music, and what was done about each:

| He said | Done |
|---|---|
| "basically pipe going up and down quick" | A note lasts 3.8 s on average (1.2 s before); no note is under a second (70% were). |
| "the trumpet type instrument and pipes are over used or just too flat" | A new kaba gaida voice in the bench, rounder and lower, whose bag pressure wanders so a held note leans sharp and brighter and sinks back. One pipe, one kaval, nothing else. |
| "a little too Viking ... Needs more mist" (spike 1) | The drone is quiet and dark, and grows only for the leap. The mist is the pipe's own long, dark echo far under it, which thickens for the leap. |
| "mist too soft now" (spike 2) | The pipe itself stays close and clear in front of the haze. |
| "a lot of the same tones" | The quiet to loud range is 13 dB (9 to 11 before). Most of the sound is still in one octave: that is where a kaba gaida plays. |

**The process, written down.** The steps the song went through are now a checklist in
[`docs/music-design.md`](../../docs/music-design.md#making-a-song-the-checklist): choose it for a place in the game,
the sheet, the pencil sketch, Dominic hears both, the track in a file of its own, measure it, hear it in the game,
write down what changed from the sheet, archive it. One song at a time.

**In the game.** The song replaces the first draft's track 04. Checked with the game run headless at the camp, autumn,
19h: it prints `music: 04_autumn_dusk (autumn dusk, by the fire)`. `./check.sh` passes.

**The first draft goes in with it.** The game's music system and the 23 first-draft tracks were in pull request #63,
never merged. This song is built on that branch and merged up to main, so the pull request for the song carries #63
too. Main had taken the first draft's decision numbers (D-059, D-060) for the start-up work, so those two became D-072
and D-073, and the files that named them were changed to match.

## Bugs and what was learned

- **A part that plays briefly came out far too loud.** The bench sets each part's level from the loudest half of
  its samples. The kaval plays for 12 of 146 seconds, so that half was mostly silence and it was pushed up until it
  was 10 dB louder than the pipe (Claude saw it in the loudness curve, not by ear). Fixed with `level_over`, which
  measures a part only where it plays. Now in the checklist.
- **Merging the first draft up to main**: four files in conflict (the decisions, the timeline, Dominic's notes, and
  the game's main loop, where the music's tick and the season clock's tick both went in).

## Open

Only hearing it can say whether the new pipe still sounds like a trumpet, whether a pipe this slow holds for two and
a half minutes, and whether the haze is mist or mud. All of it is Claude's call until Dominic has heard it.

## Pictures and sound

- `images/2026-11-11/107-music-autumn-dusk-as-made.png`: the tune's shape as made, above the first draft's.
- `images/2026-11-11/108-the-camp-at-dusk-where-the-song-plays.jpg`: the camp at 19h in autumn, where it plays.
- `audio/2026-11-11/04-music-autumn-dusk-the-demo-song.ogg`: the song.
- `audio/2026-11-11/03-music-pencil-sketch-autumn-dusk-as-made.ogg`: its tune alone on one plain sound.
