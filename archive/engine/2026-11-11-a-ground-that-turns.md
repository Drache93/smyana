# A ground that turns (2026-11-11)

**Creel pull request:** Casaide/creel#23. **For:** Smyana's seasons (Drache93/smyana#11).

Smyana's ground is a set of textures per season. The season used to change between places, so one set was loaded per
place. With the season clock the ground has to change while the men stand on it.

Blending two sets would have been two lines of shader, and wrong: Dominic's rule for the look is "everything crisp and
sharp", and two pixel textures mixed are neither one nor the other. So Claude made it a turn, not a blend:

- `ground_atlas_next` is a second atlas with the same layout as the first.
- `ground_atlas_mix` says how far it has come in, 0 to 1. Each texel of the ground is from the one atlas or the
  other. Which, is decided by a number that is half the texel's own and half its little patch's (five texels across),
  so the second set arrives a texel at a time, in patches: snow settles in flecks that grow together.
- A game that sets neither draws as before.

It is documented in Creel's `docs/settings.md`, as every setting is (Dominic's rule of the same day).
