# The fire lights the men

*2026-11-12, Claude, from Dominic's note.*

Dominic, 16:48 UTC: "Campfire glow isn't quite right. Its from camera perspective, so I see round glow. But should be
over the men, creating shadow and light on them".

He was right. The fire was a Creel glow: a flattened disc of light laid over the finished picture, wherever it fell on
the screen. A man standing behind the fire was lit only where his body overlapped the disc on screen, never by where
he stood. Nothing cast a shadow from it, and men three tiles away stood dark.

What it does now (all in Smyana, `src/smyana.lobster`; no Creel change):

- **The ground round the fire** is lit in the world, out to five and a half tiles. It is brightest at the stones,
  falls off with the distance and flickers with the flames. It is drawn under everything that stands, so what stands
  can shade it.
- **Each man near a fire** casts a shadow on the ground away from it. His own frame is laid flat from his feet, longer
  the further he stands from the low flames, and darker the closer he is.
- **Each man is lit on his side toward the fire.** His frame is drawn again over him, with a warm light added: a rim
  on the edge that faces the flames, his front when the fire is before him, and only the edges of his back when it is
  behind him. His legs get more than his head. Sleeping men are lit softly all over.
- **Trunks, tents and beasts near the fire** are lit the same way, up to about a man's height or two, so a tree's
  foot glows and its crown stays dark.
- How strong all of this is follows the hour's mood (its glow). At night the fire is the main light; by day the sun
  drowns most of it.
- The old screen glow stays, smaller (radius 36 to 22), as the bright air just round the flames.

Pictures: 57 (before), 58 (after, the same moment), 59 (close, the men asleep and the shadows) and 60 (a winter dusk
camp in the fir woods).

Left to do: shadows from the trunks and tents (they keep only their sun shadows). The men still stand wider round the
fire than the ring asks, because twenty men don't fit in it; that is for the camp's own work.

## Also today: Dominic on the woods, the walk and the dress

While this was being made, Dominic sent notes and reference photos on the woods (too sparse, the ferns read as
palms, the trail is too yellow: "a little path through Africa"), on the men's walk (too fast, too small a step) and on
their dress (a photo, and the April Uprising of 1876 as a source). They are kept verbatim in
`archive/notes/2026-11-12-dominic-forest-density-and-ferns.md`, `-the-mens-walk.md` and `-men-dress-reference.md`.
They are the next work, in that order. The photos are not ours, so they are described there and not kept.
