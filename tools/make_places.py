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


class Land:
    """what a place's own shape (`land`) is handed: the rows `g`, the levels `lev` ((x, y) to a level, or a ramp's
    letter), the trail's line, the map's size, its random numbers, `put`, the zones where no tree grows, and the
    clearings. `base` is the level of any tile it leaves unset."""
    def __init__(self, g, lev, trail_y, w, h, rng, put, bare_zone, clearings):
        self.g, self.lev, self.trail_y, self.w, self.h, self.rng, self.put = g, lev, trail_y, w, h, rng, put
        self.bare_zone, self.clearings, self.base = bare_zone, clearings, 4


WALK = ".:=b"


def walk_check(pid, rows, heights, gates):
    """that the men can walk from every gate to every other one, as Creel will see it: a tile is walked if its ground
    is and no tile round it stands higher than its top (a ramp's top is a level up)"""
    h, w = len(rows), len(rows[0])
    def level(x, y):
        ch = heights[y][x] if heights else "4"
        return (ord(ch) - 97, 1) if ch.isalpha() else (int(ch), 0)
    ok = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if rows[y][x] not in WALK: continue
            lv, rp = level(x, y)
            ok[y][x] = not any(0 <= x + dx < w and 0 <= y + dy < h and level(x + dx, y + dy)[0] > lv + rp for dx in (-1, 0, 1) for dy in (-1, 0, 1))
    names = list(gates)
    seen = set()
    todo = [(x, y) for x in range(gates[names[0]][0], gates[names[0]][2] + 1) for y in range(gates[names[0]][1], gates[names[0]][3] + 1) if ok[y][x]]
    assert todo, "%s: the %s gate has no ground to stand on" % (pid, names[0])
    seen.update(todo)
    while todo:
        x, y = todo.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if 0 <= n[0] < w and 0 <= n[1] < h and ok[n[1]][n[0]] and n not in seen:
                seen.add(n)
                todo.append(n)
    for e in names[1:]:
        r = gates[e]
        assert any((x, y) in seen for x in range(r[0], r[2] + 1) for y in range(r[1], r[3] + 1)), "%s: no way from the %s gate to the %s" % (pid, names[0], e)
    return sum(1 for row in ok for v in row if v)


RIM = 10  # tiles of thick forest round every place, so the view never runs off the map (the camera stays inside it)


