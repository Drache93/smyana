# Summer greens, 2026-11-11

Dominic looked at a summer wood (picture 97) and said the firs had "lots of brown at the bottom", the light looked
washed out, the scene was "too green, and lacking variation", and "the lighter coloured trees are almost invisible on
the grass". His words are in [the notes](../notes/2026-11-11-dominic-in-his-own-words.md) (20:45). Claude did the work.

## Why it looked washed out

Three things in the summer day mood (`day.summer` in `data/atmosphere.json`) stacked up:

- a strong yellow highlight tint (0.45 of `#ffe8a0`) on everything lit, which cut the blue out of the greens and pushed
  them all toward one yellow green;
- a pale yellow-green haze (`#b8c8a0`) over the whole screen, which lifted the darks;
- a yellow sun colour and a grey-green shade colour, so lit and shaded parts had no cool/warm difference between them.

Under that, the art itself had one green everywhere: the beech, hornbeam and oak crowns, the bracken, the herbs, the
grass tufts and the grass ground were all close in hue and brightness. A hornbeam's lit crown was nearly the colour of
the tufts below it, which is why the light trees vanished on the grass.

## What changed

- `day.summer`: highlight 0.15 of a near-white, a cool blue-grey haze at 0.1, a less yellow sun, a cool shade
  (`#7c8c9c`) and a little more contrast.
- Crowns (`leaf_look`): deeper, cooler greens; oak darkest, hornbeam bluish, beech fresh. Each tree of a kind is a little
  different (kind 1 darker and bluer, kind 2 fresher and yellower).
- Meadow: the summer grass ground (`tools/ground_atlas.py`) is warmer and more olive; tufts are one fresh, one deep green
  and one gone straw; herbs one silvery, one warm, one green; bracken in three greens.
- The forest floor in summer: under the beeches last year's leaves are dull brown with moss in them, no longer orange;
  under the conifers it is thin needles on moss, olive brown, where it was a dark rusty pool round each tree. That pool
  was the "brown at the bottom" of the firs (the fir's own bark is grey).

Autumn and winter are unchanged (checked on the comparison scene). Pictures: 98 (before and after, the gorge's beech
side in summer), 100 (a conifer wood in summer after).

## Later: saplings of each kind (#98)

Saplings were all young beeches. Now each wood has its own (`tools/tree_vox.py` makes `oak_sapling_0`,
`hornbeam_sapling_0`, `spruce_sapling_0`, `fir_sapling_0`, after the other trees so their seeds don't change): a
broadleaf wood's are half beech, the rest oak and hornbeam; a conifer wood's are spruce, fir and some beech. A sapling
is one picture, its stem and leaves together. The conifers' are evergreen and stand through the winter; the
broadleaves' still go under the snow with the rest of the undergrowth.

Claude tried breaking the summer and autumn crowns into clusters by thinning their leaves with noise. It didn't work:
thinning a solid crown shows its dark inside, not sky, so the crowns only went darker. Crowns with sky between their
clusters have to be built that way in the .vox models (leaves in clumps on twigs, as after leaf-fall), which is the rest
of #98.

## Later: the men's pixels (Creel `sprite_even`)

Dominic at 21:16: "concerned the men look a little pixelated" (picture 105). The men are drawn one voxel to one art
pixel, and the zoom is in quarter steps (2.75, 4.75...), so with nearest sampling one art pixel came out two screen
pixels wide and the next three: uneven, jagged edges. He chose a sharp filter from three options. Creel's sprite shader
now samples sharp bilinear when `sprite_even` is on (Casaide/creel#26): each art pixel is solid, and only the one screen
pixel where two meet is a mix. Smyana switches it on; look option `even:0` shows the old way. The first try mixed the
texels before recolouring the team key and left a few purple pixels, so each texel is now recoloured first. Picture
106 is before and after at zoom 4.75. Up close the men are still pixel art, 40 voxels tall; more detail would mean
remaking them.
