# Environment handoff, 2026-11-11 08:10 UTC

Written by Claude when Dominic drew a line under the long environment thread (his words, 08:02, are in
[his notes](2026-11-11-dominic-in-his-own-words.md)). A fresh thread, "Close all open environment issues", takes over
from here. What is done and left per issue is from this thread's own audit at about 08:00; check each issue's comments
before relying on it.

## State of the code

- Everything is merged. Smyana `main` is at PR #44 (riders at the wood's edge). Creel `main` is at its PR #21
  (`ground_water_ripples`), and the `creel` submodule points at Creel's `main`.
- No pull request is open from this thread, so there is no merge order to keep. This note is the only new commit.
- Nothing was started on the ford's risk (see #20 below): only a plan.

## The comparison scene

Run from `src/` (cloud session: Lobster is `/home/user/lobster/bin/lobster`):

```sh
xvfb-run -a -s "-screen 0 1600x900x24" /home/user/lobster/bin/lobster smyana.lobster -- windowed \
  leg:camp_look camp:29,32 look:30,30 hour:16 zoom:2 shot:/path/out.png at:3
```

- The camera is 22 degrees from `camera_elev` in `data/route.json` (D-051); `elev:30` on the command line shows the
  engine's own angle.
- The map `data/maps/camp_clearing.json` is written by `python3 tools/make_scene.py`, from measurements of the mock-up
  `archive/images/2026-11-10/23-route-beech-after-leaf-fall.jpg`. Its units: one "r" (x - y) is about 97 px and one
  "d" (x + y) about 36 px at zoom 2. Shadows fall down-left whatever the hour.
- Show ours above the mock-up. The latest is `archive/images/2026-11-11/42-riders-at-the-woods-edge.jpg`; before the
  riders, `40-comparison-rich-trees-floor-and-water.jpg`.
- Other looks: `leg:gorge_look` (add `mended` for the mended bridge), and any leg in `data/route.json` with
  `season:autumn` and so on.
- **Keep `leg:camp_look` running**: the music thread's first demo is men standing round this camp with music playing.
- Before every push: `LOBSTER=/home/user/lobster/bin/lobster src/lint.sh --fix`, then `LOBSTER=... ./check.sh`, which
  must print `run_check: ok`. After a change to a tree or camp bake, raise `TREE_BAKE` or `CAMP_BAKE`.

## Dominic's rules for the look (all in his notes, verbatim)

- Autumn's rich reds, oranges and yellows are the poster. After leaf-fall the trees keep their own colours and about
  half their leaves (D-052). "Leaf shades look great": keep the ground's leaf shades.
- Ground soft and pretty, not spotty. Banks slope softly, never a sharp wall. Grass is pale tufts in drifts, not lawns.
- The camera angle is a game setting, not the engine's. Every Creel setting or feature is documented in
  `creel/docs/settings.md` in the same pull request.

## The open issues

Closed already: #7 (seeing the men) and #8 (undergrowth).

The lighting thread was asked to take #12, #13, #14 and #15 and had not answered; they are listed as open here.

| Issue | Done | Left |
|---|---|---|
| #20 Obstacles | Bridge mended with carried wood (D-049, `mend_bridge`), or round by the ford. Landslide heaps cleared by digging `spoil` (D-048). Gorge on the route (D-050). Ford is slow (terrain speed 60). | The ford's risk: a loaded man may lose part of his load, and cold costs health in winter. Plan: in `route_tick` (`src/smyana/route.lobster`), every 10 ticks, for men on a ford cell, with checks in the gorge part of `src/run_check.lobster`; next decision number for it. Climbing or walking round the slide. How each looks on the way home. Carts. |
| #16 Ground | Raised ground and soft banks, stream with soft shore, ripples and two depths, crags at cliff feet. Ford and broken bridge in the gorge. | The gorge is flat: it needs real cliffs. Cliff rims are ruled straight. No ridge or pass ground. |
| #18 Frame budget | A size budget per place in `data/route.json` (`budget`: tiles and old trees). | No measured frame time or sprite count per place; no grey-box stress test. |
| #5 Route | Three places grey-boxed and joined: beech valley, fir woods, gorge, out and home. | Forest edge, high ridge, pass. Walking it at game speed and timing it against the hour. |
| #4 Maps and carrying the run | Route file, exits, letters between places, the men carried, places remember terrain, wear and bridges (`PlaceMemory`). | Carts, caches and dead animals are not carried or remembered. A timed real load. |
| #10 Season clock | Season is set per leg. | No clock in the sim; nothing driven by it (leaf cover, food, cold); higher ground ahead of the valley. Needs Creel work. |
| #11 Seasons on screen | A look per season for trees, undergrowth and ground; the "late" leaf-fall stage; winter bake. | The change is not gradual: it steps between legs. Leaves do not fall or pile up while you watch. |
| #9 Cover | Nothing in the sim. | All of it. Needs Creel work. |
| #17 Roman ruins | Nothing. | The voxel props (columns, paved road, drain) and their moss by season. |
| #6 Trees | Species with old, mature and young trees, stumps, felled logs, a look per season, crowns the men walk under. | No sawn stage. Black pine and fir are not distinct from Scots pine and spruce. Beech trunks are slimmer than the mock-up's and fork too high. |
| #3 Parent | | Close when the rest are closed. |

## Smaller things still wrong in the comparison scene

- No smoke from the fire.
- Riders in the back wood's shade: the horse reads, the man barely. It needs help from the light (a rim on units in
  shade, less mist over units, or bloom). Passed to the lighting thread, not answered.
- Lit leaves a little too orange (lighting).

## Housekeeping for the next thread

- Archive pictures for 2026-11-11: the environment takes even numbers, next 44; lighting takes odd.
- Next free decision: D-053 (check `main` first).
- Journal: `archive/journal/2026-11-11-soft-banks-soft-grass-and-the-camera.md`; use `date -u` for section times.
- Work to an issue, comment on it with the pull request, tick its boxes, close it.
