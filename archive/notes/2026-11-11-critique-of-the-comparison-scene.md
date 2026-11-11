# Comparison scene critique, 2026-11-11

A critical read of `/mnt/project-files/smyana-trees/comparison-scene.jpg` (the 06:14 version): our in-engine frame above, the target mock-up (beech clearing after leaf-fall) below. Written by Claude at Dominic's request. No code was changed. Sizes are measured on the 1600 px wide frames and are rough.

## The short version

Ours reads as a bright orange floor with small colourful trees dotted on it and a camp parked in the shadow at the top. The target reads as a small lit clearing held inside a dark, cool, misty wood. The ground and grass work since the last round has helped, but the three biggest gaps are not about ground detail at all. They are where the light falls, what the trees are, and the overall colour.

Measured over the whole frame: ours averages RGB 107, 72, 34 with saturation 154 out of 255. The target averages 89, 70, 51 with saturation 103. So ours is about half again as saturated and has a third less blue. The top third of ours is a flat 53, 40, 30 brown; the target's top third is a grey 66, 58, 55.

## Ranked differences

### 1. The back of the wood is an empty brown floor (hurts most)

- Ours: the top third is flat dark brown ground with a dozen bare black trunks cut off by the frame. No crowns, no twigs, no depth, no mist. It looks like the map ends.
- Target: the same area is the richest part of the picture. Layer on layer of pale grey trunks, dark twig masses with dull red leaves, a fir or two, and blue-grey mist between the layers. Leaf litter and low green are still visible on the floor in there.
- Fix: plant the back wood three or four rows deep with full-size beeches whose crowns are in frame, not just trunks. Paint each row further back paler and bluer (a mist step per row keyed to distance up the screen). Keep floor detail (litter, low herbs) under the shade instead of letting shade flatten it to one brown. The lower camera will help here only if there is something to see: at 22 degrees more of the back wood is in view, so an empty back will hurt more, not less.

### 2. The camp sits in the shade and the empty ground gets the light

- Ours: tents, fire, the ring of men and all the horses are inside the shadow. The sunlit pool falls on bare leaves and a path in the middle of the frame. The eye goes to nothing.
- Target: the pool of light is the camp. The canvas tent and the striped lean-to are the brightest things in the picture, and the darkness is a frame on all four sides.
- Fix: move the camp down and right into the sun, or open the canopy above it, so the lit clearing and the camp are the same place. Then close the lit area in: dark trees along the bottom and both sides, as in the target. Aim for the fire and the canvas tent near the centre of the frame.

### 3. The trees are the wrong trees

