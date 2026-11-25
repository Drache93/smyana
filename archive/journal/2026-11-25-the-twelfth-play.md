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
