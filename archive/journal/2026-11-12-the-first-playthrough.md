# The first whole playthrough

2026-11-12, late evening. Claude, from Dominic's questions ([notes](../notes/2026-11-12-dominic-playthrough.md)).

Dominic asked whether he could start the game and play it through: moving, shooting, threats, the whole route. Until
now each piece had been checked alone (the headless run check drives the route with its own hand). So a bot now plays
the real game at forty times speed (D-113), as Age of Anything's tests do.

What it found, in order:

1. **Food.** The men leave with four days' food each; the route takes about ten nights. Without foraging they were
   starving by the pass and dying of hunger and cold on the way home. Left as it is: a gameplay question for Dominic.
2. **No end when all are dead.** The run went on forever over twenty bodies. It now ends: "Nobody came home."
3. **Stuck at a ford.** On the way home with the gorge's bridge still down, two men stood for good at the ford's west
   end, where rock pinched it to one tile. The rock is grass now (data/maps/gorge.json).
4. **A mauled man.** Once, the bear came into a night camp and the man it mauled never walked again: his formation
   waited on him and he on it. Not seen again since; a man who comes no nearer for half a minute is now sent on alone.
5. **The patrol never catches them.** At speed 4 against the men's 6, men who keep walking leave the pass before it
   reaches them, so the set-piece fight doesn't happen by itself.

With the men fed, the whole route plays: the village, the beech valley, the fir woods (five wolves), the gorge, the
ruins, the pass, the ridge, and back in winter and spring (two more wolves, the bear), to the homecoming, 20 of 20.

The start: with the cache warm it took 8 s, and on a fresh clone 40 s of baking. Two seconds went on re-reading the
men's voxel models and most of a second on hashing 28 MB of tree models seven times. Both are gone, and the pictures
now ship baked (D-114): about 1.5 s here. Steady at 60 fps on Dominic's machine, he says; the bot's frame counts under
a software renderer here don't speak to that.
