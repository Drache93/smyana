# Smyana: game design

*Started 2026-11-10 (as "Shift: Game Design Doc"). This is the working design; it changes as we
go, and the reasons for each change are in [`../archive/decisions.md`](../archive/decisions.md).
Anything marked **Proposal** is Claude's suggestion to fill a gap and isn't agreed yet.*

## Overview

Smyana is an atmospheric survival RPG, built as an RTS. Twenty men leave a fictional village in
the Rhodopes with stone hammers and swallow-tailed rifles, inspired by the travelling builders
of Kovachevitsa. They spend summer, autumn and winter in the forest gathering, cutting, hunting,
fighting and surviving. On the way they come across old Roman ruins and other places that teach
them something. In spring they bring home what they gathered and learned. It runs on the same
engine as Age of Anything (Creel) and uses the same camera. The trees are much bigger, so the
men walk between and under them.

The game is a demo: one run from summer to spring, in real time, about an hour long. It isn't
about growing a village. It's about what the men go through to support the people waiting for
them at home.

**Pillars**

- **Hardship for the ones at home.** Every choice weighs the men's safety against what they can
  bring back to their families.
- **The shifting season.** The forest changes around them from green to gold to bare and
  snowbound. That change is both the art and the main mechanic.
- **Small men, giant forest.** Twenty named men, never more, in an old forest that should make
  you feel small.
- **Homecoming.** The village is only seen twice, when they leave and when they return. Coming
  home is the emotional payoff of the run.

## Core loop

A run is one long journey through the forest and back. The men leave in summer, gather and hunt
as they go, find ruins and other places to learn from, get through winter in the woods and walk
home in spring. There are no jobs to work. The journey is the game.

The way home is the hardest part. The men are carrying the most when they're slowest, the
leaves are down, and the caches they left are easiest to find. The run ends when they reach the
village. What they bring back, and who is still with them, is the score.

## The builders

Twenty men leave and no more ever join, so every one who comes home matters. Each has a name,
looks a little different, and has someone waiting at home. They all share the same verbs:
**build, chop, shoot**, plus carry and gather.

- **Kit.** Traditional dress: white shirts, dark wool and red sashes. They carry stone hammers
  and long rifles with swallow-tailed butts.
- **Carrying is people.** Each man carries a fixed load. Lose one and you lose his load too, so
  losses compound.
- **Who waits at home (Proposal).** Each man's panel shows who he's working for, like a wife, a
  mother or children. Losing him is felt at the homecoming, not just in the numbers.
- **Needs.** Hunger, warmth and rest. When one runs out the man slows down, then his health
  starts to drop.
- **Craft.** No classes. Men get slowly better at what they do, and learn new techniques from
  what they find, like Roman ruins. Those techniques are part of what they bring home.

## The forest

Trees are the main character. They're giant, units walk between and beneath them, and they
change with the season. Each tree does three jobs:

| Role | What it does | How the season changes it |
|---|---|---|
| Resource | Wood, bark, nuts, mushrooms and game around it | Food peaks in autumn and is gone by winter |
| Cover | Units under a canopy are harder for bandits and animals to spot | Cover shrinks as leaves turn and fall, so it's gone in winter |
| Hiding place | Caches can be stashed at the base or in the hollow | A cache that was well hidden in summer can be in plain sight by late autumn |

- **Felling is a trade.** Cutting a tree gives a lot of wood but removes cover and hiding places
  for good, both for you and for the route home.
- **Undergrowth.** Ferns and bushes give low cover that lasts a bit longer into the year than
  the canopy does.
- **The route.** The map runs from the village, through valley forest, up into the mountains.
  Higher ground turns colder sooner, so the season runs ahead of you as you climb. Deep woods
  are one mood among several: beech clearings, dark fir, bare ridges, gorges with ruins.
- **Trees of the Rhodopes.** Beech, Scots and black pine, fir and spruce. A few old giants, mature
  trees, and lots of young trees and saplings the men can fell.

## What they bring home

The point of going is what comes back: goods and new knowledge for the families at home. Weight
is the cost, since the more the men carry, the slower they walk.

- **Pay and goods.** Gathered, cut and hunted on the way: food, hides, wood, herbs, and anything
  worth taking from the places they find. Goods are what keep the village through the next
  winter.
- **Knowledge.** New techniques learned from what the men find, like how to build Roman drains
  after studying old Roman ruins. They weigh nothing but take time to learn, and each one
  changes life back home.
- **Carts.** Built from wood on the road. A cart carries far more than men can, but it's slow and
  can't go everywhere a man can.
- **Caches.** Drop goods on the way out and pick them up on the way back, so they only weigh on
  the last leg. Animals or patrols can find them, and the falling leaves expose them over time.
- **The homecoming.** The run ends at the village in spring. The families come out to meet the
  men, and anyone lost is remembered by name. Then a closing cutscene shows the village in the
  years after, changed by what they learned, like Roman drains in the fields. Every piece of
  knowledge brought home shows up as a visible upgrade.

## Threats

The season is the main enemy. Wolves, bears and Ottoman patrols are the dangers in the forest,
and every one gets worse as cover thins out.