def place(pid, wood, seed, w, h, west_y, east_y, stream_x, old_gap, old_fill, young_clumps, clearings, rocks, slide=None, river=None, ruins=None, land=None, edges=("west", "east"), extra=None, north_rock=True):
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
    if ruins:  # (the Roman road runs straight)
        for x in range(ruins + RIM - 7, ruins + RIM + 8): trail_y[x] = trail_y[ruins + RIM]
    # (a place with a shape of its own, #48: its levels and its ground laid by its own function, which may move the
    # trail and say where it ends; see the places at the bottom)
    lev = {}
    bare_zone = []
    trail_x = (0, w - 1)
    base = 4
    if land:
        ctx = Land(g, lev, trail_y, w, h, rng, put, bare_zone, clearings)
        trail_x = land(ctx) or trail_x
        base = ctx.base
    # the valley's sides: rock along the north and south edges, ragged
    north = noise1(rng, w, 9)
    south = noise1(rng, w, 9)
    for x in range(w):
        if north_rock:
            for y in range(int(2.5 + north[x] * 2.0)): put(x, RIM - 2 + y, "#")
        for y in range(int(2.5 + south[x] * 2.0)): put(x, h + 1 - RIM - y, "#")
    for (cx, cy, r) in rocks:
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + rng.uniform(-1.5, 1.5): put(x, y, "#")
    gorge = None
    # the stream: north to south, a tile wide (two or three men: it is a stream, as in the mock-ups, not a river), with
    # no gaps at its bends, a ford where the trail crosses
    bridges = []
    if river:
        # a river too wide and deep to wade (the gorge's): three tiles across, wandering little. The trail meets it at
        # a bridge (#20: found broken), and `ford` tiles downstream it runs wide and shallow: a path leaves the trail
        # on each bank, goes down to the ford and comes back
        rx, ford = river[0] + RIM, river[1]
        # (level and straight across the gorge's floor and up both ramps, easing back to its own line beyond them)
        for x in range(w):
            k = min(1.0, max(0.0, (abs(x - rx) - 23) / 8.0))
            trail_y[x] = int(round(trail_y[rx] * (1 - k) + trail_y[x] * k)) if x != rx else trail_y[x]
        ty = trail_y[rx]
        sw = noise1(rng, h, 10)
        mid = []
        for y in range(h):
            near_bridge = max(0.0, 1.0 - abs(y - ty) / 6.0)
            mid.append(int(round(rx + sw[y] * 2 * (1.0 - near_bridge))))
            wide = 3 if abs(y - (ty + ford)) <= 2 else 1
            for x in range(mid[y] - wide, mid[y] + wide + 1): put(x, y, "~", ".#")
        for y in range(ty + ford - 1, ty + ford + 2):
            for x in range(w):
                if g[y][x] == "~": g[y][x] = "="
        for side in (-1, 1):
            px = rx + side * 7
            for y in range(ty, ty + ford + 1): put(px, y, ":", ".#")
            for x in range(min(px, rx), max(px, rx) + 1): put(x, ty + ford, ":", ".#")
        bridges = [[rx - 1, ty, rx + 1, ty]]
        gorge = (rx, 14)
    elif stream_x >= 0:
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
    for x in range(trail_x[0], trail_x[1] + 1):
        a, b = trail_y[x], trail_y[max(trail_x[0], x - 1)]
        for y in range(min(a, b), max(a, b) + 1): put(x, y, ":", ".#b")

    # a landslide, found after it has happened (#20; Dominic: "smaller and more focused. Like on a pass above a cliff
    # face, so we only have a very tight space to go, and it's blocked"). The trail runs a ledge on a mountain's side:
    # a cliff above it (a bluff four levels up), a gorge below it (four levels down, a river in its bed), and where
    # the cliff has let go its debris lies across the trail. Bare mountain ground: no forest stands on the ledge or
    # in front of the faces. One tile of the ledge's lip is left to squeeze by until the men can clear it.
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

    # the gorge's depth (#16): the river runs on a floor four levels below the wood, between rock walls that jog a
    # tile or two in runs so no rim is ruled straight. The trail comes down to the floor by a ramp cut through each
    # wall, a level a tile, seven tiles wide (its outer rows lie under the wall's faces and can't be walked). The
    # bridge and the ford are both on the floor, so the river is crossed as before.
    ramp_zone = []
    if gorge:
        gx, half = gorge
        # (Dominic, 2026-11-11, on the first try, which had sheer walls four levels high: "erm those are all hard
        # edges on the gorge though". Then the walls were broken slopes with a rock on nearly every cell to hide the
        # ruled faces. Now Creel draws proper cliffs (Creel #25, D-075): each level's drop is a curve through the tile
        # below it, with ledges, a rolled rim and scree. So the wall is laid plainly, rising its four levels outward
        # in each row: its foot bends slowly, and how many tiles it takes to climb changes along it, from one (a sheer
        # face four levels high, over the river's bends) to five (a stair of ledges). Rock lies on some ledges and at
        # the foot, not over everything.)
        bend = {-1: noise1(rng, h, 14), 1: noise1(rng, h, 14)}
        wide = {-1: noise1(rng, h, 7), 1: noise1(rng, h, 7)}
        ty_at = {-1: trail_y[gx - half - 2], 1: trail_y[gx + half + 2]}
        for y in range(h):
            for x in range(w):
                side = -1 if x < gx else 1
                d = abs(x - gx) - half                      # tiles out from the floor's edge
                on_ramp = abs(y - ty_at[side]) <= 3
                if on_ramp:                                 # the ramp: a level a tile, the same in all its rows
                    lev[(x, y)] = 2 if d <= 0 else "cdef"[d - 1] if d <= 4 else 6
                    continue
                # (beside the ramp the wall stands where the ramp does, and bends away from it over a few rows)
                ease = min(1.0, (abs(y - ty_at[side]) - 3) / 6.0)
                foot = bend[side][y] * 2.5 * ease
                span = 4.0 if ease < 1.0 else max(1.0, min(5.0, 2.6 + wide[side][y] * 3.2))
                dd = d - foot                               # tiles up the wall from its foot
                k = 0 if dd <= 0 else int(math.ceil(dd * 4.0 / span - 1e-9))
                lev[(x, y)] = 2 + max(0, min(4, k))
                if 0 < k < 4 and g[y][x] in "." and rng.random() < 0.22: g[y][x] = "#"   # (a rock on a ledge)
                elif k == 0 and dd > -1.5 and g[y][x] in "." and rng.random() < 0.18: g[y][x] = "#"   # (fallen at the foot)
        for side in (-1, 1):
            x0, x1 = sorted((gx + side * (half - 3), gx + side * (half + 7)))
            ramp_zone.append((x0, ty_at[side] - 4, x1, ty_at[side] + 4))
        bare_zone += ramp_zone

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
                if g[y][x] == "." and (x, y) not in lev and slide and y > trail_y[slide[0] + RIM] + 9 and rng.random() < 0.1 and not near_t(x, y): g[y][x] = "t"

    # the Roman ruins (#17, D-067): the trail runs on the old paved road for a dozen tiles, a drain beside it, column
    # stubs along its north side and one fallen, the footings of a building behind them; a clearing round them. Each
    # piece is a prop ("ruins": [name, x, y in milli-tiles]); the ground under them stays grass, so the undergrowth
    # grows up among them and turns with the year.
    ruin_props = []
    if ruins:
        rx = ruins + RIM
        ry = trail_y[rx]
        clearings.append((rx, ry - 2, 7))
        def ruin(name, x, y):
            ruin_props.append([name, x * 1000 + 500, y * 1000 + 500])
            if g[y][x] not in ":=~": g[y][x] = "."
        # (the road is one long piece of work, cut into tiles: road0 to road12, in the order of ROAD_PLAN in
        # src/smyana/trees.lobster, its drain drawn with it; where its stones are gone or buried, grass grows over it,
        # and a young tree has come up through its kerb, #97)
        plan = "fwhwgwwbbwhgf"
        for k, x in enumerate(range(rx - 6, rx + 7)):
            ruin("road%d" % k, x, trail_y[x])
            if plan[k] in "gb": g[trail_y[x]][x] = "."
        g[trail_y[rx + 4] - 1][rx + 4] = "t"
        for k, x in enumerate([rx - 5, rx - 2, rx + 4]): ruin("column%d" % (k % 2), x, trail_y[x] - 2)
        ruin("drumsx0", rx + 1, trail_y[rx + 1] - 2)
        ruin("drumsy1", rx - 3, trail_y[rx - 3] + 3)
        for x in range(rx - 3, rx + 2): ruin("wallx%d" % (0 if x in (rx - 3, rx) else 1), x, ry - 7)
        for y in range(ry - 6, ry - 4): ruin("wally%d" % (y % 2), rx - 4, y)
        ruin("wally1", rx + 2, ry - 6)

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
        if g[y][x] != "." or in_clearing(x, y) or near(x, y, ":=~%", 2 if river else 1) or near(x, y, "t", 1): continue
        gap = 2.0 if rim(x, y) else old_gap  # (the rim is a wall of trees)
        # (round a clearing the trees stand close, so it is a small lit room in a dark wood, as in the target picture)
        if any(r * r < (x - cx) ** 2 + (y - cy) ** 2 <= (r + 2.2) ** 2 for (cx, cy, r) in clearings): gap = 1.15
        if any((x - ox) ** 2 + (y - oy) ** 2 < gap * gap for ox, oy in olds): continue
        olds.append((x, y))
        g[y][x] = "T"
    gates = {"west": [RIM, trail_y[RIM] - 3, RIM + 3, trail_y[RIM] + 4], "east": [w - RIM - 4, trail_y[w - RIM - 1] - 3, w - RIM - 1, trail_y[w - RIM - 1] + 4]}
    gates = {e: gates[e] for e in edges}
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
    if ruin_props:
        rows = doc.pop("rows")
        doc["ruins"] = ruin_props
        doc["rows"] = rows
    if bridges:  # (Creel: a timber deck over these tiles, x0, y0, x1, y1)
        rows = doc.pop("rows")
        doc["bridges"] = bridges
        doc["rows"] = rows
    if lev:
        rows = doc.pop("rows")
        doc["cliffs"] = 0.7   # (Creel's relief_cliffs: how far each drop wanders across the tile below it)
        doc["rows"] = rows
    if extra: doc.update(extra(doc))
    if lev:  # the ground's levels (Creel: 0 to 9): the place stands at 4, the gorge's bed at 0, the bluff at 8
        rows = doc.pop("rows")
        doc["heights"] = ["".join(str(lev.get((x, y), base)) for x in range(w)) for y in range(h)]
        doc["rows"] = rows
    walked = walk_check(pid, doc["rows"], doc.get("heights"), gates)
    with open("data/maps/%s.json" % pid, "w") as f:
        f.write("{\n")
        keys = [k for k in doc.keys() if k != "rows"]
        for k in keys: f.write(' %s: %s,\n' % (json.dumps(k), json.dumps(doc[k])))
        f.write(' "rows": [\n' + ",\n".join('  "%s"' % r for r in doc["rows"]) + "\n ]\n}\n")
    n = lambda ch: sum(r.count(ch) for r in doc["rows"])
    print("%s: %dx%d, %d old trees, %d young, %d tiles walked, gates %s" % (pid, w, h, n("T"), n("t"), walked, gates))


