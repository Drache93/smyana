// ------------------------------------------------------------------ the run: one map per place (issue #4, D-020)
// The run is a route of legs (data/route.json), each a visit to a place, and a place is one map. Only one place is
// loaded at a time: when the men walk off an edge the world is emptied (gen/reset.lobster) and the next place set up,
// and the men walk in from the matching edge. What comes with them is kept here between the two: who is alive, each
// man's health and load, and the clock. What stays behind is kept too, per place, so the way home finds the stumps
// and the worn trails the way out left.
// Sim side only (no window): the game draws from it, run_check.lobster plays it headless.

class Man:
    name:string
    look:int  // which of the looks in men.json
    hp:int
    carry:int = 0  // his load: how much, and of what ("" nothing)
    carry_kind:string = ""
    uid:int = 0  // his unit in the place that's loaded (ids start again in every place)
    alive:bool = true

// What a place keeps while the men are away (per map id).
class PlaceMemory:
    terrain:[int]  // every cell's terrain: a felled tree is a stump
    amount:[int]   // what's left of each tree being cut
    wear:[int]     // the trails worn by walking
    visits:int

var route = jobj()
var men_data = jobj()
var men = []::Man
var leg_id = ""
var arrived_by = ""      // the edge the men came in by
var run_ticks = 0        // the clock: sim ticks since the run began, the walks between places included
var gates_armed = false  // the men have walked clear of the edge they came in by: a gate can take them out again
var gate_names = []::string
var gate_rects = []::[int]  // tiles: x0, y0, x1, y1
var last_load_s = 0.0       // how long the last place took to set up, seconds
let place_memory = dictionary<string, PlaceMemory>(17)

def route_load():
    route = lib_data("route.json")
    men_data = lib_data("men.json")

def leg_of(id:string) -> JV: return at(at(route, "legs"), id)
def leg_now() -> JV: return leg_of(leg_id)
def place_now() -> string: return gstr(leg_now(), "place", "")
def run_over() -> bool: return gbool(leg_now(), "end", false)
var season_force = ""  // (for a look at a place in another season: the game's season: option)
def season_now() -> string: return if season_force != "": season_force else: gstr(leg_now(), "season", "summer")

def ticks_per_hour() -> int: return gint(route, "day_minutes", 8) * 60 * TICK_HZ / 24

// The hour of the day, 0 up to 24.
var hour_force = -1.0  // (for a look at a place at another hour: the game's hour: option)

def hour_now() -> float:
    if hour_force >= 0.0: return hour_force
    let h = float(gint(route, "start_hour", 7)) + float(run_ticks) / float(ticks_per_hour())
    return h - floor(h / 24.0) * 24.0

def men_alive() -> int:
    var n = 0
    for(men) m: if m.alive: n++
    return n

def man_of(uid:int) -> Man?:
    for(men) m: if m.alive and m.uid == uid: return m
    return nil

// The run from its start: twenty men at the first place's edge.
def run_begin():
    let unit = at(men_data, "unit")
    let names = gstrs(men_data, "names")
    let looks = gstrs(men_data, "looks")
    men = map(gint(men_data, "count", 20)) n: Man { names[n % names.length], n % looks.length, as_int(at(unit, "hp")) }
    run_ticks = 0
    place_memory.clear()
    enter_leg(gstr(route, "start", ""), gstr(route, "start_edge", "west"))

// Why this place is over the size budget ("" if it isn't): checked when it's loaded.
def over_budget() -> string:
    let b = gobj(route, "budget")
    let old = str_index(tr_names, "tree")
    var olds = 0
    for(terrain) t: if t == old: olds++
    let mw = gint(b, "width", W)
    let mh = gint(b, "height", H)
    let mo = gint(b, "old_trees", olds)
    if W > mw: return "{place_now()} is {W} tiles across, the budget is {mw}"
    if H > mh: return "{place_now()} is {H} tiles down, the budget is {mh}"
    if olds > mo: return "{place_now()} has {olds} old trees, the budget is {mo}"
    return ""

