# The Roman ruins' props (2026-11-11)

For issue #17. Made by Claude in the thread that took over the remaining environment issues.

## What was made

Voxel props in `src/smyana/trees.lobster` ("the Roman ruins"), baked onto the rocks sheet:

- **The paved road** (`paving{x,y}{0..3}`): a tile each, of big flat stones fitted together with grass in the joints. A
  few stones are missing, and there are kerbs on both sides. There are four layouts, so the road doesn't repeat.
- **A drain** (`drain{x,y}{0,1}`): a channel of dressed stone beside the road. Most of it still has its cover slabs. In
  the second kind most covers are gone and one has fallen in across the channel. The drain is the knowledge the men
  bring home (Roman drains, from the Kovachevitsa story).
- **Column stubs** (`column0`, `column1`): a square base and a fluted shaft broken off at the top, with ivy up the
  shaded side. The tall one stands about two and a half men high.
- **A fallen column** (`drums{x,y}{0,1}`): its drums lying where they fell, one rolled off, and its capital.
- **Wall stubs** (`wall{x,y}{0,1}`): courses of squared limestone with a band of red brick through them, as Roman walls
  in Thrace have. The tops are broken, with ivy over them and fallen stones at the foot.

The stone is a pale, warm limestone (`roman_look`), worked square, so it reads as a different stone from the local
gneiss. Creel's rock light adds lichen on the tops and moss low on the shaded sides.

## Where they stand

A map lists its ruins as `"ruins": [name, x, y in milli-tiles]`, and `build_props` stands them up. `tools/make_places.py`
lays them out with `place(..., ruins=x)`: the trail runs straight along a dozen tiles of road, with the drain beside it,
three columns and a fallen one along its north side, and the footings of a building behind them, all in a clearing.
The ground under them stays grass, so the undergrowth grows up between them and turns with the year. Undergrowth does
not grow through a wall or a column, but grass does grow between the road's stones.

Until the ruins get their own map (issue #53), they stand in a small beech clearing, `data/maps/ruins.json`. To look
at it: `leg:ruins_look look:30,23 zoom:2`.

Picture 88: the ruins in autumn. Picture 90: the ruins in winter with the men round a fire, for scale.

## Not done

- The ruins do not block walking yet: the men can walk through a wall or a column.
- No snow lies on the stone in winter. The same is true of the gneiss rocks and the gorge's outcrops.
- There is no arch, and nothing the men can study yet. Studying the drain belongs with the mechanics (phase 3).