def ragged(rng, n, step, by):
    """a line that wanders by up to `by` tiles"""
    return [v * by for v in noise1(rng, n, step)]


def wall_tile(c, x, y, k_of, rock_most=0.85):
    """the ground on a broken rock wall (as the gorge's): outcrops of gneiss on nearly every ledge, bare stone between"""
    if c.g[y][x] == ".": c.g[y][x] = "#" if c.rng.random() < rock_most else "b"


def village_edge(c):
    """Map 1 (#52): the last lane out of the village. The village stands as blocks at the low west end, beyond the
    gate (a set, not walked: its houses are raised blocks with stone roofs on either side of the lane); terraced
    fields climb north of the trail, their walls wandering, with no trees on them; the first trees, oak and hornbeam,
    stand beyond them and along the river."""
    w, h, rng, ty = c.w, c.h, c.rng, c.trail_y
    # (the village: houses either side of the lane, two levels up, their roofs bare stone)
    houses = [(1, -9, 3, 3), (5, -8, 3, 3), (2, -14, 4, 3), (7, -13, 2, 2), (1, 4, 3, 3), (6, 4, 2, 3), (2, 9, 4, 3), (7, 9, 2, 2)]
    lane = ty[3]
    for (hx, hy, hw, hh) in houses:
        for y in range(lane + hy, lane + hy + hh):
            for x in range(hx, hx + hw):
                c.g[y][x] = "b"
                c.lev[(x, y)] = 6
    c.bare_zone.append((0, lane - 16, RIM + 1, lane + 14))
    # (the terraces: three fields, each a level above the last, from the lane's side up the hill to the north)
    edges = [ragged(rng, w, 7, 1.2), ragged(rng, w, 6, 1.4), ragged(rng, w, 8, 1.4)]
    ends = [RIM + 46, RIM + 40, RIM + 32]
    end_wob = ragged(rng, h, 5, 2.5)
    for x in range(RIM + 2, w):
        e = min(ty[max(0, x - 6):x + 7]) - 5   # (well clear of the trail, which climbs across the slope)
        for band in range(3):
            top = int(round(e - band * 5 + edges[band][x]))
            for y in range(0, top + 1):
                if x <= ends[band] + end_wob[y]: c.lev[(x, y)] = 5 + band
        if x <= ends[0] + 3: c.bare_zone.append((x, 0, x, e + 1))


