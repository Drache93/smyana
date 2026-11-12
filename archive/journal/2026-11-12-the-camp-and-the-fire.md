# The camp and the fire (2026-11-12)

Phase 3, resources and mechanics (#50), begun on 2026-11-12 from 15:17 UTC after Dominic's "next?"
([his words](../notes/2026-11-12-dominic-next-the-survival-phase.md)). Made by Claude. Decisions D-092 to D-094. No
Creel change was needed.

![The men round the fire in the snow, their breath showing](../images/2026-11-12/52-round-the-fire-in-the-snow-their-breath-showing.jpg)

## Design first

As with the threats, a plan before building: [`docs/survival.md`](../../docs/survival.md). It turns D-009 ("every
night is a choice between eating and being found") into the needs, the camp and the fire, food by place and season,
packs and weight, caches, the Roman drain and the tally, each one read off the world rather than a meter, and an order
to build them in. Carts are proposed to be cut. Everything in it is a Proposal until Dominic agrees.

## What is in

- **The needs** (`src/smyana/survival.lobster`, numbers in `data/survival.json`): each man is fed, warm and rested,
  kept on him between places. They fall with the hours, the work, the load, the cold and the walks between places.
  Low, they slow him; run out, cold and hunger take his health, and a man can die of a winter night in the open. He
  lies where he fell, as a man shot does.
- **Making camp** is one key, C, with men chosen. They find the most open ground nearby, stand round the fire's far
  side and flanks, and lay it: two bundles of wood off their backs, or most of a minute finding dead wood. C again puts
  it out, or lights it again. At night they sleep round it, feet to the fire, and wake at first light or at a shot.
- **The meal**: the first camp after five in the evening, a portion each from their packs (they leave with four days'
  food), hot and filling at a lit fire, half as good cold.
- **The fire's danger**: the wolves keep seven tiles off it (and the winter pack won't rush a man inside that), a
  patrol sees it at night from far off through any cover and comes to look, and the bear smells a camp with food in
  it and wanders round it.
- **Reading the men**: their breath shows in cold air; a cold man shivers standing; in a camp they face the fire.
  With one man chosen his name shows at the bottom left with a few words on how he is.
- **For a look**: `cd src && lobster smyana.lobster -- leg:fir_woods_home makecamp hour:18.5 zoom:3.5` (the men make
  camp as the place opens; `fresh` keeps them from getting hungry, cold or tired). The run check spends a winter night
  in the fir woods with half the men round a fire and half out in the cold, and checks the camp sleeps, eats hot,
  stays warm and rests while the others don't, the wolves keep off the fire, and a patrol passing sixteen tiles off
  sees the fire and comes to look. The walk of the whole route is checked with the men kept fresh.

![The men make camp in the beech valley at dusk](../images/2026-11-12/51-the-men-make-camp-in-the-beech-valley-at-dusk.jpg)

![Asleep round the fire, feet to it; the wolves kept off](../images/2026-11-12/53-asleep-round-the-fire-feet-to-it-the-wolves-kept-off.jpg)

## Found on the way

- The first camp in the winter fir woods had the men scattered three or four tiles round a fire hidden behind a trunk:
  the ring round the fire ran into trees. Now the camp goes to the most open ground within four tiles, and a man whose
  place is a tree takes the nearest open ground to it.
- The first camp order from the look option included the wolves (every unit in the place) and so put the men in a
  muddle; orders now go to men only.
- The breath, drawn into the lit world, came out the same blue-grey as the snow and could not be seen. It is drawn over
  the lit picture now, a cool grey in the art's own pixels.

## Left for later

- A tired man sitting down when he stops needs a sitting pose (later, with the other poses).
- Barks for hunger and cold come with the voices (#51).
- Next in the plan: food patches by place and season (#66), then packs and caches.
