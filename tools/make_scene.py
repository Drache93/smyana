#!/usr/bin/env python3
"""Writes data/maps/camp_clearing.json: the mock-up's beech clearing (archive picture 23) laid out tile for tile, to
compare the game beside it (Dominic, 2026-11-10: "please recreate the scene with river on the right, full trees at the
back, clearing, so we can compare better"). Not on the route: `leg:camp_look camp:29,32 look:30,30 hour:16 zoom:2`.
On screen right is x - y and down is x + y; at the mock-up's zoom the window shows about twelve tiles each way.
Run from the repo's root: python3 tools/make_scene.py"""
import json, math, random

W = H = 60
CX, CY = 30, 30
LEGEND = {".": "grass", ":": "trail", "T": "tree", "t": "young_tree", "#": "rock", "~": "water", "=": "ford"}
rng = random.Random(23)
g = [["."] * W for _ in range(H)]


def sr(x, y): return (x - y) - (CX - CY), (x + y) - (CX + CY)   # right, down (in tiles' half-diagonals)


# the stream: in at the right's middle, out at the bottom's middle, bending
def run(points, ch, over):
    """a run of tiles through the points, joined edge to edge (never only by corners, which would break it)"""
    last = None
    for (x, y) in points:
        x, y = int(round(x)), int(round(y))
        if last and x != last[0] and y != last[1] and g[last[1]][x] in over: g[last[1]][x] = "=" if g[last[1]][x] == "~" else ch
        if 0 <= x < W and 0 <= y < H and g[y][x] in over: g[y][x] = "=" if g[y][x] == "~" else ch
        last = (x, y)


pts = []
for i in range(-60, 61):
    d = i / 3.0                      # down
    # (as the mock-up's: in at the right edge level with the camp, steeply down to the ford, then gentler to the
    # bottom's middle; measured on the picture at the game's 22 degrees and zoom 2)
    r = 4.6 - 0.4 * (d - 3.0) - 0.5 * min(0.0, d - 3.0) + 0.5 * math.sin(d * 0.6)   # right
    pts.append(((r + d) / 2.0 + CX, (d - r) / 2.0 + CY))
run(pts, "~", ".")
stream = [int(round(v * 1000)) for p in pts[::2] for v in p]

# the clearing: an oval, wider than deep on screen, the stream through its right side
def in_clearing(x, y):
    r, d = sr(x, y)
    # (open down to the picture's bottom edge, where a dark row of trees closes it)
    return ((r + 0.5) / 8.6) ** 2 + ((d - 2.25) / 11.75) ** 2 <= 1.0

# the trail: from the fire rightwards to the stream and over it
pts = []
for i in range(-9, 16):
    r = i / 3.0
    d = 1.7 + (r + 3.0) * 0.3 + 0.25 * math.sin(r * 0.7)   # (down to the ford, winding a little)
    pts.append(((r + d) / 2.0 + CX, (d - r) / 2.0 + CY))
run(pts, ":", ".~")   # (where it meets the stream: a ford)
# the camp (the camp thread's models, src/smyana/camp.lobster), as the mock-up has it: the fire left of the middle, the
# tents behind it, the woodpile before it, the pack mules to the right of the tents and the horses at the wood's edge
FIRE = (-3.0, 1.0)   # (the look's camp:29,32: the middle of that tile)
camp = []
def stand(name, r, d):
    camp.append([name, int(round(((r + d) / 2.0 + CX) * 1000)), int(round(((d - r) / 2.0 + CY) * 1000))])