def roman_ruins(c):
    """Map 5 (#53): a mossy shelf above the river. The river runs east under the shelf's south edge, on a floor four
    levels down, between a broken rock wall and the far bank (the gorge's river, come out of its cut). The Roman
    road and its ruins stand in a clearing on the shelf (the props of #17)."""
    w, h, rng = c.w, c.h, c.rng
    foot = ragged(rng, w, 11, 2.0)
    span = ragged(rng, w, 7, 1.0)
    rough = [noise1(rng, h, 3) for _ in range(w)]
    bed = ragged(rng, w, 13, 1.5)
    for x in range(w):
        e = RIM + 52 + foot[x]
        for y in range(int(e) - 1, h):
            k = int(math.ceil((y - e + rough[x][y] * 0.8) * 4.0 / (4.5 + span[x])))
            if k <= 0: continue
            c.lev[(x, y)] = max(0, 4 - k)
            if 0 < k < 4: wall_tile(c, x, y, k)
        mid = e + 9 + bed[x]
        for y in range(int(e) + 4, h):
            if abs(y - mid) <= 1.6: c.g[y][x] = "~"
            elif abs(y - mid) <= 2.8 and c.g[y][x] == ".": c.g[y][x] = "b"
        c.bare_zone.append((x, int(e) - 1, x, int(e) + 8))


