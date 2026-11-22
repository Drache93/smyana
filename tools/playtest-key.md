# What the log's names mean (you cannot hear; this is what a player would hear)

Lines come back from each step with the game's clock on them (minutes:seconds a player has spent).

- `heard: 2:10 music begins: <track> (calm|danger|moment)` and `the music ends`.
- `heard: 2:31 <sound>, close | not far off | far off, to the left | to the right`.
- `said: 3:02 <name>: "<words>"`: words that appear over a man's head.
- `clock: 3:30 <place>, <season>, <hour>h, <n> men`: every half minute.
- `clock: ... the picture at the pointer is now: ...`: what the mouse cursor looks like (pictures do not show it).
- `heard: 1:07 rain on the leaves, coming up` / `... fades away`: a steady sound of the forest rising or going.
- `deaf: ...` and `(unstick: ...)`: notes for the developers; ignore them.
- `clock: ... the screen now: menu | play | leaving | letter | arriving | end`.

Music tracks (all synthesised sketches of Bulgarian folk instruments; a first draft):
- 01_summer_day: flute (kaval) and plucked lute, unhurried and bright, bells far off. About 2 minutes.
- 02_summer_dusk: one bowed fiddle over a soft drone, warm, a little homesick.
- 03_autumn_day: flute in mist, men humming far away.
- 04_autumn_dusk: one low bagpipe, as slow as it can go, a low flute far off at the end. The most finished track.
- 05_autumn_night: low fiddle, long gaps, the drone barely there.
- 06_winter_day: almost nothing: wind, single lute notes, a flute phrase now and then.
- 07_winter_night: one man's voice, unaccompanied.
- 08_spring_morning: a quick bright tune, flute, lute, bells.
- 09_spring_day: the main theme hinted on flute, women's voices far off.
- 10_wary: no tune, low drone, single damped notes. 11_hiding: a low fiddle that barely moves, a stray drum beat.
- 12_beasts: drum and drone only, fast uneven hits. 13_bandits: drum, bagpipe, fast and hammering.
- 14_ottomans: a shrill reed pipe and a big drum. 15_chase: the fastest track.
- 16_end_stroke: one drum blow with its echo, when danger ends.
- 18_a_man_dies: a short lament, one voice. 19_the_fire: the men hum together at the camp fire.
- 21_leaving_the_village, 22_homecoming, 23_ending, 24_menu.
Calm tracks play through once and the next begins about a second later.

Sounds:
- pan, boom_wood / boom_valley / boom_gorge / boom_open: a flintlock rifle fired near (the flash in the pan, then the bang, with that place's echo). far_*: a shot far off.
- cock, pour, rod, ram: a man reloading his rifle (about 18 seconds).
- howl, far_howl, snarl, yelp: wolves. bear_huff, bear_roar, bear_swipe: a bear.
- The forest (since 2026-11-23): steady beds that fade in and out (the wind in the trees, birdsong, crickets, rain on the leaves, the stream, the fire crackling), and single bird calls: cuckoo (spring), woodpecker (summer), jay (autumn), raven (winter), owl (night).
- The men (since 2026-11-23): their footsteps are a steady sound under everything while they walk (not in the log); `men wading`; `ack`: a man's low "hm" in answer to an order; `gather`: hands in leaves; `knife`: butchering; `pack_down`: packs set down; `fire_light`: flint and steel, then the tinder catching.
- A volley is thinned: only some of the guns that fire in the same breath are heard, so the log shows fewer shots than men.
