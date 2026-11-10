# The Archive

A record of how Smyana is made: pictures, notes, decisions, changes of direction, funny bugs,
and the ideas that didn't make it. Two reasons:

1. **For future AI sessions (and future us):** *why* things are the way they are. Code shows what;
   the archive shows how we got here and what we tried.
2. **For anyone following along:** scroll back and watch a few voice memos turn into a game.

## Why this archive matters

Most of Smyana's code, art and writing is made with AI. The direction, the feel and the mood
are not. They come from Dominic, mostly as voice notes, and those are kept here in full so
anyone can see where the game really comes from. In his words (2026-11-10):

> It's important that I think to show that even when a game or an art is created by AI, it's the
> human creativity that drives it all. That's really important, I think. And because none of the
> direction the game has, none of the feel, the mood would have come without the human touch.
> And I think it's really important that we show all that. Equally, the game engine [Creel] comes
> from experimenting. It comes from me wanting to make the game, the open source engine that I
> wanted as a child. And pushing that and being able to play a game that I've made with my own son
> is an amazing feeling. And being able to build on that, put it onto Steam Deck,
> put onto phone, it's just been really amazing just to see that what I can do with AI. Because a
> lot of people see it as a negative thing when you're using only AI, but when a person that's
> full-time employed can make a game and make something that really put their heart into
> something as a side project, that wouldn't have been possible without AI. It would have been
> months and months of work and learning, and this allows me to be creative and enjoy that
> creativity without needing to take up loads and loads of time as basically a part-time job in
> order to do it.

So: **every voice note and message Dominic gives about the game goes into the archive, in his own
words**, as audio in `audio/` where there is a recording and as text in `notes/`. Claude's
summaries sit next to them, never instead of them.

## Rules

**It is append-only history.** Don't rewrite old entries. If something changes, write a new
entry that says so and link back.

## Layout

```
archive/
  README.md          this file
  decisions.md       numbered decision log (D-001, D-002...), newest at the bottom
  timeline.md        one line per moment worth remembering, for a quick scroll
  journal/
    YYYY-MM-DD-short-title.md   one entry per session or milestone
  images/
    YYYY-MM-DD/
      NN-short-description.png|jpg   screenshots, mock-ups, bugs, sketches
  audio/
    YYYY-MM-DD/
      NN-short-description.ogg       voice memos and sound tests (Opus, mono)
  notes/
    YYYY-MM-DD-short-title.md   source material: Dominic's own words, transcripts, research
  engine/
    README.md        how Creel changes are recorded
    YYYY-MM-DD-short-title.md   one entry per engine change made for this game
```

## The game and the engine

Smyana is built on Creel, the engine from Age of Anything, and the engine is extended in
parallel with the game. Game work goes in `journal/`. Engine work goes in `engine/`: what
changed in Creel, what the game needed it for, and pictures of before and after. Both get a
line in `timeline.md`, and engine decisions go in `decisions.md` like any other.

## Journal entry template

```markdown
# YYYY-MM-DD: Short title

**Area:** game | engine | art | audio | story
**Who:** Dominic + Claude

## What happened
Short narrative of the session.

## Decisions
- D-0NN: one line (full entry in decisions.md)

## Direction changes
What we thought before -> what we think now, and why.

## Pictures
![caption](../images/YYYY-MM-DD/NN-name.jpg)

## Funny moments and bugs worth remembering
- ...

## Ideas parked
- ...
```

## Pictures and audio

- Name files `NN-short-description.ext`, numbered in order within the day.
- Keep bug screenshots. They're the best part.
- Keep files reasonably small: JPEG for mock-ups and paintings, PNG for crisp game captures,
  Opus for audio. No videos in git for now.
- Only commit pictures we made or have the rights to. Reference shots of other games stay out.

## Writing

Plain words, with dates. Credit who decided what (Dominic or Claude). Before making a design
call, skim `decisions.md` so you don't undo a deliberate choice.