stand("tent0", FIRE[0] + 0.2, FIRE[1] - 2.2)
stand("tent1", FIRE[0] + 2.1, FIRE[1] - 2.0)
stand("tent1", FIRE[0] - 1.5, FIRE[1] - 2.3)
stand("woodpile", FIRE[0] - 1.2, FIRE[1] + 0.6)
# (what the mock-up's camp has lying about it, from the wood's own pieces: a log to sit on before the fire, a block to
# split wood on by the pile, stones by the tent, and flat slabs of gneiss to step on in the ford)
stand("log0", FIRE[0] + 1.3, FIRE[1] + 1.1)
stand("stump", FIRE[0] - 2.0, FIRE[1] + 1.3)
stand("slabs0", FIRE[0] + 3.4, FIRE[1] - 1.5)
stand("slabs1", FIRE[0] + 7.0, FIRE[1] + 4.0)
for i in range(3): stand("mule%d" % [1, 4, 6][i], FIRE[0] + 4.0 + i * 0.95, FIRE[1] - 2.1 + 0.15 * (i % 2))
for i in range(5): stand("horse%d" % [0, 5, 2, 1, 7][i], FIRE[0] + 2.2 + i * 0.95, FIRE[1] - 3.8 - 0.2 * (i % 2))
# the men who aren't at the fire: by the mules, on the trail, at the stream and over it, as in the mock-up
men = []
for (r, d) in ((4.4, -1.5), (2.9, 1.4), (6.6, 3.2), (7.6, 3.7), (8.9, 2.4), (4.3, 4.2), (-2.4, -0.7), (0.9, -1.3), (6.4, -2.8), (-0.6, 2.9), (-5.0, -0.3), (3.4, -3.2)):
    men.append([int(round(((FIRE[0] + r + FIRE[1] + d) / 2.0 + CX) * 1000)), int(round(((FIRE[1] + d - FIRE[0] - r) / 2.0 + CY) * 1000))])
def by_camp(x, y): return any(abs(x + 0.5 - cx / 1000.0) < 0.7 and abs(y + 0.5 - cy / 1000.0) < 0.7 for _, cx, cy in camp)

# the trees: thick at the back (the top of the picture), close round the clearing, a few big ones framing it
olds = []
def near(x, y, chars, rad):
    return any(g[yy][xx] in chars for yy in range(max(0, y - rad), min(H, y + rad + 1)) for xx in range(max(0, x - rad), min(W, x + rad + 1)))

for (r, d) in ((-5.9, 5.3), (6.6, 5.8), (-7.9, 9.5), (8.0, 11.5)):   # (none up-sun of the camp: it stands in the light)
    x, y = int(round((r + d) / 2.0 + CX)), int(round((d - r) / 2.0 + CY))
    if g[y][x] == "." and not by_camp(x, y):
        g[y][x] = "T"
        olds.append((x, y))
for _ in range(W * H * 3):
    x, y = rng.randrange(1, W - 1), rng.randrange(1, H - 1)
    if g[y][x] != "." or in_clearing(x, y) or near(x, y, "~=:", 0) or by_camp(x, y): continue
    r, d = sr(x, y)
    gap = 1.0 if d < -3.5 else 1.3
    if any((x - ox) ** 2 + (y - oy) ** 2 < gap * gap for ox, oy in olds): continue
    olds.append((x, y))
    g[y][x] = "T"

doc = {
    "schema": "aow.map/2", "id": "camp_clearing", "width": W, "height": H, "legend": LEGEND,
    "starts": [[CX - 1, CY + 1]], "rim": 10,
    "gates": {"west": [CX - 3, CY - 1, CX - 1, CY + 1]},
    "wood": "beech",
    "scene": 1,
    "pines": 0,
    "stream": 0.42,
    "shore_soft": 0.3,
    "grass_seed": 9057,
    "camp": camp,
    "fire": [int(round(((FIRE[0] + FIRE[1]) / 2.0 + CX) * 1000)), int(round(((FIRE[1] - FIRE[0]) / 2.0 + CY) * 1000))],
    "men": men,
    "streams": [stream],
}
with open("data/maps/camp_clearing.json", "w") as f:
    f.write("{\n")
    for k, v in doc.items(): f.write(' %s: %s,\n' % (json.dumps(k), json.dumps(v)))
    f.write(' "rows": [\n' + ",\n".join('  "%s"' % "".join(r) for r in g) + "\n ]\n}\n")
print("camp_clearing: %d old trees" % len(olds))
