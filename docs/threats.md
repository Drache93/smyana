# Threats and the fight

*Claude's design, 2026-11-12, written before building, for Dominic to change. Everything here is a **Proposal**
until he agrees it. It follows the design doc's "Threats" table, the world plan's legs (`world.md`) and issues #60 to
#64. Dominic's word on it so far: "All that matters is some fighting vs people that also have guns" (2026-11-11), and
"Let's start on the guns. And the risks phase after" (2026-11-12).*

## What every threat shares

- **Nothing on the screen but the world.** No health bars, no alert icons, no minimap dots. A threat is heard before
  it is seen (a howl, voices, a far shot, a branch), then seen, and the music tells you it has seen you.
- **They find the men only by cover.** Every threat looks with the same check the cover work made (`spots`, D-064):
  canopy, young trees and bracken hide a man, night and weather shorten everyone's sight. So the leaves falling make
  every threat worse, and a man standing still under a fir is hard to find all year.
- **A shot gives you away.** Everything within hearing of a shot (about 25 tiles in a wood, more in the open) learns
  roughly where it came from, and the smoke hangs over the man who fired for as long as it hangs (D-081). To hide is
  to hold fire.
- **A threat has a small mind with four states:** *unaware* (on its way, does not know the men are here), *wary*
  (heard or smelled something, comes to look), *hunting* (has seen a man, goes for him or fights), *gone* (lost them,
  broke off, fled or dead). It loses the men when it has seen none of them for a while, searches the last place, then
  goes back to what it was doing.
- **The music follows the state, never a timer.** Wary: the "wary" loop. Hunting: the threat's own loop (the beasts,
  the Ottomans; the chase when the men run in the pass). Everything gone or lost: the end stroke over the cut and
  quiet (D-042, the music system in PR #103). A threat that only follows at a distance (the early wolves) stays
  "wary".
- **A hit is seen, not counted.** A ball that misses throws up a little dust, snow or splinters where it lands. A man
  who is hit jerks back, and the first hit wounds him (he walks slowly). A second hit, or one very close, kills him
  (#64). The beasts are the same with more to them.
- **A flintlock misses a lot.** Close, a shot nearly always hits; at the rifle's full range it hits about one time in
  four; a man in good cover is half as easy to hit. Numbers in `data/threats.json`.

## The Ottoman patrol (built first)

The one enemy with guns. Bandits are folded into it for now (#49). A patrol is six to eight men on foot: zaptiye in
fezzes and dark blue coats, a few with the white cloth of a turban wound round the fez, a green sash where the men
wear red, and long flintlocks of their own. They reload as slowly as the men do.

- **Unaware:** they walk their road (a line of points in the leg's data), talking now and then.
- **Wary:** a shot, or smoke hanging, or (later) a fire's light: they turn off the road toward it, spread a little,
  and come on slowly.
- **Hunting:** a man seen in range is fired at, each patrolman in his own time like the men (D-082). They close in on
  the last man they saw, stopping to fire and reload. They never walk into cover they can't see into without
  shooting first.
- **Breaking off:** when half of them are down, the rest fall back the way they came. When none of the men has been
  seen for 40 seconds, they search the last place for a while, then go back to the road and on off the map.
- **What the player can do:** fight from cover (hard to see, hard to hit), lie still under the canopy and let them pass,
  or run. Each choice costs something: a fight costs men and smoke, hiding costs time, running costs the load (phase 3).
- **Where:** seen far below on the ridge (leg 7, they never come up); the set piece in the pass in the first snow
  (leg 8, D-076, D-077: they come up the ramp behind the men).
- **Open (#62):** whether they take men prisoner. Until Dominic decides, they only kill.

## The wolves (next)

A pack of five or six, in the deep fir woods.

- **Early autumn, on the way out (leg 3):** they follow at twelve to sixteen tiles, are heard far more than seen,
  and never close in. Their howls are the first sign the woods are not safe. A shot scatters them for a minute.
- **Deep winter, on the way home (leg 11):** bolder. At night they circle a camp and go for a man who is more than
  four tiles from any other, fast, all at once. A pack that loses two wolves runs. A lit fire keeps them six tiles
  off (the fire's part comes with phase 3, #68).

## The bear (after the wolves)

One bear, in the beech valley at the thaw (leg 12), when there is no cover left.

- **On the way out:** only signs of it, a scratched trunk and tracks by the stream.
- **At the thaw:** it wanders, hungry. If it sees a man close, it stands and huffs, then charges short and stops (a
  bluff). Shot, it charges for real. It takes four or five hits, and runs when it is badly hurt.

## A man dies (with the patrol)

Each death is felt (#64): he falls where he was hit and lies there; the death's short lament plays (track 18), once
for a fight however many fall. What is left of him and his name for the homecoming come later.

## Order of building

1. **The patrol and the fight** (built 2026-11-12, D-085 to D-088; the pass, D-089), on a test bench like the range: `fight:` puts the men and a patrol on a map, with
   shots both ways, smoke on both sides, misses and hits seen, men falling, the music turning. Then the patrol in the
   pass (leg 8). Its voxel men are new looks of our men's rig.
2. **The wolves** (built 2026-11-12, D-090): a voxel wolf, the pack, howls.
3. **The bear**: a voxel bear, the bluff and the charge.