- Size: ours in the foreground are saplings, about 2 to 3 men tall with trunks a few pixels wide. The target's are 4 to 6 men tall with a pale grey trunk a third of a man wide, forking low into heavy limbs.
- Structure: ours are a thin stick skeleton with leaf blobs on the ends. The target's crowns are a dense mass of fine dark twigs, like a bristle, with leaves as a sparse scatter of round dabs inside it. After leaf-fall the twigs are the crown.
- Colour: ours carry pure red, bright yellow and orange, lit full strength. The target has one leaf colour family, burnt orange to dull brown-red, and most of it is in shade. There is no pure red and no bright yellow in any target crown.
- Placement: the target has two big trees standing left and right of the clearing as a frame, plus a dark row along the bottom edge. Ours has a loose row of small trees along the bottom and nothing framing the middle.
- Fix: use the full-size beech for every tree in this frame and drop the sapling look. Add a twig layer to the leaf-fall bake (many fine dark twigs, 1 voxel thick, out to the crown's full outline) and cut the leaf count to roughly a quarter of the twig mass. Pull the leaf palette to burnt orange, rust and dull red only. Put one big beech at the left third and one at the right third of the frame, and let the bottom row be in shade so it reads as a dark silhouette with orange flecks.

### 4. The colour is too orange and the shade is warm

- Ours: lit ground is a single saturated orange, and shade is the same orange turned down to brown. Nothing in the frame is cool except the water.
- Target: lit ground is a mix of orange, straw, tan and olive green, and shade is cool, drifting to blue-grey in the distance. That warm against cool is most of the mood.
- Fix (lighting): tint the shade colour toward blue-grey and lift it slightly, so shade is cooler and a touch lighter instead of darker and browner. Bring the ground's lit saturation down by about a third. Add the mist to the back wood (see 1). Target numbers to steer by: whole-frame saturation near 100, top third near neutral grey.

### 5. The ground is one material

- Ours: one leaf texture, one colour, everywhere, with grass tufts standing on it in thin lines.
- Target: under and between the leaves there is a low green layer (moss, short grass, small herbs) covering perhaps a third of the floor, strongest at the wood's edge and under the trees. Leaves are individual flecks in three or four tones. There are mossy fallen logs, a moss-capped boulder, small bracken clumps turned orange, and bare earth around the fire.
- Fix: add a second ground layer of dull olive green showing through the litter in large soft patches, densest in shade and near the stream. Vary litter tone in big slow patches (orange, tan, brown). Add mossy logs and trampled bare earth round the fire. The two saturated green bushes and the solid orange blob in ours (centre, above the grass) match nothing in the target and should go or be recoloured.

### 6. The grass is there but too thin and too tall

- Ours: pale stalks in single-file rows, each tuft tall and separate, like young maize. Good colour.
- Target: broad dense drifts, low, made of a darker olive base with pale yellow tips dotted on top. The drifts are several men wide, hug the path edges and the stream bank, and thin out to scattered single tufts at their edges.
- Fix: three to four times the density inside a drift, about half the height, with a dark green base under the pale tips. Mass the drifts along both sides of the path and along the bank, and leave the rest of the floor with only stray tufts.

### 7. The stream

- Place: ours runs down the far right edge. The target's comes in at the right, crosses the lower right quarter on a diagonal and leaves at the bottom centre, so it is part of the scene and men stand in it.
- Colour: ours is pale grey-white in sun and near black in shade, where it reads as a tarmac road. The target is a clear mid blue everywhere, with short white dabs for ripples all along it.
- Bank: ours still has a dark outline along the left side, like a drop shadow, which is the sharp edge Dominic complained about in a new form. The target has a narrow, slightly darker earth lip, overhung by grass tufts and bracken, and the lip is uneven.
- Width: ours is about 100 px, the target about 150 px in the foreground.
- Detail: the target has a flat stepping stone and men wading at a ford where the path meets the water.
- Fix: reroute the stream through the lower right of the frame, widen it by half, keep it blue in shade (shade should darken water much less than ground), add ripple dabs, remove the dark contour and instead plant grass and bracken over the edge. Add one or two flat gneiss slabs in the water at the ford.

### 8. Camera angle, scale and depth

- Angle: in ours we look down on the tops of hats and the backs of horses, and the lean-tos read as flat striped rectangles. In the target horses are side-on, tent fronts are visible and trunks are long. The lower angle is the right direction and I would go to 22.
- Scale: our men are about 80 to 100 px tall, the target's 60 px at the fire and 75 px at the front. Ours is zoomed in by roughly a third, so the frame holds less wood. Pull the zoom back so a man at the fire is about 65 px.
- Depth: the target has perspective, so things get smaller toward the back. We cannot do that in an orthographic view, but mist and paler colour by distance (see 1) give most of the same feeling.
- Pixel size: ours is visibly blockier than the target. That is the engine's style and fine, but the shadow edges are much coarser than the art (big stair steps on every tree shadow), and that part looks like an error. Draw the shade at the art's pixel size.

### 9. The camp has no life in it

- Ours: three shelters, a fire with a tripod, and about fourteen men standing to attention in a ring, all facing the camera.
- Target: six men at the fire doing different things (one carries a log on his shoulder, two sit or stand close), plus a seat log, a chopping block with an axe in it, a woodpile, a tool rack with hammers, a crate, stones, a second tripod, and smoke rising from the fire into the trees. More men are spread out: one by the mules, three at the ford, one with a rifle on watch.
- Fix: halve the men at the fire and spread the rest to the mules, the ford and a watch post. Add the props above (the woodpile exists already). Add a smoke column. The two striped lean-tos in ours are larger than the canvas tent and tilted like floating panels; the target has one striped shelter beside one pale canvas tent, both pitched low to the ground.

### 10. Men and animals in shade turn to grey ghosts

- Ours: the men at the fire and the horses have lost their whites and reds and read as grey shapes. The three men standing in the sun look right.
- Target: white shirts and red sashes stay readable everywhere, and the fire lights the men nearest to it warm on one side.
- Fix (lighting): keep the men's own colour in shade and only darken it, and let the fire light the men round it. Moving the camp into the light (see 2) removes most of this problem.
- The target also has a line of mounted riders in blue, white and red at the edge of the wood, and mules with packs. Ours has loose dark horses with no riders or readable loads. Dominic should say whether the riders belong in this scene.

### 11. The path

- Ours: a straight, pale, hard-edged horizontal band, like a pavement.
- Target: a winding strip of brown earth from the fire down to the ford and on past the far tree, soft at the edges with grass growing into it.
- Fix: curve it from the fire to the ford, darken it to earth brown, break the edge with grass and leaf scatter.

### 12. Rock

- Neither frame shows much, but the target has stones by the tent, a stepping stone and a mossy boulder. Ours has none. A few flat gneiss slabs at the bank and by the camp would add detail and bring in the stone the houses are built from.

### 13. The fire

- Ours: a large flat disc of strong yellow on the ground.
- Target: a small white-hot core, an orange glow perhaps a man wide, and smoke.
- Fix: shrink the glow to about half the radius, make it more orange than yellow, add smoke.

## Who does what

- Trees and ground thread: 1 (planting), 2 (moving the camp), 3, 5, 6, 7, 9, 11, 12, plus the zoom and angle in 8.
- Lighting thread: 1 (mist by distance), 2 (where the light falls), 4, 10, 13, plus shadow edge size in 8 and water in shade in 7.

## Suggested order

Do 2, 1 and 3 first, in that order, with the 22 degree camera. Those three change the picture from "orange floor" to "clearing in a wood". Then 4. Everything after that is detail that will only show once those are right.
