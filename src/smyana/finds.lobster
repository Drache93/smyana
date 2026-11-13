// ------------------------------------------------------------------ finds: what lies at the ends of the side paths
// docs/off-the-path.md: the reasons to leave the trail. A place has up to two finds by the run's seed, each at the
// end of a side path whose clearing has no game at it: an empty shepherds' hut (a camp made at it keeps its fire
// inside, seen from close by only, and the men sleep out of the wind), a cache another band put by under stones, or
// wild bees' honey in a hollow old tree. A cache and the honey are piles (smyana/packs.lobster) of their own kind:
// taken the same way, found by a patrol and smelled by the bear the same way. What is taken stays taken; the hut
// stands. Numbers and sources in data/survival.json "finds". Sim side only.

let FIND_KINDS = [ "hut", "cache", "honey" ]
let PILE_CACHE = 1  // (a Pile's kind: 0 the men's own packs)
let PILE_HONEY = 2

var huts = []::int                              // this place's huts: the cell each stands on
let finds_placed = dictionary<string, int>(17)  // the places whose caches and honey have been set down (once a run)

def finds_cfg() -> JV: return gobj(survival_cfg, "finds")
def find_kind_cfg(kind:string) -> JV: return gobj(gobj(finds_cfg(), "kinds"), kind)

// The run from its start: nothing found anywhere.
def finds_begin(): finds_placed.clear()

// From (lo, hi) in a JSON pair, by h.
def pick_in(v:[JV], h:int) -> int:
    let lo = if v.length: as_int(v[0]) else: 0
    let hi = if v.length > 1: as_int(v[1]) else: lo
    return lo + h % (hi - lo + 1)

// A place set up, after its game (hunt_enter): its finds set down at the ends of the paths the game is not at. The
// huts every time (they stand); the caches and the honey the first time only (piles keep what is left of them).
def finds_enter(place:string):
    huts = []
    let first = finds_placed.get(place, 0) == 0
    finds_placed.set(place, 1)
    if not side_paths.length: return
    let hut_t = str_index(tr_names, "hut")
    let old = str_index(tr_names, "tree")
    let wood = place_wood()
    // (the kinds this wood has, and their weights)
    let kinds = []::string
    var total = 0
    for(FIND_KINDS) kind:
        let woods = glist(find_kind_cfg(kind), "woods")
        if not woods.length or (find(woods) w: as_str(w) == wood) >= 0:
            kinds.push(kind)
            total += gint(find_kind_cfg(kind), "weight", 1)
    var placed = 0
    for(side_paths.length) j:
        if placed >= gint(finds_cfg(), "per_place", 2): break
        let k = (run_seed + leg_hash(place) + j) % side_paths.length
        let sp = side_paths[k]
        let end = sp.cells[sp.cells.length - 1]
        let ex = (end % W) * TILE + TILE / 2
        let ey = (end / W) * TILE + TILE / 2
        // (not where the deer or the boar are: they keep away from men's things)
        if (find(game) g: dist2(g.home_x, g.home_y, ex, ey) < sq(6 * TILE)) >= 0: continue
        if total <= 0: break
        var roll = threat_hash(run_seed + 71, leg_hash(place), k) % total
        var kind = kinds[0]
        for(kinds) kd:
            if roll >= 0:
                kind = kd
            roll -= gint(find_kind_cfg(kd), "weight", 1)
            if roll < 0: break
        // (each kind once a place: two finds are two different things)
        total -= gint(find_kind_cfg(kind), "weight", 1)
        kinds.remove(find(kinds) kd: kd == kind)
        let h = threat_hash(run_seed + 113, leg_hash(place), k * 7 + 3)
        if kind == "hut":
            // (it stands at the clearing's end, the path coming to its door)
            if terrain[end] != hut_t: set_terrain(end, hut_t)
            huts.push(end)
        elif kind == "honey":
            // (in an old tree at the clearing's edge, the honey taken from beside it)
            var tx = ex
            var ty = ey
            for(49) n:
                let c = end + (n / 7 - 3) * W + n % 7 - 3
                if c >= 0 and c < W * H and terrain[c] == old and tx == ex:
                    let o = camp_ground_near(c, -1)
                    tx = (o % W) * TILE + TILE / 2
                    ty = (o / W) * TILE + TILE / 2
            if first: piles.push(Pile { tx, ty, pick_in(glist(find_kind_cfg("honey"), "food"), h), map(pick_in(glist(find_kind_cfg("honey"), "wax"), h / 7)): WARE_WAX, kind: PILE_HONEY })
        elif first:
            let cc = find_kind_cfg("cache")
            piles.push(Pile { ex, ey, pick_in(glist(cc, "food"), h), map(pick_in(glist(cc, "goods"), h / 5)): WARE_WOOL, kind: PILE_CACHE })
        print "find: {place} {kind} at {end % W},{end / W}, down the {[ "deer track", "sheep path", "cart track" ][sp.size]}"
        placed++

// The hut at or next to cell c (within `tiles`), or -1.
def hut_near(x:int, y:int, tiles:int) -> int:
    return find(huts) c: dist2((c % W) * TILE + TILE / 2, (c / W) * TILE + TILE / 2, x, y) <= sq(tiles * TILE)

// Right-click a hut with men chosen: they walk to it and make camp in it when the first of them is at its door.
var hut_goers = []::int
var hut_goal = -1
var hut_sent = 0

def hut_order(ids:[int], hut:int) -> bool:
    if hut < 0: return false
    hut_goers = copy(ids)
    hut_goal = hut
    hut_sent = tick
    for(ids) id, n:
        let o = camp_ground_near(hut, hut)
        issue_cmd(0, CMD_MOVE, [ id ], (o % W) * TILE + 200 + (n * 137) % 600, (o / W) * TILE + 200 + (n * 251) % 600, 0, 0)
    return true

// Every ten sim ticks (route_tick): the men sent to a hut make camp in it as they get there; given up in a minute or
// when sent elsewhere.
def finds_tick():
    if hut_goal < 0: return
    let hx = (hut_goal % W) * TILE + TILE / 2
    let hy = (hut_goal / W) * TILE + TILE / 2
    let here = filter(hut_goers) id: index_of(id) >= 0
    if not here.length or tick - hut_sent > 60 * TICK_HZ or (find(huts) c: c == hut_goal) < 0:
        hut_goal = -1
        return
    if (find(here) id: dist2(u_x[index_of(id)], u_y[index_of(id)], hx, hy) <= sq(2 * TILE)) >= 0:
        hut_goal = -1
        camp_order(here)
