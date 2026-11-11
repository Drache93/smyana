# Moods that turn, a light for each season, and men you don't lose (2026-11-11)

Dominic, when the dark-wood PR merged: "but you're not done there, why did you stop?"
([his words](../notes/2026-11-10-lighting-and-mood.md#when-the-dark-wood-pr-merged-2026-11-11-0544)).
So this pass went on to the three lighting issues: moods (#14), seasons (#11) and seeing the men (#7).
Every frame is the trees thread's comparison scene (`leg:camp_look camp:28,31 look:30,30 zoom:2.75`).

## The day turns instead of switching (#14)
Moods used to switch on the hour, so dusk came on at 18:00 in one frame. Creel now has
`atmo_set_between`, which mixes every number and colour of two moods. Smyana's `hours._blend`
(1.5 hours) is how long before a mood starts the one before it turns into it. So the afternoon goes
gold, then dusk falls, then the night comes in. The light is set again only when the turn has moved
a step (48 steps).

The night was flat: grey and washed out, with the dark wood lighter than at dusk. Now it is
moonlit blue, darker and with more contrast, with the fire as the light and the deep wood dark and
misty under its canopy.

![An autumn afternoon into night](../images/2026-11-11/01-autumn-afternoon-into-night.jpg)

## The men stay readable (#7)
With the canopy shade, the dusk and the night, the men sank into the dark. Dominic wants as little
UI as possible, so the light should show them, not markers. Where a man stands is now marked in
the shade buffer, in its blue channel, drawn back to front so a tree in front of him still hides
him. The atmosphere pass then gives the men a little less shade, wood and mist, and a little light
(`unit_lift`: 0.35 to 0.4 by day, 0.55 at dusk, 0.7 at night). The effect is subtle by day: white
shirts show. At night they read as men, not shadows. In each pair the frame on the left is before.
The day pair is at 16:30 against 16:00, so the fire differs a little.

![The men before and after, by day and at night](../images/2026-11-11/03-men-kept-readable-before-and-after.jpg)

## A light for each season (#11)
Only autumn had its own day light. Summer and spring used the plain day, which read as bright omni
light, and winter's snow was glaring white. There are now `day.summer`, `day.spring` and
`day.winter` moods, matched to the summer and first-snow mock-ups (archive pictures 15 and 17):
- Summer: warm yellow-green, with mist in the deep wood.
- Spring: fresher and softer.
- Winter: cold blue-grey, the snow greyed down and hazy.

The canopy shade gives each season the same dark wood round a lit clearing. Winter's bare trees cast
no canopy.

![Summer, spring, winter and autumn by day](../images/2026-11-11/05-a-day-in-each-season.jpg)

## Left to do
- Dawn has no season variants yet. Dusk has only autumn's.
- Moods don't yet blend between seasons, because the season changes by place.
- Dappled light moving on the ground (#7) is still to do.
