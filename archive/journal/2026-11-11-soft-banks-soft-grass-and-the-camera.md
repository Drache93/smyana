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

## The landslide can be dug away (09:10 to 09:35)

- Until now the slide could only be squeezed past. Now the men can clear it (#20, D-048; Claude): a right click on a
  heap sets the chosen men digging, as on a young tree. In the check, four men walk up the pass and dig one heap to
  bare ground in about fifty seconds; nobody carries anything away.
- First try: the men stood by the heap and did nothing. Throwing the spoil aside also wiped what kind of work the
  man was at, so he gave up at once. Only the load is emptied now.
- Found on the way: men ordered to dig from the far end of the place walked into a tree and stayed there; ordered to
  walk up first, then dig, they are fine. Not fixed (the walk to far work is Creel's).

No picture: it was tried in the check with no window, not yet looked at on screen.

## The gorge: a broken bridge and a ford (09:45 to 10:30)

- A third place, the gorge, as a grey box and not yet on the route (`leg:gorge_look`): a river three tiles wide that
  can't be waded, the trail's bridge over it found broken, and sixteen tiles downstream a wide shallow ford with a
  side path to it from each bank (#20; Claude). It is flat for now: no cliffs, so not yet a gorge to look at.
- The bridge is timber: two round beams on trestle posts, split planks across. Broken, only its two ends stand, a
  plank hanging from each.
- Mending it (D-049): a right click on the broken bridge with men chosen. Creel already had map bridges that
  workers rebuild for a price; Smyana pays the price from the wood the chosen men carry. In the check, two men with a
  load each mend it in 455 ticks (about 23 seconds) and all twenty cross.
- `mended` on the command line shows a place with its bridges standing, for pictures.

Picture 22 (broken above, mended below). Still wrong (Claude): the trail fades out before it reaches the bank, the
ford's wading is no slower for a loaded man and no colder late in the year, and mending has not been tried by hand
on screen, only in the check.

## The gorge goes onto the route (10:35 to 10:50)

- The run is six visits now (D-050): out through the beech valley, the fir woods and the gorge, and home through
  the gorge and the firs in winter and the beeches in spring. The check walks all of it: digs at the slide, sends a
  man round by the ford while the bridge is down, mends the bridge, comes back in winter and finds it standing and
  the dug heap still gone.
- Three placeholder letters were added and one reworded (Claude's words, to be replaced by Dominic's).

Picture 24: the gorge in winter, the ford and the side path to it.

## The camera goes down to 22 degrees, and two hard looks at the scene (10:50 to 11:20)

- Dominic chose the lower camera (D-051) and asked that it be the game's setting, not the engine's. Creel's view
  angle was four fixed numbers (the units' bake, the props' bake, the ground's squash and the height of a level) and
  two more inside its ground shaders; they are settings now, 30 degrees unless a game says otherwise. Smyana reads
  `camera_elev` from `data/route.json` and sets them before anything is baked. Every bake's key carries the angle.
- Dominic also asked for a critical reviewer on the comparison picture. Two reviews came back (both by Claude
  agents, neither is Dominic's word): one is kept whole in `notes/2026-11-11-critique-of-the-comparison-scene.md`.
  They agree on the worst of it: the back of the wood is an empty floor with a few trunks, the trees are saplings
  beside the mock-up's beeches (thin dark trunks, blobs of pure red and yellow where it has pale thick trunks and a
  mass of fine twigs with a few rust leaves), nothing frames the clearing in the foreground, the ground is one
  orange carpet, the grass is still too thin, the stream is paint on the ground with no stones or ripples, the camp
  stands in shade while the sun falls on bare ground, and the view is about a third too close.

Pictures 26 (the scene at 22 degrees above the mock-up) and 28 (the pass at 22 degrees). Still wrong (Claude): the
stream's edge steps more coarsely at the lower angle.

## First answers to the reviews (11:20 to 11:45)

- **Further out.** The scene was shot a third too close (men 80 to 100 px tall against the mock-up's 60 to 75). At
  zoom 2 in place of 2.75 the back of the wood has its crowns in frame and trees close the clearing in on every
  side: much of "the back is empty" and "nothing frames it" was the framing, not the planting. The comparison is
  shot at `zoom:2` from now on.
- **Rust, not red and gold, after leaf-fall.** The "late" stage has its own leaf colours: russet, burnt orange and
  brown. Full autumn keeps its reds and golds (Dominic's: autumn's rich colours are the game's poster).
- **Pale trunks.** Beech and hornbeam bark is a pale silver grey now; it was near black in shade.
- **The camp in the light.** The clearing is opened up and to the left, and the two big trees up-sun of the camp are
  gone, so the fire and the tents stand at the edge of the sunlit pool.

Picture 30. Still to do from the reviews (Claude): crowns as a mass of fine twigs, the ground in patches, grass
denser and lower, the stream's stones, ripples and overhang, logs and a chopping block by the camp, fewer men at the
fire.

## Twigs for crowns, low grass, and the scene laid out as the picture (done by 07:20 UTC)

(The clock times on the sections above ran ahead of the real clock, which is Claude's mistake; Dominic's messages in the notes carry the true times.)

More of the reviews' list, by Claude, measured on the mock-up at the game's 22 degrees and zoom 2.

- **The twigs are the crown.** After leaf-fall every thin branch of an old tree sprouts fine dark twigs a voxel
  thick, out and up from the tree's middle (`bristle` in `src/smyana/trees.lobster`). They are baked into the picture
  of the tree's last leaves, in a darker bark than the pale trunk, so a crown is a dark bristle with rust dabs in it.
  The trunks and boughs are the same models as before.
- **Grass low and thick.** A tuft is ankle to shin high now, about half what it was, with a base of short dark
  blades under pale heads. Half as many again stand on a tile, and they mass along a trail's sides and a stream's
  bank everywhere, not only in the drifts.
- **The scene as the picture.** The stream comes in at the right edge level with the camp and leaves at the bottom's
  middle. The trail winds from the fire down to a ford. One big beech stands at the left third and one at the right.
  The wood up-sun of the camp is opened so the tents, the fire and the horses stand in the light. Twelve of the
  twenty men are away from the fire: at the ford, by the mules and horses, on the trail, on watch. No pines stand
  among this clearing's beeches (`"pines": 0` in a place's map). The command is now
  `leg:camp_look camp:29,32 look:30,30 hour:16 zoom:2`.
- **A bug on the way.** With the ford in its new place the men walked off east while the picture was taken. They had
  always been told to: the order that walks them in from the gate was only stopped, and a stop leaves the group's
  march standing. Before, the march's end lay in the stream, so nothing happened. Each man is now sent to where he
  stands.

Picture 32. Still wrong (Claude): the lit ground is one orange (the patches of olive, moss and earth are next), the
stream has no stones or ripples and its bank is a dark line, the camp has no logs, block or smoke, and the trail is a
pale band where the picture has brown earth.
