#!/usr/bin/env python3
"""Writes data/maps/camp_clearing.json: the mock-up's beech clearing (archive picture 23) laid out tile for tile, to
compare the game beside it (Dominic, 2026-11-10: "please recreate the scene with river on the right, full trees at the
back, clearing, so we can compare better"). Not on the route: `leg:camp_look camp:30,31`.
On screen right is x - y and down is x + y; at the mock-up's zoom the window shows about twelve tiles each way.
Run from the repo's root: python3 tools/make_scene.py"""
import json, math, random

W = H = 60
CX, CY = 30, 30
LEGEND = {".": "grass", ":": "trail", "T": "tree", "t": "young_tree", "#": "rock", "~": "river", "=": "ford"}
rng = random.Random(23)
g = [["."] * W for _ in range(H)]


def sr(x, y): return (x - y) - (CX - CY), (x + y) - (CX + CY)   # right, down (in tiles' half-diagonals)


# the stream: in at the right's middle, out at the bottom's middle, bending
def run(points, ch, over):
    """a run of tiles through the points, joined edge to edge (never only by corners, which would break it)"""
    last = None
    for (x, y) in points:
        x, y = int(round(x)), int(round(y))
        if last and x != last[0] and y != last[1] and g[last[1]][x] in over: g[last[1]][x] = ch
        if 0 <= x < W and 0 <= y < H and g[y][x] in over: g[y][x] = ch
        last = (x, y)


pts = []
for i in range(-60, 61):
    d = i / 3.0                      # down
    r = 4.6 - 0.36 * d + 0.9 * math.sin(d * 0.45)   # right
    pts.append(((r + d) / 2.0 + CX, (d - r) / 2.0 + CY))
run(pts, "~", ".")

# the clearing: an oval, wider than deep on screen, the stream through its right side
def in_clearing(x, y):
    r, d = sr(x, y)
    return ((r + 0.5) / 6.6) ** 2 + ((d - 0.6) / 5.2) ** 2 <= 1.0

# the trail: from the fire rightwards to the stream and over it
pts = []
for i in range(-9, 24):
    r = i / 3.0
    d = 0.9 + 0.25 * math.sin(r * 0.7)
    pts.append(((r + d) / 2.0 + CX, (d - r) / 2.0 + CY))
run(pts, ":", ".")
for y in range(H):
    for x in range(W):
        if g[y][x] == "~" and any(g[y + dy][x + dx] == ":" for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))) and any(g[y + dy][x + dx] == ":" for dx, dy in ((1, 0), (0, -1))) and any(g[y + dy][x + dx] == ":" for dx, dy in ((-1, 0), (0, 1))): g[y][x] = "="

# the trees: thick at the back (the top of the picture), close round the clearing, a few big ones framing it
olds = []
def near(x, y, chars, rad):
    return any(g[yy][xx] in chars for yy in range(max(0, y - rad), min(H, y + rad + 1)) for xx in range(max(0, x - rad), min(W, x + rad + 1)))

for (r, d) in ((-5.6, -1.2), (5.4, 0.2), (-4.2, 4.6), (2.2, 5.6), (-1.0, -5.4), (3.0, -4.8), (-6.4, 2.2), (6.2, 3.6)):
    x, y = int(round((r + d) / 2.0 + CX)), int(round((d - r) / 2.0 + CY))
    if g[y][x] == ".":
        g[y][x] = "T"
        olds.append((x, y))
for _ in range(W * H * 3):
    x, y = rng.randrange(1, W - 1), rng.randrange(1, H - 1)
    if g[y][x] != "." or in_clearing(x, y) or near(x, y, "~=:", 0): continue
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
}
with open("data/maps/camp_clearing.json", "w") as f:
    f.write("{\n")
    for k, v in doc.items(): f.write(' %s: %s,\n' % (json.dumps(k), json.dumps(v)))
    f.write(' "rows": [\n' + ",\n".join('  "%s"' % "".join(r) for r in g) + "\n ]\n}\n")
print("camp_clearing: %d old trees" % len(olds))
