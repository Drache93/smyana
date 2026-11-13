// ------------------------------------------------------------------ what the men learn, and the tally at home
// docs/survival.md, issues #70 and #72. At the Roman ruins the men can study the old road's drain: it takes men's time
// the season doesn't give, and those men aren't gathering or keeping watch. The men who gave enough of their time to
// it know it, and take it home in their heads; if they all die it is lost. The tally is what the run comes to: who came
// back and who didn't, and where each fell, what they carry, what they learned. Sim side only.

class Student:
    id:int

var students = []::Student
var drain_uh = 0                               // men's time given to the drain so far, millionths of a man-hour (kept between the two visits)
var study_uh = 0                               // the clock when the study was last brought up to it
let drain_given = dictionary<string, int>(32)  // a man's name: his share, millionths of a man-hour
let drain_knows = dictionary<string, int>(32)  // a man's name: 1 if he learned it

def drain_cfg() -> JV: return gobj(gobj(survival_cfg, "knowledge"), "drain")

def knowledge_begin():
    students = []
    drain_uh = 0
    drain_given.clear()
    drain_knows.clear()
    study_uh = clock_uh

def knowledge_enter():
    students = []
    study_uh = clock_uh

// The cells of the old road in this place (the map's ruins: "road0" .. "road12"), whose drain runs beside it.
def drain_cells() -> [int]:
    let out = []::int
    for(glist(su_map, "ruins")) e:
        if starts_with(as_str(e.a[0]), "road"): out.push(cell_of(as_int(e.a[1]), as_int(e.a[2])))
    return out

// Whether cell c is on the old road, or beside it.
def at_drain(c:int) -> bool:
    let r = gint(drain_cfg(), "reach_tiles", 2)
    return (find(drain_cells()) d: abs(d % W - c % W) <= r and abs(d / W - c / W) <= r) >= 0

// Whether cell c is at one of the ruins standing off the road (a column, its drums, the walls): right-clicked, the men
// study the drain.
def at_ruin(c:int) -> bool:
    for(glist(su_map, "ruins")) e:
        if not starts_with(as_str(e.a[0]), "road"):
            let d = cell_of(as_int(e.a[1]), as_int(e.a[2]))
            if abs(d % W - c % W) <= 1 and abs(d / W - c / W) <= 1: return true
    return false

def drain_learned() -> bool: return drain_uh >= gint(drain_cfg(), "man_hours", 24) * 1000000

// The chosen men sent to study the drain, each to his own place along the road. Whether any went.
def study_order(ids:[int]) -> bool:
    let cells = drain_cells()
    if not cells.length or drain_learned(): return false
    var n = 0
    for(ids) id:
        if man_of(id) and index_of(id) >= 0:
            students = filter(students) s: s.id != id
            students.push(Student { id })
            let c = cells[(n * 5 + 2) % cells.length]
            issue_cmd(0, CMD_MOVE, [ id ], (c % W) * TILE + 300 + (n % 3) * 200, (c / W) * TILE - 700 + (n / 3 % 2) * 1400, 0, 0)
            n++
    return n > 0

def studying(uid:int) -> bool: return (find(students) s: s.id == uid) >= 0

// Every 10 sim ticks: men standing at the drain give it their time; one sent elsewhere stops.
def knowledge_tick():
    let duh = clock_uh - study_uh
    study_uh = clock_uh
    if not students.length or duh <= 0: return
    let least = gint(drain_cfg(), "least_hours", 1) * 1000000
    students = filter(students) s:
        let i = index_of(s.id)
        let m = man_of(s.id)
        if i < 0 or not m or drain_learned() or not at_drain(cell_of(u_tx[i], u_ty[i])): false
        else:
            if u_moving[i] == 0 and at_drain(cell_of(u_x[i], u_y[i])):
                drain_uh += duh
                drain_given.set(m.name, drain_given.get(m.name, 0) + duh)
            true
    if drain_learned():
        for(men) m: if m.alive and drain_given.get(m.name, 0) >= least: drain_knows.set(m.name, 1)

// Where a man fell, in words: the place's name, from the leg's ("The deep fir woods, going home": "the deep fir woods").
def fell_place() -> string:
    var n = gstr(leg_now(), "name", "the forest")
    let comma = find_string(n, ",")
    if comma >= 0: n = substring(n, 0, comma)
    if starts_with(n, "The "): n = "the " + substring(n, 4, -1)
    return n

// Whether this man knows the drain (for the one panel and the tally).
def knows_drain(m:Man) -> bool: return drain_knows.get(m.name, 0) == 1

// ---- the tally (#72)
// What the run came to, in a few lines for the end: who came back, who didn't and where, what they carry, what they
// learned. The homecoming and the ending (#51) will show it; till then the end screen says it.
def tally_lines() -> [string]:
    let home = filter(men) m: m.alive
    let gone = filter(men) m: not m.alive
    // (all of them dead on the road: the run ends there, and nobody comes home)
    if not home.length:
        let fell = [ "Nobody came home.", "All {men.length} men died on the road." ]
        for(gone) m: fell.push("{m.name} lies in {if m.fell_in != "": m.fell_in else: "the forest"}.")
        return fell
    let said = [ "Home.", "{home.length} of {men.length} men came back." ]
    for(gone) m: said.push("{m.name} lies in {if m.fell_in != "": m.fell_in else: "the forest"}.")
    var goods = 0
    var food = 0
    for(home) m:
        goods += m.goods
        food += m.food
    if goods > 0 and food > 0: said.push("They carry home {goods} loads of goods, and {food} portions of food left.")
    elif goods > 0: said.push("They carry home {goods} loads of goods.")
    elif food > 0: said.push("They come home with nothing but {food} portions of food.")
    else: said.push("They come home with nothing.")
    let knowers = filter(home) m: knows_drain(m)
    if knowers.length: said.push("{knowers.length} of them know how the Romans drained the land.")
    elif drain_learned(): said.push("The men who learned the Roman drain did not come home.")
    return said
