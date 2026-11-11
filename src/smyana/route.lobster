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
    bridges:[int]  // each bridge of the map: standing (1) or down

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

// ---- the season clock (issue #10, D-059)
// The year is counted in thousandths of a season: 0 is high summer, 1000 full autumn, 2000 midwinter, 3000 spring. The
// run goes from late summer to spring. The clock moves while the men are in a place (route.json's "season":
// ticks_per_milli), between the two ends that leg gives it ("year": the walk in brings it at least to the first, and
// it does not pass the second while they stay), so the season turns while you watch and still keeps to the journey.
// Everything the season drives reads it from here: the leaves (leaf_stage_at), the ground, the light, the length of
// the day, the cover the wood gives (#9).
let SEASONS = [ "summer", "autumn", "winter", "spring" ]
var year_m = 0
var season_force = ""  // (for a look at a place in another season: the game's season: option)
var year_force = -1    // (and at a point of the year between seasons: the game's year: option)

// A leg that names its season ("season", for a look) stands still at that season's height: -1 if this leg runs on
// the clock. "leaf_fall" on an autumn leg: its leaves have mostly fallen.
def year_fixed() -> int:
    if year_force >= 0: return year_force
    let name = if season_force != "": season_force else: gstr(leg_now(), "season", "")
    let k = find(SEASONS) n: n == name
    return if k < 0: -1 else: k * 1000

// The year here: higher ground runs ahead of the valley as the cold comes on (the leg's "altitude", in the year's
// thousandths) and behind it in spring, turning from the one to the other through the winter.
// Whether this leg stands still in its season (a look), off the clock.
def year_still() -> bool: return year_fixed() >= 0 and year_force < 0

def year_here() -> int:
    let fixed = year_fixed()
    if fixed >= 0: return fixed
    let alt = gint(leg_now(), "altitude", 0)
    return year_m + alt * clamp(2000 - year_m, -500, 500) / 500

def season_now() -> string: return SEASONS[((year_here() + 500) / 1000) % 4]

// Which leaves a tree wears when the year stands at y for it: summer's, autumn's, "late" (autumn's colours, most of
// the leaves down, the boughs showing), winter's bare wood, spring's.
def stage_of(y:int) -> string:
    let v = y % 4000
    return if v < 700: "summer" elif v < 1350: "autumn" elif v < 1750: "late" elif v < 2650: "winter" elif v < 3500: "spring" else: "summer"

// No two trees turn on the same day: each is up to this far ahead of the year or behind it (by its cell).
let TURN_SPREAD = 200
def turn_offset(cell:int) -> int: return if year_still(): 0 else: ((cell * 2654435761) >> 9) % (TURN_SPREAD * 2 + 1) - TURN_SPREAD

// The leaves of the tree (or the undergrowth) standing on this cell, now.
def leaf_stage_at(cell:int) -> string:
    if year_still(): return leaf_stage()
    return stage_of(year_here() + turn_offset(cell) + 4000)

// The place's leaves taken together (a leg that stands still in autumn with "leaf_fall" wears "late").
def leaf_stage() -> string:
    if year_still(): return if season_now() == "autumn" and gint(leg_now(), "leaf_fall", 0) > 0: "late" else: season_now()
    return stage_of(year_here())

// Every stage of leaf this leg can show while the men are in it (so the view has their pictures ready).
def leg_stages() -> [string]:
    if year_still(): return [ leaf_stage() ]
    let span = glist(leg_now(), "year")
    let alt = abs(gint(leg_now(), "altitude", 0))
    let lo = (if year_force >= 0: year_force elif span.length: as_int(span[0]) else: year_m) - TURN_SPREAD - alt
    let hi = (if year_force >= 0: year_force elif span.length > 1: as_int(span[1]) else: year_m) + TURN_SPREAD + alt
    let out = []::string
    for([ 0, 700, 1350, 1750, 2650, 3500 ]) begins, k:
        let ends = [ 700, 1350, 1750, 2650, 3500, 4000 ][k]
        if max(lo, 0) < ends and hi >= begins:
            let st = stage_of(begins)
            let seen = find(out) o: o == st
            if seen < 0: out.push(st)
    return out

// How much of their leaves the broadleaves still wear, 0 (bare) to 100: the canopy's part of the cover a wood gives
// (#9), and how thick the year's leaves lie on the ground is its other face.
def leaf_cover_of(stage:string) -> int: return if stage == "summer": 100 elif stage == "autumn": 85 elif stage == "late": 45 elif stage == "spring": 70 else: 0

// How far (0 .. 1000) the year's leaves have come down onto the ground: none in summer, all of them by late autumn,
// lying under the snow, gone with it in spring.
def leaves_down() -> int:
    let y = year_here() % 4000
    if year_still(): return if y == 1000 or y == 2000: 1000 else: 0
    return if y < 700: 0 elif y < 1300: (y - 700) * 1000 / 600 elif y < 2500: 1000 elif y < 2900: (2900 - y) * 1000 / 400 else: 0

