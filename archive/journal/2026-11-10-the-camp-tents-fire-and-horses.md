# 2026-11-10: The camp: tents, fireplace and horses

## What happened

Dominic asked for "the tents, fireplace, and our horses" so the first comparison scene could
show the whole camp at once ([his words](../notes/2026-11-10-dominic-in-his-own-words.md#the-camp-tents-fireplace-and-horses)).
Earlier he had noted the camp mock-up "dont match our final style": the mock-up gives what is in
the camp and how big, and the game's own crisp voxel look (the men, the trees) gives how it looks.

Claude made them as voxel models, in the same way as the men and the trees: a Python script
(`tools/camp_vox.py`) writes `.vox` files to `art/camp/vox/`, and the game bakes them
(`src/smyana/camp.lobster`) into a sheet of props with shadows.

- **Tents.** A canvas A-frame (crossed poles at both ends above a sagging ridge, flaps tied back,
  bedrolls inside, guy ropes) and a lean-to of striped Rhodope rugs (chergi) over a ridge pole,
  its striped slope turned toward the camera as in the mock-up.
- **Fireplace.** Gneiss stones round ash, charred log ends, a tripod with a copper cauldron. The
  flames stay the game's own (D-038); the game's flat placeholder stones and logs under them can
  go once the fireplace stands there.
- **Woodpile**, as in the mock-up beside the fire.
- **Horses and mules.** Four saddled riding horses (bay, grey, chestnut, dark) and four pack
  animals under a wooden pack saddle with loads: sacks and a rolled rug, kegs and tools, wicker
  baskets, long poles. Each faces right or left: sixteen frames.

## How they're lit

Creel's voxel grid lights a prop by material (bark, leaf, rock) with fixed ramps, which can't give
a striped rug or a grey horse. So the camp keeps each voxel's own palette colour and lights it the
way the grid lights the rocks (sun, its own shadow, occlusion, a rim), in four crisp bands with no
speckle. Thin things showed it first: the canvas came out blotched, because a sheet one voxel
thick has no clear normal. Two voxels thick and normals sampled out to six voxels made it read flat.
(Later blotches in the close shot are the trees' shade on the ground, not the tent.)

## Sizes

At first the sizes were real ones (a 1.35 m Rhodope pony, a 2 m tent). Beside the mock-up they
looked small, so they were raised to the mock-up's: the canvas tent a man and a half high, the
rug lean-to 4 m long, a horse's back at a man's chest.

## Pictures

- `images/2026-11-10/90-camp-beside-the-mock-up.jpg`: the mock-up (left) and the camp in the game
  (right), a lineup with the men among them, for a look only.
- `91-camp-tents-and-horses-close.jpg`: closer.
- `92-camp-sheet-as-baked.png`: the baked sheet, every frame and its shadow.

## Still to do

- The comparison scene places them (the other thread); the lineup here was a local hack, not committed.
- The animals don't walk yet; no riders.
- Dominic's call on the sizes and the looks (D-045 is Claude's).
