#!/usr/bin/env python3
"""Writes data/ground/atlas.png: the ground's textures for Creel's terrain shader. 1024 x 1024, sixteen tiles of
256 px that wrap, a texel an art pixel; alpha is the texel's height (the shader lets the higher of two grounds show
along their edge). Tile numbers are the shader's (creel/src/game/ground.lobster).
A first pass in the Rhodopes' colours, made here and not copied from anywhere: mossy greens, beech-leaf litter, grey
gneiss. Run from the repo's root: python3 tools/ground_atlas.py (numpy and Pillow)."""
import numpy as np
from PIL import Image

N = 256


def tile_noise(rng, cells):
    """smooth noise 0..1 over N x N that wraps, `cells` knots across"""
    g = rng.random((cells, cells))
    xs = np.arange(N) * cells / N
    i = xs.astype(int)
    f = xs - i
    f = f * f * (3 - 2 * f)
    a = g[np.ix_(i % cells, i % cells)]
    b = g[np.ix_(i % cells, (i + 1) % cells)]
    c = g[np.ix_((i + 1) % cells, i % cells)]
    d = g[np.ix_((i + 1) % cells, (i + 1) % cells)]
    fx = f[None, :]
    fy = f[:, None]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def hexc(h): return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], float)


def make(seed, ramp, coarse=6, fine=40, grain=0.25, fleck=None, fleck_n=0, height=0.5, rough=0.3, blades=0.0, leaf=False):
    """ramp: colours dark to light. The tone is two noises and a per-texel grain, cut into the ramp's steps."""
    rng = np.random.default_rng(seed)
    v = tile_noise(rng, coarse) * 0.55 + tile_noise(rng, fine) * 0.45
    v = v + (rng.random((N, N)) - 0.5) * grain
    if blades > 0:  # short vertical streaks: grass blades, needles
        streak = rng.random((N, N)) < blades
        v = v + streak * 0.22 + np.roll(streak, 1, axis=0) * 0.12
    v = (v - v.min()) / (v.max() - v.min())
    cols = np.array([hexc(c) for c in ramp])
    q = np.minimum((v * len(ramp)).astype(int), len(ramp) - 1)
    rgb = cols[q]
    if fleck is not None:
        ys, xs = rng.integers(0, N, fleck_n), rng.integers(0, N, fleck_n)
        fc = np.array([hexc(c) for c in fleck])
        pick = fc[rng.integers(0, len(fc), fleck_n)]
        rgb[ys, xs] = pick
        if leaf:  # a fallen leaf is a few texels, not one
            rgb[ys, (xs + 1) % N] = pick
            rgb[(ys + 1) % N, xs] = pick * 0.85
    h = np.clip(height + (v - 0.5) * rough * 2, 0, 1)
    return np.dstack([rgb, h * 255]).astype(np.uint8)


def tiles(wood, autumn):
    """The sixteen grounds of a place. Beech wood: mountain grass, a thick copper litter of beech leaves, warm grey
    gneiss. Conifer wood: moss and bilberry where the beech has grass, a dark rusty floor of needles."""
    conifer = wood == "conifer"
    grass = ["#3a4f2a", "#44592e", "#4e6433", "#586f39"] if conifer else ["#46602f", "#516d34", "#5c7a3a", "#688841"]
    dark = ["#26391f", "#2d4324", "#354d29", "#3d582f"] if conifer else ["#2f4727", "#37532c", "#405f32", "#4a6c39"]
    litter = ["#33271a", "#3f2f1e", "#4b3823", "#584229"] if conifer else ["#573a1f", "#6b4724", "#7f552a", "#946431"]
    fleck = ["#6e4a26", "#2a2016", "#7d5a30"] if conifer else ["#b07a34", "#c08a3c", "#44301c", "#9a5c28"]
    if autumn:  # the year's fall lies bright on last year's: gold, orange, red
        litter = litter if conifer else ["#7a4319", "#9a551a", "#bb6a1c", "#d8851f"]
        fleck = ["#f2b21e", "#e8701a", "#c4341a", "#f6cf4a", "#8a3a14", "#ff9a22"]
        grass = ["#4a5a2c", "#566630", "#637335", "#70803a"] if not conifer else grass
    return {
        0: make(1, grass, blades=0.06, height=0.55),                                                             # grass (conifer: moss)
        1: make(2, ["#6d6a3a", "#7c7842", "#8c874c", "#9b9657"], blades=0.05, height=0.5),                        # dry grass
        2: make(3, dark, blades=0.08, height=0.6),                                                                # dark grass
        3: make(4, grass, fleck=["#3b3550", "#4a4466", "#2c4a2a"] if conifer else ["#e8e2b0", "#d9c060", "#c9a0c8"], fleck_n=700 if conifer else 500, blades=0.05, height=0.55),  # meadow (conifer: bilberry)
        4: make(5, ["#5b4a34", "#6a573d", "#7a6547", "#8a7352"], fine=60, grain=0.35, height=0.35),               # dirt, the trail
        5: make(6, ["#5c574e", "#6e685d", "#817a6c", "#958d7c"], coarse=8, fine=24, grain=0.2, height=0.75, rough=0.4),  # rock: gneiss
        6: make(7, ["#8f8463", "#9d9270", "#aba07d", "#b9ae8a"], fine=70, grain=0.3, height=0.3),                 # sand
        7: make(8, ["#6c6650", "#78715a", "#847d64", "#90896e"], fine=70, grain=0.25, height=0.25),               # wet sand
        8: make(9, ["#3c3527", "#463e2e", "#514835", "#5c523d"], grain=0.2, height=0.3),                          # mud
        9: make(10, ["#4d3f2c", "#5a4a33", "#68563b", "#766244"], grain=0.35, height=0.4),                        # bare earth
        10: make(11, litter, fine=50, grain=0.45, fleck=fleck, fleck_n=(3000 if autumn else 2500) if conifer else (9000 if autumn else 4500), blades=0.1 if conifer else 0.0, height=0.5, leaf=autumn),  # forest floor
        11: make(12, ["#5a554c", "#6c665b", "#807868", "#948b78"], coarse=10, fine=64, grain=0.5, height=0.6, rough=0.45),  # scree: gneiss
        12: make(13, ["#4a5a2e", "#556634", "#61733b", "#6d8043"] if not conifer else dark, blades=0.06, height=0.55),  # olive grass
        13: make(14, ["#55602f", "#606b35", "#6c773c", "#788344"], blades=0.03, grain=0.3, height=0.45),          # worn grass
    }


for wood, autumn, name in (("beech", False, "atlas"), ("conifer", False, "atlas_conifer"), ("beech", True, "atlas_autumn"), ("conifer", True, "atlas_conifer_autumn")):
    sheet = np.zeros((N * 4, N * 4, 4), np.uint8)
    for k, t in tiles(wood, autumn).items():
        sheet[(k // 4) * N:(k // 4 + 1) * N, (k % 4) * N:(k % 4 + 1) * N] = t
    Image.fromarray(sheet, "RGBA").save("data/ground/%s.png" % name)
print("ok")
