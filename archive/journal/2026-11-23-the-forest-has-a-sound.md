# 2026-11-23: the forest has a sound

Monday of the final push (docs/final-push.md). Until today the wood was silent but for guns, wolves and a bear.

- `sound/forest.py` makes six looping beds and five bird calls from noise and sine waves, no samples
  (assets/audio/sfx/amb_*_1.wav, cuckoo, woodpecker, jay, raven, owl).
- `src/smyana/ambience.lobster` fades each bed by what is on the screen: wind always and more in weather and winter;
  birds by day, a chorus early, most in spring; crickets on warm nights; rain with the rain; the stream near water
  in view; the fire near a lit one. A bird calls every 25 to 70 seconds. D-147.
- The agent player's log now says what would be heard ("rain on the leaves, coming up"), and its key is in the repo
  (tools/playtest-key.md).

Claude cannot hear. The loops were checked for a seamless join and for level, and looked at as spectrograms. Whether
the birds sound like birds is for Dominic to say.

Not done: footsteps, the men's voices, sounds for gathering and butchering and orders (Tuesday).

## Then the men (Tuesday's work, begun early)

`sound/men.py`: footsteps on leaves and snow and wading as beds, and an order's "hm", gathering, the knife, packs
set down and a fire being lit as single sounds (D-148). A volley is thinned so seventeen guns are not seventeen booms
in a second. Seen working in the playtest harness's log: ack on an order, pack_down, fire_light, the fire coming up.

## The hut and the scattering band (from the third agent playtest)

- The hut showed the flame cursor and then "No way through there": the men were all sent to the first open tile
  found beside it, which could be one behind it that nobody can walk to. Now each goes to one of the six open tiles
  round it nearest the men, and the camp is made when the first is within three tiles. Not yet seen in a played run
  (the test bot did not go to a hut in the run tried).
- A gathering order on a far stand sent four pickers off and left the rest, and the band was in pieces. Now the rest
  walk with them and wait four tiles short of the stand, and a picker who is done walks back to the others.

## Second pass, from Dominic's ear

Dominic listened to both reels (his words: `archive/notes/2026-11-23-dominic-the-sounds.md`). Kept: wind and leaves
("great"), rain ("good"), the fire's crackle, footsteps ("pretty good"). Remade by Claude the same morning (D-149):

- **Birds** ("robotic, like data"): pure sliding sine chirps on a grid. Now each note's pitch wanders and flutters,
  has air in it, and the eight singers sit mostly far off with silences between phrases.
- **Stream** (heard as "lightning"): slow loud surges of low water. Now a steady bright wash, a shallow quick ripple
  and many small bubbles.
- **Fire** ("something blow hard on the fire"): the low flame flutter was loud. Cut to almost nothing; more small
  cracks, fewer big ones.
- **Footsteps** ("cut a bit at high or low band"): the thud stopped at 260 Hz and the brush sat between 900 and
  5200 Hz. Now both slope gently across the whole band.
- **Wading** ("pushing sand around"): it was a push of filtered noise. Now it is bubbles: a low plunge, a gurgle that
  thins out, drops falling back, and only a breath of spray.

All of it is still made unheard, by numbers. Sent as `sound-reel-02`.
