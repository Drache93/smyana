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


def strew(tile, seed, n, colours, length=(4.5, 7.0), lift=0.0, edge=0.9, drift=True):
    """Fallen leaves on a tile, each one a leaf: a pointed oval a few texels long at its own angle, lying over the
    ones before it, its lower edge a shade darker so it stands off what it lies on."""
    rng = np.random.default_rng(seed)
    rgb = tile[:, :, :3].astype(float)
    hgt = tile[:, :, 3].astype(float)
    cols = np.array([hexc(c) for c in colours])
    # (the colours run light to dark: a slow noise says which end a leaf's patch of ground leans to, so the carpet
    # lies in soft drifts of gold and orange and never speckles)
    lean = tile_noise(rng, 4) * 0.6 + tile_noise(rng, 9) * 0.4
    lean = (lean - lean.min()) / (lean.max() - lean.min())
    R = 5
    yy, xx = np.mgrid[-R:R + 1, -R:R + 1]
    for _ in range(n):
        cx, cy = rng.integers(0, N, 2)
        a = rng.random() * np.pi
        ln = rng.uniform(*length) / 2
        wd = ln * rng.uniform(0.5, 0.68)
        u = xx * np.cos(a) + yy * np.sin(a)
        v = -xx * np.sin(a) + yy * np.cos(a)
        inside = (np.abs(u) / ln) ** 1.5 + (np.abs(v) / wd) ** 1.5 <= 1.0
        col = cols[int(np.clip(lean[cy, cx] * len(cols) + rng.normal(0, 0.9), 0, len(cols) - 1))] * rng.uniform(0.98, 1.02) if drift else cols[rng.integers(0, len(cols))]
        under = inside & ~np.roll(inside, -1, axis=0)  # its lowest texels
        ys = (cy + yy) % N
        xs = (cx + xx) % N
        rgb[ys[inside], xs[inside]] = col
        rgb[ys[under], xs[under]] = col * edge
        hgt[ys[inside], xs[inside]] = np.clip(hgt[ys[inside], xs[inside]] + lift * 255, 0, 255)
    return np.dstack([np.clip(rgb, 0, 255), hgt]).astype(np.uint8)


def tufts(tile, seed, n, colours):
    """Tufts of grass: a few blades each, two to four texels tall, leaning."""
    rng = np.random.default_rng(seed)
    out = tile.copy()
    cols = np.array([hexc(c) for c in colours])
    for _ in range(n):
        cx, cy = rng.integers(0, N, 2)
        for b in range(rng.integers(2, 5)):
            x = cx + rng.integers(-2, 3)
            lean = rng.integers(-1, 2)
            col = cols[rng.integers(0, len(cols))]
            tall = rng.integers(2, 5)
            for k in range(tall):
                out[(cy - k) % N, (x + (lean if k >= tall - 1 else 0)) % N, :3] = col * (0.8 + 0.2 * k / tall)
    return out


def pebbles(tile, seed, n, colours):
    """Small stones: two or three texels, a light top and a dark foot."""
    rng = np.random.default_rng(seed)
    out = tile.copy()
    cols = np.array([hexc(c) for c in colours])
    for _ in range(n):
        cx, cy = rng.integers(0, N, 2)
        col = cols[rng.integers(0, len(cols))]
        w = rng.integers(2, 4)
        for k in range(w):
            out[cy, (cx + k) % N, :3] = col
            out[(cy + 1) % N, (cx + k) % N, :3] = col * 0.6
    return out


