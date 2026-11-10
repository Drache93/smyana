# Decision log

Append-only. Each entry: date, decision, who, why, and what it replaced. To change a decision,
add a new entry that supersedes the old one rather than editing it.

---

**D-001, 2026-11-10: Make an atmospheric survival game about villagers working away from home through the seasons.** (Dominic)
About twenty men from a village in 1800s Bulgaria travel out through the forest into the
mountains, gather resources, skills and knowledge, and race the seasons to bring them home.
Why: the competition theme is "Shift", and the shifting seasons are both the art and the main
mechanic. Source: the voice memos ([transcripts](notes/2026-11-10-voice-memo-transcripts.md)).

**D-002, 2026-11-10: Build it on Creel, the Age of Anything engine, with the same camera.** (Dominic)
Expanded and adapted, not a new engine. The trees are much bigger, so the men move between and
under them.

**D-003, 2026-11-10: Extend the engine in parallel with the game, and record engine work in this archive.** (Dominic)
Why: the game will keep needing things the engine doesn't do yet, starting with the lighting
moods. Engine entries go in [`engine/`](engine/).

**D-004, 2026-11-10: It's a demo: one run from summer to spring, in real time.** (Dominic)
Pause is worth trying. Several years in one game is for a later version.

**D-005, 2026-11-10: The focus is the men's hardship for the families at home, not growing a village.** (Dominic)
The village is only seen when they leave and when they come home. The homecoming is the big
emotional moment.

**D-006, 2026-11-10: The story is inspired by the builders of Kovachevitsa, in a fictional village.** (Dominic)
About 200 men with hammers and swallow-tailed rifles left Kovachevitsa for seasonal work and
came back with new skills, like building Roman drains. We use the story, not the name.

**D-007, 2026-11-10: The threats are the season, wolves, bears and the Ottomans.** (Dominic)
The men fight Ottoman patrols the way they fight bears: as a danger in the forest. Replaced:
bandits as a main threat (from the memos).

**D-008, 2026-11-10: A survival RPG built as an RTS, with no work sites or jobs.** (Dominic)
The game is travel through the forest: gathering, cutting, sleeping, fighting, surviving, and
coming across places like Roman ruins where the men learn something. Why: "jobs" felt dull.
Replaced: Claude's first design, which had the men working at sites.

**D-009, 2026-11-10: Fire is needed to feed the men, and it draws danger.** (Dominic)
Every night is a choice between eating and being found.

**D-010, 2026-11-10: Needs, crafts, undergrowth and the homecoming go in.** (Proposed by Claude, approved by Dominic)
Needs: hunger, warmth, rest. Crafts: men get better at what they do and learn techniques from
what they find. Undergrowth: low cover that lasts longer than the canopy.

**D-011, 2026-11-10: What the men learn is shown in a closing cutscene of the village, upgraded.** (Dominic)
After the homecoming. Each piece of knowledge brought home shows up as a visible change.

