#!/usr/bin/env python3
"""Grey-boxes the places of the run: writes data/maps/<id>.json for each. A place is one map (D-020). These are
stand-ins to walk through, not the real layouts: a trail from one gate to the other, a stream with a ford, the valley's
rocky sides, old giant trees you walk between and clumps of young ones you can fell. Change the numbers and run again,
or edit a map's rows by hand afterwards (then don't run this again for that place).
Run from the repo's root: python3 tools/make_places.py"""
import json, math, random

LEGEND = {".": "grass", ":": "trail", "T": "tree", "t": "young_tree", "#": "rock", "~": "water", "=": "ford", "%": "rubble", "b": "bare"}


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


RIM = 10  # tiles of thick forest round every place, so the view never runs off the map (the camera stays inside it)


def place(pid, wood, seed, w, h, west_y, east_y, stream_x, old_gap, old_fill, young_clumps, clearings, rocks, slide=None):
    # (the numbers are given for the part you walk in: the rim is added round it)
    w, h, west_y, east_y = w + RIM * 2, h + RIM * 2, west_y + RIM, east_y + RIM
    if stream_x >= 0: stream_x += RIM
    clearings = [(x + RIM, y + RIM, r) for (x, y, r) in clearings]
    rocks = [(x + RIM, y + RIM, r) for (x, y, r) in rocks]
    rng = random.Random(seed)

    def rim(x, y): return min(x, w - 1 - x, y, h - 1 - y) < RIM
    g = [["."] * w for _ in range(h)]

    def put(x, y, ch, over="."):
        if 0 <= x < w and 0 <= y < h and g[y][x] in over: g[y][x] = ch

    # the trail: from the west gate to the east gate, wandering
    wob = noise1(rng, w, 12)
    trail_y = []
    for x in range(w):
        t = x / (w - 1)
        base = west_y + (east_y - west_y) * (t * t * (3 - 2 * t))
        edge = max(0, min(x, w - 1 - x) - RIM) / 10.0
        trail_y.append(int(round(base + wob[x] * 7 * min(1.0, edge))))
    if slide:  # (the ledge of the pass runs level and straight)
        for x in range(slide[0] + RIM - slide[1] - 1, slide[0] + RIM + slide[1] + 2): trail_y[x] = trail_y[slide[0] + RIM]
    # the valley's sides: rock along the north and south edges, ragged
    north = noise1(rng, w, 9)
    south = noise1(rng, w, 9)
    for x in range(w):
        for y in range(int(2.5 + north[x] * 2.0)): put(x, RIM - 2 + y, "#")
        for y in range(int(2.5 + south[x] * 2.0)): put(x, h + 1 - RIM - y, "#")
    for (cx, cy, r) in rocks:
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + rng.uniform(-1.5, 1.5): put(x, y, "#")
    # the stream: north to south, a tile wide (two or three men: it is a stream, as in the mock-ups, not a river), with
    # no gaps at its bends, a ford where the trail crosses
    if stream_x >= 0:
        sw = noise1(rng, h, 8)
        last = None
        for y in range(h):
            sx = int(round(stream_x + sw[y] * 5))
            for x in range(min(sx, sx if last is None else last), max(sx, sx if last is None else last) + 1): put(x, y, "~", ".#")
            last = sx
        for y in range(h):
            for x in range(w):
                if g[y][x] == "~" and abs(y - trail_y[x]) <= 1: g[y][x] = "="
    # the trail itself, a tile wide and unbroken (not through the ford)
    for x in range(w):
        a, b = trail_y[x], trail_y[max(0, x - 1)]
        for y in range(min(a, b), max(a, b) + 1): put(x, y, ":", ".#")

    # a landslide, found after it has happened (#20; Dominic: "smaller and more focused. Like on a pass above a cliff
    # face, so we only have a very tight space to go, and it's blocked"). The trail runs a ledge on a mountain's side:
    # a cliff above it (a bluff four levels up), a gorge below it (four levels down, a river in its bed), and where
    # the cliff has let go its debris lies across the trail. Bare mountain ground: no forest stands on the ledge or
    # in front of the faces. One tile of the ledge's lip is left to squeeze by until the men can clear it.
    lev = {}
    bare_zone = []
    if slide:
        sx, half = slide[0] + RIM, slide[1]
        ty = trail_y[sx]
        gw, gw2 = noise1(rng, w, 5), noise1(rng, w, 6)
        # (the faces don't run ruler-straight: the ledge widens and narrows by a tile in runs of two to four tiles, the
        # bluff stepping back and the lip stepping out, and it is at its tightest where the slide lies)
        back, out = {}, {}
        x = sx - half
        while x <= sx + half:
            n, a, b = rng.randrange(2, 5), rng.choice((0, 1, 1)), rng.choice((0, 0, 1))
            for xx in range(x, x + n):
                tight = abs(xx - sx) <= 2
                back[xx], out[xx] = (0 if tight else a), (0 if tight else b)
            x += n
        for x in range(sx - half, sx + half + 1):
            t = (x - (sx - half)) / (2.0 * half)
            wall = 3 + int(round(2 * math.sin(math.pi * t)))
            for y in range(ty - back[x] - wall, ty - back[x]):  # the bluff above
                g[y][x] = "b" if y == ty - back[x] - 1 and rng.random() < 0.15 else "."
                lev[(x, y)] = 8
            for y in range(ty - back[x], ty): g[y][x] = "."     # the ledge where the bluff steps back: turf
            for y in range(ty + 1, ty + 2 + out[x]): g[y][x] = "b" if abs(x - sx) <= 1 else "."   # the ledge's lip
            deep = 2 + int(round(4.5 * math.sin(math.pi * t) ** 0.6 + gw[x] * 1.2))
            top = ty + 2 + out[x]
            mid = top + deep / 2.0 + gw2[x] * 1.2
            for y in range(top, top + deep):                    # the gorge below: a river winding in a stony bed
                g[y][x] = "~" if abs(y + 0.5 - mid) <= 1.0 and deep >= 4 else "b"
                lev[(x, y)] = 0
            put(x, top + deep, ".", "#")
        for x in range(sx - 1, sx + 2): g[ty][x] = "%"          # the heap at the cliff's foot, across the trail
        g[ty + 1][sx - 1] = "%"
        g[ty + 1][sx] = ":"
        bare_zone = [(sx - half - 3, ty - 8, sx + half + 3, ty + 20)]

    def near(x, y, chars, r):
        for yy in range(max(0, y - r), min(h, y + r + 1)):
            for xx in range(max(0, x - r), min(w, x + r + 1)):
                if g[yy][xx] in chars: return True
        return False

    def near_t(x, y):
        return any(g[yy][xx] == "t" for yy in range(y - 1, y + 2) for xx in range(x - 1, x + 2))

    def in_clearing(x, y):
        if any(x0 <= x <= x1 and y0 <= y <= y1 for (x0, y0, x1, y1) in bare_zone): return True
        return any((x - cx) ** 2 + (y - cy) ** 2 <= r * r for (cx, cy, r) in clearings)

    # (below the gorge the wood starts again low: young trees only, nothing tall standing in front of the cliff)
    for (x0, y0, x1, y1) in bare_zone:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if g[y][x] == "." and (x, y) not in lev and y > trail_y[slide[0] + RIM] + 9 and rng.random() < 0.1 and not near_t(x, y): g[y][x] = "t"

    # young trees: clumps to fell, never touching each other on all sides (a man must reach each one)
    for _ in range(young_clumps):
        cx, cy = rng.randrange(RIM + 3, w - RIM - 3), rng.randrange(RIM + 3, h - RIM - 3)
        if in_clearing(cx, cy): continue
        for _ in range(rng.randrange(4, 9)):
            x, y = cx + rng.randrange(-3, 4), cy + rng.randrange(-3, 4)
            if 1 <= x < w - 1 and 1 <= y < h - 1 and g[y][x] == "." and not near(x, y, ":=~", 0) and not near(x, y, "tT", 1):
                g[y][x] = "t"
    # the old trees: a tile or two apart so the men walk between them, off the trail and the water, and clear of
    # the young clumps (placed first, so a close wood still has trees to fell)
    olds = []
    for _ in range(int(w * h * old_fill)):
        x, y = rng.randrange(2, w - 2), rng.randrange(2, h - 2)
        if g[y][x] != "." or in_clearing(x, y) or near(x, y, ":=~%", 1) or near(x, y, "t", 1): continue
        gap = 2.0 if rim(x, y) else old_gap  # (the rim is a wall of trees)
        # (round a clearing the trees stand close, so it is a small lit room in a dark wood, as in the target picture)
        if any(r * r < (x - cx) ** 2 + (y - cy) ** 2 <= (r + 2.2) ** 2 for (cx, cy, r) in clearings): gap = 1.15
        if any((x - ox) ** 2 + (y - oy) ** 2 < gap * gap for ox, oy in olds): continue
        olds.append((x, y))
        g[y][x] = "T"
    gates = {"west": [RIM, trail_y[RIM] - 3, RIM + 3, trail_y[RIM] + 4], "east": [w - RIM - 4, trail_y[w - RIM - 1] - 3, w - RIM - 1, trail_y[w - RIM - 1] + 4]}
    doc = {
        "schema": "aow.map/2", "id": pid, "width": w, "height": h, "legend": LEGEND,
        "starts": [[RIM + 3, trail_y[RIM + 3]]],
        "rim": RIM,
        # Smyana's own: where the men walk off this place (tile rectangles x0, y0, x1, y1), by edge name. route.json
        # says where each edge leads.
        "gates": gates,
        # which trees stand here and which ground lies under them: beech (broadleaves at their whole height),
        # conifer (pine and spruce at their whole height), deep (the high dark woods: trunks running up out of sight)
        "wood": wood,
        "rows": ["".join(r) for r in g],
    }
    if lev:  # the ground's levels (Creel: 0 to 9): the place stands at 4, the gorge's bed at 0, the bluff at 8
        rows = doc.pop("rows")
        doc["heights"] = ["".join(str(lev.get((x, y), 4)) for x in range(w)) for y in range(h)]
        doc["rows"] = rows
    with open("data/maps/%s.json" % pid, "w") as f:
        f.write("{\n")
        keys = list(doc.keys())
        for k in keys[:-1]: f.write(' %s: %s,\n' % (json.dumps(k), json.dumps(doc[k])))
        f.write(' "rows": [\n' + ",\n".join('  "%s"' % r for r in doc["rows"]) + "\n ]\n}\n")
    n = lambda ch: sum(r.count(ch) for r in doc["rows"])
    print("%s: %dx%d, %d old trees, %d young, gates %s" % (pid, w, h, n("T"), n("t"), gates))


# The beech valley (the first place, and the last before home): open old beech wood, a stream, meadows.
place("beech_valley", "beech", 1878, 96, 64, west_y=33, east_y=28, stream_x=52, old_gap=1.7, old_fill=1.4, young_clumps=26,
      clearings=[(9, 33, 4), (30, 36, 3), (50, 31, 3.2), (70, 24, 4)], rocks=[(30, 12, 3), (61, 50, 4), (84, 40, 2)])
# The deep fir woods: closer, darker, more rock, no stream. (Drawn with the same trees for now.)
place("fir_woods", "deep", 1879, 96, 64, west_y=28, east_y=36, stream_x=-1, old_gap=1.4, old_fill=1.8, young_clumps=34,
      clearings=[(48, 30, 5)], rocks=[(20, 44, 4), (40, 14, 3), (66, 20, 5), (78, 50, 3)], slide=(62, 8))
