# Music

How Smyana's music is sketched. This is a workbench for trying out style and feel, not the
final sound. See [`docs/music-and-sound.md`](../docs/music-and-sound.md) for the plan and
[`docs/rhodope-music-style.md`](../docs/rhodope-music-style.md) for what Rhodope music is like.

## How a piece is made

1. **Write the tune as text.** A piece is a small Python file in `pieces/`. Each phrase is one
   line, such as `B4/3.2~ 'D5 B4/0.5 A4/0.9`: the note B held 3.2 seconds with vibrato, a quick
   flick of D, B again for half a second, then A. Times are seconds, because slow Rhodope song
   has no beat.
2. **Render it.** `python3 music/pieces/spike_01_autumn_dusk.py` builds every sound from sine
   waves and noise (`synth.py`, numpy only) and writes `music/out/`: a WAV, an MP3, an Opus
   file and a MIDI file. It takes about a minute. The same text always gives the same sound.
3. **Listen, change a line, render again.** Since the score is text, each change is a small
   diff with a reason in the commit.
4. **Keep the ones worth keeping.** A render goes in `archive/audio/<date>/` and its MIDI in
   `music/spikes/`.

Needs Python 3 with numpy, and ffmpeg for the MP3 and Opus files.

## Why this way

- **Everything is ours.** No samples, no recordings, no sound library licences. Nothing here
  was made by an AI music generator either: Claude wrote the notes and the code that turns them
  into sound, and both are in the repo.
- **It is honest about being a sketch.** The voices are stand-ins: the "kaval" is a breathy
  near-sine, the "gaida" a buzzy pulse. They are good enough to judge melody, pace, key, and
  how drone and tune sit together. They will not fool anyone who knows the real instruments.
- **The MIDI is the bridge to the real thing.** The same notes open in any music program, so
  they can be played through a proper sample library (see the plan's sourcing options) or
  handed to a real kaval or gaida player as a guide.

## What it can't do yet

- A singing voice. Synthesised singing in this style sounds wrong, so the lead here is a kaval.
- Loops and stems for the game (drone / melody / pulse as separate files). Easy to add: each
  part is already made separately before the mix.
- Claude can't hear. Renders are checked by measuring them (pitches, loudness, a picture of the
  sound), which catches wrong notes and bad levels but not "does this feel right". That
  judgement is Dominic's.

## Pieces

| Piece | What it tries |
|---|---|
| `spike_01_autumn_dusk.py` | Kaba gaida drone on E, a slow five-note tune on kaval, the gaida answering with its own ornaments, low strings underneath. About 1m45s. |
| `spike_02_autumn_mist.py` | The same idea after "too Viking, needs more mist": no low drone or strings, a breathier kaval far off, men humming the answer, haze. About 1m40s. |
| `spike_03_danger.py` | Music that follows the game: calm, hiding (heartbeat), a fight (tapan and gaida in fast 2/4), a dead stop, and the kaval alone afterwards. 80s. Lengths in the fight are written in beats (`bpm=`). |
| `set_02_tracks.py` | Five separate tracks made to be swapped in and out: fight, hiding, morning, autumn dusk (second take), ruins. Adds tambura, gadulka, bells and open voices. Run one with `python3 music/pieces/set_02_tracks.py fight`. |

The plan for the whole score is in [`docs/music-tracks.md`](../docs/music-tracks.md).
