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
var with_mark = false       // a second side, a mark to fire at, in every place (the range: src/smyana/guns.lobster)
let place_memory = dictionary<string, PlaceMemory>(17)

def route_load():
    route = lib_data("route.json")
    men_data = lib_data("men.json")

def leg_of(id:string) -> JV: return at(at(route, "legs"), id)
def leg_now() -> JV: return leg_of(leg_id)
def place_now() -> string: return gstr(leg_now(), "place", "")
def run_over() -> bool: return gbool(leg_now(), "end", false)

// ---- the season clock (issue #10, D-062)
// The year is counted in thousandths of a season: 0 is high summer, 1000 full autumn, 2000 midwinter, 3000 spring. The
// run goes from late summer to spring. The clock moves while the men are in a place (route.json's "season":
// ticks_per_milli), between the two ends that leg gives it ("year": the walk in brings it at least to the first, and
// it does not pass the second while they stay), so the season turns while you watch and still keeps to the journey.
// Everything the season drives reads it from here: the leaves (leaf_stage_at), the ground, the light, the length of
// the day, the cover the wood gives (#9).
let SEASONS = [ "summer", "autumn", "winter", "spring" ]
var year_m = 0
var wood_force = ""  // (for a look at a place with another wood's trees: the game's wood: option)

// Which trees stand in this place: its map's "wood", or the look's.
def place_wood() -> string: return if wood_force != "": wood_force else: gstr(su_map, "wood", "beech")

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

// ---- wading a ford (issue #20, D-065)
// How high the water stands in the streams, 0 (low) to 1000: up with the thaw as the snow goes, and in a spell of
// rain.
def high_water() -> int:
    let y = year_here() % 4000
    let thaw = if y >= 2500 and y < 2900: 1000 - abs(y - 2700) * 5 else: 0
    let kind, hard = weather_now()
    return max(thaw, if kind == "rain": hard else: 0)

// How fast a man wades, in hundredths of his pace on dry ground (route.json's "ford"): slower with a load on his
// back, and slower still the higher the water stands. So a ford is quick for men walking light in a dry autumn, and
// a long cold crossing for loaded men in the thaw: the mended bridge is worth its wood on the way home.
def wade_pace(loaded:bool) -> int:
    let f = gobj(route, "ford")
    return max(10, gint(f, if loaded: "loaded" else: "wade", 60) - gint(f, "high_water", 20) * high_water() / 1000)

// How cold the water is to a man who wades it, 0 (a summer stream) to 100 (snowmelt): for the men's warmth (#65).
def ford_cold() -> int: return clamp(winter_depth() / 8 + high_water() / 40, 0, 100)

// ---- cover (issue #9, D-064)
// What grows on a cell is worked out from the cell's number, here in the sim, and the view draws the same thing.
def cell_hash(c:int) -> int: return ((c * 2654435761) >> 7) & 0xFFFF

// Which old tree stands in a wood of this kind (the map's "wood": beech, conifer or deep, the high dark woods where
// the trunks run up out of sight).
def old_species(wood:string, pick:int) -> string:
    let r = (pick / 3) % 8
    // (a pine among the beeches is a Scots pine or a black pine, half and half; the conifer woods mix spruce, silver
    // fir, Scots and black pine; in the deep woods a fir stands among the spruces' tall trunks now and then)
    let other = (pick / 24) % 2 == 1
    var sp = if r < 4: "beech" elif r < 6: "oak" elif r < 7: "hornbeam" elif other: "bpine" else: "pine"
    if wood == "deep": sp = if r < 6: "tall" elif r < 7: (if other: "fir" else: "spruce") else: "beech"
    if wood == "conifer": sp = if r < 3: "spruce" elif r < 5: "fir" elif r < 6: "pine" elif r < 7: "bpine" else: "beech"
    // (#48, D-077: the village edge's oaks and hornbeams, a beech standing in for the lime and the wild pear; the high
    // woods of the pass and the ridge, Scots pine and spruce with a black pine or a fir now and then)
    if wood == "oak": sp = if r < 4: "oak" elif r < 6: "hornbeam" elif r < 7: "beech" else: "oak"
    if wood == "high": sp = if r < 3: "pine" elif r < 6: "spruce" elif r < 7: "bpine" else: "fir"
    return sp

