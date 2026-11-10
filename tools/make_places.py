#!/usr/bin/env python3
"""Grey-boxes the places of the run: writes data/maps/<id>.json for each. A place is one map (D-020). These are
stand-ins to walk through, not the real layouts: a trail from one gate to the other, a stream with a ford, the valley's
rocky sides, old giant trees you walk between and clumps of young ones you can fell. Change the numbers and run again,
or edit a map's rows by hand afterwards (then don't run this again for that place).
Run from the repo's root: python3 tools/make_places.py"""
import json, math, random

LEGEND = {".": "grass", ":": "trail", "T": "tree", "t": "young_tree", "#": "rock", "~": "water", "=": "ford"}


def noise1(rng, n, step):
    """a smooth line of n values in -1..1: random knots `step` apart, eased between"""
    knots = [rng.uniform(-1, 1) for _ in range(n // step + 3)]
    out = []
    for i in range(n):
        a, t = divmod(i, step)
        t = t / step
        t = t * t * (3 - 2 * t)
        out.append(knots[a] * (1 - t) + knots[a + 1] * t)
    return out


def place(pid, seed, w, h, west_y, east_y, stream_x, old_gap, old_fill, young_clumps, clearings, rocks):
    rng = random.Random(seed)
    g = [["."] * w for _ in range(h)]

    def put(x, y, ch, over="."):
        if 0 <= x < w and 0 <= y < h and g[y][x] in over: g[y][x] = ch

    # the trail: from the west gate to the east gate, wandering
    wob = noise1(rng, w, 12)
    trail_y = []
    for x in range(w):
        t = x / (w - 1)
        base = west_y + (east_y - west_y) * (t * t * (3 - 2 * t))
        edge = min(x, w - 1 - x) / 10.0
        trail_y.append(int(round(base + wob[x] * 7 * min(1.0, edge))))
    # the valley's sides: rock along the north and south edges, ragged
    north = noise1(rng, w, 9)
    south = noise1(rng, w, 9)
    for x in range(w):
        for y in range(int(2.5 + north[x] * 2.0)): put(x, y, "#")
        for y in range(int(2.5 + south[x] * 2.0)): put(x, h - 1 - y, "#")
    for (cx, cy, r) in rocks:
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + rng.uniform(-1.5, 1.5): put(x, y, "#")
    # the stream: north to south, two tiles wide, a ford where the trail crosses
    if stream_x >= 0:
        sw = noise1(rng, h, 8)
        for y in range(h):
            sx = int(round(stream_x + sw[y] * 5))
            for x in (sx, sx + 1): put(x, y, "~", ".#")
        for y in range(h):
            for x in range(w):
                if g[y][x] == "~" and abs(y - trail_y[x]) <= 1: g[y][x] = "="
    # the trail itself, two tiles wide (not through the ford)
    for x in range(w):
        for y in (trail_y[x], trail_y[x] + 1): put(x, y, ":", ".#")

    def near(x, y, chars, r):
        for yy in range(max(0, y - r), min(h, y + r + 1)):
            for xx in range(max(0, x - r), min(w, x + r + 1)):
                if g[yy][xx] in chars: return True
        return False

    def in_clearing(x, y):
        return any((x - cx) ** 2 + (y - cy) ** 2 <= r * r for (cx, cy, r) in clearings)

    # the old trees: giants, a few tiles apart so the men walk between them, off the trail and the water
    olds = []
    for _ in range(int(w * h * old_fill)):
        x, y = rng.randrange(2, w - 2), rng.randrange(2, h - 2)
        if g[y][x] != "." or in_clearing(x, y) or near(x, y, ":=~", 1): continue
        if any((x - ox) ** 2 + (y - oy) ** 2 < old_gap * old_gap for ox, oy in olds): continue
        olds.append((x, y))
        g[y][x] = "T"
    # young trees: clumps to fell, never touching each other on all sides (a man must reach each one)
    for _ in range(young_clumps):
        cx, cy = rng.randrange(4, w - 4), rng.randrange(5, h - 5)
        if in_clearing(cx, cy): continue
        for _ in range(rng.randrange(4, 9)):
            x, y = cx + rng.randrange(-3, 4), cy + rng.randrange(-3, 4)
            if 1 <= x < w - 1 and 1 <= y < h - 1 and g[y][x] == "." and not near(x, y, ":=~", 0) and not near(x, y, "tT", 1):
                g[y][x] = "t"
    gates = {"west": [0, trail_y[0] - 3, 3, trail_y[0] + 4], "east": [w - 4, trail_y[w - 1] - 3, w - 1, trail_y[w - 1] + 4]}
    doc = {
        "schema": "aow.map/2", "id": pid, "width": w, "height": h, "legend": LEGEND,
        "starts": [[3, trail_y[3]]],
        # Smyana's own: where the men walk off this place (tile rectangles x0, y0, x1, y1), by edge name. route.json
        # says where each edge leads.
        "gates": gates,
        "rows": ["".join(r) for r in g],
    }
    with open("data/maps/%s.json" % pid, "w") as f:
        f.write("{\n")
        keys = list(doc.keys())
        for k in keys[:-1]: f.write(' %s: %s,\n' % (json.dumps(k), json.dumps(doc[k])))
        f.write(' "rows": [\n' + ",\n".join('  "%s"' % r for r in doc["rows"]) + "\n ]\n}\n")
    n = lambda ch: sum(r.count(ch) for r in doc["rows"])
    print("%s: %dx%d, %d old trees, %d young, gates %s" % (pid, w, h, n("T"), n("t"), gates))


# The beech valley (the first place, and the last before home): open old beech wood, a stream, meadows.
place("beech_valley", 1878, 96, 64, west_y=33, east_y=28, stream_x=52, old_gap=4.2, old_fill=0.5, young_clumps=26,
      clearings=[(9, 33, 6), (70, 24, 7)], rocks=[(30, 12, 3), (61, 50, 4), (84, 40, 2)])
# The deep fir woods: closer, darker, more rock, no stream. (Drawn with the same trees for now.)
place("fir_woods", 1879, 96, 64, west_y=28, east_y=36, stream_x=-1, old_gap=3.4, old_fill=0.6, young_clumps=34,
      clearings=[(48, 30, 5)], rocks=[(20, 44, 4), (40, 14, 3), (66, 20, 5), (78, 50, 3)])