**D-012, 2026-11-10: The trees are Rhodope species, and the camera sits under the canopy.** (Dominic, from Claude's suggestion)
Beech, Scots and black pine, fir and spruce. The camera keeps Creel's angle but the canopy only
shows as a fringe and dappled light, so you can see the men. The forest mixes a few old giants
with young trees and saplings the men can actually fell, lots of undergrowth, and slightly
bigger men. Why: the first under-canopy mock-up had trunks far too wide to cut down.

**D-013, 2026-11-10: Deep woods are one mood among several, not the whole map.** (Claude's suggestion, Dominic: "let's try it out")
The route runs through beech clearings, deep fir, high ridges and gorges with ruins, and the
seasons change the same woods. Why: Dominic worried a whole game in deep forest would get
samey, while still wanting the feeling of deep woods.

**D-014, 2026-11-10: The title is Смяна (Smyana).** (Dominic)
Bulgarian for "shift": the change of the seasons, and a shift of work. Written "Smyana" in Latin
letters for the repo and the competition submission; the Cyrillic Смяна can go on the game's
imagery. Replaced: the working title "Shift". Also considered: Гурбет (Gurbet, the word for
going away for seasonal work), Листопад (Listopad), Преход (Prehod), Кръговрат (Kragovrat).
Dominic wanted a word for "shift" rather than gurbet.

**D-015, 2026-11-10: Keep the work in a public repo with an archive, the same way as Age of Anything.** (Dominic)

**D-016, 2026-11-10: Aim for a game of about an hour.** (Dominic)
Why: enough to cover the journey, the Roman ruins and the Ottomans in the pass properly.

**D-017, 2026-11-10: Keep every voice note and message from Dominic in the archive, in his own words.** (Dominic)
Why: so much of the game is made with AI that it matters to show where the direction, feel and
mood come from: the human behind it. Audio goes in `audio/`, text in `notes/`, and summaries
sit alongside, never instead. See [the statement in the archive README](README.md#why-this-archive-matters).

**D-018, 2026-11-10: Almost all of Smyana's art is made new in November.** (Dominic)
The trees, the forest and the foliage are all replaced, and very little art, if any, comes from
Age of Anything. The engine work (the lighting moods first) has already started. The Bulgarian
man was the first art test made for Smyana, even if Age of Anything may reuse him.

**D-019, 2026-11-10: The men get looks mixed at random, and carry the swallow-tail rifle and masons' hammers.** (Dominic)
Hats and cloaks change from man to man. The rifles have the traditional swallow-tail butt,
which matters most. The particular hats, coats, cloaks and tools (in [`art/men/`](../art/men/README.md))
are Claude's first pass and still need Dominic's sign-off.

**D-020, 2026-11-10: Each place on the route is its own map, loaded whole.** (Proposed by Claude, approved by Dominic)
No single giant map and no streaming in chunks. A place loads when the men reach it, behind the
letter home read between places, and is swapped at its edge. The men, their loads, the carts and
the season clock carry across, and each place remembers what was done to it for the way home.
Why: the one-hour run is already a chain of places, each used twice, and Creel keeps a map as
full-size grids (terrain, walking, fog, whole-map flow fields, ground textures, generated save
code), so streaming would mean rewriting most of the sim. See issue #4.

**D-021, 2026-11-10: The UI is extremely minimal, if not none.** (Dominic)
So the focus is on the environment. Where we can, the world shows the state of things instead
of meters and panels.

**D-022, 2026-11-10: The Steam Deck is set aside for now.** (Dominic)
No Steam Deck testing or budgets in the plans until Dominic brings it back.

**D-023, 2026-11-10: Fixing a bridge, fording a river and a landslide are among the environmental obstacles.** (Dominic)
For now the landslide is found after it has happened, not a live event. See issue #20.
**D-024, 2026-11-10: Smyana is its own program on Creel, with Creel as a pinned submodule.** (Claude)
Creel sits in `creel/` at a fixed commit, and Smyana has its own main program, data pack and
reset code beside it. What Creel lacks is worked around in the game first and noted in
`archive/engine/`, then moved into Creel by its own issue there. For Dominic to confirm.

**D-025, 2026-11-10: The route is a file of legs, and the men leave a place together.** (Claude)
`data/route.json` lists each leg: the place, the season, the edge the men walk in by and where
each exit leads. A place is left when every living man stands in an exit gate, and a gate only
counts once the men have walked clear of it after arriving. The letter home shows while the
next place loads (D-020). Nobody is left behind by accident; whether a man can be left behind
on purpose is open.

**D-026, 2026-11-10: What the run carries and what a place remembers, for now.** (Claude)
Carried: who is alive, each man's health and load, the hour, the day and the season. A place
remembers its ground: stumps, wood left in a part-cut tree, wear. Needs, skills, carts, caches
and dead animals join as those systems are made.

**D-027, 2026-11-10: A place is at most 128 by 96 cells and 700 old trees.** (Claude, Proposal)
The check fails a place over this budget. The two grey boxes are 96 by 64 with 171 and 261 old
trees, and load in about 3 seconds at worst. The numbers are a first guess until the frame rate
is measured on a real graphics card (#18).

**D-028, 2026-11-10: Old trees can't be felled, young ones can, and crowns fade over the men.** (Claude)
The giants are scenery and cover: a small trunk that blocks, a wide crown that doesn't, drawn
faint wherever a man stands beneath it (a first answer to #7). Young trees are the wood: one
felled tree is one man's load and leaves a stump. For Dominic to confirm.

**D-029, 2026-11-10: A place says how big its trees are.** (Dominic; Claude worked out how)
The mock-ups have places with normal RTS-sized trees and places where the trees fade off to the
sky. So each map names its wood: whole trees about five or six men tall, or a deep wood whose
trunks run up out of sight with only understorey at full height. This supersedes the giant
size in D-028; crowns still fade over the men. Old trees still can't be felled.

**D-030, 2026-11-10: The tree kinds come from Dominic's list of the Rhodopes' trees.** (Dominic)
Conifers of the high woods: Norway spruce, Scots and black pine, silver fir, dwarf mountain
pine on the summits. Broadleaves of the valleys: oaks, beech, hornbeam, ash, and by the rivers
plane, alder and willow, with maple, lime, wild pear and elm. The full list is in his words in
the notes. Made so far: beech, oak, hornbeam, Scots pine, spruce and fir.

**D-031, 2026-11-10: Autumn is the game's poster season.** (Dominic)
"Autumn the red, oranges and yellows are Soooo rich. Huge part of the games mood." Autumn gets
the richest colour in the leaves and on the ground, and is what the game is shown with.

**D-032, 2026-11-10: The rock is the region's building stone, shown as flat slabs.** (Dominic: the rocks are key to house building; Claude: gneiss, Proposal)
Outcrops stand as stacked flat beds, and loose slabs lie beside them, because this is the stone
the walls and roofs at home are made of. That it is warm grey gneiss is Claude's reading and
needs Dominic's check.

**D-033, 2026-11-10: The rock is gneiss, used with wood for roofs and walls.** (Dominic)
Confirms the Proposal in D-032.

**D-034, 2026-11-10: The look comes first, and the archive's pictures are the target.** (Dominic)
The route pictures are the design to match, in style as well as layout. What's in the engine so
far is a grey-box stand-in. Work on the look until those pictures can be made in the engine with
our men, before more systems.

**D-035, 2026-11-10: Trees are designed in 2D from real photos first, then made as vox.** (Dominic)
The same order as the men: a design sheet, his sign-off, then the voxel model.

**D-036, 2026-11-10: Trees are sized in men from the mock-ups, and every frame is checked beside the target before it is shown.** (Dominic's correction, Claude's rule)
Dominic: "Those are still much bigger than mockup and you've gone for very soft style." Measured against the beech
clearing mock-up, an old tree is about six men tall with a trunk a quarter to a third of a man wide; the first vox
beech was about nine men tall with a trunk wider than a man is tall, because it was sized in metres with the wrong man.
The vox tool now takes its sizes in men (a man stands 40 voxels at 112 voxels a tile). The beech is a slim bole,
boughs, branches and twigs that show, and leaves as dabs in clusters at the twigs' ends; after leaf-fall the old trees
keep only some clusters. The target is picture 23 (Dominic: "This is our target", with the caveat that it is also a
mock-up, "just closest we have to rich and deep environment that draws a player in"). Engine changes are allowed where
the engine limits the look (Dominic). Lighting and mood are worked in their own thread.

**D-037, 2026-11-10: The light is a low afternoon sun, and its shadows join into one deep shade.** (Dominic: picture 23 is the target; Claude: how, Proposal)
The art is baked under a sun 26 degrees up, so everything casts long shadows the same way. The
shadows are drawn into one shade that whatever stands in it shares, and the lit ground takes a
warm sun colour; places with a lot of shade round them go darker and greyer, so a lit clearing
stands out of dark woods. Rays run through the gaps and mist lies in the shade. All of it is in
`data/atmosphere.json`, per mood.

**D-038, 2026-11-10: The campfire is only for a look until fire is part of the game.** (Claude)
`camp:<x>,<y>` puts the men round a fire to check its light. Fire as a system (feeding the men,
drawing danger) is still to come and will use the same fire and glow.

**D-039, 2026-11-10: No 2D sheet before a tree's model any more.** (Dominic: "Skip 2D")
Supersedes the sheet-first step of D-035. The beech's sheet showed the design held; the fault was in the model. The
other kinds go straight to models, each checked beside the mock-ups (D-036) before it is shown.

**D-040, 2026-11-10: Shadows are a normal, soft shade, not long dark ones.** (Dominic)
"Design the shadows at much less dark. Normal show shade basically." Supersedes D-037's low sun
and deep shade: the sun stands at 40 degrees and the shade is a light multiply in every mood.
The shadows still join into one shade where they overlap.

**D-041, 2026-11-10: Everything crisp and sharp.** (Dominic)
"Biggest difference with the design is evryhting crisp and sharp." Shadows have hard pixel
edges; the rays, mist in the shade and darker-woods layers are off (they smudged); haze and bloom
are light; the voxel baker's per-voxel light jitter is turned down and leaves get four hard bands.
D-040's "soft" meant light, not blurred.

**D-036, 2026-11-10: The music follows the game.** (Dominic)
It changes with season and time of day. When a battle or a danger comes it changes to match,
tenser or faster, and when it's over it ends as fast as it began. A fight with bandits or
Ottomans, or hiding the men and carts, each has its pace carried by the music. How (states,
an intensity dial, separate loops) is a proposal in `docs/music-and-sound.md`.

**D-042, 2026-11-10: The game swaps whole music tracks.** (Dominic)
Calm music plays, then a sudden swap to fight music, and back again. One recording does not
blend from one mood into another. This sets aside the layered "intensity dial" Claude proposed
under D-036 unless swapping proves too blunt. A proposed list of 24 tracks is in
`docs/music-tracks.md`.

**D-043, 2026-11-10: A landslide is small and blocks a tight pass.** (Dominic)
"I think better if landslides are smaller and more focuses. Like on a pass above a cliff face, so we o ly have a very
tight space to go, and its blocked." The fir woods' slide lies across a ledge between a crag and a ravine, using Creel's
high ground for the first time (Claude: how). Until the men can clear a slide, one tile of the ledge's lip stays open.
