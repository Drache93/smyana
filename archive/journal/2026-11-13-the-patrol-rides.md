# The patrol rides

2026-11-13. Claude, for Dominic.

Dominic, 06:03 UTC ([his words](../notes/2026-11-13-dominic-big-old-trees-and-the-mounted-patrol.md)): "Patrol have
horses. Need to think how it happens... Real goal is random.encounters". The rules are in `docs/threats.md`
("Riders and chance meetings"), still a proposal for him to agree.

## What was built

- **A horse** (`data/voxel/bodies/horse.json`), and the patrol's four looks riding it. Creel's riders sit astride a
  mount's seat. The horse's coat changes with the rider's look: bay, grey, chestnut, black.
- **Riders on the trail.** They set out from the ridge, 36 hours behind. Each place has a brisk time
  (`brisk_h`). Daylight the men spend there past that brings the riders nearer. At no hours behind, they ride in by
  the edge the men came in by. Beaten, the trail goes cold. Left behind, they stay six hours back.
- **Chance meetings**, one place in four by the run's seed (`seed:<n>`), never two places running. A patrol is
  camped off the trail, resting on it for an hour or two, or guarding the ruins, with its horses tied near.
- Patrols get down to fight (`patrol_dismount`) and up again to ride (`patrol_mount`).

## Testing

- A full playthrough (`script:play fast:40 fresh`) passed. The riders caught up in the gorge and again in the fir
  woods, where the men beat them and the trail went cold. A camped patrol was met at the pass. 19 of 20 men came home.
- The first playthrough stuck: the bot kept aiming at a wolf the men could not get at, for three days. The bot now
  leaves a foe be after three hours, and never aims at a horse.
- The riders made every start slow (5 s, not 2). The horse's walk cycle was saved under two keys, so each start
  measured it again. It is now saved once.

## Not yet

The camp's fire, the horses, smoke and voices heard first, the wary music, and the pass patrol riding. The riders'
legs are white like their trousers on foot. I had thought of navy, but I have no evidence for it.

## Pictures

- [15](../images/2026-11-13/15-a-patrol-met-guarding-the-ruins-horses-tied.jpg): a patrol met guarding the ruins,
  its horses tied by the wall.
- [16](../images/2026-11-13/16-the-patrols-riders-four-looks-two-sides.png): the four riders, from two sides.

## The riders' legs

Dominic, 08:28 UTC: "there legs are cutting through the horses". Creel set the legs of a rider a fixed distance out,
narrower than the horse's barrel, and too short, so the shins ran inside it. Now the shin hangs straight down at the
horse's widest point along it, found from the horse's own shapes (Creel PR 33). A rider's seat sets its leg length;
the men's are 9 and 8.5 body units, so their boots hang below the belly. [17](../images/2026-11-13/17-riders-legs-before-through-the-horse-above-after-down-its-sides-below.png):
before above, after below.
