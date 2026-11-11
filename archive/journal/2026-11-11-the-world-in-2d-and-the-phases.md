# 2026-11-11: the world in 2D, and the phases

Dominic, at 07:59 UTC: "we haven't really planned out what our game world map will be, the size and shape and scale. I
think it's worth us putting together a two-dimensional design of the world". His words, and his comments on the plan,
are in `archive/notes/2026-11-11-dominic-in-his-own-words.md`.

## The plan (Claude, 07:59 to 08:07 UTC)

Read first: the 18 open issues, the design doc, `data/route.json` and the three built maps. What was there: three
grey-boxed places (beech valley, fir woods, gorge), each 96 x 64 walkable tiles, with the men turning round beyond the
gorge (D-050); and a design doc whose one-hour table also had a ridge and a pass that nothing had built.

What Claude proposed, as a document with two pictures:

- The country and the walked ground are at two scales. A man walks 1.2 tiles a second, so a map is about 150 m across;
  seven of them are under 1 km of a 55 km trail. The letters home cover the rest. Picture 60 draws the maps about 15
  times too big so they can be seen.
- A line, not a loop, so each place is met twice in two seasons.
- Seven maps: the three built ones and four new (village edge, Roman ruins, the pass, the high ridge). Picture 62.
- Heights from 1,050 m to 2,050 m, with the trees Dominic listed sorted by height.

The pictures were drawn by a script (matplotlib): the relief is made up to fit the route, not a real place.

## Dominic's answers (08:09 to 08:14 UTC)

He commented on the plan itself, ten comments in five minutes, and Claude changed the plan after each:

- Threats and the fight before resources, for the feel: sound, smoke, music, flintlocks (D-053).
- The line and the seven maps agreed (D-054).
- Two hours, not one: "2mins at the roman ruins wont ever happen" (D-055). Claude doubled every leg.
- Bandits merged with the Ottomans (D-056).
- The load time to come down at the end (D-057), and an old-looking map in the loader as a stretch goal (D-058).
- The frame "at the end basically".
- Claude had guessed dates (phase 1 by 15 November). Dominic: "realistically much shorter. We have done the whole env
  in less than a day. We will complete phase 1 today i expect". The dates were dropped.

## The issues

Four parents and 32 new issues: phase 1 (#48, with #52 to #57), phase 2 (#49, with #58 to #62 and #64), phase 3 (#50,
with #65 to #73) and the frame (#51, with #74 to #84). Four existing issues were brought into line: #4, #5, #11, #16.
The environment issues that belong to a later phase (#9, #10, #13, #15, #20) are named in the parents and stay where
they are.
