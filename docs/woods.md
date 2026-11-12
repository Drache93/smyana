# The woods: dense, natural, Rhodope

*Claude's plan, 2026-11-12, written before building, for Dominic to change. Everything here is a **Proposal** until he
agrees it. It answers his notes of the day (`archive/notes/2026-11-12-dominic-forest-density-and-ferns.md`): a
Bulgarian looking at the Roman ruins said the woods are too sparse, the dry ground too dry, the ferns read as little
palms and are the wrong kind in the wrong places, and the plants are dotted about; the range picture "looks like a
little path through Africa". "It should feel dense and rich and alive."*

## What is wrong now (looked at again: the ruins in autumn, the range, the beech valley)

1. **Too few trees, scattered one by one.** The maps are drawn by hand, a `T` here and there: about one tile in seven
   is a tree, each alone, evenly sprinkled. No real wood grows like that. With the open ground between them it reads
   as savanna.
2. **The tree shapes say "acacia".** Our broadleaves are a bare trunk with a flat, spreading crown on top. Seen from
   above, over open ground, that is the African thorn tree's outline.
3. **The ground is dry and yellow.** The open ground between trees is tan and orange, the grass pale straw, and the
   trail a yellow sand stripe. In the photos (summer and autumn alike), anything open is green, and a path is dark
   earth with grass up its middle.
4. **The ferns are palm trees.** Our fern is a stem of fronds radiating out from one point above the ground. That is
   the shape of a palm. They stand alone, one per tile, on dry open ground, where no fern grows.

## What the Rhodope woods are like

From Dominic's photos and the sources (Wikipedia's *Rodope montane mixed forests* and *Rhodope Mountains*, the
Bulgarian beech forest survey of Tzonev et al. 2006, the Crossbill guide):

- **The western Rhodopes are among the most wooded mountains in Europe**, with "the largest coniferous woods in the
  Balkans". Seen from a height, the hills are covered unbroken, a dark green fur. Clearings are the exception: hay
  meadows and pastures cut out round villages and in valley floors.
- **Zones by height.** Lower down there are oak and hornbeam, with beech on the shaded slopes. Around 1000 to 1400 m,
  beech is mixed with silver fir. Higher up there is Norway spruce, with Scots pine on the dry and rocky ground.
  Plane, alder and willow grow along the rivers.
- **A closed wood is closed above, not below.** In an old beech or beech-fir wood, the crowns meet overhead; underneath
  are tall straight grey trunks and the brown floor of last year's leaves. The herb layer is thin and patchy in deep
  shade, and rich where light gets in.
- **The ferns** are mostly the male fern (*Dryopteris filix-mas*), the lady fern (*Athyrium filix-femina*) and the
  soft shield fern (*Polystichum setiferum*), in the beech-fir woods. Common polypody (*Polypodium vulgare*) grows on
  rocks and mossy boulders. Bracken (*Pteridium*) covers the clearings and the edges on poorer ground and turns
  orange-brown in autumn. A male fern is a **shuttlecock**: a ring of fronds rising from one crown at the ground,
  arching outward, each frond a long narrow blade that tapers at both ends. It has no stem. Bracken is a **sea** of
  flat, triangular fronds on single stalks, knee to waist high, rather than separate plants. Ferns grow where it is
  shady and damp: on north slopes, by streams, at the foot of rocks and under the fir.
- **Edges.** Where a wood meets a meadow there is a belt of young trees and shrubs (hazel, hawthorn, blackthorn,
  dog rose, bramble) before the grass. Trees in the open stand in loose groups and hedgerows along the old terraces,
  not as single trees on a grid.
- **Trees grow in clumps and families.** Young trees come up in the gaps where an old one fell. Spruce stands in dense
  groups of all ages. Alders and willows follow the water in a line.
