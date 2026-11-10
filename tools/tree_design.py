#!/usr/bin/env python3
"""Draws a tree's 2D design sheet (art/trees/design/<kind>.png): its sizes beside a man, and its look in each season.
The design comes first and the voxel model is made from it (D-035). Run from the repo's root:
python3 tools/tree_design.py [beech|spruce]   (Pillow)"""
import math, random, sys
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


def limb(d, a, b, wa, wb, rng, BARK=BARK):
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


SPRUCE_BARK = [(158, 126, 104), (126, 96, 78), (94, 70, 58), (62, 46, 40)]   # thin red-brown scales, greyer with age
NEEDLE = [(98, 132, 78), (56, 92, 56), (32, 62, 42), (18, 38, 30)]           # dark, a little blue: lit top to deep shade
TIP = (156, 196, 84)                                                         # the new shoots of May
CONE = [(176, 124, 70), (128, 84, 48)]
SNOW = [(246, 247, 250), (206, 214, 226)]


def bough(d, a, length, side, lift, pal, rng, tips=False, snow=False, cones=0, belly=0.16):
    """a spruce bough from a on the trunk: out, sagging, its tip turned up again, with the branchlets hanging from it
    like a comb. lift: 1 rises (near the top), 0 lies level, -1 droops (low down)."""
    pts = []
    n = max(4, int(length / 5))
    for i in range(n + 1):
        t = i / n
        sag = -lift * 0.34 * t + belly * math.sin(math.pi * t) - 0.1 * t * t * t * (1 if lift < 0.6 else 0)
        pts.append((a[0] + side * length * t, a[1] + length * sag))
    hang = length * 0.2 + 3
    for i, (x, y) in enumerate(pts):            # the hanging branchlets: dark, longest in the middle of the bough
        t = i / n
        h = hang * (0.35 + 0.65 * math.sin(math.pi * min(1.0, t * 0.9 + 0.1)))
        for k in range(3):
            xx = x + rng.uniform(-3, 3)
            hh = h * rng.uniform(0.5, 1.0)
            d.line([(xx, y), (xx + side * rng.uniform(-1, 2), y + hh)], fill=pal[3 if k == 0 else 2], width=3)
    for i, (x, y) in enumerate(pts):            # the top of the bough: lit
        t = i / n
        r = 2.2 + 3.2 * (1 - t) + length * 0.012
        d.ellipse([x - r * 1.5, y - r, x + r * 1.5, y + r * 0.7], fill=pal[1])
    for i, (x, y) in enumerate(pts):
        t = i / n
        r = 1.6 + 2.2 * (1 - t) + length * 0.008
        if rng.random() < 0.75: d.ellipse([x - r * 1.5, y - r * 1.3, x + r * 0.9, y - r * 0.1], fill=pal[0])
        if snow and rng.random() < 0.9:
            d.ellipse([x - r * 1.9, y - r * 1.9, x + r * 1.9, y - r * 0.2], fill=SNOW[0])
            d.ellipse([x - r * 1.2, y - r * 0.7, x + r * 1.9, y - r * 0.1], fill=SNOW[1])
    if tips:
        for (x, y) in pts[n // 2:]:
            for k in range(2): 
                xx, yy = x + rng.uniform(-4, 4), y + rng.uniform(-3, hang * 0.6)
                d.ellipse([xx - 1.6, yy - 1.6, xx + 1.6, yy + 1.6], fill=TIP)
        x, y = pts[-1]
        d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=TIP)
    for k in range(cones):                      # cones hang, long and thin, from the outer half of the top boughs
        x, y = pts[rng.randrange(n // 2, n + 1)]
        x += rng.uniform(-3, 3)
        d.ellipse([x - 2.6, y + 2, x + 2.6, y + 15], fill=CONE[1])
        d.ellipse([x - 2.6, y + 2, x + 0.6, y + 14], fill=CONE[0])


def spruce(d, x, ground, height, girth, season, seed, bole=0.06, spread=0.2, stand=False):
    """Norway spruce. bole: how far up the trunk is clear of live boughs. stand: grown among others, so the lower
    trunk carries dead stubs and no green."""
    rng = random.Random(seed)
    H = height * PX
    r0 = girth * PX / 2
    top = (x + rng.uniform(-0.006, 0.006) * H, ground - H)
    # the foot: shallow roots running out along the ground, no deep flare
    d.polygon([(x - r0 * 2.2, ground), (x - r0, ground - r0 * 1.2), (x + r0, ground - r0 * 1.2), (x + r0 * 2.2, ground)], fill=SPRUCE_BARK[2])
    d.polygon([(x - r0 * 2.2, ground), (x - r0, ground - r0 * 1.2), (x - r0 * 0.3, ground - r0 * 1.2), (x - r0 * 0.8, ground)], fill=SPRUCE_BARK[0])
    limb(d, (x, ground - r0 * 0.6), top, r0, 1.2, rng, SPRUCE_BARK)
    for i in range(int(H * max(bole, 0.1) / 9)):        # the bark: small round scales
        yy = ground - r0 - rng.random() * H * max(bole, 0.1)
        xx = x + rng.uniform(-0.8, 0.7) * r0
        d.arc([xx - 4, yy - 3, xx + 4, yy + 5], 200, 340, fill=SPRUCE_BARK[3])
    base = ground - H * bole
    if stand:                                           # dead stubs and thin dead boughs below the green
        for i in range(int(height * 1.4)):
            yy = ground - H * (0.12 + rng.random() * (bole - 0.14))
            side = rng.choice((-1, 1))
            ln = rng.uniform(0.02, 0.07) * H
            d.line([(x, yy), (x + side * ln, yy + ln * rng.uniform(0.1, 0.5))], fill=SPRUCE_BARK[3], width=2)
    levels = max(5, int((H * (1 - bole)) / (H * 0.022 + 9)))
    rows = []
    for i in range(levels):
        t = i / (levels - 1)                            # 0 the lowest live whorl, 1 the tip
        y = base + (top[1] + H * 0.035 - base) * t
        ln = H * spread * (1 - t) ** 0.8 * rng.uniform(0.86, 1.08) + H * 0.012
        if stand and t < 0.12: ln *= 0.55 + t * 3       # the lowest live boughs in a stand are thin and short
        lift = -1.0 + 2.0 * min(1.0, t * 1.25)          # droop at the foot, level in the middle, rising at the top
        rows.append((y, ln, lift, t))
    pal = NEEDLE
    for (y, ln, lift, t) in rows:                       # low boughs first: each whorl overlaps the one below
        # the boughs that come toward us: a dark heap over the trunk
        w = ln * 0.42
        for k in range(int(4 + w / 5)):
            xx, yy = x + rng.gauss(0, 0.4) * w, y + rng.uniform(-0.02, 0.2) * ln + 3
            d.line([(xx, yy), (xx, yy + ln * 0.16 + 4)], fill=pal[3 if rng.random() < 0.6 else 2], width=4)
        nc = 1 if (height > 8 and t > 0.62 and t < 0.94 and rng.random() < 0.7) else 0
        for side in (-1, 1):
            bough(d, (x, y), ln * rng.uniform(0.9, 1.05), side, lift, pal, rng, tips=season == "spring",
                  snow=season == "winter", cones=nc if season != "spring" else 0)
        for k in range(int(2 + w / 9)):                 # light on the near boughs
            xx, yy = x + rng.gauss(-0.15, 0.4) * w, y + rng.uniform(-0.03, 0.06) * ln
            d.ellipse([xx - 5, yy - 2.5, xx + 5, yy + 2.5], fill=pal[1 if rng.random() < 0.7 else 0])
            if season == "winter" and rng.random() < 0.6: d.ellipse([xx - 6, yy - 5, xx + 6, yy - 0.5], fill=SNOW[0])
    # the leader: one straight spike
    d.line([(top[0], top[1] + H * 0.05), (top[0], top[1] - H * 0.012)], fill=pal[2], width=3)
    if season == "spring": d.line([(top[0], top[1] + H * 0.012), (top[0], top[1] - H * 0.012)], fill=TIP, width=3)


def spruce_sheet():
    W, Hh = 2700, 1900
    im = Image.new("RGB", (W, Hh), BG)
    d = ImageDraw.Draw(im)
    f1, f2, f3 = font(40), font(22), font(17)
    d.text((40, 26), "Norway spruce, Picea abies (смърч)", font=f1, fill=INK)
    d.text((40, 78), "Design sheet 2: sizes beside a man, and the year. Game scale: an old spruce is about eight men tall "
                     "(a real one is twenty or more). Taller and far narrower than the beech.", font=f2, fill=INK)
    g1 = 900
    d.line([(30, g1), (W - 30, g1)], fill=(150, 132, 104), width=3)
    man(d, 110, g1)
    d.text((70, g1 + 12), "a man", font=f3, fill=INK)
    sizes = [("sapling", 1.5, 0.05, 0.04, 0.3, False, 11), ("young: can be felled", 4.6, 0.16, 0.05, 0.25, False, 12),
             ("mature, in the open:\ngreen to the ground", 9.2, 0.42, 0.06, 0.21, False, 13),
             ("old: can't be felled", 13.2, 0.7, 0.16, 0.19, False, 14),
             ("in a stand: bare bole,\ndead stubs, green high up", 12.4, 0.5, 0.52, 0.15, True, 15),
             ("deep wood: bole to the sky", 16.5, 0.72, 0.72, 0.13, True, 16)]
    xs = [290, 520, 900, 1420, 1900, 2380]
    for (name, h, girth, bole, spread, stand, seed), x in zip(sizes, xs):
        spruce(d, x, g1, h, girth, "summer", seed, bole, spread, stand)
        d.multiline_text((x - 110, g1 + 30), name, font=f3, fill=INK)
    g2 = 1620
    d.line([(30, g2), (W - 30, g2)], fill=(150, 132, 104), width=3)
    seasons = [("spring: bright new tips", "spring"), ("summer", "summer"), ("autumn: unchanged,\ndark against the beech", "autumn"),
               ("winter: snow lies on\nthe boughs and bends them", "winter")]
    for i, (label, s) in enumerate(seasons):
        x = 260 + i * 470
        spruce(d, x, g2, 9.6, 0.42, s, 21, 0.07, 0.2)
        d.multiline_text((x - 110, g2 + 30), label, font=f3, fill=INK)
    # the two shapes a bough takes, close up
    bx = 2150
    rng = random.Random(4)
    d.text((bx - 60, g2 - 470), "a bough, close up", font=f2, fill=INK)
    limb(d, (bx, g2 - 60), (bx, g2 - 410), 26, 22, rng, SPRUCE_BARK)
    for k in range(40):
        yy = g2 - 70 - rng.random() * 330
        xx = bx + rng.uniform(-18, 16)
        d.arc([xx - 6, yy - 4, xx + 6, yy + 7], 200, 340, fill=SPRUCE_BARK[3])
    bough(d, (bx + 20, g2 - 360), 300, 1, 0.9, NEEDLE, rng, cones=3, belly=0.07)
    bough(d, (bx + 20, g2 - 250), 330, 1, 0.0, NEEDLE, rng, belly=0.07)
    bough(d, (bx + 20, g2 - 140), 330, 1, -0.9, NEEDLE, rng, belly=0.07)
    d.text((bx + 360, g2 - 440), "top: rises", font=f3, fill=INK)
    d.text((bx + 380, g2 - 250), "middle: level", font=f3, fill=INK)
    d.multiline_text((bx + 380, g2 - 90), "low: droops,\ntip turns up", font=f3, fill=INK)
    notes = [
        "Shape: a narrow spire with one straight leader. Boughs in whorls: rising near the top, level in the middle, drooping low down with the tips turned up again.",
        "Branchlets hang from each bough like a comb or a curtain, so every bough is lit along its top and dark beneath. Long thin cones hang from the top third.",
        "Bark: thin red-brown scales, greyer on old trunks. Roots are shallow and run out along the ground: a fallen spruce lifts a whole plate of earth.",
        "In the open it is green to the ground. In a stand the lower boughs die: a bare bole with grey stubs, and the green starts high up. That is the deep-wood tree.",
        "The year: it never changes colour. Bright tips in May, snow in winter. In autumn it is the dark that the beech's copper burns against.",
        "The floor under spruce: brown needles, moss on rocks and logs, bilberry. Dim and green, where the beech floor is copper and open.",
    ]
    for i, n in enumerate(notes): d.text((40, 1706 + i * 28), n, font=f3, fill=INK)
    sx = 2150
    for j, (name, cols) in enumerate([("bark", SPRUCE_BARK), ("needles", NEEDLE), ("new tips, cones", [TIP] + CONE), ("snow", SNOW)]):
        d.text((sx, 1706 + j * 28), name, font=f3, fill=INK)
        for k, c in enumerate(cols): d.rectangle([sx + 150 + k * 34, 1704 + j * 28, sx + 180 + k * 34, 1728 + j * 28], fill=c, outline=(150, 132, 104))
    im.save("art/trees/design/spruce.png")
    print("art/trees/design/spruce.png")


SHEETS = {"beech": beech_sheet, "spruce": spruce_sheet}
for name in sys.argv[1:] or SHEETS: SHEETS[name]()