| Threat | Behaviour | Counter |
|---|---|---|
| The season | Cold, food running out, snow closing the passes | Move fast, carry fuel, set off for home in time |
| Wolves | Hunt in packs at night, circle a camp and pick off stragglers | Fire keeps them back, stay together, rifles |
| Bears | Drawn to food and caches in autumn. Asleep in winter, waking hungry in spring | Avoid dens, guard the food, rifles at range |
| Ottoman patrols | Move along roads and valleys. Will fight the men and take goods | Fight like a bear: rifles from cover, or hide under canopy and let them pass |

**Proposal:** threats are only visible in a man's line of sight. Thinning cover then works both
ways, since you can see further but so can they.

## Day, night and camp

The game runs in real time, with a day and night cycle. At dusk the men make camp, and the
player decides about the fire:

| Choice | Upside | Downside |
|---|---|---|
| Keep it burning | The only way to cook and feed the men. Warm, and wolves stay back | Smoke and light can be seen by patrols and bears |
| Put it out | Hidden, but nobody eats properly | Cold. Late in the year some men may fall ill |
| Walk on through the night | Gains time on the season | Nobody rests, so the men are slow and clumsy the next day |

Sleep restores rest, but the men always wake hungry, so every night uses food. **Proposal:** a
night takes about a minute of real time, so it's a beat rather than a chore. A pause that still
lets you give orders is worth trying.

## Art and audio

The game should feel very atmospheric. Everything about the art comes from the trees, leaves
and ferns, and their colours set the palette, shapes and softness of everything else. It's the
Age of Anything look, with darker, moodier lighting.

- **Scale.** Trees are several times their Age of Anything size. The camera sits under the
  canopy: trunks run off the top of the screen, the canopy shows as a fringe of leaves and
  dappled light, and the men move between the trunks.
- **Season as palette.** Deep green in summer, then gold and rust, then bare, snow-dusted
  branches, and the first green again on the way home. The change should be gradual and
  visible minute to minute.
- **Light and weather.** Light shafts and haze in summer, firelight at dusk, mist and falling
  snow in winter. Night is properly dark, so a fire really matters.
- **Leaves as a signal.** Falling leaves and a thinning canopy show how much cover is left, with
  no need for a meter.
- **The village.** Seen only at the start and the end. The homecoming scene should be the most
  crafted moment in the game. A wide opening cinematic introduces the forest, the wilderness
  and the village.
- **Audio.** Wind in the canopy, birds, distant wolves, the crunch of snow, the fire. The
  soundscape changes with the season, from busy summer to near-silent winter. The music plan is
  in [`music-and-sound.md`](music-and-sound.md).

## Engine: what Creel needs

Recommendation: build Smyana as its own game pack on Creel, not as a mod of Age of Anything.
Most of the engine carries over as is. The new work is mainly giant trees and the season clock.
These estimates came from a quick read of the engine code, so they're rough. Engine work as it
happens is recorded in [`../archive/engine/`](../archive/engine/).

| Area | Keeps from Creel | New or changed for Smyana | Size |
|---|---|---|---|
| Camera and view | 2:1 isometric, 96 x 48 world tiles, 8-facing voxel units, y-sorted draw | Canopy layer drawn over units, fading or cut away around selected units | Medium |
| Trees | Tree models with stages (standing, felled, sawn, stump) | Giant multi-tile trees: small trunk footprint, large non-blocking canopy. Leaf stages per season baked as extra looks | Large |
| Seasons | Fixed 20 Hz integer sim tick | A season clock in the sim that drives leaf cover, food yield and temperature. The view picks a palette and tree look from it | Medium |
| Lighting | Day lighting | Lighting moods: summer haze, dusk and firelight, night, mist and snow | Medium |
| Cover and sight | Fog and line of sight | A concealment value under canopy and in ferns, read by the sim's spotting checks | Medium |
| Units | Workers, gathering, combat, voxel bodies | One villager body with 20 looks. Needs meters (hunger, warmth, rest) as new per-unit columns | Medium |
| Economy | Gathering and carrying | Band-wide load and a speed penalty, carts, caches as hidden stockpiles | Medium |
| Time of day | None | Day and night lighting tint, a camp command with three choices | Small |
| Maps | ASCII maps, flow fields | One long route map from village to mountains, larger than a match map | Medium |
| AI | Bots that issue commands | Wolf pack, bear and Ottoman patrol behaviours instead of a rival civilisation | Medium |

What stays out: ages, tech trees and race generation from prompts, since Smyana has one fixed
people.

## Open questions

- [ ] Besides Roman ruins, what other places can the men find, like monasteries, shepherd huts
      or old mines?
- [ ] Can Ottoman patrols take men prisoner, or only kill and rob?
- [ ] What is the fictional village called?
- [ ] Which pieces of knowledge can be brought home, and what upgrade does each one show in the
      closing cutscene?
- [ ] What does the village look like, at departure and at the homecoming? (Needs a redesign.)
- [ ] Opening and closing cinematics.
- [ ] Voice acting: who speaks, and in what language?
