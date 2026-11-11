# Rough relief: rims that wander (2026-11-11)

Creel PR Casaide/creel#24, for Smyana #16. Done by Claude after Dominic's "those are all hard edges on the gorge
though" (16:09).

## Why

Creel draws raised ground with one quad for each tile top and one vertical face for each tile edge. Every rim, step and
ramp crease therefore ran ruled along the tile grid. On the gorge's diagonal walls that became a staircase of straight
lines. PR #92 hid most of it under gneiss outcrops, but where each ramp meets its wall the ruled lines still showed.

## What changed

- `relief_rough` (levels, off by default). Near any change of height, the ground rises and falls on a smooth noise.
  Those tiles, their faces and their rims are drawn in 4 by 4 strips, so a rim bends. Flat ground and ground far from
  any drop are unchanged. `lift_at` includes it, so the men stand on it.
- `relief_rough_size` sets the size of the swells (1.5 tiles).
- The light on rough ground is worked out at each corner from the slope, so it runs smoothly and turns sharply only at a
  rim. Before, it changed tile by tile, which was itself a ruled look.
- Smyana sets 0.9; a map can set its own with `"rough"`.

Picture 84: the west ramp before (left) and after (right). Picture 86: the gorge's walls in winter, seen for the
first time.

## What it does not do

The footprint of a cliff still follows the tiles; only its heights wander. The faces are still sheer. A ramp beside a
stepped wall still leaves dark triangles of face. Dominic asked for an issue for proper cliffs (16:32, "Our work so far
was worked around"): Casaide/creel#25 lists what they need, including footprints off the grid, faces with ledges and
scree, walkability kept apart from the look, and snow on the ledges. The rock outcrops on the walls carry no snow in
winter.
