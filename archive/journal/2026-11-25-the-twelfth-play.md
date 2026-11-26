# The twelfth play, and a bug as old as the huts (2026-11-25)

After Dominic merged PR 129 ("Merged", 21:46) a twelfth first-time player was sent through the whole game cold, from
the title (`archive/playtests/2026-11-25-12-first-time-player.md`). It got three places and five nights in, all
twenty men alive.

What it found that mattered most was small in code: a right click on a shepherds' hut, under a pointer that says
"camp here", had never made a camp. One function gave a hut's number in a list and its callers read it as a place on
the map. Earlier plays had reported huts that "did not take" and each time the fix went round it (a longer wait, a
nearer door). This time the play was reproduced by hand in the fir woods and the cause read out of the code (D-211).

The rest is D-212 to D-214: a man the drag missed now follows the band, the band says when it is waiting for him, a
kill gets a ring, a cache says what it held, the houses lose a stray shadow bar, the evening by the fire runs
faster, and women come down the lane at the homecoming.

Not done: the play's biggest complaint, that nothing threatens the men in the first half hour, is a design question
for Dominic, not a bug.

## The test bot afterwards (night of 2026-11-25 to 26)

On the build with D-211 to D-214: seeds 1, 2 and 4 came home with 8, 14 and 15 of 20. Seed 3 ran out its five days
in the pass on the way home with six men left, five of them standing in the gate and the sixth eight tiles off: a
slow, hungry run that fought a patrol, not a stall. The bot's own rule for huts on the way home did something for
the first time after D-211 and sent it to a hut up to thirty tiles back; it now takes only one within sixteen tiles
that is not behind it.
