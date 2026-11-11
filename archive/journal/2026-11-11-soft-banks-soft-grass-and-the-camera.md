# 2026-11-11: soft banks, soft grass, and a look at the camera's angle

Dominic, of the comparison scene: "ew're still missing lot of detail. The ebankment is too sharp, should be softly going
down. And missing all the soft grass". And: "should we adjust the camera angle i wonder, feels more special in the mockup
with the angle". His words are in `archive/notes/2026-11-11-dominic-in-his-own-words.md`.

## The camera (a trial, not a change)

Our camera looks down from 30 degrees above the ground, as Age of Anything's does. The mock-up looks lower. A trial at
22 degrees (three numbers in Creel and one in its ground shader, not committed) gives picture 02: now, the trial, the
mock-up. Lower stacks the trunks into a wall at the back and lets the crowns frame the clearing. It costs sight of the
men behind trees, and the screen reaches about a third deeper into the map. Dominic's to decide; asked.

## The stream

- The bank was a wall of dark earth a few pixels high along the far shore. It is gone. The ground now slopes down to
  the water on both sides: its own cover carries on down the slope, damper and darker, earth showing by the waterline,
  the slope turned to the sun lit and the other in shade (Creel: `ground_shore_soft`).
- The stream is narrower than its tiles and winds. Creel's water mask is a tile's worth of water, blurred, so Smyana
  paints the water again after it, finer (`build_stream`): along the stream's own line where the map gives one
  (`"streams"`), else through the middle of the water's tiles. The men still walk the same tiles.
- The water is the mock-up's pale blue under the sky, not teal (Creel: `ground_water_shallow`, `ground_water_deep`).

## The grass

Looking closely at the mock-up: its grass is not a green floor. It is pale upright tufts, shin to knee high, standing
out of the fallen leaves, thick in drifts and thinning to single tufts. Ours was flat green patches with flat dabs of
herbs on them.

- A tuft of grass as a model (`grass_tuft`): thin stems from a few feet close together, dark at the foot and straw
  yellow at the tip, six shapes. Up to 26 a tile, by a smooth drift a few tiles across, and thinner under a close wood.
- In autumn the leaves lie over the open ground as well, with only a worn spot of turf here and there.

Picture 04 is the scene above the mock-up. Still open (Claude): the tufts could stand closer yet at a drift's middle;
the trail fades under the leaves before it reaches the stream; the men do not sit round the fire; the crowns are in
full leaf where the mock-up's are nearly bare.

## After leaf-fall, and the camp lived in (06:20 to 06:45)

More of the detail the mock-up has and we lacked (picture 06):

- **Crowns after leaf-fall.** The mock-up's trees are dark boughs with the last leaves hanging on in clumps; ours were
  in full autumn leaf. An autumn leg can now say its leaves have mostly fallen (`"leaf_fall"` in `data/route.json`):
  the trees wear a "late" stage, autumn's colours with most of the leaves gone, a bough here still dressed and the next
  bare. The shade on the ground stays that of the whole crown, or the wood's shade breaks into flickering holes. The
  comparison leg uses it; the route's own autumn legs keep their full colour until the season clock (#10) drives this.
- **The trail** runs down to the stream and fords it (it stopped short: the stream's tiles had overwritten it).
- **The men** stay where the scene puts them (the order that walks them in from the gate is called off): most round
  the far side of the fire, facing it, the rest by the mules, on the trail and at the stream.
- **The flames** are drawn a pixel of the art at a time, a red flame with an orange one and a yellow heart inside it,
  under the tripod; they were five flat bars. Still a look-only fire (D-038). Nothing grows where the men tread round
  it.

## The pass: faces that jog, a river in the gorge (06:50 to 07:05)

- The faces ran ruler-straight along one row of tiles. Now the ledge widens and narrows by a tile in runs of two to
  four tiles, the bluff stepping back and the lip stepping out, tightest where the slide lies.
- Creel cut every outer corner of high ground down to the ground below (a hill's rounded shoulder, made for hills one
  level high). On cliffs four levels high that gave great slanted wedges at each jog (kept out of the archive: no
  picture was saved). A setting, `relief_sharp`, keeps the corners: sheer faces that jog square.
- The gorge's river is a narrow winding river now, by the same finer water as the clearing's stream.

Picture 08. Still wrong (Claude): the jogs are square blocks, a quarry more than a mountain; faces need breaking at a
finer grain than a tile, which Creel's ground can't do yet.

## The grass again: fine stems in drifts (07:10 to 07:40)

- Seen in the beech valley, the first tufts read as small round bushes, evenly dotted, each with a spot of shadow
  (Claude's own look at it; Dominic had asked for "all the soft grass").
- A tuft is now nine to twelve single stems spread over a fifth of a tile, a leaf dab on each, and casts no shadow.
- Where tufts stand comes from a better-mixed number (the old one put them in rows), 24 chances a tile, and the
  drifts have a harder edge: thick inside, almost nothing outside.

Pictures 10 (the scene) and 12 (the beech valley's ford).

## The pass: crags at the cliffs' feet (07:45 to 08:05)

- The faces can't be broken finer than a tile in Creel's ground, so the breaking is done with rock standing in front
  of them (Claude): crags, buttresses of the same dipping beds, most of a face's height, broad along the face and
  narrow front to back. One stands at every corner of a face and at three tiles in ten along it; loose slabs lie at
  another three in ten. Lower faces get a lower crag.
- The first crags were thin pale beds, a stack of pancakes (not kept). Beds are two to three times thicker now and
  darker, nearer the face's own tone.

Picture 14. Still wrong (Claude): the rim of a face is still a ruled line, and the crags' fronts have dark upright
streaks from the rock light.

## The fir woods: no drawn line round the needle floor (08:10 to 08:20)

- Looking at the route's other places in the new look (Claude): in the fir woods the brown needle floor ended on the
  grass along a hard scalloped line. Creel's ground gets a setting, `ground_litter_fringe`, that scatters the floor's
  edge a pixel at a time, so needles and leaves thin out onto the grass. Smyana sets it to 0.3 everywhere.

Picture 16.

## Brambles (08:25 to 08:40)

- A new plant of the undergrowth (#8; Claude): long dark red canes arching out of one foot and down to the ground
  again, leaves in threes along them, green going wine red in autumn. They grow in thickets a few tiles across where
  a tree or two gives half shade, at a wood's edge, not out in the open and not deep under a close wood.
- The first try had a leaf at every other joint and stood high: bare hoops, like spiders (not kept). Lower canes and
  a leaf at nearly every joint made them thickets.

Picture 18. They are only looked at so far: walking through them costs nothing yet.

## Winter: what's left of the undergrowth (08:45 to 09:00)

- In winter the undergrowth simply vanished: snow, bare trees and nothing else. Now it dies back instead (#8;
  Claude): the bracken stands dead and rust brown, one grass tuft in three shows through the snow as straw, the
  brambles keep their canes and a few dark wine leaves. Bushes and herbs are gone until spring.
- The strewn edge of the forest floor is much narrower in winter (0.1 against 0.3): at 0.3 it peppered the snow.

Picture 20. Still wrong (Claude): two broadleaf crowns stand summer green in the snow, and the dead bracken stands as
upright as the live (it should lie flattened).
