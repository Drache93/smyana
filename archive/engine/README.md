# Engine work (Creel)

Smyana runs on Creel, the engine from Age of Anything. We extend Creel alongside the game, so
each time the game needs something the engine can't do yet, the change is made in Creel and
recorded here (D-003).

One file per change or batch of changes: `YYYY-MM-DD-short-title.md`, using this template.

```markdown
# YYYY-MM-DD: Short title

**Who:** Dominic + Claude
**Creel change:** link to the commit or pull request in the engine repo

## What the game needed
Which part of the game asked for this, and why.

## What changed in the engine
What was added or changed, in plain words. Note anything other Creel games
(like Age of Anything) need to know.

## Pictures
Before and after: ![caption](../images/YYYY-MM-DD/NN-name.jpg)

## Decisions
- D-0NN: one line (full entry in ../decisions.md)

## Left to do
- ...
```

Add a line to [`../timeline.md`](../timeline.md) for each entry.

## What's coming

From the design doc ([`../../docs/design.md`](../../docs/design.md)), the engine work this game
is expected to need:

- **Lighting moods:** summer haze, autumn dusk and firelight, night, mist and snow. In progress.
- Giant trees: a small trunk footprint with a large canopy that doesn't block, and seasonal
  leaf stages.
- A season clock in the sim that drives leaf cover, food and temperature.
- Cover and concealment under the canopy and in ferns, read by the spotting checks.
- Day and night, and a camp command.
- Needs (hunger, warmth, rest) per unit; band-wide load, carts and caches.
- Wolf, bear and Ottoman patrol behaviours.
- One long route map from the village to the mountains.

## Entries

*(none yet)*
