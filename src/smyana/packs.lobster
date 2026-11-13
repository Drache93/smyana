// ------------------------------------------------------------------ packs, weight, piles and caches
// docs/survival.md, issues #67 and #69: carrying is people. Each man's pack holds food and goods together, up to a
// limit, and weighs on his pace. The chosen men can drop their packs (X) to move light, and pick them up again; a
// pile left at the foot of an old tree is a cache for the way home. A pile is as hidden as a man would be there: a
// patrol that sees one takes it, the bear eats the food in one. A man who falls drops his pack where he falls. Numbers
// in data/survival.json "packs". Sim side only.

class Pile:
    x:int  // sim units
    y:int
    food:int
    goods:int
    kind:int = 0  // 0 the men's own packs; a find (smyana/finds.lobster): PILE_CACHE, PILE_HONEY

var piles = []::Pile
let pile_memory = dictionary<string, [Pile]>(17)  // each place's piles while the men are away: its caches
var piles_lost = 0                                // piles taken by a patrol or eaten by the bear (for the checks)

def packs_cfg() -> JV: return gobj(survival_cfg, "packs")

// How full a man's pack is, in its own units (a bundle of wood on top counts).
def pack_weight(m:Man, i:int) -> int: return m.food + m.goods + (if i >= 0 and u_carry[i] > 0: gint(packs_cfg(), "wood", 2) else: 0)

// How much room is left in his pack.
def pack_room(m:Man) -> int: return max(0, gint(packs_cfg(), "most", 12) - m.food - m.goods)

// His pace for his load, in hundredths kept.
def load_pace(m:Man, i:int) -> int: return 100 - gint(packs_cfg(), "slow", 22) * min(pack_weight(m, i), gint(packs_cfg(), "most", 12)) / max(1, gint(packs_cfg(), "most", 12))

def packs_begin():
    pile_memory.clear()
    piles_lost = 0

def packs_enter(place:string):
    piles = []
    let was = pile_memory.get(place)
    if was: piles = was

def packs_leave(place:string): pile_memory.set(place, piles)

// X: the chosen men put their packs down where they stand, each keeping a day's food; one pile for them all, at their
// middle. Whether anything was put down.
def packs_drop(ids:[int]) -> bool:
    let keep = gint(packs_cfg(), "keep_food", 1)
    var food = 0
    var goods = 0
    var cx = 0
    var cy = 0
    var n = 0
    for(ids) id:
        let m = man_of(id)
        let i = index_of(id)
        if m and i >= 0:
            food += max(0, m.food - keep)
            m.food = min(m.food, keep)
            goods += m.goods
            m.goods = 0
            cx += u_x[i]
            cy += u_y[i]
            n++
    if n == 0 or food + goods == 0: return false
    piles.push(Pile { cx / n, cy / n, food, goods })
    return true

// The pile near (x, y) within a tile and a half, or -1.
def pile_near(x:int, y:int) -> int:
    let r = TILE * 3 / 2
    return find(piles) p: dist2(p.x, p.y, x, y) <= r * r

// The chosen men pick up pile k, sharing it out into their packs as far as they have room; what is left stays.
// They walk to it first (pile_tick gives it out when they are there).
class Fetch:
    id:int
    pile:Pile
    since:int = 0  // the tick he was sent (his order reaches him a tick or two later)

var fetchers = []::Fetch

def packs_fetch(ids:[int], k:int):
    let p = piles[k]
    fetchers = filter(fetchers) f: (find(ids) id: id == f.id) < 0
    for(ids) id, n:
        if man_of(id):
            fetchers.push(Fetch { id, p, since: tick })
            issue_cmd(0, CMD_MOVE, [ id ], p.x + (n % 3 - 1) * 400, p.y + (n / 3 % 3 - 1) * 400, 0, 0)

// A man's pack where he fell (threats_on_death).
def pack_falls(m:Man, x:int, y:int):
    if m.food + m.goods > 0: piles.push(Pile { x, y, m.food, m.goods })
    m.food = 0
    m.goods = 0

// Every 10 sim ticks: men at a pile take from it; a patrol that sees a pile takes it; the bear eats the food in one.
def packs_tick():
    let r = TILE * 3 / 2
    fetchers = filter(fetchers) f:
        let i = index_of(f.id)
        let m = man_of(f.id)
        if i < 0 or not m or (find(piles) p: p == f.pile) < 0: false
        elif dist2(u_x[i], u_y[i], f.pile.x, f.pile.y) > r * r: tick <= f.since + TICK_HZ or u_moving[i] == 1 or dist2(u_tx[i], u_ty[i], f.pile.x, f.pile.y) <= r * r
        else:
            let tf = min(f.pile.food, pack_room(m))
            m.food += tf
            f.pile.food -= tf
            let tg = min(f.pile.goods, pack_room(m))
            m.goods += tg
            f.pile.goods -= tg
            false
    piles = filter(piles) p: p.food + p.goods > 0
    // (found: a patrolman who sees the pile, as he would see a man lying there; the bear, by smell, if there is food)
    let smell = gint(packs_cfg(), "bear_smell_tiles", 10) * TILE
    piles = filter(piles) p:
        let c = cell_of(p.x, p.y)
        var found = false
        for(patrols) pt:
            for(patrol_alive(pt)) pid:
                let pi = index_of(pid)
                if not found and pi >= 0 and spots(u_x[pi], u_y[pi], c, gint(patrol_cfg(), "sight", 10) * TILE): found = true
        for(bears) b:
            let bi = index_of(b.id)
            if not found and bi >= 0 and p.food > 0 and dist2(u_x[bi], u_y[bi], p.x, p.y) <= smell * smell:
                if dist2(u_x[bi], u_y[bi], p.x, p.y) <= TILE * TILE: found = true
                elif b.state == B_WANDER:
                    b.home_x = p.x
                    b.home_y = p.y
        if found: piles_lost++
        not found
