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


def worn(earth, grass_tile, seed, share=0.42):
    """A trail as a worn gap in the growth, not a solid stripe (Dominic, 2026-11-12: "a path is not a single solid
    thing... it's more of a gap in all the growth"): bare earth where feet go, and the grass coming back through it in
    soft patches and tufts, so its edge frays into the grass beside it."""
    rng = np.random.default_rng(seed)
    v = tile_noise(rng, 7) * 0.65 + tile_noise(rng, 22) * 0.35
    v = (v - v.min()) / (v.max() - v.min())
    out = earth.copy()
    g = v > 1.0 - share
    out[g] = grass_tile[g]
    return out


def tiles(wood, season):
    """The sixteen grounds of a place. Beech wood: mountain grass, a thick copper litter of beech leaves, warm grey
    gneiss. Conifer wood: moss and bilberry where the beech has grass, a dark rusty floor of needles."""
    conifer = wood == "conifer"
    autumn = season == "autumn"
    grass = ["#3a4f2a", "#44592e", "#4e6433", "#586f39"] if conifer else ["#4a6a2a", "#557832", "#60853a", "#6b9142"]
    dark = ["#26391f", "#2d4324", "#354d29", "#3d582f"] if conifer else ["#2f4727", "#37532c", "#405f32", "#4a6c39"]
    litter = ["#33271a", "#3f2f1e", "#4b3823", "#584229"] if conifer else ["#573a1f", "#6b4724", "#7f552a", "#946431"]
    fleck = ["#6e4a26", "#2a2016", "#7d5a30"] if conifer else ["#b07a34", "#c08a3c", "#44301c", "#9a5c28"]
    if season == "" and conifer:
        # (summer, Dominic 2026-11-11: "Fir have lots of brown at the bottom". Under the conifers the needles lie thin
        # on moss: an olive-brown floor with green through it, not a dark rusty pool round every tree)
        litter = ["#3d3c25", "#45432a", "#4d4a2f", "#555134"]
        fleck = ["#6a4a28", "#5a4026", "#7a5a32", "#4f6a2c", "#5d7632", "#2e2a1c"]
    if autumn:  # the year's fall lies bright on last year's: gold, orange, red
        litter = litter if conifer else ["#7a4319", "#9a551a", "#bb6a1c", "#d8851f"]
        fleck = ["#f2b21e", "#e8701a", "#c4341a", "#f6cf4a", "#8a3a14", "#ff9a22"]
        # (2026-11-12, a Bulgarian's eye: the open ground was "too dry". In the photos an autumn meadow is still green,
        # going gold, the colour is in the trees)
        # (later the same day, Dominic: "Why would anything be green if it's autumn?" The meadow turned: tawny gold,
        # rich rather than the pale straw of a dry summer; under the conifers the moss stays)
        grass = ["#7e6c2e", "#8c7832", "#9a8436", "#a8903c"] if not conifer else grass
        dark = ["#62542a", "#6c5c2c", "#76642e", "#806c32"] if not conifer else dark
    t = {
        0: make(1, grass, blades=0.06, height=0.55),                                                             # grass (conifer: moss)
        1: make(2, ["#5c6a32", "#66753a", "#718040", "#7c8a48"] if not autumn else ["#86642c", "#94702f", "#a27c34", "#b08838"], blades=0.05, height=0.5),                        # dry grass (2026-11-12: "too dry": a paler green, not straw)
        2: make(3, dark, blades=0.08, height=0.6),                                                                # dark grass
        3: make(4, grass, fleck=["#3b3550", "#4a4466", "#2c4a2a"] if conifer else ["#e8e2b0", "#d9c060", "#c9a0c8"], fleck_n=700 if conifer else 500, blades=0.05, height=0.55),  # meadow (conifer: bilberry)
        4: make(5, ["#3e3123", "#4a3b2a", "#564531", "#614f38"], fine=60, grain=0.35, height=0.35),               # dirt, the trail (2026-11-12: dark earth, not "a yellow trail")
        5: make(6, ["#5c574e", "#6e685d", "#817a6c", "#958d7c"], coarse=8, fine=24, grain=0.2, height=0.75, rough=0.4),  # rock: gneiss
        6: make(7, ["#8f8463", "#9d9270", "#aba07d", "#b9ae8a"], fine=70, grain=0.3, height=0.3),                 # sand
        7: make(8, ["#6c6650", "#78715a", "#847d64", "#90896e"], fine=70, grain=0.25, height=0.25),               # wet sand
        8: make(9, ["#3c3527", "#463e2e", "#514835", "#5c523d"], grain=0.2, height=0.3),                          # mud
        9: make(10, ["#4d3f2c", "#5a4a33", "#68563b", "#766244"], grain=0.35, height=0.4),                        # bare earth
        10: make(11, litter, fine=50, grain=0.45, fleck=fleck, fleck_n=(3000 if autumn else 2500) if conifer else (9000 if autumn else 4500), blades=0.1 if conifer else 0.0, height=0.5, leaf=autumn),  # forest floor
        11: make(12, ["#5a554c", "#6c665b", "#807868", "#948b78"], coarse=10, fine=64, grain=0.5, height=0.6, rough=0.45),  # scree: gneiss
        12: make(13, (["#4a6a2e", "#557634", "#60823b", "#6b8e43"] if not autumn else ["#74602a", "#7e6a2e", "#887232", "#927c36"]) if not conifer else dark, blades=0.06, height=0.55),  # olive grass
        13: make(14, ["#56662f", "#617236", "#6c7e3d", "#788944"] if not autumn else ["#6e5c30", "#786434", "#826c38", "#8c743c"], blades=0.03, grain=0.3, height=0.45),          # worn grass
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
            # (2026-11-12: the bed under the leaves a browner orange, so a wood's floor reads as fallen leaves, not dry ground)
            t[10] = strew(make(11, ["#8a5a26", "#94622a", "#9e6a2e", "#a87232"], coarse=4, fine=12, grain=0.04, height=0.45), 111, 3000, fall, lift=0.04)
            # (only a few blown leaves out on the grass: the carpet of them is under the trees)
            for k, n in ((0, 110), (1, 130), (2, 160), (3, 90), (12, 120), (13, 130)):
                t[k] = strew(tufts(t[k], 200 + k, 500, ["#a08a3c", "#b09a46", "#8e7834"]), 300 + k, n, fall)
            t[4] = strew(pebbles(make(5, ["#4a3a28", "#54432e", "#5e4b34", "#68543a"], fine=30, grain=0.08, height=0.35), 404, 160, ["#8a8476", "#7a7466"]), 304, 140, fall)
            t[9] = strew(make(10, ["#6e5a3e", "#746042", "#7a6546", "#806a4a"], grain=0.1, height=0.4), 309, 500, fall)
        elif season != "winter":
            # (last year's leaves gone dull and dark under the summer's green, moss and seedlings through them: in the
            # first summer render they read as orange pools of autumn round every tree)
            old = ["#6e5234", "#664a2e", "#755a3a", "#5e4630", "#7a6040", "#56602e", "#4c5a2a", "#62702f"]
            t[10] = strew(make(11, ["#4f3f2a", "#54442d", "#5a4830", "#5f4d33"], coarse=5, fine=18, grain=0.06, height=0.45), 111, 3200, old, lift=0.04)
            for k in (0, 2, 3, 12, 13):
                t[k] = tufts(t[k], 200 + k, 600, ["#6f8f3c", "#7e9a44", "#5f7a34", "#8aa64c", "#96ac56"])
            t[4] = strew(pebbles(t[4], 404, 260, ["#9b9485", "#b0a896", "#857e70"]), 304, 120, old)
    else:
        t[4] = pebbles(t[4], 404, 260, ["#9b9485", "#b0a896", "#857e70"])
    if season != "winter":
        # (the trail: lighter earth, worn, with the grass of the place through it)
        earth = ["#5e4c34", "#6a573c", "#766245", "#826d4d"] if season != "autumn" else ["#5a4630", "#655038", "#705a3f", "#7b6446"]
        bed = pebbles(make(5, earth, fine=40, grain=0.2, height=0.35), 404, 160, ["#9b9485", "#b0a896", "#857e70"])
        if not conifer and season == "autumn": bed = strew(bed, 304, 160, fall)
        t[4] = tufts(worn(bed, t[0], 405), 406, 260, ["#6f8f3c", "#7e9a44", "#5f7a34"] if season != "autumn" else ["#a08a3c", "#8e7834", "#b09a46"])
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
