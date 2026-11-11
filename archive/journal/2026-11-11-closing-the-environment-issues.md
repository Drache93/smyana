# Closing the environment issues (2026-11-11)

A fresh thread, started when Dominic drew a line under the two long ones (his words, 08:02, in
[his notes](../notes/2026-11-11-dominic-in-his-own-words.md)). It works from the
[environment handoff](../notes/2026-11-11-environment-handoff.md) and the lighting thread's
[last section](2026-11-11-moods-seasons-and-the-men.md#where-this-thread-stopped-handoff-2026-11-11). His complaint
about the old pictures was that they were made from stale versions, so every picture here says which commits it was
rendered from. Times are UTC.

## The two threads' last work brought together (08:05 to 08:15)

The lighting thread's rim on units in shade (pull request 45) and the environment handoff (46) both added a line to
the end of the timeline, so 45 conflicted with main. Claude merged both onto main in this thread's branch, kept both
lines, and pointed the engine at Creel's main, where the rim had been merged (Creel `8234c4b`).

## The riders face along the path, under the trees (10:00 to 10:10)

Dominic, 08:37: "riders at the edge shouldnt be looking away, should be facing to the right - like they're following
your path - and be much closer to the trees".

- A rider could only face the two ways the camp's horses do, side on to the camera, and at the back of the clearing
  that showed their backs. Riders are now baked facing four ways (`CAMP_RIDER_TURNS` in `src/smyana/camp.lobster`):
  `rider8` to `rider11` face down the screen to the right, the way the trail runs to the ford.
- They stand nearly two tiles further back, in under the first trunks of the back wood (`tools/make_scene.py`).

Picture 44, rendered from this branch on Smyana main `13a2956` with Creel `8234c4b`:

![riders along the path under the trees](../images/2026-11-11/44-riders-along-the-path-under-the-trees.jpg)

## The season clock (10:10 to 10:50)

Issues 10, 11, 13 and 14 all waited on one thing: the season was a word on each leg of the route, and it changed only
between places. Claude gave the run a clock for the year (D-059).

- **The clock** (`src/smyana/route.lobster`). The year is counted in thousandths of a season: 0 high summer, 1000 full
  autumn, 2000 midwinter, 3000 spring. A leg of the route gives two ends (`"year": [450, 800]`): the walk in brings the
  year at least to the first, and it moves on while the men are there, one thousandth every 28 ticks, up to the
  second. So the season turns while you watch, and a slow player still can't reach winter in the first valley. It is
  plain whole numbers in the sim, carried from place to place with the men.
- **Higher ground runs ahead** (`"altitude"` on a leg): the fir woods are 150 thousandths further into autumn than
  the valley below, and the same amount behind it in spring. The turn from ahead to behind happens through the
  winter, where nobody can see it.
- **Each tree turns on its own day.** A tree is up to 200 thousandths ahead of the year or behind it, by the cell it
  stands on, and so is each clump of undergrowth. A wood goes gold a tree at a time, thins a tree at a time, and comes
  into leaf a tree at a time. The stages are the ones already baked: summer, autumn, late (after leaf-fall), bare,
  spring.
- **Leaves come down** from every crown that is shedding, a pixel or two of the tree's own colour each, and the
  carpet on a beech wood's floor thickens with the clock, an eighth at a time.
- **The ground turns a texel at a time.** Creel gained a second set of ground textures that turns in over the first
  with no blending, so it stays crisp ([engine note](../engine/2026-11-11-a-ground-that-turns.md)). Autumn's leaves
  turn in over summer's ground, the first snow over the leaves, and spring's ground under the snow as it goes.
- **The light stands between two seasons** (#14). Each season's moods were already there; now the light is mixed from
  the season before and the season coming, on top of the turn from one hour's mood to the next.
- **The days shorten** (#13): `atmosphere.json` has the hours of dawn, day, dusk and night at midsummer and at
  midwinter (`hours_winter`), and they move with the clock. At midwinter dusk begins at half past three.
- **The night runs faster** (#13): the clock of the day is now its own count, and from nine at night to five in the
  morning it runs two and a half times as fast (`"night"` in `route.json`), so a night by the fire is about a minute.
- A leg that names a `"season"` stands still in it, off the clock. The comparison scene does, so it looks as it did.
  `year:<n>` on the command line shows any place at any point of the year.

Picture 46: the beech valley at six points of the year (450, 800, 1300, 1700, 2100, 2800), rendered from this branch
on Smyana main `a5ed604` with Creel's `ground_atlas_next` branch (Casaide/creel#23):

![the beech valley at six points of the year](../images/2026-11-11/46-the-beech-valley-at-six-points-of-the-year.jpg)

What it shows, and what is still weak: the turn at 800 is the best of it, green and gold and red in one wood. Spring's
green is loud beside the others. The floor under the trees is already orange in summer, which is the litter under
each old tree and was so before.

## The trees' shadows on the horses (10:15 to 10:40)

Dominic, 10:12, with a close-up of the camp's horses: "the way the shaddows fall on the horses isnt very realistic,
feels like it flat from camera perspective? but shadows dont fall like that right?" and "(trees shadow on the horse)".

He was right. The shade is a picture the size of the screen, and a horse kept the shade of whatever ground lay behind
it on the screen. A tree's shadow lying on the ground two tiles back was painted across the horse's flank as if the
horse were flat on the ground.

- Creel now keeps a copy of the ground's shade (`atmo_shade_standing`), and a unit drawn with `atmo_shade_stand`
  takes the shade of the ground at its own feet, all of it alike, read at five places across the feet so it goes into
  a shadow by degrees (Casaide/creel#23, documented in Creel's `docs/atmosphere.md`).
- Smyana draws its men, horses, mules and riders that way.
- The first try read the ground straight below each pixel of the body, which drew a shadow's edge as upright stripes,
  and it did the same to the rug lean-to and the bushes. One reading for the whole body, and only for men and animals,
  is what stayed.

Picture 48, before above and after below, from this branch on Smyana main `a5ed604` with Creel `3a903bf`:

![the horses before and after](../images/2026-11-11/48-horses-take-the-shade-at-their-feet-before-and-after.jpg)

Between the two, at 10:18, Dominic asked the threads to write their state down and stop, to pace usage, and a minute
later said the environment is the focus and this thread goes on. The
[state written then](../notes/2026-11-11-environment-state-at-the-pause.md) stands as the list of what is left; the
season clock and this fix, which it lists as unfinished, are in the pull request with this entry.

## The mist no longer lightens the deep wood (10:45)

The start-up thread (issue 86) found that shade under overlapping trees came out greyer and lighter than a lone
tree's shadow (Dominic there: "Lone trees its dark, overlapping its grey"). Its fix to Creel's mist could not be
pushed from that thread, so it is carried in this thread's Creel pull request (Casaide/creel#23): the mist keeps the
haze's colour and never lightens what it lies on. Picture 50 is the comparison scene with all of the above, from this
branch on Smyana main `a5ed604` with Creel `7100d3d`:

![the comparison scene](../images/2026-11-11/50-comparison-with-shade-at-the-feet-and-darker-deep-wood.jpg)
