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
