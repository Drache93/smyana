// ------------------------------------------------------------------ gathering: what the wood gives in its season
// docs/survival.md, issue #66. A place's open ground has patches of what its wood gives in the season (data/survival.json
// "forage": berries and herbs in summer, nuts, mushrooms and pears in autumn, almost nothing in winter, greens in
// spring), worked out from each cell's number like the bracken, so the view draws the same ones. Right-click a patch with
// men chosen and each goes to the nearest one, stands on it and gathers it into his pack. What is taken stays taken, on
// the way home too. Sim side only.

class Forager:
    id:int    // the man
    cell:int  // the patch he is gathering
    work:int  // ticks he has stood at it

var foragers = []::Forager
let forage_taken = dictionary<int, int>(64)        // this place's patches already gathered: cell -> 1
let forage_memory = dictionary<string, [int]>(17)  // each place's, while the men are away
var food_gathered = 0                              // portions gathered in the run (for the checks and the tally)
var goods_gathered = 0

def forage_cfg() -> JV: return gobj(survival_cfg, "forage")

// What this place's wood gives now.
def forage_finds() -> [JV]: return glist(gobj(gobj(forage_cfg(), "woods"), place_wood()), season_now())

// The find on cell c (its index in forage_finds), or -1: open grass, not a trail, not yet taken.
def patch_at(c:int) -> int:
    if c < 0 or c >= W * H or forage_taken.get(c, 0) == 1: return -1
    if terrain[c] != str_index(tr_names, "grass") or walks[0][c] != 1 or bracken_at(c): return -1
    var roll = cell_hash(c + 31337) % 1000
    for(forage_finds()) f, k:
        roll -= gint(f, "per_mille", 0)
        if roll < 0: return k
    return -1

// Every patch in the place now (for the view).
def forage_patches() -> [int]: return filter(W * H) c: patch_at(c) >= 0

// The run from its start: nothing taken anywhere.
def forage_begin():
    forage_memory.clear()
    food_gathered = 0
    goods_gathered = 0

// A place set up: what was taken there before is still taken; nobody is gathering.
def forage_enter(place:string):
    foragers = []
    forage_taken.clear()
    let was = forage_memory.get(place)
    if was: for(was) c: forage_taken.set(c, 1)

// The men walk off: the place remembers what they took.
def forage_leave(place:string):
    let cells = []::int
    for(W * H) c: if forage_taken.get(c, 0) == 1: cells.push(c)
    forage_memory.set(place, cells)

// The chosen men sent to gather round cell c: each to the nearest patch within reach of it no other has. Whether any
// went.
def forage_order(ids:[int], c:int) -> bool:
    let r = gint(forage_cfg(), "reach_tiles", 6)
    let near = []::int
    for((r * 2 + 1) * (r * 2 + 1)) n:
        let x = c % W + n % (r * 2 + 1) - r
        let y = c / W + n / (r * 2 + 1) - r
        if x >= 0 and y >= 0 and x < W and y < H and patch_at(y * W + x) >= 0 and (find(foragers) f: f.cell == y * W + x) < 0: near.push(y * W + x)
    var sent = false
    for(ids) id:
        let i = index_of(id)
        if i >= 0 and near.length:
            foragers = filter(foragers) f: f.id != id
            var best = 0
            for(near) p, k: if dist2((p % W) * TILE, (p / W) * TILE, u_x[i], u_y[i]) < dist2((near[best] % W) * TILE, (near[best] / W) * TILE, u_x[i], u_y[i]): best = k
            let p = near[best]
            near.remove(best)
            foragers.push(Forager { id, p, 0 })
            issue_cmd(0, CMD_MOVE, [ id ], (p % W) * TILE + TILE / 2, (p / W) * TILE + TILE / 2, 0, 0)
            sent = true
    return sent

// Whether this man is gathering (he works: his hunger falls faster).
def foraging(uid:int) -> bool: return (find(foragers) f: f.id == uid) >= 0

// Every sim tick (route_tick): a man stood at his patch gathers it; one sent elsewhere gives up.
def forage_tick():
    let fc = forage_cfg()
    let need = int(as_float(at(fc, "gather_s")) * float(TICK_HZ))
    let finds = forage_finds()
    foragers = filter(foragers) f:
        let i = index_of(f.id)
        let m = man_of(f.id)
        let k = patch_at(f.cell)
        let px = (f.cell % W) * TILE + TILE / 2
        let py = (f.cell / W) * TILE + TILE / 2
        if i < 0 or not m or k < 0 or dist2(u_tx[i], u_ty[i], px, py) > TILE * TILE: false
        elif u_moving[i] == 1 or dist2(u_x[i], u_y[i], px, py) > TILE * TILE: true
        else:
            f.work += 10  // (it is called every ten ticks)
            if f.work < need: true
            else:
                let fd = finds[k]
                m.food += min(pack_room(m), gint(fd, "food", 0))
                m.goods += min(pack_room(m), gint(fd, "goods", 0))
                food_gathered += gint(fd, "food", 0)
                goods_gathered += gint(fd, "goods", 0)
                forage_taken.set(f.cell, 1)
                false