- **Low cloud.** Cloud lies on the slopes and lifts off a wood in plumes (Dominic's photo).

## What to change

### 1. Woods grown by rules, not dotted by hand (the biggest change)

The maps keep their hand-drawn shape: rock, water, the trail, and where the clearings are. But instead of a `T` for
each tree, a map paints **stands**: closed wood, open wood, wood edge, meadow, streamside, scree. The game grows each
one when the map loads, by rules:

- **Closed wood:** most tiles have a tree, in clumps (a noise field decides where it is thickest). There are small
  gaps where an old tree came down: a log, saplings and brambles in the light. Under it are the leaf floor, a few
  ferns in the damp and moss on the stones.
- **Open wood:** half as many trees, in groups of two to five, with grass and bracken between.
- **Edge:** a belt one to three tiles deep of young trees, hazel, hawthorn and bramble between a wood and a meadow,
  following the line where they meet.
- **Meadow:** lush grass, flowers in drifts, and the odd lone tree or group of trees, mostly near the edges.
- **Streamside:** alders and willows in a line along the water, with ferns and tall herbs on the bank.

The men still have to walk through a closed wood. A tree only blocks its own trunk's tile. The crowns spread over
the tiles round it, so the wood is **closed overhead and open at the men's height**, as a real beech wood is. The
crowns over the men already thin out so they can be seen. Thickets (young spruce, a windfall) are where a closed
wood can't be walked through, and they shape the ways through it.

**Beyond the edge of play** is more wood: the map's rim is packed with crowns, so a place is a clearing in a forest
and not an island.

Numbers per stand (how thick, how clumped, how many of each kind) go in `data/woods.json`, by place and wood kind,
so they can be tuned by eye. The current maps are converted: their trees mark where the wood is, and the generator
grows it out.

Risk: two to four times as many trees on screen. The frame rate has to be watched (the crowns are the costly
sprites). If needed, the rim and the deep wood can be drawn as massed crowns baked into one picture.

### 2. Tree shapes

- **Beech in a closed wood:** a tall straight grey trunk, with a high crown that is domed and full, not flat. **In
  the open:** a broad dome reaching low.
- **Oak:** a wider, lumpier crown in clusters, with a shorter trunk and big low limbs.
- **Spruce and fir:** many more of them, in the fir woods and mixed into the beech higher up. They are narrow,
  dark, dense cones of all ages and heights. Spruce wood should read as dark fur from above.
- Every crown is fuller and rounder at its edge, with no umbrella silhouettes.

### 3. Ground and trail

- **Open ground is green** in summer and spring, and green going gold in autumn, not tan and orange. The leaf floor
  stays brown only under closed wood, where it belongs.
- **The trail** is dark brown earth and stones, with grass up its middle and along its sides. It must not be a sand
  stripe.
- The pale straw tufts become fresh green grass in summer, going gold late in the year.

### 4. Ferns and the undergrowth

- **Male fern:** a new shuttlecock model (fronds rising from the ground and arching out, tapering blades, no stem).
  It grows in groups of three to ten, only in shade and damp: under closed wood, by streams, at the foot of rocks
  and logs.
- **Bracken:** a low, continuous layer of flat fronds over whole patches of clearings and edges, rather than
  separate plants. It turns orange-brown in autumn, a strong autumn colour.
- **Polypody** on rocks and mossy stones.
- The current fern model is retired. (Dominic, of the bridge scene: "all these little ferns everywhere that just look
  really out of place".)
- Undergrowth in general follows the light: rich at edges and in gaps, thin in deep shade, lush by water.

### 5. Low cloud on the mountains

Cloud lying on the hillsides and lifting off the wood in slow plumes, at dawn, after rain, and in autumn. This builds on
Creel's low fog (D-084), but sits on the slopes and drifts up rather than only filling the valley floor. It comes after
the woods themselves.

## Order of building

1. The stand generator, the edge belts and the dense rim, on one place first (the beech valley). Then picture it
   against Dominic's photos, check the frame rate, and convert the other places.
2. The ground and trail colours (a quick win, done alongside 1).
3. The tree shapes.
4. The ferns, bracken and undergrowth.
5. Low cloud.

Each step is pictured against the reference photos before the next one starts.