def tiles(wood, season):
    """The sixteen grounds of a place. Beech wood: mountain grass, a thick copper litter of beech leaves, warm grey
    gneiss. Conifer wood: moss and bilberry where the beech has grass, a dark rusty floor of needles."""
    conifer = wood == "conifer"
    autumn = season == "autumn"
    grass = ["#3a4f2a", "#44592e", "#4e6433", "#586f39"] if conifer else ["#46602f", "#516d34", "#5c7a3a", "#688841"]
    dark = ["#26391f", "#2d4324", "#354d29", "#3d582f"] if conifer else ["#2f4727", "#37532c", "#405f32", "#4a6c39"]
    litter = ["#33271a", "#3f2f1e", "#4b3823", "#584229"] if conifer else ["#573a1f", "#6b4724", "#7f552a", "#946431"]
    fleck = ["#6e4a26", "#2a2016", "#7d5a30"] if conifer else ["#b07a34", "#c08a3c", "#44301c", "#9a5c28"]
    if autumn:  # the year's fall lies bright on last year's: gold, orange, red
        litter = litter if conifer else ["#7a4319", "#9a551a", "#bb6a1c", "#d8851f"]
        fleck = ["#f2b21e", "#e8701a", "#c4341a", "#f6cf4a", "#8a3a14", "#ff9a22"]
        grass = ["#77803a", "#808840", "#899044", "#929848"] if not conifer else grass
        dark = ["#5e6c32", "#667436", "#6e7c3a", "#76843e"] if not conifer else dark
    t = {
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
    # the forest floor is leaves you can see, not a speckle: this year's fall in autumn, last year's brown the rest of
    # the year; and a wood's grass and trail have leaves and tufts and stones on them too
    if not conifer:
        if autumn:
            # (soft: close warm tones on a warm bed, no dark gaps between the leaves; Dominic: "verry spotty, ground was
            # soft and pretty in the mockup")
            # (2026-11-11, Dominic: the ground is "not rich enough yet". The fall has more shades in it, as the trees do:
            # straw and gold, orange, and one leaf in four rust, red-brown or brown. Still no dark gaps.)
            fall = ["#f0c658", "#ecb848", "#e6ae40", "#e2a538", "#dc9a30", "#d68f2c", "#cf8528", "#c87a26", "#e9d27c",
                    "#bd6a26", "#b25a24", "#c65228", "#a8602c", "#9a5226"]
            t[10] = strew(make(11, ["#c8802a", "#cf892c", "#d6922e", "#dc9a30"], coarse=4, fine=12, grain=0.04, height=0.45), 111, 3600, fall, lift=0.04)
            for k, n in ((0, 520), (1, 560), (2, 640), (3, 480), (12, 560), (13, 560)):
                t[k] = strew(tufts(t[k], 200 + k, 500, ["#7f8f40", "#8a9846", "#75853c"]), 300 + k, n, fall)
            t[4] = strew(pebbles(make(5, ["#9c8358", "#a48b5e", "#ac9364", "#b49b6a"], fine=30, grain=0.08, height=0.35), 404, 60, ["#a39a86", "#968d7a"]), 304, 200, fall)
            t[9] = strew(make(10, ["#6e5a3e", "#746042", "#7a6546", "#806a4a"], grain=0.1, height=0.4), 309, 500, fall)
        elif season != "winter":
            old = ["#8a5c2c", "#845628", "#90622f", "#7c5126", "#966834"]
            t[10] = strew(make(11, ["#74491f", "#7a4e22", "#805325", "#865828"], coarse=5, fine=18, grain=0.06, height=0.45), 111, 3200, old, lift=0.04)
            for k in (0, 2, 3, 12, 13):
                t[k] = tufts(t[k], 200 + k, 600, ["#6f8f44", "#7fa04c", "#5c7a3a", "#8cab55"])
            t[4] = strew(pebbles(t[4], 404, 260, ["#9b9485", "#b0a896", "#857e70"]), 304, 120, old)
    else:
        t[4] = pebbles(t[4], 404, 260, ["#9b9485", "#b0a896", "#857e70"])
    # bare mountain ground and scree: stones you can see, of many sizes, lying on stony earth with a tuft between them
    t[11] = tufts(strew(strew(make(12, ["#77705f", "#7b7463", "#7f7867", "#837c6b"], coarse=5, fine=16, grain=0.05, height=0.55),
                              512, 420, ["#8a8374", "#8f8879", "#857e6f", "#948d7d"], length=(6.0, 13.0), edge=0.86, drift=False),
                        513, 500, ["#8c8576", "#888172", "#928b7b"], length=(3.0, 6.0), edge=0.88, drift=False),
                 514, 140, ["#6f7a3c", "#7d8742", "#5f6a34"])
    if season == "winter":
        # the first snow: thin and blue-white in the open with grass tips through it, thinner still under the trees
        # where the fallen leaves show, trodden to slush on the trail
        snow = ["#c3ccd8", "#d4dbe4", "#e3e8ed", "#f2f4f5"]
        tips = ["#6d7a45", "#8a7a4a", "#56603a"]
        for k, n in ((0, 500), (1, 900), (2, 350), (3, 600), (12, 500), (13, 1200)):
            t[k] = make(20 + k, snow, coarse=7, fine=30, grain=0.12, fleck=tips, fleck_n=n, height=0.6)
        t[10] = make(31, ["#a9aeb2", "#bfc4c7", "#d5d8d9", "#e8e9e8"], fine=50, grain=0.3, fleck=["#8a4a1c", "#6b4724", "#b0702a", "#4b3823"], fleck_n=1500 if conifer else 3500, height=0.5, leaf=not conifer)
        t[4] = make(32, ["#5f5648", "#716859", "#8a8478", "#a9a69f"], fine=60, grain=0.4, height=0.35)
        t[9] = make(33, ["#5a4d3c", "#6d6252", "#8d877c", "#b4b2ad"], grain=0.4, height=0.4)
    return t


for wood, autumn, name in (("beech", "", "atlas"), ("conifer", "", "atlas_conifer"), ("beech", "autumn", "atlas_autumn"), ("conifer", "autumn", "atlas_conifer_autumn"),
                           ("beech", "winter", "atlas_winter"), ("conifer", "winter", "atlas_conifer_winter")):
    sheet = np.zeros((N * 4, N * 4, 4), np.uint8)
    for k, t in tiles(wood, autumn).items():
        sheet[(k // 4) * N:(k // 4 + 1) * N, (k % 4) * N:(k % 4 + 1) * N] = t
    Image.fromarray(sheet, "RGBA").save("data/ground/%s.png" % name)
print("ok")
