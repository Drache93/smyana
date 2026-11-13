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

**D-044, 2026-11-10: Our Lobster is formatted and warning-free.** (Dominic)
For quality and fewer bugs, every Lobster file of ours is in `lobsterfmt`'s layout (Lobster's style guide) and compiles
with no warnings, as in Age of Anything. `src/lint.sh` checks both and `./check.sh` runs it, before every commit.

**D-045, 2026-11-10: The camp's props keep their own colours, at the mock-up's sizes.** (Claude, awaiting Dominic)
The tents, fireplace, woodpile, horses and mules are `.vox` models one voxel a pixel, like the men, baked with their
palette's colours under the props' light rather than Creel's per-material ramps (a rug's stripes and a horse's coat
need real colours). Sizes are taken from the camp mock-up, a little bigger than real ponies and tents.

**D-046, 2026-11-10: A closed wood is in shade, and a clearing is the lit room in it.** (Dominic's
direction, Claude's how) Dominic: "Our pic still looks like big bright omni light on everything." The
ground under a closed canopy lies in shade, and it goes darker and misty there, while clearings and
open woods keep the sun. This is crisp, pixel for pixel, as D-041 asks. It replaces the blurred
darker-woods ring that D-041 switched off.

**D-047, 2026-11-11: The light turns through the day, each season has its own, and the men stay readable.**
(Dominic's direction to keep going, Claude's how) Moods blend into each other over 1.5 hours rather than
switching. Summer, spring and winter get their own day light, matched to the mock-ups. The men are kept
readable by the light itself, not by UI markers (as #7 asks): a little less shade, mist and dark on
them, stronger at dusk and night.

**D-048, 2026-11-11: A landslide is dug away like a tree is felled.** (Claude's how, to Dominic's obstacle in #20:
"to be cleared, climbed or walked round") A heap of the slide is ground the men can work: order them onto it and they
dig, eight spells of work a heap, and it is left as bare ground they can walk. What they dig they throw aside: nobody
is loaded with it, and it is worth nothing. It costs only time, against squeezing by the lip one man at a time. It is
data (the `rubble` ground carries a resource, `spoil`), so the same works for any heap on any place.

**D-049, 2026-11-11: A broken bridge is mended with the wood on the men's backs.** (Claude's how, to Dominic's
obstacle in #20: "The men can repair it with wood they've cut (slow, and it costs wood), or go another way.") Mending
costs eight wood, two full loads, and it is taken off the loads of the men sent to mend it: no store, no pile, in
keeping with "carrying is people". With too little wood between them nothing happens. Two men take about twenty
seconds; more are quicker. The other way is a ford a way downstream, reached by a side path from each bank. A place
remembers whether its bridge was left mended or down.

**D-050, 2026-11-11: The gorge is on the route, and the men turn round beyond it.** (Claude, following the route in
`docs/design.md`) The run is now beech valley, fir woods, gorge on the way out, and the same three back: the gorge and
the firs in winter, the beeches in spring. The season's work lies beyond the gorge's east gate and isn't played: the
men leave by that gate in autumn and come back in by it in winter. So the landslide and the bridge are each met
twice, and are found the second time as they were left. The new letters are placeholders, as the others are.

**D-051, 2026-11-11: The camera looks down at 22 degrees, and the angle is the game's setting.** (Dominic) "let's try
lowering camera angle", after seeing 30 and 22 side by side with the mock-up, and then: "Camera angle should be game
setting not engine enforced". Creel keeps 30 degrees as its own and gains the settings; Smyana asks for 22 in
`data/route.json` (`camera_elev`). Everything baked is baked again for the angle. It is a try: `elev:30` on the command
line shows the old view.

**D-052, 2026-11-11: After leaf-fall the trees keep their colours and about half their leaves.** (Dominic) "Trees are a
bit naked there ... the rhodope autumn trees are rich with shades. Some tree yellowz some red, some orange. Like our
pallette that was designed for the trees". The "late" stage had been thinned to a few clinging leaves, all rust and
brown, after a review against the mock-up (Claude, earlier the same day). Now each tree keeps its own yellow, orange or
red and about half its crown, over the fine twigs. How bare the trees go on the way to winter is still open ("Depends
how we end up showing the change to winter").

**D-053, 2026-11-11: The work goes in phases: the world map, then threats and the fight, then resources, and the frame
last.** (Dominic) First: "20 men walking around the entire game world with obviously nothing to do". He first put
resources second and threats last, then on reading the plan: "i want to focus on the feel of the game first, actually
wonder now if the \"risks\" should be done before resources to get the sounds and music and flintlock fighting - sound
and smoke is soooooo important there for the right feel". Claude swapped them and he went on from there. The village,
intro, homecoming and ending come "at the end basically". Issues #48 to #51.

**D-054, 2026-11-11: The world is one line of seven maps, out and back, with the turn on the high ridge.** (Claude's
plan, agreed by Dominic: "this is good. Because we coem back through different season/weather", and of the seven maps,
"sounds good, we'll adjust after we play if needed") Village edge, beech valley, deep fir woods, gorge, Roman ruins,
the pass, the high ridge: 13 legs. The ruins are their own map and the pass comes before the ridge. The village is in
the west and the climb goes east ("yes"). This supersedes D-050's turn-round beyond the gorge: the gorge's east gate
leads to the ruins. The design is `docs/world.md`.

**D-055, 2026-11-11: The run is two hours, not one.** (Dominic) "all of this suggets a 2 hour first game is more
realistic. 2mins at the roman ruins wont ever happen". Supersedes the one-hour run of the design doc. The maps keep
their sizes until the men have walked them.

**D-056, 2026-11-11: Bandits are merged with the Ottoman patrol for now.** (Dominic) "All that matters is some
fighting vs people that also have guns". One armed human enemy, who shoot back.

**D-057, 2026-11-11: The load time is brought down at the end of development.** (Dominic) "we'll need to ensure at the
end of development we get the load time down". Every load is measured from phase 1 on, so there are numbers to beat
(#57, #82).

**D-058, 2026-11-11: An old-fashioned map in the loader is a stretch goal.** (Dominic) "could be fun if stretch goal we
have a old fashioned looking map we show in the loader". Behind the letter home, drawn from the world picture (#84).

**D-059, 2026-11-11: The game opens on a live menu, not a loading screen.** (Dominic, #86) "we want very minimal
loader. The game menu should show the village (once ready - just the men in forest for now is fine) alive in real time
-> when you "start" , the menu should just fade away". The loader is the name, Смяна, on the dark; the menu is the same
name over the men going about the wood, with Start and Quit. Under the menu the men move but the run's clock and gates
wait. The name is set in Old Standard TT (SIL Open Font License), a 19th-century book face with Cyrillic (Claude).

**D-060, 2026-11-11: Where anything touches the ground is the darkest point.** (Dominic, #86) "Darkest point should be
where anything touches the ground". Every trunk, young tree, stump and man has a small dark oval at its foot, drawn on
the ground, which the shade darkens further. Shade under a closed canopy is never lighter than one lone tree's: Creel's
`mist` keeps the haze's hue but no longer lightens ("Lone trees its dark, overlapping its grey").

**D-061, 2026-11-11: The zoom and the camera's speed follow the window, not its pixels.** (Claude, for Dominic's #86)
The zoom is in steps of the window's height, so the wheel always returns to the default and a Retina screen sees what
a small one does; it starts one step further out than before. The camera moves 1.6 window heights a second. The mouse
has the game's own cursors: a pointer, a pointer with an order's ring, and an axe over a young tree.

**D-062, 2026-11-11: The season is a clock, and each leg of the route gives it two ends.** (Claude; a Proposal until
Dominic has seen it move.) The year is counted in thousandths of a season (0 high summer, 1000 full autumn, 2000
midwinter, 3000 spring). It moves while the men are in a place, between the two ends that leg gives it, and the walk
to the next place brings it at least to that leg's first end. Higher ground runs ahead in autumn and behind in spring.
Each tree turns on its own day, up to 200 thousandths either side. The ground, the light, the length of the day and
the leaves' cover all read the one clock. Why two ends and not a free-running clock: the pictures per season are made
for a place, and a player who waits in the first valley must not find winter there. A leg that names a season stands
still in it (the looks). Closes #10.

**D-063, 2026-11-11: Weather comes in spells, counted from the clock.** (Claude; a Proposal until Dominic has seen
it.) A spell of three hours is clear, mist, rain or snow by the season's chances, and which one is worked out from the
spell's number, so it is the same in every run and the sim stays repeatable. Rain falls as snow where snow lies. Lying
snow slows the men by up to a quarter. Weather moves the light on top of the hour's and the season's mood instead of
having moods of its own, so there are three small sets of numbers and not three more moods for each hour and season.
A leg can name its weather; a leg that stands still in its season stays clear, so the comparison scene is unchanged.
For #15.

**D-064, 2026-11-11: Cover is worked out from the trees and the clock, and is never shown as a number.** (Claude; a
Proposal until the threats use it.) A tile hides a man by the old trees within two tiles (by the leaves each still
wears; conifers all year), young trees beside him and bracken under him. A watcher's range is cut by up to seven
tenths at full cover, and further by night and weather. There is no stored cover map: it is read from the map and the
season clock when asked, so felling and leaf-fall change it with nothing to keep in step. The player reads it from the
leaves (design doc, "Leaves as a signal"). For #9.

**D-065, 2026-11-11: A ford costs time, more with a load and more in high water.** (Claude; a Proposal.) A man wades
at six tenths of his pace, four tenths loaded, and up to a fifth less when the water is high (the thaw, or hard rain).
The risk of a ford is time and cold, not drowning: nobody is lost to a stream by a roll of dice. How cold the water is
is given to the needs (#65) to use. For #20.

**D-066, 2026-11-11: Raised ground is rough near every drop, and proper cliffs are Creel's work.** (Dominic asked for
the cliffs issue; Claude chose the rough relief.) Near a change of height the ground rises and falls by up to 0.9 of a
level, so no rim is ruled along the tiles (Creel `relief_rough`). This is a step, not the cure. Natural cliffs, with
curved footprints, broken faces and ledges, are Casaide/creel#25. Until then, rock outcrops over the walls stay. For
#16.

**D-067, 2026-11-11: The Roman ruins are worked limestone with brick bands, laid out by the map.** (Claude; a
Proposal.) The ruins' stone is a pale limestone cut square, so it reads as a different stone from the local gneiss.
Their walls have a band of red brick, and the road is paved with big fitted stones and has kerbs. There is a drain
beside the road, because the drain is what the men bring home. A map places each piece (`"ruins"`); the ground under them
stays grass so the undergrowth grows up among them and turns with the year. For #17; the ruins' own map is #53.

**D-068, 2026-11-11: A felled tree leaves its stump, its lopped top and a sawn round.** (Claude; a Proposal.) Until the
mechanics give felling stages of their own, a stump the men made always has the tree's top, boughs and a round of its
trunk lying beside it, so a cut wood looks worked. The fir and the black pine are their own shapes; a pine among the
beeches is half Scots, half black. For #6.

**D-069, 2026-11-11: Summer's crowns are cooler and deeper than the meadow, and the summer light is clear.** (Dominic
asked; Claude chose how.) Dominic found the summer scene washed out, too green and samey, with light trees lost on the
grass. The summer light no longer lays a yellow highlight and a pale yellow-green haze over everything; its shade is
cool. The crowns are deeper and bluer greens, each kind its own and each tree of a kind fresher or darker, while the
meadow under them is warmer and olive, with one tuft in three gone straw. Last year's leaves under the beeches are dull
and mossy, and the floor under the conifers is thin needles on moss, not a dark brown pool round every tree.

**D-070, 2026-11-11: The Roman road is one long road, cut into tiles, that changes as it goes.** (Dominic asked for
it to be less samey, #97; Claude chose how.) Every stone and kerb is laid once along the whole road, stones of many
sizes, so no tile repeats. It bows a little off straight and runs whole, heaved by roots, with its stones gone, buried
with only the kerbs showing, and fades into the trail at both ends (`ROAD_PLAN`). Its drain comes and goes and runs
under it once in a culvert (`ROAD_DRAIN`). Grass and undergrowth grow where its stones are gone or buried, and a young
tree has come up through its kerb. The road's pieces cast no baked shadow (a long flat piece's shadow drew stray lines).

**D-071, 2026-11-11: Every art pixel is drawn the same size at any zoom.** (Dominic chose it from three options; Claude
built it.) Smyana zooms in quarter steps, so with nearest sampling one art pixel was two screen pixels wide and the next
three, which made the men's edges jagged. Creel's `sprite_even` samples sprites sharp bilinear: every art pixel is
solid and only the screen pixel where two meet is a mix, so the art stays crisp (D-041) and reads evenly. The ground is
not changed. Rejected: zooming only in whole-number steps (fewer, bigger zoom jumps), and remaking the men at twice the
detail (a much bigger job that changes their look).

**D-072, 2026-11-11: Which calm track plays when is data, by season and the light's mood of the hour.** (Claude's
how, to Dominic's D-036 and D-042; open to him) The nine calm tracks are shared over four seasons and four moods of
the day (dawn, day, dusk, night) in `data/music.json`: dawn has the day's track except in spring, which has a morning
of its own. A track plays once and the forest is then left alone for 90 seconds, a short gap so the first demo is not
mostly silence; the plan's "a few minutes" waits for the sounds of the world. At night with a fire lit, the men's song
takes turns with the season's night track. The main theme the frame tracks share is a first version, a proposal like
every track of the first draft.

**D-073, 2026-11-11: Each song has a design stage before it is made.** (Dominic) "each song needs a clear design
stage. Like we did for 2D before 3D", after hearing the first draft of the score: "worry we're just churning out songs
with not much thoughts". How (Claude's, for him to agree): a sheet in plain words with a picture of the tune's shape,
then a "pencil" sketch of the tune alone, and only then the track (`docs/music-design.md`). The first draft's tracks
stay in the game as placeholders until each is replaced by a designed one.

(D-072 and D-073 were written as D-059 and D-060 on the music branch, pull request #63, and renumbered on
2026-11-11 at 22:05 UTC when it was merged up to main, where those numbers had gone to the start-up thread.)

**D-074, 2026-11-11: The demo's one song is autumn dusk: one kaba gaida, as slow as it can go.** (Dominic asked for
"one good song for that demo"; the choice of song and everything in it is Claude's, made while he was away, and open
to him.) It is the track the camp plays at dusk in autumn. Its sheet (`docs/music-design.md`) held, with one addition:
a fourth phrase with the piece's one leap, up a fifth to the pipe's top note, answered at the end by the far kaval's
leap down a fifth. The pipe is a new, rounder kaba gaida whose bag pressure wanders, so held notes are never still;
the mist is the pipe's own long dark echo, not a separate haze of high notes; the drone is low in the mix and grows
only for the leap. Every later song goes through the same written checklist, one at a time.

**D-075, 2026-11-11: Cliffs are drawn off the grid, and the sim's levels stay as they are.** (Dominic asked for proper
cliffs, Creel #25; Claude chose how.) Creel's `relief_cliffs` draws each level's drop as a curve inside the unwalkable
tile below it, with ledges where two drops drift apart, scree at the foot, ramps as straight slopes and snow on the
ledges in winter. Walkable ground keeps its level, so pathing, the bridge and the ford are unchanged. The gorge's walls
are laid plainly, from a sheer four-level face to a five-tile stair of ledges, with rock on a fifth of the ledges
instead of nearly every cell. Rejected: overhangs (a different store than a height field, much more work), and a rim
that rolls over (it left seams at the ramps). Supersedes the rock cover of the gorge's walls (picture 82).

**D-076, 2026-11-11: The far-below set piece is built from real height first.** (Claude; a Proposal.) For Dominic's
men on a mountain road with the Ottomans following far below on the same path, the pass or ridge map (#52 to #55) gets
a road on a shelf seven or eight levels above the valley path, with proper cliffs between. At the 22-degree camera
that is about 250 art pixels of drop, half the screen at zoom 2. A perspective trick (a far valley drawn smaller and
hazier beyond the map) is a Creel feature to make only if that is not deep enough. The road should run east-west so
the cliff faces south and is lit.

**D-077, 2026-11-11: The four new places are grey-boxed to the world plan, each with a shape of its own.** (Claude,
while Dominic was away; he had agreed the plan, D-053 to D-058.) The village edge has the village as raised blocks
beyond the lane, and terraces north of the trail. The Roman ruins stand on a shelf four levels above the river. The
pass carries the trail on a shelf eight levels above a valley path, which a ramp near the east gate joins to the shelf
(D-076, now built: the cliff faces south and the patrol can come up behind the men). The high ridge has one gate, a
lookout at the trail's end, and the far valley and its road eight levels below, seen and not walked. The gorge's east
gate now leads to the ruins and the men turn round on the ridge (supersedes the turn-round in D-050). The old small
ruins map is kept for the close look. Rejected: putting the far-below road on the ridge only (the pass is where the
patrol follows the men, leg 8), and joining the valley path to the trail at the west end (the men would meet the
patrol head-on instead of being followed).

**D-078, 2026-11-11: Two stand-in woods until the new species come.** (Claude.) A map's "wood" can now be `oak` (the
village edge: oak and hornbeam, with a beech for the lime and the wild pear) or `high` (the pass and the ridge: Scots
pine and spruce, with a black pine or a fir now and then). `oak` counts as broadleaved, so it has the beeches' leaf
litter and young trees that lose their leaves. `high` has the conifers' floor. #56 replaces the stand-ins.

**D-079, 2026-11-11: The run starts at the top of the lane at 6 in the morning, and the last walk has no letter.**
(Claude.) The 13 legs follow the world plan's seasons (`"year"` spans in `data/route.json`). The high legs run ahead of
the valleys (`"altitude"`), but the pass is kept in autumn on the way out. Leaving the village takes the run's first
10 thousandths of a season, so the beech valley still starts in late summer, as the run check expects. Walking down
the lane at the end goes straight to the end screen, with no blank letter between.

**D-080, 2026-11-12: A shot is two sounds and a gap, and the place answers it.**
(Claude.) The lock and pan are one sound, the charge another, and the game puts the hang (0.06 to 0.18 s, one shot in
twelve up to 0.9 s) between them, so no two shots sound alike. Each map is one of four kinds of place for the echo
(close wood, valley, gorge, open ridge, `data/guns.json`), its echo made into the bang's own file. A shot far from the
view is the low far boom. All the sounds are made by `sound/flintlock.py` from noise and sine waves, none recorded.

**D-081, 2026-11-12: The rifle's smoke hangs where it was fired and hides the man.**
(Claude.) 26 s in the wood, 18 in a valley, 20 in the gorge, 10 on the ridge, drifting slowly east. It is drawn over
the men, on purpose: a line that has fired a few times stands in its own smoke and is hard to see, from the player's
side as much as the enemy's.

**D-082, 2026-11-12: The reload is 18 to 23 seconds, and each man aims in his own time.**
(Claude.) A Balkan long gun was loaded by hand with horn and rod; 18 s is quick for it. Each man takes 1 to 4.5 s to
bring his rifle up when told to fire, and 0 to 5 s more over each reload, so twenty rifles go off in ones and twos
and never as one volley (#58). Picked by a hash of his id and the tick, so a run is the same each time.

**D-083, 2026-11-12: The men carry the rifle on the shoulder, muzzle up and back.**
(Claude.) As the builders in old pictures carry long guns; it shows the swallow-tail butt in front of him. Aimed, the
butt is in the shoulder and the left hand under the barrel; reloading, the rifle stands upright. Dominic's to judge
(D-019 left the rifle's look to him).

**D-084, 2026-11-12: The ridge is a view across, not down: laid on the diagonal, the valley in low fog, a patrol on
the far road.** (Dominic asked for map, fog and camera together and agreed it is "important for the atmosphere";
Claude chose how.) The trail and rim run across the picture, the drop is cliffs, the valley's fog lies by height so
the ridge stays crisp, and the riders are left unmarked so the fog takes them, with a red banner as the one accent.
The camera stays the game's 22 degrees (D-051); nothing new was needed there. Low fog is an option in Creel, off by
default.

**D-085, 2026-11-12: Threats find the men only by their cover, and a shot gives the shooter away.** (Claude; a
Proposal, `docs/threats.md`.) Every threat looks with the cover check (D-064). A shot is heard across the place (22
tiles in a wood, up to 40 on the open ridge), and a man who has fired is seen through his cover for 12 seconds, while
his smoke hangs over him. So to hide is to hold fire. Each threat has a small mind: on its way, wary (it heard
something and comes to look), hunting (it has seen a man), gone. The music follows that state, never a timer.

**D-086, 2026-11-12: A flintlock misses a lot; the first ball wounds and the second kills.** (Claude; a Proposal.) A
ball hits nine times in ten at two tiles or closer, falling to one in four at the rifle's full range, and good cover
halves that. A hit takes 25 of a man's 40: he is wounded and walks at 55 in a hundred; the second hit kills him, and
one fired from a tile away kills outright. What the player sees: the ball's spray of earth (or snow) by a man it
missed, a puff off the coat of one it hit, and the dead lying where they fell, on their backs, away from who shot
them. No health is shown. In the first test fight about one ball in four hit.

**D-087, 2026-11-12: The first threat built is the Ottoman patrol, on foot.** (Claude, following Dominic's "All that
matters is some fighting vs people that also have guns", 2026-11-11.) Zaptiye in red fezzes, some with a turban's
white cloth wound round it, dark blue coats with brass, a green sash where the men wear red: the men's own voxel rig
with new looks. They walk a road, come to look at a shot they hear, fire at the men they see in their own time and
reload as slowly, close in on the last man seen, and fall back the way they came when half are down. They only kill:
prisoners stay open (#62). The ridge's far-off patrol is mounted (D-084); whether some of the patrol ride is open.

**D-088, 2026-11-12: The men fire only when told, then keep at it.** (Claude; a Proposal.) Men told to fire go on
firing, each at the nearest enemy he can see, until they are told to walk somewhere; a man shot at does not fire back
by himself, so hiding is always the player's choice. When the danger ends, the end stroke plays as before (D-042),
or, if a man fell in the fight, the short lament (track 18) in its place, once.

**D-089, 2026-11-12: In the pass the patrol follows the men, and only catches men who stop.** (Claude, building D-076
and D-077.) On leg 8, eight patrolmen set out on the valley path 30 seconds after the men come in, climb the ramp by
the east gate and walk the trail behind them, a little slower than the men walk. So the pressure is behind you: keep
going and they never close, stop to rest, to fell or to fight and they are on you. Fighting them from the rocks or
the last trees is the player's choice.

**D-090, 2026-11-12: The wolves are heard more than seen, and only winter's go for a man.** (Claude, from the threats
plan, docs/threats.md; a Proposal.) A pack of five or six, a voxel wolf on Creel's rig with two pairs of legs. In
autumn on the way out (leg 3) they follow the men at about fifteen tiles, never closing, and a shot within fourteen
tiles scatters them for a minute; the music stays "wary" while they follow. In winter on the way home (leg 11) they
follow closer, and at night they rush a man more than four tiles from any other, all at once, and draw off if he gets
back to the others. Two wolves down and the pack runs. A bite wounds a man like a ball. While they follow one howls
now and then and the others join in (every 25 to 60 seconds); a bite snarls, a ball yelps. The sounds are made from
sine waves and noise like the flintlock's (sound/wolves.py). A lit fire keeping them off comes with the fire (#68).

**D-091, 2026-11-12: The bear bluffs before it fights, and only fights when shot at.** (Claude, from the threats plan,
docs/threats.md; Dominic chose to build it next.) One brown bear in the beech valley at the thaw (leg 12), wandering
round where it lives. A man it sees within nine tiles (by the same cover check, so bare woods make it worse) makes it
rear up and huff for a moment, then charge him and stop two tiles short, and amble off; it leaves them be for forty
seconds after. A ball fired at it, hit or miss, makes it charge the one who fired, for real: its swipe wounds a man
like a ball does. A ball does it a fixed wound (no one-shot kill close up), so it takes four hits before it runs and
a fifth kills it. The music is the beasts' loop while it rears, bluffs or charges. So the right answer to a bear is to
hold fire and back off; to shoot is to fight it. Signs of it on the way out (a scratched trunk, tracks by the stream)
are left for later.

**D-092, 2026-11-12: Each man is fed, warm and rested, and a need run out costs his health.** (Claude, from the
survival plan, docs/survival.md; a Proposal.) Three needs per man, 100 to 0, kept on him between places: hunger falls
about 60 a day (faster working or loaded), warmth goes toward the air's (season, height of the place, night, wind,
rain, snow, a ford's water) and climbs fast by a lit fire, rest falls about 5 an hour awake and comes back asleep in a
camp. Below 30 each need takes up to a ninth of his pace; at 0 cold takes 3 health an hour and hunger 1.5, so a
winter night in the open without a fire can kill a man. Fed, warm and asleep he heals slowly. The walks between places
cost food and rest (no meal, no sleep on the way). Numbers in data/survival.json.

**D-093, 2026-11-12: Camp is one key, and the fire is the night's choice.** (Claude, building D-009; a Proposal.) With
men chosen, C makes camp: they pick the most open ground near them, stand round its far side and flanks (never
between the fire and the camera) and lay a fire, which costs two bundles of wood off their backs, or nearly a minute
of finding dead wood if nobody carries any. C again puts it out, or lights it again. At night men in a camp sleep, lying
feet to the fire, and wake at first light or at a shot. The day's meal is eaten at the first camp after five in the
evening, one portion each from what they carry (shared out if a man has none): hot at a lit fire, half as good cold.
They leave the village with four days' food each. A lit fire warms everyone within four tiles; wolves will not come
within seven tiles of it; a patrol sees it at night from 34 tiles through any cover (its smoke by day from 18) and
comes to look as for a shot; the bear smells a camp with food in it from 16 tiles and wanders round it.

**D-094, 2026-11-12: A man's state is read off him, with one line of words for one man.** (Claude, from #73 and
D-021; a Proposal.) Cold air shows the men's breath, a little pale cloud now and then, the colder the more often; a
cold man shivers when he stands; men in camp face the fire; a hungry or tired man is slower, so he falls behind. The
only words: with one man chosen, his name and under it how he is ("cold and hungry", "worn out", "well"). Nothing for
a group, no meters.

**D-095, 2026-11-12: The wood's food lies in patches you send men to, by the wood and the season.** (Claude, from the
survival plan; a Proposal.) Open ground off the bracken has patches of what its kind of wood gives in the season
(data/survival.json "forage"): bilberries and herbs in summer, beechnuts, mushrooms, wild pears and lingonberries in
autumn, nearly nothing in winter, nettles and wild garlic in spring; none on the fir woods' floor in winter or spring.
Each is worked out from the cell's number, as the bracken is. Right-click one with men chosen and each goes to the
nearest patch within nine tiles of it and gathers it in six seconds: one or two portions into his pack (at most
twelve), or goods to take home (herbs, mountain tea). What is taken stays taken, on the way home too. The patches are
a few pixels of art on the ground (pale caps, husks, fruiting tufts, flowering sprigs) with no marker; a first pass
that needs Dominic's eye.

**D-096, 2026-11-12: A man's pack is food and goods together, and a pile of packs is a cache.** (Claude, from the
survival plan; a Proposal.) A pack holds twelve, food portions and goods alike; a bundle of wood on top weighs two. A
full pack takes about a fifth off a man's pace. X drops the chosen men's packs in one pile where they stand, each
keeping a day's food, so they can run or fight light; right-clicking the pile shares it back out as far as their packs
have room. A pile left anywhere is a cache: a patrolman who would see a man lying there (the same cover check, so the
falling leaves and a felled tree give it away) takes it, and the bear smells food in one from ten tiles, wanders to it
and eats it. Each place keeps its piles for the way home. A man who falls drops his pack where he falls. This merges
the plan's "drop the packs to run" and "caches" into one thing, with no separate cache order.

**D-097, 2026-11-12: The Roman drain is studied with men's time, and lives in the men who learned it.** (Claude, from
#70 and D-011; a Proposal.) Right-click the ruins off the road (a column, its drums, the walls) with men chosen: they
stand along the old road, whose drain runs beside it, and study. It takes 24 hours of men's time on the clock (eight
men about three hours), kept between the two visits to the ruins; those men work (they get hungrier) and aren't
gathering or keeping watch. Every man who gave at least an hour of it knows it, and it is lost if they all die. The one
panel says "knows the Roman drain". It is the only piece of knowledge for the demo.

**D-098, 2026-11-12: Until the homecoming is made, the end screen says the tally.** (Claude, from #72; a Proposal.)
Kept as the run goes: who came back, each man who didn't by name and the place he lies in, what they carry home, and
how many know the Roman drain (or that those who learned it did not come home). For now it is the end screen's lines;
the homecoming and the ending (#51) will show it instead of saying it.

**D-099, 2026-11-12: The fire is a light in the world, not a glow on the picture.** (Dominic, "should be over the men,
creating shadow and light on them"; built by Claude.) A lit fire lights the ground round it, out to 5.5 tiles. It
lights each man and the foot of each trunk, tent or beast near it on their side toward it, and each standing man casts
a shadow on the ground away from it, longer the further he stands. Its strength follows the mood's glow, so it rules
the night and is faint by day. Creel's screen glow stays, smaller, as the lit air round the flames. All of it is in
Smyana, and Creel is unchanged.

**D-100, 2026-11-12: The woods are grown from the maps' trees by rules, not dotted by hand.** (Dominic, "It should feel
dense and rich and alive"; Claude's plan `docs/woods.md`, a Proposal.) When a place loads, its drawn trees say where
the wood is. The wood is grown out from them (`src/smyana/woods.lobster`, numbers in `data/woods.json`):
- About half the tiles of a wood hold an old tree, in clumps from a smooth field, thinner in some places and with
  gaps in others, and a tenth hold young trees.
- A mantle of young trees grows at the edge toward the open, and small groups of trees stand out in the meadows.
- The rim beyond play is wooded.
- The trail, a ford, the gates, a patrol's road, the camp, the ruins, a bridge, the start and a cliff's edge are left
  clear.
- No pocket of open ground is closed off from the gates.
The same place grows the same wood every time. The camp clearing (already dense, the mock-up) is left as drawn. The
size budget is now 6400 old trees a place, and the frame rate is to be watched.

**D-101, 2026-11-12: Open ground is green and the trail is dark earth.** (From Dominic and a Bulgarian's eye: "the
dried out part is too dry looking", "a yellow trail, which just isn't something that would make sense"; Claude,
`tools/ground_atlas.py`, the soft grass in `src/smyana/trees.lobster`.)
- The summer grass is a fresh green, not olive and straw. The soft grass tufts are green with lighter tips, not straw
  (this supersedes their straw-tipped look from 2026-11-11).
- In autumn the meadow is green going gold, with only a few blown leaves on it. The carpet of leaves lies under the
  trees, on a browner bed.
- The trail is dark brown earth with stones in every season, not a pale sand stripe.

**D-102, 2026-11-12: Crowns are full domes, and the trees grow in stands of one kind.** (From Dominic: "the trees
right now, they look really good and the density's better. I'm just wondering if they look like the right kind of
tree or not"; Claude, `tools/tree_vox.py`, `species_pick` in `src/smyana/route.lobster`.)
- Beech, oak and hornbeam crowns get a full leafy shell round their branch tips, so they read as domes and not as
  flat umbrellas (the acacia outline).
- Which tree grows where follows a smooth field over the map, so trees of one kind stand together, as they do in the
  western Rhodopes: beech mostly, with patches of oak and hornbeam, and stands of silver fir and spruce, and pine on
  the far side. Before, each tile picked its kind at random.
- The trail (supersedes D-101's dark trail, which Dominic found "much too hard"): lighter worn earth broken up by
  patches of grass, pebbles and tufts, "more of a gap in all the growth" than a solid stripe.

**D-103, 2026-11-12: A soft watercolour filter over the picture, on trial.** (From Dominic: "Try making this a bit
more watercolour… a filter over the top to make things smoother, less pixelated"; Claude, Creel PR 30.)
Creel's atmosphere pass gains a `paint` setting: a Kuwahara filter that flattens busy areas into patches of colour and
keeps edges, leaving the men sharp. Smyana sets it to 0.5 in `data/atmosphere.json`; `paint:<v>` on the command line
tries another strength (0 off, 1 is blotchy). Dominic to say whether it stays.

**D-104, 2026-11-12: The palm-like fern is retired: bracken in the light, male ferns in the shade.** (From Dominic and
a Bulgarian's eye: the ferns "read as small palm trees", "all these little ferns everywhere that just look really out
of place"; Claude, from docs/woods.md.)
- Bracken is a patch over a whole tile, many fronds arching up out of the ground with broad triangular blades, in
  drifts out in the light (clearings and the wood's edges, never under closed wood). It turns orange-brown in autumn.
- The male fern is a shuttlecock with no stem, in groups of a few, only in the shade under the wood or in the damp by
  water and at a rock's foot.
- Dominic, 17:32: his wife suggests rose hip bushes in place of ferns. He wants to see the new ferns first; rose hips
  come next.

**D-105, 2026-11-12: Every shadow falls one way.** (From Dominic: "the shadows aren't all going the same direction";
Claude.) The men's (and the horses') shadows went down and right while the trees' went left. Two mistakes: the way was
taken from the sun's light with its fall from the sky in it, not along the ground as the trees' baker lays it, and the
men's ground was squashed by the old 30 degree camera's half, not by the 22 degree camera's sine. Both fixed, and the
sheets are now keyed by the shadows' way, so they bake again when it changes.

**D-106, 2026-11-12: Dog roses at the wood's edge.** (Dominic's wife's idea, through Dominic: "instead of ferns, we
should try rose hip bushes"; "Looks great, let's try rose hip too"; Claude.) Rosa canina: long arching canes a man high
or more, small leaves, and red hips in twos and threes at the canes' ends. They grow in the wood's mantle where a tree
or two gives half shade, a few together, and now and then out in the meadow. The hips are orange in high summer and
scarlet in autumn, and they hang on the bare canes through the winter.

**D-107, 2026-11-12: In autumn nothing is green but the evergreens.** (From Dominic: "Why would anything be green if
it's autumn?"; Claude.) The meadow grass, the low herbs, the grass tufts, the bushes, the brambles and the male ferns
all turn tawny gold, rust or red in autumn. This supersedes D-101's "green going gold" meadow. Summer and spring stay
green. The firs, spruces and pines stay green, and where they grow is the next question (Dominic asked).

**D-108, 2026-11-12: Evergreens by height and ground.** (Dominic asked: "Do we expect evergreens mixed in with the
other ones? What's their general rules of placement in regards to each other?"; Claude, from the Rhodope zonation in
docs/woods.md.) The low broadleaf woods (the gorge, the ruins and their road: `"firs": 0` in the map) have no fir or
spruce, and their few pines stand only on rock and by drops. The beech-fir belt (the beech valley) keeps its firs and
spruces in groups among the beeches, with pines only on rocky ground. The high and deep woods are unchanged: spruce,
fir and pine. Not yet done: firs drawn to shaded north slopes and damp hollows, and alder and willow by the water.

**D-109, 2026-11-12: The men walk slowly, under load.** (From Dominic: they moved "very fast and very small steps", and
"let's really consider the weight and the effort and the age and how difficult everything is for them"; Claude.) The
men's speed is 6 (about 0.6 tiles a second; it was 12). Their stride is longer and heavier: a slower heel and toe,
more hip bob and sway, the chest leaning into the walk and the head forward (tools/men_bodies.py). The rifle barrel
and stock are half as thick (data/voxel/gear.json), no longer a "hand cannon". Wolves, bears and their charge were
slowed to match (12, 6, 14); the Ottoman patrol stays at 4, slower than the men, as before. Creel's block pace now
rounds and never stops a slow walker (creel PR 31). Not yet done: pistols in the sash and packs on their backs.

**D-110, 2026-11-12: A right click gives the order; the camera pans flat over cliffs.** (From Dominic's playtest: "I
can select everyone, but I don't seem to have to move anyone", and the camera "starts to get all jittery" over cliffs;
Claude.) Orders listened to SDL's middle button ("mouse2"); the right button is "mouse3", as in Creel's own controls.
Either now gives the order. The camera's edge clamp went through a ground pick and back, so on raised ground each
frame nudged it; it now clamps in flat map space and never moves the camera when it's inside the map.

**D-111, 2026-11-12: The men carry their load.** (From Dominic: "they might have a few pistols on their body... they
might have their packs"; Claude.) Every man has two flintlock pistols through the front of his sash, long grips with
big silver ball pommels (they had two stubs there before, too small to see). Each carries a grey felt bedroll tied
across his shoulder blades, a red-striped woven bag (torba) at his left hip, or both, by turn
(art/men/tools/men.py, write_vox.py). The patrol has the pistols but no packs. Not dynamic: the load shows in the look
and the slower walk (D-109), not in the numbers.

**D-112, 2026-11-12: Beeches leafy to the ground; some fork low; a deep leaf floor all year.** (From Dominic, with a
photo of a beech wood: "the trees have foliage all the way up the branch, or we've got the ones where the tree splits
early at the bottom", and "everywhere off the path will just be covered in really deep leaf cover"; Claude.) The beech
and hornbeam models grow short leafy shoots from low on the trunk up into the crown, longer the higher they are, so the
green runs down the tree instead of sitting on a bare pole; their low shoots keep more dead leaves through winter, as
young beech does. One of each young, mature and old beech, and one old hornbeam, fork low into two or three stems
(tools/tree_vox.py; TREE_BAKE "trees 63"). Under a broadleaf tree the fallen leaves now lie in every season and reach
2.6 tiles, deep, so in a closed wood they meet; the trail keeps only a thin scatter; grass gives out sooner under
broadleaves. This supersedes the summer part of D-101's green floor in closed broadleaf wood; glades stay turf.

**D-113, 2026-11-12: A fast playthrough checks the whole game, and finds what breaks it.** (From Dominic: "very fast
playthroughs where we speed it up loads and shoot through everything really quickly"; Claude.) `script:play fast:<n>`
plays the real game, window and all, with the sim n times as fast: the men walk every leg, fire at any beast or
patrolman within eight tiles, camp at night and walk on at first light, and every event is logged on a "play:" line; a
leg not left in three game days is called stuck, with where every man is. Its first runs found: the game never ended
when every man was dead (now "Nobody came home", with where each lies); two men wedged for good where rock pinched the
gorge's ford to one tile on its west bank (the rock there is now grass); food runs out after four nights of about ten
(not changed: gameplay, for Dominic); the Ottoman patrol, slower than the men, never catches men who keep walking (not
changed). A man walking with the others who comes no nearer for half a minute is sent on by himself (a safety net for
Creel's block steering, which once held a man the bear had mauled in a night camp). With the men fed (`fresh`) the
whole route plays from the village to the homecoming: 13 legs, 8 fights, 20 of 20 home.

**D-114, 2026-11-12: Nothing bakes at load: the pictures ship in baked/.** (From Dominic: "we shouldnt be baking at
load. no point right?"; Claude.) Every sheet (men, beasts, trees in every season, snow, camp) is baked by
`tools/prebake.sh` into `baked/`, which is committed; a start only reads it. A changed key still bakes that sheet and
writes it there, to be committed with the change. The start also stopped re-reading the men's voxel models (2 s: they
are read only when something must be baked; the walk cycles are kept beside the sheets) and re-hashing the 28 MB of
tree models for each of seven sheets (the key is now each model's length and tail). A start with everything baked: 8 s
to about 1.5 s, here.

**D-115, 2026-11-13: A beech's crown is one egg from low on the tree to the top.** (From Dominic: "It should be
rounder... covering the top part of the tree rather than the whole of the tree", and his photographs; Claude.) Made
from the photos of an open-grown beech and of old Balkan beeches, not guessed: the trunk runs up through the crown as
a leader; limbs leave it all the way up, low ones long, near level and drooping at their ends, high ones short and
steep; the leaves lie in flat layered sprays along every limb out to an egg-shaped, lobed shell, widest a little below
its middle, leafy underneath and at the sides as on top, with gaps where the limbs and the sky show. Supersedes the
domed beech crown of D-101 (other broadleaves keep it).

**D-116, 2026-11-13: The old forest has giants of every kind, which the men can't fell.** (From Dominic: "The forest
is old, likely they've be some really big/thick ones. We had planned some that can't be cut down because of size", and
"Not just beech right?"; sizes from field sources, Claude.) One old tree in six is a giant: a beech forking low into
great limbs, an oak with dead limbs in its crown, a silver fir, a spruce, a Scots pine and a black pine, each taller
and about twice as thick as an old tree of its kind, with buttresses, burrs and old wounds. Like every old tree
(D-028), a giant blocks the way and can't be felled. Not the hornbeam (a smaller tree), and no plane trees yet (new
kinds are on hold).

