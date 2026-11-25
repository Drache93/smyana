# The eleventh first-time play: the homecoming and the ending (2026-11-24)

An agent played the last place by hand through `tools/playtest.sh` (`leg:village_home by:east goods hour:9`), without reading the game's code or docs. Its report, as it gave it. Note: the harness counts the run's clock, which stands still while the end's words are up, so the agent never saw the screen that says how many men came back; a person at the game does.

## Playtest report: Smyana, last leg (village_home, from the east, with goods, 9h)

**Verdict:** I got all 20 men home, but the game never reached an ending. It played five lines of text over a frozen village and then stopped dead at 8:12 on its own clock. There was no result, no end screen, no menu, and nothing I pressed did anything.

I used 43 pictures, all in `/tmp/smyana-playtest-11/`. The harness is stopped. I read nothing outside the two allowed files, apart from the harness's own `game.log` to check the clock once the picture stopped changing.

## 1. What happened

- **Title menu (0001).** "Смяна" in large letters over the forest with the band standing in it. "Start" and "Quit" are small, pale, and drawn over the men; "Start" sits on top of a man. One click started the game.
- **Start of play (0002).** Words over the men: "The track goes on across this place. That way." Bottom hint: "Drag across the men to choose them". A ring at the left edge is labelled "The way on".
- **First drag (0003).** My first drag-select and right-click did nothing: no rings, no movement, hint unchanged. New words: "Game keeps to the quiet ground over that way. Meat for the road, if we come up on them slowly." A second ring appeared, labelled "Right click to go and look".
- **Second drag (0004).** This time it selected. Faint rings appeared under the men, plus a small bar of icons (fire, pack, hand, four loaves). Hint: "Right click to send them".
- **The walk (0005 to 0022, about 0:20 to 6:10).** I right-clicked "The way on" over and over. Each click moved the men about a quarter of a screen, then they stood.
- Rain came and went. They waded a stream twice.
- Words seen or logged: "The birds have had the best of this one. There will be better bushes."; "Roe deer, there among the trees. Meat, if we come up slow and stop short of them."; "A shepherds' hut, off the track there. A roof for the night, if we want one."; "Strawberries!" (twice); "The men are tired, and hungry with it. A fire, a meal and a night's sleep."; the "Game keeps to the quiet ground…" line a second time, from a different man.
- Hint seen once: "The wheel, or + and - brings the view closer."
- I ignored the deer, hut and strawberries and did not camp. Nothing bad came of it.
- **Arrival (0023 to 0024, about 6:10 to 6:35).** The marker turned north onto a cobbled lane with stone walls and two women standing by. One more right-click on it and the log said "leaving" then "home", and the homecoming music began. The icons and markers vanished and I lost control.
- **Walking in (0025 to 0026, 6:35 to 6:49).** The camera moved up the lane and came closer. The men walked in and spread out. The log said the screen was now "after".
- **The words (0027 to 0032, about 7:00 to 7:25).** One line at a time at the bottom:
- "The herbs and the mountain tea were hung to dry under the eaves, against the winter's coughs."
- "The wax went for candles, for the church and for the long evenings."
- "The hides were scraped and tanned. By autumn there were shoes for the children."
- "The wool was washed in the river and spun through the summer."
- "In late summer the men took down their rifles again."
- **After that (0033 to 0043).** That last line stayed on screen and nothing else changed. At 8:12 the homecoming music ended, the ordinary forest tune (09_spring_day) started, and the game's clock stopped for good.
- I tried a left click, space, Return, Escape, a camera key, and another click. Nothing changed.
- I then let it run a further two and a half real minutes. The picture was identical and the clock was still at 8:12, with the process using heavy CPU throughout.
- The log never said "the screen now: end".

## 2. The village

**What reads well.** It is clearly a stone mountain village and a pleasant change from the forest. There is a wide cobbled lane between low dry-stone walls, and two- and three-storey stone houses with timber bands, a jutting upper window and plank doors. A stone fountain trough stands by the lane. Thin smoke rises from four chimneys. There are women in black dresses, red aprons and white kerchiefs, a loaded pack horse on the left, and another animal (goat or donkey) top right.

**What looks wrong.**
- **The world ends in black.** The top-left corner of the screen is a flat black void; the lane, wall and grass are cut off along a straight diagonal. It sits there for the whole ending (0026 to 0043).
- **Dark squares on the lane.** Three or four big square patches of darker, bluish cobbles, like wrong tiles or shadows with nothing casting them. Men stand on them (0026, 0027 onward).
- **Lane end at the forest.** The cobbles stop in a ragged edge, with a pale see-through patch of cobble over the grass (0023, 0024).
- **The women are clones and do not react.** All seven or eight are the same figure, standing stiff, facing nowhere in particular. Nobody moves towards anybody.
- **A woman with a log through her.** The woman on the right of the lane has a long brown beam lying through her at waist height (0024, 0025, 0026 onward). It might be meant as a carrying pole; it reads as a log clipping through her.
- **The low house.** The house at the bottom centre has its roof at about lane-wall height, as if sunk in the ground. Men on the lane are nearly as tall as its roof ridge (0025, 0026).
- **Flat dark shape in the left yard.** A dark grey polygon lies beside the left house, with a log in it. It reads as a hole or a pond, not a shadow (0025 onward).
- **Grey clutter on the right house's roof.** I could not tell what it is: a nest, rubble, or a bug (0025, 0026).
- **Small green twig shapes** on the yard and grass that I could not identify (0025).
- **The smoke looks the same in every picture**, so it may not be animated.

