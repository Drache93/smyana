# Creel: a model's own shadow exact to a voxel, and ground up to nine levels

2026-11-10, Casaide/creel#13 (Claude, for Dominic's notes below).

## Own shadow

Dominic (22:18): "The trees in the example had shadows in the branches too. Our pic still looks like big bright omni
light on everything".

Why they had none: the voxel baker looked for a voxel's shadow by marching toward the sun in steps of 1.5 lighting
units. Smyana's trees are baked a voxel to an art pixel with a lighting unit of about 8.5 voxels, so each step was
nearly 13 voxels and jumped clean over boughs and twigs two to six voxels thick. A crown shaded nothing under it.

Now (`vg_sun_shadow`): the baker first makes a picture of the model as the sun sees it, keeping for each line of light
the voxel nearest the sun. A voxel is in the sun only if it is that one (within 2.5 voxels). One pass, no marching,
hard edges. `vg_shade` takes some sky light from shadowed voxels as well (Smyana: 0.4, `atmosphere.json` "sun":
"self_shadow", "self_shade"). Off by default in Creel, so Age of Anything's bakes do not change.

The lighting thread had begun a longer march for the same fault (`vg_shadow_reach`) and dropped it for this.
Picture 86: the same beech before and after.

## Nine levels

Dominic (22:17) of the landslide pass: "there's no cliff above?". Creel's ground had levels 0 to 3, each 30 art px,
about 0.6 of a man: three of them make a bank. `MAX_LEVEL` is 9 now (heights `0` to `9`, ramps `a` to `i`), so a ledge
can have four levels of cliff above it and four below. The cliff shader's packing of heights changed with it, and
Smyana's own cliff shader follows.

## A stream below its bank (added 22:40)

Dominic (22:26): "Stream also has a bank, slight depth in mock up". First tried as real low ground (the stream's tiles a
level down): the banks came out as a saw's teeth, because raised ground follows tile edges and the stream runs
across them. Kept as a bug shot in the journal's words only (no picture saved). Instead the terrain shader does it:
`ground_bank_px` says how far the water lies below the ground, and under the far shore that much earth shows (lit lip,
soil, dark wet foot), following the water's own ragged edge. `ground_water_edge` moves where the water begins on its
mask, so a stream can be narrower than its tile (0.62 in Smyana; much more and a one-tile stream breaks into pools).
Picture 88.
