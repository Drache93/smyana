#!/usr/bin/env python3
"""Draws a tree's 2D design sheet (art/trees/design/<kind>.png): its sizes beside a man, and its look in each season.
The design comes first and the voxel model is made from it (D-035). Run from the repo's root:
python3 tools/tree_design.py   (numpy and Pillow)"""
import math, random
from PIL import Image, ImageDraw, ImageFont

PX = 46          # px a metre on the sheet, at the game's scale (a man is 1.7 m)
MAN = 1.7
BG = (236, 229, 212)
INK = (52, 46, 40)

BARK = [(196, 196, 188), (164, 165, 158), (128, 130, 124), (96, 98, 94)]   # beech: smooth silver grey, light to dark
LEAF = {
    "summer": [(126, 168, 66), (86, 130, 50), (50, 88, 38), (30, 58, 30)],
    "early autumn": [(228, 196, 62), (196, 160, 44), (120, 128, 44), (70, 80, 34)],
    "autumn": [(238, 150, 40), (206, 104, 28), (150, 62, 22), (84, 36, 18)],
    "late autumn": [(190, 98, 40), (150, 70, 30), (104, 46, 24), (64, 30, 18)],
    "spring": [(176, 212, 88), (138, 184, 66), (90, 136, 50), (52, 90, 38)],
}


def font(size):
    for f in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/dejavu/DejaVuSans.ttf"):
        try: return ImageFont.truetype(f, size)
        except OSError: pass
    return ImageFont.load_default()


def limb(d, a, b, wa, wb, rng):
    """a tapered limb from a to b, lit from the left: three strokes, light to dark across it"""
    steps = max(2, int(math.dist(a, b) / 3))
    for i in range(steps + 1):
        t = i / steps
        x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
        w = wa + (wb - wa) * t
        d.ellipse([x - w, y - w, x + w, y + w], fill=BARK[2])
    for i in range(steps + 1):
        t = i / steps
        x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
        w = wa + (wb - wa) * t
        d.ellipse([x - w, y - w * 0.9, x + w * 0.35, y + w * 0.9], fill=BARK[1])
        d.ellipse([x - w, y - w * 0.8, x - w * 0.35, y + w * 0.8], fill=BARK[0])


def spray(d, x, y, w, h, pal, rng, n):
    """a beech's leaves lie in flat sprays: a low wide heap of small leaves, lit on top, dark beneath"""
    for i in range(n):
        u = rng.gauss(0, 0.42)
        v = rng.random()
        px = x + u * w
        py = y - (1 - abs(u)) * h * v + h * 0.25
        shade = 0 if v > 0.72 else 1 if v > 0.42 else 2 if v > 0.14 else 3
        if rng.random() < 0.12: shade = max(0, shade - 1)
        r = rng.uniform(1.6, 3.0)
        d.ellipse([px - r * 1.3, py - r * 0.8, px + r * 1.3, py + r * 0.8], fill=pal[shade])


def beech(d, x, ground, height, girth, season, seed, bole=0.42, spread=0.42, marcescent=False):
    """height and girth in metres. bole: how far up the clean trunk goes. Returns nothing: draws on d."""
    rng = random.Random(seed)
    H = height * PX
    foot = (x, ground)
    fork = (x + rng.uniform(-0.02, 0.02) * H, ground - H * bole)
    r0 = girth * PX / 2
    # the foot: a flare like an elephant's
    d.polygon([(x - r0 * 1.9, ground), (x - r0 * 1.05, ground - r0 * 2.4), (x + r0 * 1.05, ground - r0 * 2.4), (x + r0 * 1.9, ground)], fill=BARK[2])
    d.polygon([(x - r0 * 1.9, ground), (x - r0 * 1.05, ground - r0 * 2.4), (x - r0 * 0.2, ground - r0 * 2.4), (x - r0 * 0.5, ground)], fill=BARK[0])
    limb(d, (x, ground - r0), fork, r0, r0 * 0.72, rng)
    # the bark's marks: thin dark scars across it, an eye where a branch was
    for i in range(int(H * bole / 14)):
        yy = ground - r0 * 2.6 - rng.random() * (H * bole - r0 * 3)
        d.line([(x - r0 * 0.6, yy), (x + rng.uniform(0.1, 0.7) * r0, yy + 1)], fill=BARK[3], width=1)
    # boughs: steeply up and then out, each ending in twigs
    tips = []
    n = 5 if height > 6 else 4 if height > 3 else 3
    for i in range(n):
        side = -1 if i % 2 == 0 else 1
        t = (i + 0.5) / n
        out = side * H * spread * rng.uniform(0.55, 1.0) * (0.35 + 0.65 * (1 - abs(t - 0.4)))
        up = H * (1 - bole) * rng.uniform(0.45, 0.92) * (0.5 + 0.5 * t)
        start = (fork[0], fork[1] + H * bole * 0.16 * (1 - t))
        mid = (start[0] + out * 0.35, start[1] - up * 0.62)
        end = (start[0] + out, start[1] - up)
        limb(d, start, mid, r0 * 0.42, r0 * 0.26, rng)
        limb(d, mid, end, r0 * 0.26, r0 * 0.1, rng)
        tips += [mid, end]
        for k in range(3):
            tw = (end[0] + rng.uniform(-0.2, 0.2) * H * spread + side * 0.1 * H * spread, end[1] - rng.uniform(-0.03, 0.12) * H)
            d.line([end, tw], fill=BARK[2], width=max(1, int(r0 * 0.12)))
            tips.append(tw)
            for q in range(3):  # the fine zig-zag twigs that show in winter
                t2 = (tw[0] + rng.uniform(-0.06, 0.06) * H, tw[1] - rng.uniform(0.0, 0.05) * H)
                d.line([tw, t2], fill=BARK[3], width=1)
    lead = (fork[0] + rng.uniform(-0.03, 0.03) * H, ground - H * 0.93)
    limb(d, fork, lead, r0 * 0.5, r0 * 0.1, rng)
    tips += [lead, ((fork[0] + lead[0]) / 2, (fork[1] + lead[1]) / 2)]
    if season == "winter" and not marcescent: return
    pal = LEAF["late autumn" if season == "winter" else season]
    thin = {"late autumn": 0.35, "winter": 0.5, "early autumn": 0.95}.get(season, 1.0)
    # a beech's crown is a tall dome, leafy all the way down its sides: more sprays between the boughs
    top_y = ground - H * 0.95
    for i in range(int(10 + height * 2.2)):
        v = rng.random()
        cy = fork[1] + (top_y - fork[1]) * v + H * 0.04
        half = H * spread * (0.35 + 0.75 * math.sin(math.pi * min(1.0, v * 0.85 + 0.12)))
        tips.append((fork[0] + rng.uniform(-1, 1) * half, cy))
    order = sorted(tips, key=lambda p: -p[1])   # low sprays first, so the upper ones overlap them
    for (tx, ty) in order:
        if rng.random() > thin + 0.25: continue
        w = H * spread * rng.uniform(0.34, 0.5)
        spray(d, tx, ty, w, w * 0.34, pal, rng, int(w * 2.4 * thin))


