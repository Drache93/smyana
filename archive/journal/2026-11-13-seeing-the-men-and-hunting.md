# Seeing the men, knowing what to do, and hunting

*2026-11-13, Claude, thread "Make the gameplay clear and add hunting".* Dominic's words are in
`archive/notes/2026-11-13-dominic-food-and-playing-it.md`.

Dominic agreed the men keep their four days' food and make up the rest in the wood: "Foraging and hunting needed
yeh". Then he played it, and wrote what playing it was like: he couldn't always see his men, couldn't tell what he
could click, the men marched wide, the music stopped, the next place took longer than the first, and above all he
couldn't tell what he was meant to be doing or why.

## The men under the trees (D-120)

His screenshot (`images/2026-11-13/18-bug-the-men-hidden-under-the-crowns.jpg`) shows the men half lost in a beech:
its crown thinned out over them already, but its trunk and limbs didn't. Now the trunk thins too, and every man is
drawn once more over everything, faintly. In plain sight his ghost lands on himself and changes nothing; behind a
tree it shows him through it (`19-the-men-under-a-beech-before-and-after-their-ghost-shows-through.jpg`). It costs
one more sprite a man.

## What can be clicked (D-121)

Felling and gathering were in, but nothing said so: only young trees can be felled, and the patches are small. The
mouse now carries a name and, with men chosen, what a right-click does. The old trees say they are too big to fell.

## Game (D-122)

From the sources (Animal Diversity Web on the roe deer, the Acta Zoologica Bulgarica supplement on the Rhodopes' game
and wilddocu.de on the Balkan chamois): roe deer and wild boar in the woods, chamois on the rocky slopes. Each a voxel
body like the wolf's, the deer and the chamois with a summer and a winter coat. They graze by the trail, look up at a
man they can see and run if he comes on or moves; they run from every shot. A boar takes two balls and charges. A
carcass is butchered into the packs. The shot is still heard by any patrol.

## The rest

- A long march goes in a column, two abreast (D-123). The first try sent each man to his own spot at the end, and in
  a gate's narrow end twenty men pressing for twenty spots never arrived: the fast playthrough stuck. Now the column
  is given one move together when its head is nearly there.
- The next place loads in about a second; it was the letter's twenty seconds that felt like loading. It now stays as
  long as it takes to read, and says when a click will go on (D-124). The music plays on, track after track.
- How to teach the game, and give each place a reason to stop: a proposal for Dominic, `docs/clarity.md`.

## Playing it through

The fast playthrough (`./play.sh windowed script:play fast:40`) now hunts and gathers when the men are down to three
days' food, as a careful player would. What it found along the way: the game was set down too far from the trail to
ever be met; the bot's camp could be undone by the column's late starters; a patch that can't be reached held the bot
forever; the evening meal ended with the first man to eat, so men still walking into the camp went without; a
band that reached a gate at nightfall walked on into the next place unfed. All fixed.

The last run, with no help: twenty men out, two home. Six hunts, four kills (chamois, a boar and a deer: 69 days'
meat) and 34 portions gathered. The food ran out on the ridge, and the deaths were mostly the winter's cold, in the
pass and the fir woods on the way home. The cold is the next thing to look at, with Dominic.