// Whether this kind of wood is broadleaved (its ground is the beeches' leaf litter, its young trees lose their leaves).
def broadleaved(wood:string) -> bool: return wood == "beech" or wood == "oak"

def leafy(sp:string) -> bool: return sp == "beech" or sp == "oak" or sp == "hornbeam"

// The old tree on this cell (a place can say it has no pines among its beeches: "pines": 0).
def old_tree_at(c:int) -> string:
    let sp = old_species(place_wood(), cell_hash(c) / 7)
    return if (sp == "pine" or sp == "bpine") and gint(su_map, "pines", 1) == 0: "beech" else: sp

// Bracken grows in drifts a few tiles across, and a little between them.
def bracken_drift(c:int) -> bool: return cell_hash((c / W / 4) * W + (c % W) / 4 + 9001) % 8 < 3
def bracken_at(c:int) -> bool: return cell_hash(c + 40507) % 100 < (if bracken_drift(c): 62 else: 7)

// How well a man standing on this cell is hidden, 0 (in plain sight) to 100 (route.json's "cover" has the numbers).
// The canopy is most of it: each old tree within two tiles gives some, a broadleaf by the leaves it still wears
// (leaf_cover_of, so it thins as the leaves fall and is gone in winter), a fir or a pine all year. A young tree beside
// him gives a little, and bracken on his own tile some more, which lasts longer into the year than the leaves and
// stands dead through the winter at half. A felled tree is a stump on the map, which the place remembers, so its
// cover is gone on the way home too.
def cover_at(c:int) -> int:
    let cv = gobj(route, "cover")
    let old = str_index(tr_names, "tree")
    let young = str_index(tr_names, "young_tree")
    let x = c % W
    let y = c / W
    var canopy = 0
    var low = 0
    for(5) j: for(5) i:
        let u = x + i - 2
        let v = y + j - 2
        if u >= 0 and v >= 0 and u < W and v < H:
            let n = v * W + u
            let near = max(abs(i - 2), abs(j - 2)) <= 1
            if terrain[n] == old:
                let sp = old_tree_at(n)
                let leaves = if leafy(sp): leaf_cover_of(leaf_stage_at(n)) elif sp == "tall": gint(cv, "tall", 70) else: 100
                canopy += gint(cv, if near: "tree_near" else: "tree_far", 10) * leaves / 100
            elif terrain[n] == young and near:
                low += gint(cv, "young", 8) * (if broadleaved(place_wood()): leaf_cover_of(leaf_stage_at(n)) else: 100) / 100
    if terrain[c] == str_index(tr_names, "grass") and bracken_at(c):
        let stage = leaf_stage_at(c)
        low += gint(cv, "bracken", 20) * (if stage == "winter": 50 elif stage == "spring": 80 else: 100) / 100
    return min(100, min(gint(cv, "canopy_most", 75), canopy) + low)

// How far anything sees just now, in hundredths of how far it sees on a clear day: less at night, in mist, in rain
// and in falling snow.
def sight_pct() -> int:
    let cv = gobj(route, "cover")
    let kind, hard = weather_now()
    let dim = if kind == "clear": 0 else: gint(cv, kind, 0) * hard / 1000
    return (100 - dim) * (if is_night(): 100 - gint(cv, "night", 40) else: 100) / 100

// Whether a watcher at (fx, fy) who sees `range` on a clear day in the open (sim units, as u_x) spots a man on
// cell c: the man's cover takes off up to cover.hides hundredths of the range, and the hour and the weather more.
// For the spotting checks of wolves, the bear and the patrol (#60 to #62).
def spots(fx:int, fy:int, c:int, range:int) -> bool:
    let reach = range * sight_pct() / 100 * (100 - cover_at(c) * gint(gobj(route, "cover"), "hides", 70) / 100) / 100
    let dx = (c % W) * TILE + TILE / 2 - fx
    let dy = (c / W) * TILE + TILE / 2 - fy
    return dx * dx + dy * dy <= reach * reach

