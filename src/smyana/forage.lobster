// ------------------------------------------------------------------ gathering: what the wood gives in its season
// docs/survival.md, issue #66, docs/gathering.md. A place has a few STANDS of what its wood gives in the season (data/
// survival.json "forage"): wild pears fallen in a clearing, ceps deep under the old trees, a dog rose red with hips, a
// slope of mountain tea. Each holds a good amount and is drawn big, so it is seen, not hunted for with the mouse
// (Dominic, 2026-11-13: "gameplay is moving my mouse over everything to find something"); the first man to come near
// one calls it out. Right-click a stand with men chosen: up to four go and gather it into their packs, food for the
// road or goods to take home. What is taken stays taken, on the way home too. Sim side only.

class Stand:
    cell:int  // its middle
    kind:int  // its find (an index in forage_finds())
    left:int  // what is still there to gather
    called:bool = false

class Forager:
    id:int     // the man
    stand:int  // the stand he is gathering
    x:int      // the spot he gathers from
    y:int
    work:int = 0   // ticks he has gathered toward the next one
    since:int = 0  // the tick he was sent (his order reaches him a tick or two later)

var stands = []::Stand
var foragers = []::Forager
var forage_key = ""                                // this place in this season: what its stands are kept under
let forage_memory = dictionary<string, [int]>(17)  // each place-and-season's stands' left, while the men are away
var food_gathered = 0                              // portions gathered in the run (for the checks and the tally)
var goods_gathered = 0

def forage_cfg() -> JV: return gobj(survival_cfg, "forage")

// What this place's wood gives now.
def forage_finds() -> [JV]: return glist(gobj(gobj(forage_cfg(), "woods"), place_wood()), season_now())

// The run from its start: nothing taken anywhere.
def forage_begin():
    forage_memory.clear()
    food_gathered = 0
    goods_gathered = 0

// A place being set up: nobody is gathering; its stands come once its wood has grown (stands_grow).
def forage_enter(place:string):
    foragers = []
    stands = []
    forage_key = "{place}:{season_now()}"

// The men walk off: the place remembers what is left of each stand.
def forage_leave(place:string): if forage_key != "": forage_memory.set(forage_key, map(stands) s: s.left)

// The place's stands, by the run's seed (after the wood, its side paths and its finds: route.enter_leg). Light-loving
// finds at the side paths' clearings and open glades; shade ones deep under the old trees; high ones on open stony
// ground. Kept apart, away from the gates and the trail.
def stands_grow():
    stands = []
    let finds = forage_finds()
    if not finds.length: return
    let grass = str_index(tr_names, "grass")
    let trail = str_index(tr_names, "trail")
    let old = str_index(tr_names, "tree")
    let bare = str_index(tr_names, "bare")
    let rim = gint(su_map, "rim", 0) + 4
    // (how far each cell is from the trail, in tiles, up to 12: a walk out from every trail cell)
    let far = map(W * H) c: if terrain[c] == trail: 0 else: 99
    let todo = filter(W * H) c: far[c] == 0
    var head = 0
    while head < todo.length:
        let n = todo[head]
        head++
        if far[n] < 12:
            for([ 1, -1, W, -W ]) d:
                let v = n + d
                if v >= 0 and v < W * H and abs(v % W - n % W) <= 1 and far[v] > far[n] + 1:
                    far[v] = far[n] + 1
                    todo.push(v)
    def open_round(c:int, r:int) -> int:
        var n = 0
        for((r * 2 + 1) * (r * 2 + 1)) k:
            let v = c + (k / (r * 2 + 1) - r) * W + k % (r * 2 + 1) - r
            if v >= 0 and v < W * H and walks[0][v] == 1: n++
        return n
    def trees_round(c:int, r:int) -> int:
        var n = 0
        for((r * 2 + 1) * (r * 2 + 1)) k:
            let v = c + (k / (r * 2 + 1) - r) * W + k % (r * 2 + 1) - r
            if v >= 0 and v < W * H and terrain[v] == old: n++
        return n
    def by_gate(c:int) -> bool:
        for(gate_rects) r: if abs(c % W - (r[0] + r[2]) / 2) + abs(c / W - (r[1] + r[3]) / 2) < 16: return true
        return false
    let ends = map(side_paths) sp: sp.cells[sp.cells.length - 1]
    let seed = run_seed * 977 + leg_hash(forage_key)
    for(finds) f, k:
        let ss = glist(f, "stands")
        let want = (if ss.length: as_int(ss[0]) else: 1) + threat_hash(seed, k, 1) % max(1, (if ss.length > 1: as_int(ss[1]) else: 1) - (if ss.length: as_int(ss[0]) else: 1) + 1)
        let where = gstr(f, "where", "light")
        // (the cells it may grow on, best first: a light find at a path's clearing before a glade)
        let spots = []::int
        if where == "light": for(ends) e: spots.push(e)
        for(W * H) n:
            let c = (n * 7919 + threat_hash(seed, k, 2)) % (W * H)
            let x = c % W
            let y = c / W
            if x >= rim and y >= rim and x < W - rim and y < H - rim and walks[0][c] == 1 and not by_gate(c):
                let t = terrain[c]
                if where == "light" and t == grass and far[c] >= 4 and open_round(c, 2) >= 22: spots.push(c)
                elif where == "shade" and t == grass and far[c] >= 8 and trees_round(c, 2) >= 4: spots.push(c)
                elif where == "high" and (t == bare or t == grass) and far[c] >= 3 and open_round(c, 2) >= 20: spots.push(c)
        var placed = 0
        for(spots) c:
            if placed < want and not by_gate(c) and (find(stands) s: abs(s.cell % W - c % W) + abs(s.cell / W - c / W) < 12) < 0 and hut_near((c % W) * TILE, (c / W) * TILE, 5) < 0 and not pile_within((c % W) * TILE, (c / W) * TILE, 5):
                let am = glist(f, "amount")
                let lo = if am.length: as_int(am[0]) else: 4
                let hi = if am.length > 1: as_int(am[1]) else: lo
                stands.push(Stand { c, k, lo + threat_hash(seed, k * 31 + placed, 3) % (hi - lo + 1) })
                placed++
    // (what was taken before, still taken)
    let was = forage_memory.get(forage_key)
    if was: for(stands) s, n: if n < was.length: s.left = was[n]
    for(stands) s: print "stand: {forage_key} {gstr(finds[s.kind], "id", "")} x{s.left} at {s.cell % W},{s.cell / W}"

