# Creel: smoother voxel units

2026-11-13. Claude, for Smyana's men ([journal](../journal/2026-11-13-the-men-without-the-spots.md)).

- **`vx_smooth_normals`** (passes, 0 off): averages each surface voxel's normal and occlusion with those of the surface
  voxels in the 3 × 3 × 3 round it that face the same way, in `vx_fill_end`. A `.vox` model's stairs then shade
  smoothly.
- **`vx_despeckle`** (passes, 0 off): softens the shaded cell before its outline. Each pixel becomes the mean of itself
  and the pixels beside it of the same material at near the same depth (not the team colour or a light).
- Also written down: what `vx_set_res` does to a unit made of `.vox` models. A model voxel is baked to
  `res × size / 2` pixels, and under 1 its rows are lost.

All three are in `docs/settings.md` in the same pull request, per the docs rule.
