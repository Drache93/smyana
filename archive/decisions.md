# Decision log

Append-only. Each entry: date, decision, who, why, and what it replaced. To change a decision,
add a new entry that supersedes the old one rather than editing it.

---

**D-001, 2026-11-10: Make an atmospheric survival game about villagers working away from home through the seasons.** (Dominic)
About twenty men from a village in 1800s Bulgaria travel out through the forest into the
mountains, gather resources, skills and knowledge, and race the seasons to bring them home.
Why: the competition theme is "Shift", and the shifting seasons are both the art and the main
mechanic. Source: the voice memos ([transcripts](notes/2026-11-10-voice-memo-transcripts.md)).

**D-002, 2026-11-10: Build it on Creel, the Age of Anything engine, with the same camera.** (Dominic)
Expanded and adapted, not a new engine. The trees are much bigger, so the men move between and
under them.

**D-003, 2026-11-10: Extend the engine in parallel with the game, and record engine work in this archive.** (Dominic)
Why: the game will keep needing things the engine doesn't do yet, starting with the lighting
moods. Engine entries go in [`engine/`](engine/).

**D-004, 2026-11-10: It's a demo: one run from summer to spring, in real time.** (Dominic)
Pause is worth trying. Several years in one game is for a later version.

**D-005, 2026-11-10: The focus is the men's hardship for the families at home, not growing a village.** (Dominic)
The village is only seen when they leave and when they come home. The homecoming is the big
emotional moment.

**D-006, 2026-11-10: The story is inspired by the builders of Kovachevitsa, in a fictional village.** (Dominic)
About 200 men with hammers and swallow-tailed rifles left Kovachevitsa for seasonal work and
came back with new skills, like building Roman drains. We use the story, not the name.

**D-007, 2026-11-10: The threats are the season, wolves, bears and the Ottomans.** (Dominic)
The men fight Ottoman patrols the way they fight bears: as a danger in the forest. Replaced:
bandits as a main threat (from the memos).

**D-008, 2026-11-10: A survival RPG built as an RTS, with no work sites or jobs.** (Dominic)
The game is travel through the forest: gathering, cutting, sleeping, fighting, surviving, and
coming across places like Roman ruins where the men learn something. Why: "jobs" felt dull.
Replaced: Claude's first design, which had the men working at sites.

**D-009, 2026-11-10: Fire is needed to feed the men, and it draws danger.** (Dominic)
Every night is a choice between eating and being found.

**D-010, 2026-11-10: Needs, crafts, undergrowth and the homecoming go in.** (Proposed by Claude, approved by Dominic)
Needs: hunger, warmth, rest. Crafts: men get better at what they do and learn techniques from
what they find. Undergrowth: low cover that lasts longer than the canopy.

**D-011, 2026-11-10: What the men learn is shown in a closing cutscene of the village, upgraded.** (Dominic)
After the homecoming. Each piece of knowledge brought home shows up as a visible change.

**D-012, 2026-11-10: The trees are Rhodope species, and the camera sits under the canopy.** (Dominic, from Claude's suggestion)
Beech, Scots and black pine, fir and spruce. The camera keeps Creel's angle but the canopy only
shows as a fringe and dappled light, so you can see the men. The forest mixes a few old giants
with young trees and saplings the men can actually fell, lots of undergrowth, and slightly
bigger men. Why: the first under-canopy mock-up had trunks far too wide to cut down.

**D-013, 2026-11-10: Deep woods are one mood among several, not the whole map.** (Claude's suggestion, Dominic: "let's try it out")
The route runs through beech clearings, deep fir, high ridges and gorges with ruins, and the
seasons change the same woods. Why: Dominic worried a whole game in deep forest would get
samey, while still wanting the feeling of deep woods.

**D-014, 2026-11-10: The title is Смяна (Smyana).** (Dominic)
Bulgarian for "shift": the change of the seasons, and a shift of work. Written "Smyana" in Latin
letters for the repo and the competition submission; the Cyrillic Смяна can go on the game's
imagery. Replaced: the working title "Shift". Also considered: Гурбет (Gurbet, the word for
going away for seasonal work), Листопад (Listopad), Преход (Prehod), Кръговрат (Kragovrat).
Dominic wanted a word for "shift" rather than gurbet.

**D-015, 2026-11-10: Keep the work in a public repo with an archive, the same way as Age of Anything.** (Dominic)

**D-016, 2026-11-10: Aim for a game of about an hour.** (Dominic)
Why: enough to cover the journey, the Roman ruins and the Ottomans in the pass properly.

**D-017, 2026-11-10: Keep every voice note and message from Dominic in the archive, in his own words.** (Dominic)
Why: so much of the game is made with AI that it matters to show where the direction, feel and
mood come from: the human behind it. Audio goes in `audio/`, text in `notes/`, and summaries
sit alongside, never instead. See [the statement in the archive README](README.md#why-this-archive-matters).

**D-018, 2026-11-10: Almost all of Smyana's art is made new in November.** (Dominic)
The trees, the forest and the foliage are all replaced, and very little art, if any, comes from
Age of Anything. The engine work (the lighting moods first) has already started. The Bulgarian
man was the first art test made for Smyana, even if Age of Anything may reuse him.