// The stand at or near cell c (within three tiles of its middle) with something left, or -1.
def stand_at(c:int) -> int:
    return find(stands) s: s.left > 0 and abs(s.cell % W - c % W) <= 3 and abs(s.cell / W - c / W) <= 3

// The chosen men sent to gather the stand at cell c: the nearest few of them, each to a spot of his own round it.
// Whether any went.
def forage_order(ids:[int], c:int) -> bool:
    let k = stand_at(c)
    if k < 0: return false
    let s = stands[k]
    let sx = (s.cell % W) * TILE + TILE / 2
    let sy = (s.cell / W) * TILE + TILE / 2
    let near = filter(ids) id: index_of(id) >= 0
    insertion_sort(near) a, b: dist2(u_x[index_of(a)], u_y[index_of(a)], sx, sy) < dist2(u_x[index_of(b)], u_y[index_of(b)], sx, sy)
    let most = gint(forage_cfg(), "most_men", 4)
    foragers = filter(foragers) f: (find(ids) id: id == f.id) < 0
    var sent = 0
    for(near) id:
        if sent < most:
            let a = float(sent) * 1.7 + 0.4
            let x = sx + int(cos(a) * float(TILE) * 0.9)
            let y = sy + int(sin(a) * float(TILE) * 0.6)
            foragers.push(Forager { id, k, x, y, since: tick })
            issue_cmd(0, CMD_MOVE, [ id ], x, y, 0, 0)
            sent++
    return sent > 0

// Whether this man is gathering (he works: his hunger falls faster).
def foraging(uid:int) -> bool: return (find(foragers) f: f.id == uid) >= 0

// Every ten sim ticks (route_tick): a man at his spot gathers one a gather_s into his pack, till the stand is bare or
// his pack full; one sent elsewhere gives up.
def forage_tick():
    let fc = forage_cfg()
    let need = int(as_float(at(fc, "gather_s")) * float(TICK_HZ))
    let finds = forage_finds()
    foragers = filter(foragers) f:
        let i = index_of(f.id)
        let m = man_of(f.id)
        if i < 0 or not m or f.stand >= stands.length: false
        else:
            let s = stands[f.stand]
            if s.left <= 0 or pack_room(m) <= 0 or (tick > f.since + TICK_HZ and dist2(u_tx[i], u_ty[i], f.x, f.y) > TILE * TILE): false
            elif u_moving[i] == 1 or dist2(u_x[i], u_y[i], f.x, f.y) > TILE * TILE * 2: true
            else:
                f.work += 10  // (it is called every ten ticks)
                if f.work >= need:
                    f.work -= need
                    s.left--
                    if gstr(finds[s.kind], "gives", "food") == "goods":
                        m.wares.push(max(0, find(WARES) w: w == gstr(finds[s.kind], "ware", "herbs")))
                        goods_gathered++
                    else:
                        m.food++
                        food_gathered++
                true

// The first man to come near a stand not yet seen calls it out, once: its stand, his id; -1 for none (the view says
// it over his head). By day only.
def stand_seen() -> int, int:
    if is_night(): return -1, -1
    let r = gint(forage_cfg(), "call_tiles", 8) * TILE
    for(stands) s, k:
        if not s.called and s.left > 0:
            let sx = (s.cell % W) * TILE + TILE / 2
            let sy = (s.cell / W) * TILE + TILE / 2
            for(men) m:
                let i = index_of(m.uid)
                if m.alive and i >= 0 and dist2(u_x[i], u_y[i], sx, sy) <= r * r:
                    s.called = true
                    return k, m.uid
    return -1, -1
