# Making the game clear: what to do, and why

*Superseded in part, 2026-11-13: Dominic wants no goals per place and no keys to teach (see `docs/off-the-path.md`).
What follows is kept as written.*

*Claude's proposal, 2026-11-13, after Dominic played and wrote: "how to make fires? Game is look great but the gameplay
is missing and unclear atm. I know we were focusing on env. But we'll need to figure out a balance to ensure players
dont just walk through the path waiting for something to happen with no clarity on what or why". Everything here is a
**Proposal** until he agrees it, except the parts marked built.*

## What is wrong now

- **Nothing says what the men are for.** The letter between places is mood, not a goal. A player sees a trail and
  walks it.
- **The verbs are hidden.** Camp is the C key, dropping packs is X, foraging is a right-click on a small patch, felling
  only works on young trees. Nothing in the game tells you any of it.
- **The pressure is invisible.** Food, cold and the riders behind are all real in the sim, but you only learn about
  them when men start dying.
- **Stopping is never rewarded until it is too late.** Every place can be walked through in a few minutes.

## The idea in one breath

Each place asks one question: **do we stop here, and for what?** The men have to get over the mountains and home
before the winter closes the pass, with something to show for it. Food runs out after four days, so they have to stop
to hunt and gather; stopping costs daylight, and daylight lets the riders behind catch up. The game teaches its verbs
the first time each one matters, in the men's own words, and then never again.

## 1. A goal you can read (Proposal)

- **The journey's goal, once, at the start:** under the title as the run begins, two lines in the letter's voice: *"Over
  the mountains to the work, and home before the snow shuts the pass. Twenty of us go."*
- **Each place's goal, as it opens:** one line under the place's name, in the same voice, saying what this place is
  for. For example: the beech valley, *"Good hunting in the beeches. Two days to the gorge."*; the ruins, *"The old
  road. The Romans drained it somehow."*; the pass, *"Patrols on the pass. Cross by night."* It fades after a few
  seconds. Data in `route.json` per leg.
- **The way on:** while no order is given, a faint mark at the screen's edge points to the place's exit (only when it
  is off the screen). Nothing on the map itself.

## 2. Each verb taught once, when it first matters (Proposal)

A single line at the bottom of the screen, in the letter's hand, shown once per run the first time its moment comes,
then never again. The men speak it, not a tutorial:

| When | The line |
|---|---|
| The run starts | *Pick the men: drag over them, or double-click one for all. Right-click to send them.* |
| First dusk | *"It's getting dark. We should make camp." Choose the men and press C to make a fire.* |
| Food below two days | *"Two days' bread left." Right-click game to shoot it, or what the wood gives to gather it.* |
| First game seen | *"Deer, there." Right-click it with the men chosen: the shot will be heard.* |
| First shot heard by a patrol | *"They heard that."* |
| A man cold at night with no fire | *"I can't feel my hands."* |
| First young tree near the trail | *Young trees can be cut for firewood: right-click one.* |
| First ford or snow | *Heavy packs are slow here. X drops them; come back for them.* |

## 3. What the mouse is on (built, 2026-11-13)

By the pointer, the name of what is under it and, with men chosen, what a right-click will make them do:
"Old beech: too big to fell, young trees give the wood", "Mushrooms: gather", "Roe deer: shoot it for meat (the shot
is heard)", "Your packs: pick them up", "Roman ruins: study how they drained the road". This answers "I can't click
on trees to see what they have".

## 4. The pressure made readable (Proposal)

- **Food in days, not portions:** with men chosen, under the one-man panel (or alone, for a group), *"Bread for 3 days"*.
  It is the one number the whole game turns on.
- **The riders behind:** when they are a day or less behind, the men say so once (*"Horses on the trail behind us"*),
  and the wary music starts. Today they arrive with no warning.
- **Weather and the year:** the letter names the season it is written in.

## 5. Reasons to stop in every place (part built)

- **Game** (built 2026-11-13): roe deer and boar in the woods, chamois on the rocks, from the sources. Each kill is
  several days' meat, and a shot is a shot.
- **What the wood gives** (built, PR 112): patches by season.
- **One thing per place worth going off the trail for:** the ruins' drain (built), a good spring, an old tree for a
  cache, a hut with a hearth (no fire seen from outside), a bridge to mend. One per map, set in data.

## Order, if agreed

1. The verb lines (2) and food in days (4): small, and they answer "how do I make a fire".
2. The goal lines (1) per leg.
3. The riders' warning (4) and one stop-worth thing per place (5).