// How much snow lies (0 .. 1000): it comes after the leaves are down, and goes in spring.
def snow_lying() -> int:
    let y = year_here() % 4000
    return if y < 1700: 0 elif y < 2000: (y - 1700) * 1000 / 300 elif y < 2500: 1000 elif y < 2900: (2900 - y) * 1000 / 400 else: 0

// How deep in winter the year is (0 high summer .. 1000 midwinter): the days shorten by it.
def winter_depth() -> int:
    let y = year_here() % 4000
    return if y < 2000: y / 2 else: (4000 - y) / 2

def ticks_per_hour() -> int: return gint(route, "day_minutes", 8) * 60 * TICK_HZ / 24

// ---- the clock of the day (issue #13)
// Counted in millionths of an hour since the run began, so it can run at two speeds: by day at day_minutes a day, and
// through the night faster (route.json's "night": its hours and its speed in hundredths), so a night is about a
// minute of waiting by the fire and not three.
var clock_uh = 0
var hour_force = -1.0  // (for a look at a place at another hour: the game's hour: option)

def hour_now() -> float:
    if hour_force >= 0.0: return hour_force
    let h = float(gint(route, "start_hour", 7)) + float(clock_uh) / 1000000.0
    return h - floor(h / 24.0) * 24.0

def is_night() -> bool:
    let n = gobj(route, "night")
    let falls = gint(n, "from", 21)
    let ends = gint(n, "to", 5)
    let h = (gint(route, "start_hour", 7) + clock_uh / 1000000) % 24
    return if falls > ends: h >= falls or h < ends else: h >= falls and h < ends

def clock_tick():
    clock_uh += 1000000 / ticks_per_hour() * (if is_night(): gint(gobj(route, "night"), "speed", 100) else: 100) / 100
    // (the season: one thousandth every so many ticks, up to where this leg lets it go)
    let span = glist(leg_now(), "year")
    if span.length > 1 and year_m < as_int(span[1]) and run_ticks % max(1, gint(gobj(route, "season"), "ticks_per_milli", 28)) == 0: year_m++

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
    clock_uh = 0
    year_m = gint(gobj(route, "season"), "start", 0)
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
    // (the walk here brought the season on at least to where this leg begins)
    let span = glist(leg_now(), "year")
    if span.length: year_m = max(year_m, as_int(span[0]))
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
        // (a bridge is as the men left it: mended, or still down)
        for(mem.bridges) up, k: if up == 0 and k < br_up.length: bridge_hurt(k, 1 << 20)
    else:
        // a bridge found broken (#20: the leg's "bridge_down")
        if gint(leg_now(), "bridge_down", 0) > 0: for(br_id.length) k: bridge_hurt(k, 1 << 20)
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
// The chosen men mend broken bridge k (#20, D-049): it costs wood, and the wood is what they carry on their backs. If
// they carry enough between them it comes off their loads and they go to work; if not, nothing happens. Whether.
def mend_bridge(ids:[int], k:int) -> bool:
    if br_up[k] == 1: return false
    let wood = str_index(resource_names, "wood")
    if br_payer[k] < 0:
        var have = 0
        for(ids) id:
            let i = index_of(id)
            if i >= 0 and u_carry_kind[i] == wood + 1: have += u_carry[i]
        var need = br_cost[wood]
        if have < need: return false
        for(ids) id:
            let i = index_of(id)
            if i >= 0 and u_carry_kind[i] == wood + 1 and need > 0:
                let n = min(need, u_carry[i])
                u_carry[i] -= n
                need -= n
        stock[wood][0] += br_cost[wood]
    issue_cmd(0, CMD_HELP_BUILD, ids, br_id[k], 0, 0, 0)
    return true

def route_tick() -> string:
    run_ticks++
    clock_tick()
    // (clearing a landslide (#20): what a man digs out he throws aside, down the slope, so he is never loaded with
    // it and digs on till the heap is gone)
    let spoil = str_index(resource_names, "spoil") + 1
    for(u_carry) n, i:
        if n > 0 and u_carry_kind[i] == spoil: u_carry[i] = 0
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
    place_memory.set(place, PlaceMemory { copy(terrain), copy(amount), copy(wear), if was: was.visits + 1 else: 1, copy(br_up) })

// The walk to the next place (the clock moves on), and the next place loaded with the men at its edge.
def route_arrive(edge:string):
    let ex = exit_by(edge)
    run_ticks += gint(ex, "hours", 0) * ticks_per_hour()
    clock_uh += gint(ex, "hours", 0) * 1000000
    enter_leg(rstr(ex, "to"), gstr(ex, "arrive", ""))
