# The environment work at the pause, 2026-11-11 10:25 UTC

Written by Claude when Dominic asked the threads to write down where they are and stop, to pace usage ("Yes we need to
pace ourselves, have them document current state and stop", 10:18). It follows the
[environment handoff](2026-11-11-environment-handoff.md) of 08:10; read that first for the look's rules and the
comparison scene's command.

## Merged or ready to merge

- **Smyana pull request 47** is ready: the lighting thread's rim on units in shade (it replaces pull request 45, which
  can be closed), the engine at Creel's main, and the riders facing along the path under the trees (picture 44).
- **Creel pull request 23** is ready: `ground_atlas_next` and `ground_atlas_mix`, a second set of ground textures that
  turns in crisply. Nothing in Smyana's main uses it yet. Merge it before the season clock's pull request.

## Done but not yet in a pull request: the season clock (issues 10, 11, 13, 14)

It works, lint is clean and `check.sh` passes with new checks. It is kept as a patch in the project's shared folder,
`smyana-environment/wip/smyana-season-clock-and-foot-shade-wip.patch` (apply on main after pull request 47, with the
`creel` submodule at Creel pull request 23's commit). A picture of the beech valley at six points of the year is
`smyana-environment/seasons-through-the-year.jpg`.

- The year is counted in thousandths of a season: 0 high summer, 1000 full autumn, 2000 midwinter, 3000 spring.
- **A leg of `data/route.json` no longer says `"season"`. It says `"year": [from, to]`**, and may say `"altitude"`
  (how far its high ground runs ahead in autumn and behind in spring). The clock moves while the men are in the place,
  one thousandth every `season.ticks_per_milli` ticks, between the two ends. A leg that still says `"season"` stands
  still in it (the looks: `camp_look`, `gorge_look`), so new legs written the old way keep working.
- Each tree and clump of undergrowth turns on its own day (up to 200 either side); leaves come down from shedding
  crowns; the leaf carpet thickens; the ground's textures turn in a texel at a time; the light is mixed from the two
  seasons the year stands between; dawn and dusk move toward each other into winter (`hours_winter` in
  `atmosphere.json`); the night's hours run faster (`"night"` in `route.json`).
- `year:<n>` on the command line shows a place at any point of the year.
- The patch also holds its journal section, its engine note, decision D-059 and its timeline line. D-053 to D-058 were
  taken by the world plan, so the next free decision after it is D-060.

Still to do on it: watch the whole tour once (it was started twice and stopped both times), then open the pull
request and comment on issues 10, 11, 13 and 14.

## In progress, not right yet: the trees' shadows on the horses

Dominic, 10:12: "the way the shaddows fall on the horses isnt very realistic, feels like it flat from camera
perspective? but shadows dont fall like that right?" and "(trees shadow on the horse)".

He is right, and the cause is known: shade is kept in a picture the size of the screen, so a horse takes the shade of
whatever ground lies behind it on the screen, painted flat across its body. The fix being tried is in the same patch
and in `smyana-environment/wip/creel-foot-shade-wip.patch`: Creel keeps a copy of the ground's shade
(`atmo_shade_standing`), and what stands up reads its shade from the ground at its own foot (`atmo_shade_stand`).

The first try (`smyana-environment/wip/horses-shade-before-after-wip.jpg`, before above, after below) is better on
most horses and wrong in two ways:

- Each pixel column reads the ground straight below itself, so a shadow's edge shows as upright stripes on a body.
  Next: one reading for the whole body at the middle of its foot, or a few steps across it.
- Wide things that are not animals (the rug lean-to, bushes) get the stripes too. Next: only men and animals read
  their shade this way.

It needs its own Creel pull request with the two names documented in `docs/atmosphere.md`.

## The open environment issues

The world plan (`docs/world.md`, issues 48 to 57) arrived this morning and takes over part of this list.

| Issue | State |
|---|---|
| 10 Season clock | Done in the patch. Close with its pull request. |
| 11 Seasons on screen | Done in the patch (gradual change, falling leaves, snow coming and going). Snow on boughs is not done. |
| 13 Day and night | Shorter winter days and the faster night are in the patch. Close with it. |
| 14 Moods | Blending between seasons is in the patch. Close with it. |
| 12 Creel's lighting list | Bookkeeping: tick what is merged, close. |
| 5 Route | Superseded by the world plan (issues 48, 52 to 55, 57). Close with a pointer. |
| 4 Maps and carrying the run | What is left (carts, caches) belongs to issues 69 and 71; load timing to 57. Close with a pointer. |
| 18 Frame budget | The size budget exists; measuring is in issue 57. Close with a pointer, or add a sprite count first. |
| 15 Weather | Not started: rain, falling snow, wind. Mist exists as mood knobs. |
| 9 Cover | Not started. The clock gives `leaf_cover_of(stage)` to build it on. |
| 20 Obstacles | Left: the ford's risk (plan in the handoff), walking round the slide. Carts are issue 71. |
| 16 Ground | Left: the gorge's depth (also named in issue 48), cliff rims ruled straight. |
| 17 Roman ruins | Not started: the voxel props. The map is issue 53. |
| 6 Trees | Left: a sawn stage, black pine and fir as their own shapes, thicker beech trunks. New kinds are issue 56. |
| 3 Parent | Close when the rest are. |

## To pick this up in a cloud session

Build Lobster as project memory says (`smyana-lobster-lint`), `mkdir src/bake_cache` so bakes are kept, and render
with the handoff's command. Say which commits each picture was rendered from.
