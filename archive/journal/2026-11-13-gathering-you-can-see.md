# Gathering you can see

*2026-11-13, Claude, thread "Make the gameplay clear and add hunting".* Dominic's words are in
`archive/notes/2026-11-13-dominic-off-the-path.md` (the last two sections). Decisions D-134 to D-137; the design as
built is `docs/gathering.md`.

Dominic played and found the gathering was "moving my mouse over everything to find something", the hover text over
trees "lots of text instead of visual", the order signs "placholder", and no reason to fell trees. Claude wrote a
short proposal; he ticked every question and said "go ahead". It was built in the proposal's order.

## 1. Words off the mouse, no felling

The text under the mouse is gone. The cursor is now a small drawn picture when a right-click will do something (image
28: a basket, a hand, a knife, a sight, a fire, a book, a spade), and plain otherwise. Only a man's name shows. Young
trees are scenery; making camp sends two men a few tiles out for dead wood instead.

## 2. A few big stands, called out

The dozens of one-tile patches became two to five stands a place, each ten to twenty portions, drawn twice life size
and spread over a few tiles (image 26: ceps under the autumn beeches). Where each grows comes from field sources (in
data/survival.json): ceps deep under old trees, wild pears and the dog rose in the light, mountain tea high on open
stony ground. The first man near one says so over his head. The first try drew the items in one small heap: the hash
that spread them only gave a quarter of the range, so they were spread again with a hash each for bearing and distance.

## 3. Things for home

A pack's goods are kinds now: herbs, wax, hides, wool. The tally at home names each ("A cake of wild bees' wax, for
candles.").

## 4. Drawn signs and loaves

The word row at the foot of the screen became three pictures under the chosen men's feet (a fire, a pack, an open
hand) and a loaf for each day the bread will last (image 27).

## The playthrough

The first fast playthrough stopped in the fir woods: the bot hunted, butchered and cached there for three days, which
the test called stuck. A player can stay that long, so the limit is now five days.
