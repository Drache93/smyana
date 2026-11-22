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
