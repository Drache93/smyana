# 2026-11-10: Rhodope trees, ground and rock

## What happened

Dominic looked at the first runnable version and said the trees were a crazy size and had to
keep to the designs. He then asked for the right trees, ground and rocks for the region (the
rock matters because it's what the houses are built from), pointed out that the mock-ups have
some places with normal RTS-sized trees and others where the trees fade off to the sky, gave a
list of the Rhodopes' trees, and said autumn's reds, oranges and yellows are a huge part of the
mood and should probably be the game's poster
([his words](../notes/2026-11-10-dominic-in-his-own-words.md#the-trees-the-ground-and-the-rock)).

He was right about the size. Claude had built every old tree about thirteen men tall with a
trunk three men wide, which is the first under-the-canopy mock-up Dominic had already turned
down, not the route frames he liked. Measured against the route frames (pictures 19 to 23), an
old tree is five or six men tall with a trunk about a man wide.

What changed, all still stand-ins built in code until the real art (#6):

- **Size.** Old broadleaves are now five to six men tall, young trees two to three. The camera
  starts closer, so the men are about the size they are in the route frames.
- **Size is set per place** (D-029). A map says what kind of wood it is. The beech valley is
  "beech": whole trees at RTS size. The fir woods are "deep": dark bare spruce and fir trunks
  that run up and fade out before their tops, with only their shade on the ground, and whole
  broadleaves and young firs beneath them as understorey.
- **Kinds** (D-030), from Dominic's list: beech (smooth silver trunk), oak (short thick dark
  trunk, wide crown), hornbeam (smaller, dense), Scots pine (tall bare trunk, flat top), spruce
  and fir (dark spires). Ash, plane, alder, willow, maple, lime, wild pear, elm, black pine and
  dwarf pine are not made yet.
- **Autumn** (D-031). Each broadleaf turns its own colour, and each tree of a kind a little
  differently: beech orange, gold or red, oak russet, hornbeam gold. The young trees turn too.
  In autumn the fallen leaves spread much further over the ground and the ground textures
  switch to a brighter litter. Conifers stay dark, which sets the colours off.
- **Rock** (D-032). Rock cells now carry an outcrop: thick flat beds stacked in steps, warm
  grey, with Creel's lichen and moss on them. Loose slabs lie beside outcrops. These don't do
  anything in the game yet.
- **Ground.** Four ground atlases instead of one: beech wood and conifer wood, each with an
  autumn version. The conifer floor is dark needles, moss and bilberry. Leaf litter is laid in
  ragged patches under each tree, not rings.

## Decisions

- D-029: A place says how big its trees are: whole trees, or trunks fading to the sky.
- D-030: The tree kinds come from Dominic's list of the Rhodopes' trees.
- D-031: Autumn is the game's poster season.
- D-032: The rock is gneiss in flat slabs, as outcrops and loose building stone.
- D-033: Dominic confirms gneiss, used with wood for roofs and walls.
- D-034: The look comes first, and the archive's pictures are the target.
- D-035: Trees are designed in 2D from real photos first, then made as vox.

## Direction changes

- The first version's giant trees everywhere are gone (D-028 said old trees are giants whose
  crowns fade over the men; the fading stays, the giant size doesn't. See D-029).

## Pictures

![The trees at the mock-ups' size: beech and a Scots pine](../images/2026-11-10/38-trees-at-the-mock-ups-size.png)

![The beech valley in autumn](../images/2026-11-10/39-beech-valley-autumn.png)

![The deep fir woods: trunks fading to the sky, autumn understorey](../images/2026-11-10/40-deep-fir-woods-trunks-to-the-sky.png)

![A gneiss outcrop in the beech valley](../images/2026-11-10/41-gneiss-outcrop.png)

For the size it replaced, see [picture 33](../images/2026-11-10/33-beech-valley-summer.png).

## Funny moments and bugs

- The first Scots pine had bark so orange it looked like a carrot with a hat.
- The first rock outcrops were grey lumps with dark green cones on them: the ledges were too
  fine to see and Creel's moss covered the rest. Rebuilt as a few thick plates.
- With the trees at the right size the edge of the map shows as a grey void. The giants had
  been hiding it.

## Known limits

- Gneiss is Claude's reading of the region's building stone. Dominic to confirm the rock and
  its colour.
- The crowns are still rounded lumps. A beech's flat layers don't read yet (#6).
- The deep woods are too bright and too thin next to the mock-up: they need the lighting work
  (Casaide/creel#5, #12), ferns and undergrowth (#8) and mist (#15).
- The edge of a map needs a wall of forest or a camera limit (#5).
- The autumn leg is the fir woods, where most trees are evergreen. Whether the route should put
  a broadleaf place in autumn is for #5.

## Later the same evening: the look comes first

Dominic asked whether the open issues were being checked and updated (they hadn't been: Claude
then posted where #4, #6, #7 and #11 stand) and said he wants the look first, so the archive's
pictures can be made in the engine with our men. Claude first took the pictures as a guide to
size and layout only, which was wrong: Dominic said the style being built doesn't match the
design, and the pictures are the target (D-034). He confirmed gneiss (D-033).

A second pass the same evening got closer in layout but not in style: broadleaves rebuilt as
branches with clusters of leaves, bracken, bushes and fallen logs (#8), an autumn leaf carpet
over the whole floor of a broadleaf wood, deeper shade under the crowns, a warm autumn mood,
and a rim of thick forest round each place with the camera kept inside it, so the map's edge
never shows. It still reads as flat poster shapes next to the picture. Dominic's answer: design
the trees in 2D from real photos first, then make the vox (D-035).

![The second pass: leaf carpet, clusters, undergrowth. Still not the style](../images/2026-11-10/42-autumn-second-pass.png)

The first design sheet, for beech, drawn by `tools/tree_design.py`. It was drawn from what
Claude knows of the tree, not from photos: the session's network couldn't reach any, so it
still needs checking against real pictures before the vox is made.

![Beech design sheet: sizes beside a man, and the year](../images/2026-11-10/43-beech-design-sheet.png)

Dominic's answer to the sheet: "Looks good!" So the beech was made as vox from it
(`tools/tree_vox.py` writes `art/trees/vox/beech_*.vox`: a sapling, two young, two mature, two
old). The palette index says what each voxel is (bark, or a leaf lit from above, mid, or
beneath), and the game bakes the wood and the leaves as separate pictures, so the leaves take
the season's colour and still fade over a man. The first try filled the crown solid, and from
the game's camera the layers vanished into one lump; thinner sprays with air between them
brought them back.

![The vox beech in autumn, with the men](../images/2026-11-10/44-vox-beech-autumn.png)

![The same place in summer](../images/2026-11-10/45-vox-beech-summer.png)

Still to do on beech: the crown hides most of the branches, the light on it is flatter than the
target pictures, and the oak, hornbeam, pine and spruce are still the old stand-ins.

## The spruce's design sheet (Claude, for Dominic's check)

The second sheet, made the same way as the beech's (`python3 tools/tree_design.py spruce`). It
sets the spruce at about eight men tall, taller and much narrower than the beech, and shows the
two forms it takes: green to the ground in the open, and a bare bole with dead stubs in a stand,
which is the deep-wood tree. It doesn't change through the year except for bright tips in spring
and snow in winter. Drawn from what is known of the tree, not yet checked against photos. No vox
is made from it until Dominic has looked.

![The spruce design sheet](../images/2026-11-10/46-spruce-design-sheet.png)

## The beech rebuilt against the target (Dominic's correction)

Dominic, of the first vox beech and the spruce sheet: "Those are still much bigger than mockup and you've gone for
very soft style. Again, what are you testing there?" and "Your 2D design was much closer to our original mockup, but
you implemented it soft and cloudy. Why?" He was right. Claude had tested that sheet to vox to game worked, not the look
beside the mock-up. Three causes of the softness: leaves scattered as single voxels, each voxel only a pixel or two of
dithered shade, and the baker's light reaching 64 voxels where it should reach a few (the grid's unit was a whole
tile), which flattened every tree to one tone. And the size was wrong by half again (D-036).

Rebuilt: sizes in men, a slim silver bole, boughs, branches and twigs, leaves as dabs in clusters, baked nearly twice
as fine on sheets of their own, with the grid's unit small so the baker's light and shade work within the tree. The
camera is closer, so a man is the size he is in the mock-ups. Until the other kinds have models, the beech valley is
all beech.

![The target, and the game now](../images/2026-11-10/47-beech-beside-the-target.png)

![The men by the rebuilt beeches](../images/2026-11-10/48-beech-rebuilt-with-the-men.png)

Still short of the target: the woods are too thin now the trees are the right size, the bark and twigs are too pale,
the undergrowth is still the coarse grey-box, and the light, shade and haze (their own thread).

Later the same evening: the beech wood made closer (old trees under two tiles apart, young clumps placed first so
there are still trees to fell), the bark darkened, bare twiglets added, and the undergrowth (#8) rebuilt as fine as the
trees: ferns as ribs with leaflets, bushes as stems with leaf dabs, and pale patches of low herbs like those in the
target's clearing.

![A closer wood, darker bark](../images/2026-11-10/49-closer-beech-wood-darker-bark.png)

![Fine ferns and herb patches](../images/2026-11-10/50-fine-ferns-and-herb-patches.png)

The flat light turned out to be every model's fault, not only the vox trees': each grid is built in tiles, and the
baker's light reaches a few of the grid's units, so it reached across the whole tree. Now every grid's unit is made a
sixteenth of a tile just before it is drawn (`LIGHT_UNITS`), and logs, the stump, the rocks, the deep-wood trunks and
the young spruces are built as fine as the vox trees. The deep fir woods have slim dark trunks with dead snags, a
quarter to a third of a man wide as in their mock-up, and stand closer.

![The deep fir woods](../images/2026-11-10/51-deep-fir-woods-slim-dark-trunks.png)

Summer in the same style: the crowns fuller (more leaves round each twig's end, which fall in autumn), and the crown's
fade over the men (#7) set to the new, smaller beech.

![Summer](../images/2026-11-10/52-beech-wood-summer-new-style.png)

![Autumn](../images/2026-11-10/53-beech-wood-autumn-new-style.png)

Dominic: "Skip 2D" (D-039). Oak, hornbeam, pine and spruce made straight as models with the same tool: the oak
stout and wide, keeping most of its russet leaves; the hornbeam small and narrow; the pine a bare bole with a high
crown; the spruce a spire of drooping whorls. The old stand-in trees built in code are gone.

![Beech, oak, hornbeam and pine together](../images/2026-11-10/54-mixed-wood-beech-oak-hornbeam-pine.png)

![The fir woods with a whole spruce](../images/2026-11-10/55-fir-woods-with-whole-spruce.png)

The autumn ground is no longer all orange: the leaf carpet lies in drifts, with grass, herbs and bare earth showing
between them in the open (the lighting work found that the target's ground is mixed, and that is what its light needs).

![Autumn ground in drifts](../images/2026-11-10/69-autumn-ground-not-all-orange.png)

Winter (#11): a first-snow ground (`tools/ground_atlas.py`, `atlas_winter.png`): thin blue-white snow in the open with
grass tips through it, the fallen leaves showing under the trees, slush on the trail, and the bare trees' long shadows
across it. No snow lies on the boughs or the men yet.

![First snow in the beech wood](../images/2026-11-10/70-first-snow-in-the-beech-wood.png)

The stream and the trail narrowed from two tiles to one, and trees set close round each clearing. A tile is still
about three men across, so the stream is about twice as wide as the target's: the ground is drawn tile by tile, and
going narrower needs either a smaller tile or a ground that can draw a strip inside one. Not decided.

![The stream and trail, one tile wide](../images/2026-11-10/71-narrower-stream-and-trail.png)

A first landslide (#20): in the deep fir woods the trail is buried under fallen gneiss with broken trunks and loose
slabs in it (`slide` in `tools/make_places.py`), found after it has happened. The men have to walk round it. It is
only a look and a blocked way so far: nothing to clear or climb, and it is the same on the way home.

![The landslide across the trail](../images/2026-11-10/72-landslide-across-the-fir-woods-trail.png)

Dominic, in the lighting thread: "Should be harder edged too. Biggest difference with the design is evryhting crisp
and sharp. Our new stuff is looking soft so far, engine issue?" One cause was in the trees: they were baked at 112
voxels a tile and stretched to the screen, while the men are one voxel to one pixel of Creel's art (135.76 a tile). Now
every tree, rock and plant is baked at the men's fineness. A .vox model can't be more than 256 voxels a side, so the
big trees are saved in pieces (`<name>.cXYZ.vox`). The baker's per-voxel dither and the screen's haze are being looked
at in the lighting thread.

![Trees at the men's fineness](../images/2026-11-10/74-trees-at-the-mens-fineness.png)