def the_pass(c):
    """Map 6 (#54): a long narrow saddle at 1,900 m. The trail runs east on a shelf eight levels up, crags above it
    to the north; to the south the shelf breaks off in one tall face (a ledge part way down here and there) to a
    valley floor at level 1 with a path of its own. That is D-076's set piece: on the way home (leg 8) the patrol
    walks the path far below the men. Near the east gate a ramp climbs from the valley path to the shelf, so the
    patrol can come up behind them (phase 2). The last trees thin out on the shelf: Scots pine, spruce."""
    w, h, rng, ty = c.w, c.h, c.rng, c.trail_y
    c.base = 8
    for x in range(w): ty[x] = max(RIM + 11, min(RIM + 19, ty[x]))
    crag = ragged(rng, w, 6, 2.5)
    e1 = ragged(rng, w, 9, 1.5)
    ledge = noise1(rng, w, 5)
    path = ragged(rng, w, 12, 2.0)
    drift = [noise1(rng, w, 4) for _ in range(h)]
    face = {}
    for x in range(w):
        top = int(round(RIM + 4 + crag[x]))
        for y in range(0, top):
            c.lev[(x, y)] = 9
            c.g[y][x] = "#" if rng.random() < 0.55 else "b"
        a = int(round(RIM + 25 + e1[x]))
        b = a + 1 + max(0, int(round(ledge[x] * 2.5)))
        face[x] = (a, b)
        for y in range(a, h): c.lev[(x, y)] = 5 if y < b else 1
        for y in range(a, b): c.g[y][x] = "b"
        for y in range(top, a):
            if c.g[y][x] == "." and drift[y][x] > 0.25: c.g[y][x] = "b"
        c.bare_zone.append((x, b, x, b + 3))
    # (the valley path, the whole way across, out of sight at both ends)
    vy = [int(round(RIM + 36 + p)) for p in path]
    for x in range(w):
        for y in range(min(vy[x], vy[max(0, x - 1)]), max(vy[x], vy[max(0, x - 1)]) + 1): c.g[y][x] = ":"
    # (the ramp up from it to the shelf, seven tiles of a level each, seven wide; its outer two lie under faces)
    rx = RIM + 94
    T = min(face[x][0] for x in range(rx - 3, rx + 4)) - 1
    for x in range(rx - 3, rx + 4):
        for y in range(T, h):
            k = y - T
            c.lev[(x, y)] = "hgfedcb"[k] if k < 7 else 1
            if c.g[y][x] == "b" and k < 9: c.g[y][x] = "."
        c.bare_zone.append((x, T - 2, x, T + 9))
    for y in range(ty[rx], vy[rx] + 1): c.g[y][rx] = ":"