// Empties the world and sets up this leg's place, as the men left it if they've been, and walks them in by `edge`.
def enter_leg(id:string, edge:string):
    let t0 = seconds_elapsed()
    leg_id = id
    arrived_by = edge
    gates_armed = false
    gate_names = []
    gate_rects = []
    reset_world()
    if run_over(): return
    let unit = shallow_copy(at(men_data, "unit"))
    set(unit, "line", jarr([ shallow_copy(unit) ]))
    let side = jobj()
    set(side, "units", jarr([ unit ]))
    let place = place_now()
    setup_world(1878, place, [ side ], load_rules("smyana"), [])
    let gs = gobj(su_map, "gates")
    for(gs.keys) name, k:
        gate_names.push(name)
        gate_rects.push(map(gs.a[k].a) v: as_int(v))
    let why = over_budget()
    if why != "": print "over budget: {why}"
    let mem = place_memory.get(place)
    if mem:
        for(mem.terrain) t, c: if terrain[c] != t: set_terrain(c, t)
        for(mem.amount) a, c: amount[c] = a
        wear = copy(mem.wear)
    else:
        // the first time here: the trail is already worn (others walk it too)
        let trail = str_index(tr_names, "trail")
        for(terrain) t, c: if t == trail: wear[c] = tr_max
    walk_in(edge)
    last_load_s = seconds_elapsed() - t0

def gate_index(edge:string) -> int: return find(gate_names) n: n == edge

def in_rect(r:[int], x:int, y:int) -> bool: return x >= r[0] and y >= r[1] and x <= r[2] and y <= r[3]

// The men put down in the gate they came by, each with what he had, and sent a few tiles in along the trail.
def walk_in(edge:string):
    let g = gate_index(edge)
    assert g >= 0
    let r = gate_rects[g]
    let cells = []::int
    for(W * H) c: if in_rect(r, c % W, c / W) and walks[0][c] == 1: cells.push(c)
    assert cells.length > 0
    let k = type_of_slot(0, "worker")
    let ids = []::int
    var n = 0
    for(men) m:
        if m.alive:
            let c = cells[n % cells.length]
            let lap = n / cells.length  // (more men than cells: the next lot a little aside)
            let i = add_unit(0, k, (c % W) * TILE + 300 + (lap % 2) * 400, (c / W) * TILE + 300 + ((lap / 2) % 2) * 400)
            u_hp[i] = m.hp
            let kind = str_index(resource_names, m.carry_kind)
            if kind >= 0 and m.carry > 0:
                u_carry[i] = m.carry
                u_carry_kind[i] = kind + 1
            m.uid = u_id[i]
            ids.push(m.uid)
            n++
    grow_scratch()
    update_pop()
    let cx = (r[0] + r[2] + 1) * TILE / 2
    let cy = (r[1] + r[3] + 1) * TILE / 2
    let step = 7 * TILE
    let tx = cx + (if edge == "west": step elif edge == "east": -step else: 0)
    let ty = cy + (if edge == "north": step elif edge == "south": -step else: 0)
    if ids.length: issue_cmd(0, CMD_MOVE, ids, tx, ty, 0, 0)

// Each man's health and load as they are now, and who has died.
def men_read():
    for(men) m:
        if m.alive:
            let i = index_of(m.uid)
            if i < 0: m.alive = false
            else:
                m.hp = u_hp[i]
                m.carry = u_carry[i]
                m.carry_kind = if u_carry[i] > 0 and u_carry_kind[i] > 0: resource_names[u_carry_kind[i] - 1] else: ""

// After every sim tick: the clock, and whether the men are all standing in a gate that leads on. Returns that
// gate's edge ("" while they aren't).
def route_tick() -> string:
    run_ticks++
    if tick % 10 != 0 or run_over(): return ""
    let inside = map(gate_names): 0
    var alive = 0
    var in_any = 0
    for(men) m:
        if m.alive:
            let i = index_of(m.uid)
            if i < 0: m.alive = false
            else:
                alive++
                let x = u_x[i] / TILE
                let y = u_y[i] / TILE
                var here = false
                for(gate_rects) r, g:
                    if in_rect(r, x, y):
                        inside[g]++
                        here = true
                if here: in_any++
    if not gates_armed:
        if in_any == 0 and alive > 0: gates_armed = true
        return ""
    let exits = gobj(leg_now(), "exits")
    for(gate_names) name, g:
        if alive > 0 and inside[g] == alive and has(exits, name): return name
    return ""

def exit_by(edge:string) -> JV: return at(at(leg_now(), "exits"), edge)

// The men walk off by `edge`: what they carry is read, and the place remembers how they left it.
def route_leave(edge:string):
    men_read()
    let place = place_now()
    let was = place_memory.get(place)
    place_memory.set(place, PlaceMemory { copy(terrain), copy(amount), copy(wear), if was: was.visits + 1 else: 1 })

// The walk to the next place (the clock moves on), and the next place loaded with the men at its edge.
def route_arrive(edge:string):
    let ex = exit_by(edge)
    run_ticks += gint(ex, "hours", 0) * ticks_per_hour()
    enter_leg(rstr(ex, "to"), gstr(ex, "arrive", ""))
