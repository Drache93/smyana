# 2026-11-13: Round beeches, and the old forest's giants

## What happened

The evening before, Dominic said the beech crowns were the wrong shape: "It should be rounder. Right now you seem to
sort of be focusing on covering the top part of the tree rather than the whole of the tree." And then: "Stop
guessing. Any more trees or foliage or greens and stuff, always get some evidence before you do it." Claude had a
guess at a rounder crown ready; it was thrown away unseen, and nothing was changed until there was evidence.

In the morning he sent photographs of beeches ([his words, and what the photos show](../notes/2026-11-13-dominic-big-old-trees-and-the-mounted-patrol.md)),
then: "The forest is old, likely they've be some really big/thick ones", and "Not just beech right?"

## The beech, from the photos

Ours (picture 06) were a wide cap of leaves on a narrowing funnel: the leaves were at the twigs' ends, and the twigs
were at the top of boughs that rose steeply from one fork. The photo's beech is the other way about. So the beech now
has its own maker in `tools/tree_vox.py` (`beech()`), written from the photo:

- One crown shaped like an egg, widest a little below its middle, from low on the tree to the top. Its outline is
  lobed, not smooth, as each big limb carries its own mass.
- The trunk runs up through it as a leader, and the limbs leave it all the way up in a spiral: the low ones long and
  near level, drooping at their ends, the high ones short and steep, each reaching just to the egg's shell.
- The leaves lie in flat, level sprays along every limb and branch, from a third of the way out, with more out to the
  shell all over it, as thick at the sides and nearly as thick underneath as on top. Where no branch is near, there is
  a gap, and the limbs and the sky show.
- The leafy shoots low on the trunk (D-112) stay.

Pictures 01 (summer), 02 (autumn) and 07 against 06.

## The giants

Old trees are already the ones the men can't fell (the map's "tree"; only young trees are felled). What was missing
was size. Each kind's second old model is now a giant of the old forest, and one old tree in six stands as one. The
sizes are from field sources, as far as they go (no photos could be fetched here):

| Kind | What the sources say | The giant (men: height, trunk across) |
|---|---|---|
| Beech | Dominic's Balkan photos: thick twisted trunks forking low into great limbs. An ancient beech is over 4.5 m round, up to 6 m ([Woodland Trust](https://ati.woodlandtrust.org.uk/how-to-record/species-guides/beech)) | 6.2, 0.7: forks low into three, a wide root flare, burrs, a dead limb or two |
| Oak | Ancient oaks are over 6 m round, up to 10 m, with dead wood in the crown ([Woodland Trust](https://ati.woodlandtrust.org.uk/how-to-record/species-guides/oak/)); the two old oaks of Velichka, Bulgaria: 550 and 500 years, 22 and 18 m tall, 5.3 and 4.95 m round ([BNR](https://bnrnews.bg/en/post/115792/residents-of-velichka-village-are-proud-of-their-two-centenary-oaks)) | 5.4, 0.9: a quarter of its limbs dead and bare ("stag-headed") |
| Silver fir | Old trunks 2 to 2.5 m across, up to about 60 m; an old crown goes flat or stag-headed ([Trees and Shrubs Online](https://www.treesandshrubsonline.org/articles/abies/abies-alba)) | 7.2, 0.75 |
| Norway spruce | 40 to 50 m, 1 to 1.5 m across, rarely more; tapers fast; Bulgaria's tallest 55.4 m ([Gymnosperm Database](https://mail.conifers.org/pi/Picea_abies.php)) | 7.4, 0.62 |
| Scots pine | The pine of Pchelarovo in the Eastern Rhodopes: about 500 years, nearly 25 m tall, 3.5 m round ([BNR](https://parliament140.bnr.bg/en/post/102060947/a-five-century-old-scots-pine-attracts-visitors-in-the-rhodope-village-of-pchelarovo)) | 6.2, 0.62 |
| Black pine | No Bulgarian record found; the giant is sized as the Scots pine's | 5.8, 0.7 |

Every giant also gets buttresses at its foot and burrs and old wounds up its bole. The game's trees are about a third
of their real height (an old tree is five or six men tall, from the mock-ups), but their trunks are near real width,
so the giants read stout. The hornbeam has no giant (a smaller tree), and its crown is unchanged: nothing was found on
its shape yet. Plane trees by the rivers would be a new kind, and new kinds are on hold (Dominic, 2026-11-11).

Pictures 03 and 08 put each kind's old tree beside its giant; 04 and 05 are the beech valley in the game.

## Also

`tools/tree_vox.py` can now make some models only (`python3 tools/tree_vox.py beech oak_old_1`), each with its own
seed as before, and removes a model's old pieces when it shrinks. The trees' bake is "trees 64" and baked/ is baked
again.

## Pictures

- `images/2026-11-13/01-...summer.jpg`, `02-...autumn.jpg`: the beeches as baked, young to old and the giant, beside
  the oaks.
- `03-...jpg`: fir, spruce, Scots pine, black pine, each old tree and its giant.
- `04`, `05`: the beech valley in autumn and in summer.
- `06`, `07`: the beech models before and after, side on.
- `08`: each kind's old tree and its giant, side on.

## Later: the giants get their scars

Dominic on the giants: "a little more character with old ones than just bigger... They've survived a lot. They've
maybe survived a lightning strike or two." What old trees show, from the Woodland Trust's
[What are ancient trees?](https://www.woodlandtrust.org.uk/media/1836/what-are-ancient-trees.pdf): a hollowing trunk
"with one or more openings to the outside", cavities where limbs broke away, a crown "growing downwards" with dead
antler-like limbs standing out of it, and in conifers a top flattened by storm or lightning "with many new stems". And
lightning, from [Alabama Extension](https://www.aces.edu/blog/topics/forestry/caring-for-lightning-struck-trees/):
bark "blown out along a narrow strip" that can "spiral down the trunk".

So each giant now carries some of these (`character()` in `tools/tree_vox.py`):

- **Beech:** the low fork into three great crooked limbs is on show now (its crown starts higher), two lightning
  scars of bare pale wood spiralling down the bole, a hollow at its foot, dead limbs out of the top.
- **Oak:** a big hollow at the foot, open to the side, two lightning scars, dead stag-head limbs.
- **Silver fir:** its top snapped off, a dead stub, and three new tops grown up round it from the highest whorls; a
  lightning scar.
- **Spruce:** the same broken top, so it stands with two or three spires; a hollow.
- **Scots pine:** lightning scars, a dead snag top, a hollow. **Black pine:** dead limbs out of its crown, a hollow.

The game now draws the bark's tones from the model: bare wood pale, dead wood grey, wounds and hollows dark (before,
all bark was one tone, so the old scar marks never showed). Trees 65. Pictures 09 to 11.