def high_ridge(c):
    """Map 7 (#55): the bare ridge at 2,050 m, the furthest point, and the turn for home: the men come in by the west
    gate and go out by it. Gneiss slabs and grass, dwarf pines (young spruces stand in) and few trees; a rocky knoll
    to the north. To the south the ridge breaks away in ledges of rock to the far valley eight levels below, its road
    running across it, seen and not walked (D-076). Spruce grows down there, below the rim."""
    w, h, rng, ty = c.w, c.h, c.rng, c.trail_y
    c.base = 8
    end = RIM + 74
    crest = ragged(rng, w, 10, 2.0)
    span = ragged(rng, w, 7, 1.5)
    knoll = ragged(rng, w, 8, 3.0)
    rough = [noise1(rng, h, 3) for _ in range(w)]
    drift = [noise1(rng, w, 5) for _ in range(h)]
    road = ragged(rng, w, 14, 2.5)
    for x in range(w):
        # (the trail bends south at its end, to the lookout over the valley)
        t = max(0.0, (x - (end - 20)) / 20.0)
        ty[x] = int(round(ty[x] * (1 - t) + (RIM + 40) * t)) if x <= end else ty[end]
    for x in range(w):
        top = int(round(RIM + 6 + knoll[x]))
        for y in range(0, top):
            c.lev[(x, y)] = 9
            c.g[y][x] = "#" if rng.random() < 0.5 else "b"
        e = RIM + 46 + crest[x]
        sp = 8.0 + span[x]
        for y in range(top, h):
            k = int(math.ceil((y - e + rough[x][y]) * 4.0 / sp))
            if k <= 0:
                if c.g[y][x] == "." and drift[y][x] > -0.15: c.g[y][x] = "b"
                continue
            c.lev[(x, y)] = max(0, 8 - 2 * k)
            if k < 4: wall_tile(c, x, y, k, 0.5)
        floor = int(e + sp) + 1
        ry = int(round(floor + 12 + road[x]))
        for yy in range(min(ry, int(round(floor + 12 + road[max(0, x - 1)]))), max(ry, int(round(floor + 12 + road[max(0, x - 1)]))) + 1):
            if yy < h: c.g[yy][x] = ":"
        c.bare_zone.append((x, floor, x, floor + 3))
    return (0, end)


# The beech valley (the first place, and the last before home): open old beech wood, a stream, meadows.
place("beech_valley", "beech", 1878, 96, 64, west_y=33, east_y=28, stream_x=52, old_gap=1.7, old_fill=1.4, young_clumps=26,
      clearings=[(9, 33, 4), (30, 36, 3), (50, 31, 3.2), (70, 24, 4)], rocks=[(30, 12, 3), (61, 50, 4), (84, 40, 2)])
# The deep fir woods: closer, darker, more rock, no stream. (Drawn with the same trees for now.)
place("fir_woods", "deep", 1879, 96, 64, west_y=28, east_y=36, stream_x=-1, old_gap=1.4, old_fill=1.8, young_clumps=34,
      clearings=[(48, 30, 5)], rocks=[(20, 44, 4), (40, 14, 3), (66, 20, 5), (78, 50, 3)], slide=(62, 8))
# The gorge: its floor four levels below the wood, rock walls either side, a river too deep to wade, the trail's bridge over it found broken,
# and a ford a way downstream.
place("gorge", "beech", 1880, 96, 64, west_y=30, east_y=34, stream_x=-1, old_gap=1.6, old_fill=1.5, young_clumps=30,
      clearings=[(38, 31, 4), (58, 31, 4)], rocks=[(42, 24, 3), (55, 40, 3), (44, 52, 3), (70, 18, 4)], river=(48, 16))
# The Roman road, for a look (leg:ruins_look): a small beech clearing with the old road through it.
place("ruins_road", "beech", 1881, 40, 30, west_y=16, east_y=15, stream_x=-1, old_gap=1.6, old_fill=1.4, young_clumps=6,
      clearings=[], rocks=[(6, 4, 2)], ruins=20)
# The four places of the world plan (#48, D-077): the village edge, the Roman ruins, the pass and the high ridge.
place("village_edge", "oak", 1882, 76, 64, west_y=40, east_y=26, stream_x=56, old_gap=1.8, old_fill=1.2, young_clumps=18,
      clearings=[(16, 40, 4)], rocks=[(64, 50, 2)], land=village_edge, north_rock=False)
place("ruins", "beech", 1883, 76, 76, west_y=30, east_y=28, stream_x=-1, old_gap=1.7, old_fill=1.3, young_clumps=22,
      clearings=[(14, 30, 3), (60, 26, 3)], rocks=[(12, 12, 3), (58, 10, 3), (68, 44, 2)], ruins=38, land=roman_ruins)
place("pass", "high", 1884, 108, 44, west_y=16, east_y=14, stream_x=-1, old_gap=2.4, old_fill=0.5, young_clumps=14,
      clearings=[], rocks=[(30, 8, 2), (62, 20, 2), (84, 9, 3)], land=the_pass)
place("ridge", "high", 1885, 108, 76, west_y=26, east_y=26, stream_x=-1, old_gap=3.0, old_fill=0.35, young_clumps=10,
      clearings=[], rocks=[(24, 18, 2), (46, 30, 2), (60, 16, 3), (78, 34, 2), (92, 22, 3)], land=high_ridge, edges=("west",))