def man(d, x, ground):
    h = MAN * PX
    d.ellipse([x - h * 0.07, ground - h, x + h * 0.07, ground - h * 0.86], fill=INK)                   # head and kalpak
    d.rectangle([x - h * 0.075, ground - h * 1.04, x + h * 0.075, ground - h * 0.95], fill=INK)
    d.polygon([(x - h * 0.13, ground - h * 0.85), (x + h * 0.13, ground - h * 0.85), (x + h * 0.16, ground - h * 0.4), (x - h * 0.16, ground - h * 0.4)], fill=INK)
    d.rectangle([x - h * 0.11, ground - h * 0.4, x - h * 0.02, ground], fill=INK)
    d.rectangle([x + h * 0.02, ground - h * 0.4, x + h * 0.11, ground], fill=INK)


def beech_sheet():
    W, Hh = 2700, 1650
    im = Image.new("RGB", (W, Hh), BG)
    d = ImageDraw.Draw(im)
    f1, f2, f3 = font(40), font(22), font(17)
    d.text((40, 26), "European beech, Fagus sylvatica (бук)", font=f1, fill=INK)
    d.text((40, 78), "Design sheet 1: sizes beside a man, and the year. Game scale: an old beech is about six men tall "
                     "(a real one is fifteen to twenty).", font=f2, fill=INK)
    g1 = 760
    d.line([(30, g1), (W - 30, g1)], fill=(150, 132, 104), width=3)
    man(d, 110, g1)
    d.text((70, g1 + 12), "a man", font=f3, fill=INK)
    sizes = [("sapling", 1.6, 0.06, 0.25, 0.5, False), ("young: can be felled", 4.2, 0.2, 0.38, 0.4, False),
             ("mature", 7.6, 0.5, 0.42, 0.42, False), ("old: can't be felled", 10.4, 0.85, 0.4, 0.46, False),
             ("deep wood: bole to the sky", 13.0, 0.75, 0.74, 0.34, False)]
    xs = [300, 580, 1040, 1680, 2380]
    for (name, h, girth, bole, spread, _), x in zip(sizes, xs):
        beech(d, x, g1, h, girth, "summer", hash(name) % 9999, bole, spread)
        d.text((x - 110, g1 + 12), name, font=f3, fill=INK)
    g2 = 1420
    d.line([(30, g2), (W - 30, g2)], fill=(150, 132, 104), width=3)
    seasons = ["spring", "summer", "early autumn", "autumn", "late autumn", "winter"]
    for i, s in enumerate(seasons):
        x = 240 + i * 410
        beech(d, x, g2, 8.0, 0.55, s, 77, 0.4, 0.4)
        d.text((x - 70, g2 + 12), s, font=f2, fill=INK)
    beech(d, 2520, g2, 3.4, 0.14, "winter", 5, 0.34, 0.42, marcescent=True)
    d.text((2440, g2 + 12), "young beech keep their\ndead leaves all winter", font=f3, fill=INK)
    notes = [
        "Bark: smooth and silver grey at every age, with thin dark scars across it. Never ridged or brown.",
        "Foot: flares out like an elephant's foot. Trunk: one clean straight bole, then boughs that rise steeply before they spread.",
        "Leaves: small, in flat sprays that lie level, so the crown is built of layers with shade between them. Lit on top, dark beneath.",
        "The year: lime green in spring, deep green in summer, then yellow, orange and copper. The leaves fall late and lie thick.",
        "The floor under beech: a deep copper litter with very little growing in it. Bracken and bushes keep to the edges and clearings.",
    ]
    for i, n in enumerate(notes): d.text((40, 1490 + i * 28), n, font=f3, fill=INK)
    # swatches
    sx = 1900
    d.text((sx, 1490), "bark", font=f3, fill=INK)
    for k, c in enumerate(BARK): d.rectangle([sx + 60 + k * 34, 1488, sx + 90 + k * 34, 1512], fill=c)
    for j, s in enumerate(["spring", "summer", "autumn", "late autumn"]):
        d.text((sx, 1520 + j * 28), s, font=f3, fill=INK)
        for k, c in enumerate(LEAF[s]): d.rectangle([sx + 110 + k * 34, 1518 + j * 28, sx + 140 + k * 34, 1542 + j * 28], fill=c)
    im.save("art/trees/design/beech.png")
    print("art/trees/design/beech.png")


beech_sheet()
