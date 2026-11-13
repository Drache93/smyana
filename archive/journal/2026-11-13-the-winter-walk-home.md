# The winter walk home: what feeds the men

*2026-11-13, Claude, thread "Make the gameplay clear and add hunting".* Dominic's words are in
`archive/notes/2026-11-13-dominic-off-the-path.md` (the last section).

Dominic asked for two things: balance food against the winter cold, and make the test bot follow the signs down the
side paths so the fast playthrough is a fair test.

## Why the men died

Not the cold, mostly. A day's walk in midwinter on the pass is cold, but walking men keep above freezing by day and a
fire holds the night. They died of hunger: twenty men eat twenty portions a day, the wood gives nothing in winter, and
the way home is about six winter days. The design's answer was always there (docs/design.md: "Pick up the caches left
on the way out"), but nothing the bot did, or a player could easily do, built enough of a store.

## The bot, as a careful player

It now sends four men quietly down a side path whose mouth shows signs of game, stops twelve tiles short of the end,
creeps on to seven tiles and shoots; fills its packs in the autumn and leaves what is over four days' food a man as a
cache in each place it will come back through, and fetches it in winter; looks for patches twenty tiles round; stops at
four in the afternoon and camps, rather than walking into the next place in the dark and missing the meal and the
sleep. Several of its own faults turned up on the way: it counted its nights as time spent on food, picked up its own
cache as it left it, and foraged through the evening meal.

Hunting needed one change to the game (D-130): deer that bolted the moment a man moved inside six tiles could never be
shot, since six tiles is the rifle's reach.

## The proposal that was turned down

Claude proposed paying the men in bread at the ridge, "the work". Dominic: there is no work (D-129). So the season
carries them: autumn's finds are thicker and richer, and rose hips are the winter's one find (D-130).

## Where it stands

Last run, no help: 96 portions gathered, a cache left and fetched, the last of the men reaching the village edge in
spring. Most died of hunger on the winter legs home, where the bot spends two days a place. Next: more to find on the
way (huts, a cache of other gatherers, honey), and a faster winter walk.