## 3. The homecoming and the ending

**Did I understand it?** Half. I understood "we are home". I liked that the goods I carried turned into things in the village's year: herbs to tea, wax to candles, hides to shoes, wool spun. The last line tells me they will go out again, which fits a game called "Shift".

**What it never told me.**
- How many men came back. Twenty left and twenty came home, and the game said nothing about it.
- Whether I did well or badly, or what the goods were worth.
- That the game was over. No "The End", no title, no credits, no "thank you", no way back to the menu, no Quit.

**The picture fights the words.** The men stand scattered on the lane like statues with rifles still on their shoulders. No one puts down a pack, goes to a house, or meets a woman. The line "took down their rifles again" plays over men who never put them away.

**The text.**
- Readable but only just. It is thin pale serif with no backing, at the bottom over grass, wall and tree leaves. The last line in particular runs across a wall and a tree.
- Pace is fine, about 5 to 8 seconds a line.
- Nothing was cut off.
- There was about 10 seconds of silence with no words between "after" and the first line.
- During play, the men's spoken lines are drawn across the middle of the screen, straight through the men (0002) or as one very long line (0003).

**Did it end cleanly?** No. It froze on the last line, as described above.

## 4. Bugs and confusions

1. **Game freezes at the end (steps 33 to 43; `0033.png` to `0043.png`).** The last line never leaves. The clock stops at 8:12, exactly when 22_homecoming ends and 09_spring_day starts. No input works, and there is no end screen. The process keeps burning CPU. I cannot tell from outside whether it is a hang or a deliberate hold with a stopped clock; to a player it is a hang.
2. **Wrong music at the end (step 39; `0039.png`).** After the homecoming piece, the ordinary forest tune 09_spring_day starts over the ending, as if play had resumed. 23_ending never played.
3. **Black void at the map edge (steps 26 to 43; `0026.png`, `0027.png`).**
4. **Dark square patches on the lane (steps 24 to 43; `0026.png`, `0027.png`).**
5. **No outcome or count shown (steps 27 to 32; `0027.png` to `0032.png`).**
6. **Men frozen with shouldered rifles and identical frozen women through the whole ending (`0028.png` to `0036.png`).**
7. **Woman with a beam through her (`0025.png`, `0026.png`).**
8. **Ragged lane end with a see-through cobble patch (`0023.png`, `0024.png`).**
9. **Sunken low house (`0025.png`, `0026.png`); unexplained dark polygon in the left yard (`0025.png`).**
10. **Clock goes backwards (step 27; log at 7:00).** It says "8h" after a whole walk at "9h". The hour also never moved from 9h in six and a half minutes of walking.
11. **First drag-select ignored (step 3; `0003.png`).** The same drag worked at step 4. It may be the harness's first input after the menu, but a player would see their first action fail.
12. **"The way on" only ever sits at the screen edge (steps 5 to 20; e.g. `0006.png`, `0012.png`).** Each right-click buys a quarter-screen of walking, then the men stop. It took about 15 clicks to cross the map.
13. **Camera overshoot (step 21; `0021.png`).** When I scrolled left to click further ahead, the marker turned out to be behind me to the north-east. Nothing shows the route bending north to the village, and the track itself vanishes for a stretch (`0016.png`, `0017.png`).
14. **Strawberries look like a glitch (steps 14 to 17; `0014.png` at about 1090,195; `0015.png` at about 1550,352).** A flat smear of red and green pixels that seems to sit on top of a tree's leaves. They look more like a plant in `0016.png` and `0017.png`.
15. **Men in tree shade go nearly black; some go pale see-through green behind leaves (`0014.png`, `0015.png`, `0017.png`).** Selection rings are very faint (`0004.png`).
16. **"The way on" label drawn under the men on arrival (step 23; `0023.png`).** Nothing tells you that standing there is not enough and you must click it once more.
17. **"The men are tired, and hungry" (step 17) led to nothing.** I ignored it with no consequence, and the four loaf icons never changed.
18. **Repeated bark.** The "Game keeps to the quiet ground…" line was said twice by different men (steps 3 and 22).
19. **Menu text (`0001.png`).** "Start" and "Quit" are low contrast and "Start" is on top of a man.
20. **Arrival is abrupt (step 24).** Control is taken with no word. A line as the lane comes into view would help. The men also bunch into a tight clump whenever they stop, and stand in the stream (`0008.png`).

## 5. The three things that most need fixing

1. **The ending does not end.** Stop the freeze at 8:12. After the last line, fade out, show a clear end (title, how many men came home, "The End", credits), let a click or key return to the menu, and do not start the forest music.
2. **The homecoming is a still photograph with no result.** Have the men lower their rifles and packs and walk to the women and houses, and have the women come to meet them. Say plainly how many came back and what the goods bought.
3. **The village's visible defects in the final shot.** In order: the black void at the top left, the dark square patches on the lane, the beam through the woman, the sunken house and the dark yard polygon. Also put a dark band or shadow behind the ending text so it reads over grass and leaves.
