# The camp

What the men carry and pitch on the road, as voxel models: the camp in the autumn mock-up
(`archive/images/2026-11-10/62`, left), made in the game's own style, crisp like the men.
Dominic asked for them on 2026-11-10: "the tents, fireplace, and our horses".

| File | What |
|---|---|
| `tent_canvas` | A canvas A-frame, 3.5 m long and 2.6 m high at its crossed end poles, the ridge sagging, flaps tied back on a dark inside with two bedrolls, seams, a patch, mud up the hem, guy ropes and pegs. |
| `tent_rugs` | A lean-to of striped Rhodope rugs (chergi) over a ridge pole on two forked sticks, 4 m long, its back weighed down with stones, a fringed flap at the front, packs and a bedroll under it. |
| `fireplace` | A ring of gneiss stones on a bed of ash, three charred log ends, a tripod of poles lashed at the top and a copper cauldron on a chain. The flames are the game's own (D-038). |
| `woodpile` | Split logs stacked crosswise on two bearers, a chopping block with an axe in it. |
| `hut` | An empty shepherds' hut at a side path's end (2026-11-13, D-131): walls of dry-stacked gneiss, a low gable roof of split slabs, a smoke gap at the ridge, one low door with a wooden lintel, no window; about 3.6 by 3 m. From summer-pasture huts of the Balkan mountains and the village's slab roofs: a guess to check against a Rhodope hut. |
| `horse_0..3` | Riding horses (bay, grey, chestnut, dark), about 1.5 m at the withers, saddled on a striped or felt blanket, stirrups, bridle and reins. |
| `mule_0..3` | Pack mules (and one bay pack horse) under a wooden pack saddle (samar) with a load: sacks and a rolled rug, kegs and tool hafts, wicker baskets, long poles. |

A voxel is one pixel of the art, as the men's and the trees' are: a man is 49 voxels, a metre 28.
Each model stands on z = 0 round its foot (`vox/feet.txt`); the animals face +x. The palette holds
the real colours: the game lights them as it lights the rocks and logs and bakes each one with its
shadow into the "camp" sheet (`src/smyana/camp.lobster`): frames `tent0`, `tent1`, `fireplace`,
`woodpile`, `hut`, `horse0..7` and `mule0..7` (n % 4 the animal; n < 4 facing the camera's right, else its
left), each with `.shadow`.

Made by `tools/camp_vox.py` (run from the repo's root; numpy).

## Not done yet

- The animals only stand. No walk, no grazing, no rider.
- The fireplace has no lit state of its own: it relies on the game's flames over it.
- Sizes follow the mock-up (a man and a half for the canvas tent, a horse's back at a man's
  chest), which is a little bigger than real Rhodope ponies.
