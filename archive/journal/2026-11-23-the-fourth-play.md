# The fourth first-time play, and what it found (2026-11-23, evening)

Dominic, 17:23: "Please dont ever wait for me, can wait async". So the work went on from his sound notes into the
next agent play without stopping (report: `archive/playtests/2026-11-23-04-first-time-player.md`). 118 steps, 22
minutes of game clock, three camps; the player never left the village edge and would have quit at about ten minutes.
All of what follows is Claude's work and Claude's calls.

## Men who answer and do not move (D-151)

For nearly two minutes about fifteen men said "hm" to every order and stood, until Halt. The third play had the same.
No `deaf:` line was printed, so the game thought the order had been taken. Read in Creel: a move to within five tiles
of where a block of men was last sent is dropped as the same order again, even if the block arrived long ago. Halt
clears the block. Every walk order of ours now goes through `send_men`, which takes a standing man out of his block
first. Not yet seen cured in play.

## The night (D-150, then D-153)

First try: the clock ran at 800 once all slept. The bot then lost every man on seed 1 and brought 9 home on seed 2
(11 and 12 before). Three copies of the game side by side on seed 1: fast clock only, 0 home; `send_men` only, 12;
neither, 16. The wood's game and food come back by the tick, so short nights starve the country. Second try, kept:
the whole game runs four times faster while every man sleeps. In the harness the night from 21h to 4h went by in
about a third of the real time of a day step.

## Smaller things (D-152)

- The menu plays its own track (it never had); 70 seconds of quiet between calm tracks, ended early by a turn of the
  light; the woodpecker calls every 40 to 200 seconds, not 25 to 70.
- "That is the last of the bread" was said when the packs were set down: the count now takes in the packs.
- The red-hipped dog roses are bushes, not stands, and both first-time players went to them first. A man now says
  why there is nothing to pick. No stand was found in 22 minutes: there are two strawberry patches and one of herbs
  at the village edge, none near the start. Open.
- A later morning still at the village edge, a man says which way again.

## Left open

The day is 4:20 of light and both players felt they got nowhere; the day's length is not changed, since the balance
moved a long way on a change to the night alone. Black beyond the map's edge. Nights too dark to find one's own
camp. Drags that chose nobody twice (seen again in the harness under load; may be the harness).
