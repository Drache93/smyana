# The men without the spots

2026-11-13. Claude, for Dominic.

Dominic, 06:28 UTC ([his words](../notes/2026-11-13-dominic-big-old-trees-and-the-mounted-patrol.md)): "now that
we've done so much work on the art, I'm starting to feel like the men look a bit low-res almost, like they look a bit
spotty."

## Looking for the spots

- The spots were in the baked sprites themselves, not only in how they are drawn: the dark coats were full of grey and
  brown flecks at full size.
- The art isn't flecked. Each cloak in the `.vox` files is one colour (the black yamurluk is `#4a3628` all over).
- Turning off the bake's own shadows changed almost nothing.
- Smoothing the normals helped a little, but the flecks stayed.
- The real cause was the scale. A `.vox` voxel is half a body unit (Creel's `vx_VOX_RES`), and a man is 0.73 of a
  body, so at Creel's usual 2 voxels a body unit each art voxel was baked into 0.73 of a pixel. One row in four was
  dropped. The cloaks are shells one voxel thick, so they broke up and the coat under them showed through in flecks.

## The fix

- **Bake at a little over a voxel a pixel** (`MEN_RES` = 2 / 0.73 × 1.15). Exactly one voxel a pixel put rows on the
  half pixel and opened black holes in the skirts, so it is 1.15. The sprites are drawn smaller (`MEN_DRAW_K`), so the
  men stay the same size on screen. The sheets are about twice as big.
- **Creel: `vx_smooth_normals`** (2 passes for the men). Each surface voxel's normal and occlusion are averaged with
  those round it that face the same way, so a model's voxel stairs no longer light in flecks.
- **Creel: `vx_despeckle`** (1 pass). Each pixel is softened with those beside it of the same material at near the
  same depth. A line one pixel wide, a seam between two colours and the outline stay sharp.
- Both settings are off by default, so Age of Anything bakes as before. They are documented in Creel's
  `docs/settings.md`, as the docs rule asks.

Tried and dropped: baking the men at one art pixel a pixel (no shrinking when drawn). It is crisp, but blocky and
blotchy, and the detail goes.

## Pictures

- [12](../images/2026-11-13/12-men-before-left-after-right-at-game-size.png): the same view before (left) and after
  (right), at game size.
- [13](../images/2026-11-13/13-men-before-left-after-right-three-times.png): the same, three times larger.
- [14](../images/2026-11-13/14-men-sprites-before-above-after-below.png): three looks, before (above) and after
  (below), drawn at the same size. In the old ones the cloaks are broken.
