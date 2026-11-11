# The Roman road, varied, 2026-11-11

Dominic, on pull request 94 (16:48): "follow up issue after rest is done, the roman ruined road is quite samey". That
became issue #97. Claude did the work.

The road had been a dozen tiles of four paving layouts in turn, kerbs both sides the whole way and a drain along it,
all straight. Now (`road_piece` in `src/smyana/trees.lobster`):

- **One road.** The stones are laid on a lattice along the whole road (some cells empty, so a bigger stone, some
  doubled, so smaller ones), and each tile is cut from it, so no tile repeats.
- **It changes as it goes**, blended between tiles (`ROAD_PLAN`, "fwhwgwwbbwhgf"): whole; heaved, stones tilted and
  lifted by roots and the kerbs knocked askew; gone, more than half the stones missing and the ground showing; buried,
  the stones under soil with a corner here and there and only the kerbs showing; and at each end fading into the trail,
  its kerb stopping ragged.
- **A slight bend**: it bows about a fifth of a tile off straight at its middle.
- **The drain comes and goes** (`ROAD_DRAIN`), with lids on some blocks, and runs under the road once in a culvert:
  a row of long lids across the road and the channel's mouth open on the far side.
- **Things grow through it.** `tools/make_places.py` lets grass over the gone and buried tiles, so the undergrowth
  grows there and turns with the year; a young tree has come up through the north kerb. The paved and drained stretches
  are kept clear.

A first render showed two long dark lines beside the road: the baked shadow of a long flat piece. The road's pieces
cast no shadow now. Picture 102 is before and after, in summer. A road along the map's y waits for the ruins' own map
(#53).
