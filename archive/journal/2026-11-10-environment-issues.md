# 2026-11-10: The environment as issues

## What happened

Dominic asked to start breaking the game into GitHub issues, starting with the environment, and
asked whether the map should load in whole or in chunks as the men move. He also wanted an issue
on our side linking to Creel's lighting and atmosphere issue, Casaide/creel#5
([his words](../notes/2026-11-10-dominic-in-his-own-words.md#breaking-the-game-into-issues)).

Claude read the design doc and Creel's code. Creel loads a map from one JSON file and keeps
everything about it as grids the size of the whole map: terrain, walk grids per movement class,
fog, flow fields that each cover the whole map, the ground's textures, and save code generated
from the sim's globals. Streaming chunks would mean rewriting all of that and keeping the sim
deterministic as chunks come and go. The run, though, is already a chain of about seven places,
each played for 5 to 10 minutes and visited twice. So Claude recommended one map per place,
loaded whole behind the letter home between places (D-020). Dominic asked whether that meant a
loader; it does, but shown as the letter rather than a loading bar, and probably a few seconds
long (not yet measured).

Claude drafted 15 issues under a parent, Dominic said "List is good", and they went up as #3
(the parent) and #4 to #18:

| # | Issue |
|---|---|
| 4 | Load each place as its own map, and carry the run across |
| 5 | Lay out the route |
| 6 | Rhodope trees |
| 7 | See the men through the foliage |
| 8 | Undergrowth and ground cover |
| 9 | Cover and concealment |
| 10 | The season clock |
| 11 | The seasons on screen |
| 12 | Track Creel's lighting and atmosphere work (Casaide/creel#5) |
| 13 | Day and night |
| 14 | Lighting moods for each place and season |
| 15 | Weather |
| 16 | Ground for the route: slopes, rock and water |
| 17 | Places to find: the Roman ruins |
| 18 | Frame budget for a dense forest |

Along the way Dominic set two rules: the Steam Deck is out of scope for now (D-022), and the UI
should be extremely minimal, if not none, so the focus is on the environment (D-021). Both went
into the issues.

## Notes

- The plan was to label engine issues `engine`, but the label doesn't exist in the repo and
  can't be made from Claude's tools, so those issues say **Needs Creel work** at the top instead.
- Left for their own groups of issues: the village set and cinematics, caches as a mechanic, the
  wolves, bears and patrols, and the sound of the forest.

## Later: the obstacles

Dominic added the environmental obstacles: fixing a bridge, fording a river, and a landslide,
which for now is found after it has happened rather than seen happening (D-023). They went up
as #20 under the parent, and #16 (the ground) now points to it.
