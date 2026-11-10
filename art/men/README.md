# The men

The builders who leave the village for the season, as voxel bodies in the same style as the
Bulgarian man (Age of Anything's `mods/vox_example/tools/haidut.lobster`, 2026-11-10). His
clothes, proportions (7.5 heads, a head 10 voxels, 79 tall) and face are kept exactly; what's new
is a set of looks that can be mixed at random, and their kit.

## The looks

| Kind | Options |
|---|---|
| Hat | `kalpak` (black fur, red band: the original), `tall` (taller black kalpak, no band), `lamb` (short grey lambskin), `felt` (brown felt cap, rolled brim), `bare` (dark hair) |
| Coat | `black` (the original), `brown` (undyed wool, rust trim), `blue` (dark blue, red trim) |
| Cloak | `none`, `fleece`, `yamurluk` (the originals), `kozhuh` (sheepskin jacket with sleeves), `gunya` (shaggy goat-hair shepherd's cloak), `blanket` (a striped wool rug over the left shoulder) |
| Face | `droop` (the original moustache), `grey` (an older man: grey moustache and short beard) |

5 x 3 x 6 x 2 = 180 men. The sash stays the team colour on every one.

## The kit

- **The rifle with the swallow-tail butt** (`gear/rifle_swallow_tail.vox`): the long Balkan
  flintlock the builders carried, about 66 voxels (1.5 m against his 1.75 m). A thin barrel
  bound to a full walnut stock by brass bands, the lock on the right, and the butt split into
  two long horns with a deep V between them, studded with silver. The lower horn is the longer.
- **The masons' tools:** the `tesla` (adze-hammer: a hammer face on one side, an adze blade on the
  other, the Bulgarian builder's tool), a `dressing_hammer` (flat face and a point, for roughing
  out stone), a `stone_sledge` (two-handed) and a `trowel`.

## Files

- `vox/looks/`: one `.vox` per part, all in the man's own frame so they stack: `body_<coat>_coat`
  (the whole man bare-headed, no cloak, with the hidden `points` layer like the haidut's), then
  `hat_*`, `cloak_*` and `face_grey` holding only the voxels that differ from it, named for the
  piece they ride (`head`, `chest`, the arms for the kozhuh's sleeves).
- `vox/gear/`: the rifle and tools, each on its own.
- `vox/samples/`: the twelve random men in the pictures, each a whole `.vox`.
- `tools/`: the scripts that make all of it. `men.py` is the haidut script redone voxel for voxel
  with the looks added; `render.py` is a small renderer for looking at them; `sheets.py` makes the
  archive's pictures 24 to 31; `write_vox.py` writes `vox/`. Run from `tools/`: `python3 sheets.py`,
  `python3 write_vox.py` (numpy and Pillow).

These were made in a cloud session, where the Lobster tools couldn't be built, so they're Python
for now. When the men go into Creel, the looks move into the Lobster script (an argument per
part, like the haidut's cloaks) and the engine picks a look per man.

## Not done yet

- Not seen in the engine or in a real match yet, only in `render.py`'s pictures.
- The engine can't stack parts yet: today a variant is a whole `.vox` of its own.
- The rifle and tools have no holds yet (slung, on the shoulder, swinging, aiming).
