# The final push: a plan, and men who can eat

*2026-11-22, Claude, thread "Plan the final push to submission".* Dominic's words are in
`archive/notes/2026-11-22-dominic-the-final-push.md`. The plan is `docs/final-push.md` (D-138).

Nine days before the deadline nothing had been merged since 13 November. Dominic asked for a plan first, then said to
go ahead with it once it was ready. While it was written he set its weights: music and sound are the biggest gap, the
first five to ten minutes need guiding, the village is a stretch goal beyond something to see when leaving and
returning, and the build is for macOS, the one machine we can test on. He also asked for an agent to play the game as
a first-time player as the work goes on (D-139).

## What the build did when played

Two fast playthroughs of main (`script:play fast:40`, seeds 1 and 2): all twenty men dead of hunger before the turn
for home, both times. The bread was gone by the gorge. No game was shot and about 34 portions were gathered. On 13
November two of twenty had come home, so the gathering change of that evening had made it worse. The opening picture
(image 01) shows the other gap the plan names: "the village edge" is a wood with no village in it.

## What was wrong

Mostly not the numbers. Five faults, each found by reading a run's log:

1. **The scouts walked past the game.** Sent down a side path, they walked to a point twelve tiles short of its end
   and only then looked. A deer that had wandered up the path saw them first and the herd was gone. Now they shoot
   what they see on the way, and at the path's end they go for the nearest beast as a player who sees it would.
2. **One rifle's worth from a herd.** Every man fired at the one beast, in his own time, and the rest ran at the first
   shot. Now the men share out the herd they can see, two to a beast, and fire together (D-140).
3. **A herd ran before the men could see it.** A deer that has noticed a man runs if he comes on to within two tiles
   of where it would run anyway. In the wood a man has to be at four or five tiles to see his mark. The margin is now
   half a tile.
4. **A day's hunting ended with no camp.** The test player still counted last night's camp as made. Men died of cold
   with bread in their packs.
5. **A camp nobody could reach.** The fire was laid at the middle of the chosen men. On the pass's shelf road, with
   four men out gathering, the middle was ground none of them could walk to (D-142). And at a shepherds' hut the
   test player's order to camp, given after the men had made camp there by themselves, put the fire out.

## The numbers that did change

- A kill gives twice the portions: a roe deer 24, a boar 60, a chamois 30 (D-141).
- A man with nothing to eat loses 0.8 health an hour, not 1.5. He lasts about two days, slow and weak, and mends when
  fed. Whole bands had died in one foodless day on the pass.
- The test player keeps seven days' bread a man before it caches the rest, not four: the pass, the ridge and the pass
  again are six days with little to find.

## What the playthroughs came to

More than twenty full runs over the day, three seeds at a time, about half an hour a set on the cloud machine.

| Build | Seed 1 | Seed 2 | Seed 3 |
|---|---|---|---|
| main, as found | 0 of 20, dead by the ridge | 0 of 20, dead by the ridge | not run |
| the scouts shoot, meat doubled | 0, dead in the gorge going home | 13 home | not run |
| with the camp faults fixed | 8 nearly home (stopped) | 0, a night on the pass with no camp | 8 home |
| with slower hunger | 13 nearly home (stopped) | 2 left at the ruins | 0, most to the patrol at the ruins |
| the stalking margin, seven days' bread kept | 11 home | 16 to the gorge, then lost at the hut | 13 to the gorge, then lost at the hut |
| the hut night fixed (this commit) | **11 home** | **12 home** | 13 alive, stuck at the gorge's west gate |

A run now shoots six beasts for about 186 portions of meat and gathers 65 to 78, against none and 34 in the morning.

## Still open

- **Seed 3 sticks in the gorge on the way home.** Eleven men are through the west gate and two stand a tile short of
  it for five days. It is the old fault of stragglers at a gate, not food. First thing tomorrow.
- **The patrol kills more than the winter now.** The test player fights every patrol it meets. A player who goes round
  them should bring more men home than it does.
- **The numbers are tuned on a test player.** The agent's first play (D-139) and Dominic's own are the real test.
- Deep fir woods and the high ground give nothing to gather in winter. Adding a plant there needs sources first.