// ---- the weather (issue #15, D-063)
// It comes in spells (route.json's "weather": spell_hours on the clock each): a spell is clear, or mist, rain or snow
// by the season's chances, counted from the spell's number so two runs get the same sky. Rain that would fall where
// snow lies falls as snow. A spell comes on and goes off over its first and last quarter. A leg can name its own
// ("weather": "rain"), and a leg that stands still in its season (a look) is clear unless it does. The first spell of
// the run is always clear.
var weather_force = ""  // (for a look at a place in a weather: the game's weather: option)

def weather_hash(n:int) -> int: return ((n * 2654435761 + 40503) >> 7) & 0xFFFF

// The weather now and how hard (0 .. 1000).
def weather_now() -> string, int:
    let own = if weather_force != "": weather_force else: gstr(leg_now(), "weather", "")
    if own != "": return own, 1000
    if year_fixed() >= 0: return "clear", 0
    let w = gobj(route, "weather")
    let span = max(1, gint(w, "spell_hours", 3)) * 1000
    let mh = clock_uh / 1000         // (thousandths of an hour since the run began)
    if mh < span: return "clear", 0  // (the men leave on a clear morning)
    let h = weather_hash(mh / span)
    let chances = gobj(gobj(w, "chances"), season_now())
    var roll = h % 100
    var kind = "clear"
    for([ "mist", "rain", "snow" ]) k:
        let c = gint(chances, k, 0)
        if kind == "clear" and roll >= 0 and roll < c: kind = k
        roll -= c
    if kind == "rain" and snow_lying() > 300: kind = "snow"
    if kind == "snow" and snow_lying() == 0 and year_here() % 4000 < 1600: kind = "rain"
    if kind == "clear": return kind, 0
    let p = mh % span * 1000 / span
    let peak = 500 + (h / 100) % 501
    return kind, peak * min(250, min(p, 1000 - p)) / 250

// The wind (0 .. 1000): a little always, more in rain and snow.
def wind_now() -> int:
    let kind, hard = weather_now()
    let base = 100 + weather_hash(clock_uh / 1000000 / 2 + 77) % 250
    return if kind == "rain" or kind == "snow": min(1000, base + hard / 2) else: base

// How fast the men walk in this weather, in hundredths (#15: "snow slows the men"): lying snow takes off up to
// route.json's weather.snow_slow, and snow coming down hard a little more.
def weather_pace() -> int:
    let w = gobj(route, "weather")
    let kind, hard = weather_now()
    return 100 - gint(w, "snow_slow", 25) * snow_lying() / 1000 - (if kind == "snow": gint(w, "snowfall_slow", 10) * hard / 1000 else: 0)

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
    let sides = [ side ]
    if with_mark:
        let mark = shallow_copy(at(lib_data("guns.json"), "mark"))
        set(mark, "line", jarr([ shallow_copy(mark) ]))
        let other = jobj()
        set(other, "units", jarr([ mark ]))
        sides.push(other)
    let place = place_now()
    setup_world(1878, place, sides, load_rules("smyana"), [])
    events_on = true  // (the shots are read from the sim's events: guns.lobster; setting the world up turns them off)
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
    // (the weather's pace on the men, and the water's on a man in a ford)
    let pace = weather_pace()
    let ford = str_index(tr_names, "ford")
    for(men) m:
        if m.alive:
            let i = index_of(m.uid)
            if i >= 0:
                let wading = terrain[cell_of(u_x[i], u_y[i])] == ford
                u_speed[i] = max(1, t_speed[u_kind[i]] * pace / 100 * (if wading: wade_pace(u_carry[i] > 0) else: 100) / 100)
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
