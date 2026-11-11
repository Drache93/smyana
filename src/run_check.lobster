// The run with no window: twenty men walk the whole world (#48, #57): out of the village, through the beech valley
// (felling a tree on the way), the fir woods (digging at the landslide), the gorge (mending its bridge), the Roman
// ruins and the pass to the high ridge, and home the same way: the valley still has its stump. Proves issue #4's swap:
// one map per place, the men, their loads and the clock carried across, the place remembered. Every leg's walking time
// and every load is printed at the end, to keep in the archive. Run from src/: lobster run_check.lobster (./check.sh
// does).
import from "../creel/src"
import smyana.sim

var failed = 0
def expect(ok:bool, what:string):
    print (if ok: "ok    " else: "FAIL  ") + what
    if not ok: failed++

def ids_alive() -> [int]: return map(filter(men) m: m.alive) m: m.uid

// Steps the sim until the men stand in a gate that leads on (its edge), or `limit` ticks pass ("").
def steps_until_gate(limit:int) -> string:
    for(limit):
        step()
        let edge = route_tick()
        if edge != "": return edge
    return ""

def gate_centre(edge:string) -> int, int:
    let r = gate_rects[gate_index(edge)]
    return (r[0] + r[2] + 1) * TILE / 2, (r[1] + r[3] + 1) * TILE / 2

def walk_to_gate(edge:string) -> string:
    let x, y = gate_centre(edge)
    issue_cmd(0, CMD_MOVE, ids_alive(), x, y, 0, 0)
    return steps_until_gate(9000)

// Each leg as it was played: its id, the sim ticks the men spent in it, and how long its place took to load (s).
let leg_ids = []::string
let leg_ticks = []::int
let leg_loads = []::float
var leg_from = 0

// The men walk off by `edge` (they must all have reached it) and the next leg is loaded: its place inside the budget.
def go_on(edge:string, what:string):
    expect(edge != "", what)
    leg_ids.push(leg_id)
    leg_ticks.push(run_ticks - leg_from)
    route_leave(edge)
    route_arrive(edge)
    leg_from = run_ticks
    leg_loads.push(last_load_s)
    if not run_over(): expect(over_budget() == "", "{place_now()} is inside the size budget")

// Walks the men in clear of the gate they came by.
def walk_in_clear(n:int):
    for(n):
        step()
        route_tick()
    expect(gates_armed, "the men walked in clear of the gate")

lib_load("../data")
route_load()
run_begin()
leg_loads.push(last_load_s)
expect(place_now() == "village_edge" and u_x.length == 20, "the run starts at the village edge with twenty men ({u_x.length})")
expect(arrived_by == "west" and gates_armed == false, "they start at the top of the lane, by the west gate")
expect(over_budget() == "", "the place is inside the size budget")
// the season clock (#10): the run starts in late summer, every beech in leaf
expect(season_now() == "summer" and year_m == gint(gobj(route, "season"), "start", -1), "the season clock starts in late summer (year {year_m})")
expect(not exists(terrain.length) c: leaf_stage_at(c) != "summer", "every tree still wears the leaves of summer")
expect(leaves_down() == 0 and snow_lying() == 0, "no leaves are down yet and no snow lies")
expect(place_wood() == "oak" and old_tree_at(find(terrain): _ == str_index(tr_names, "tree")) != "", "oak and hornbeam stand at the village edge")
// out of the village, east to the beech valley
walk_in_clear(200)
go_on(walk_to_gate("east"), "the men walked out of the village to the east gate")
expect(place_now() == "beech_valley" and arrived_by == "west", "the beech valley is loaded, the men at its west edge")
// cover (#9): somewhere under the beeches a man is well hidden in summer and a watcher eight tiles' sight off does not
// spot him from six; in winter, with the leaves down, he is far less hidden there and is spotted
let grass_t = str_index(tr_names, "grass")
var hid = 0
var hid_c = 0
var open_least = 100
for(terrain) t, c:
    if t == grass_t:
        let v = cover_at(c)
        if v > hid:
            hid = v
            hid_c = c
        open_least = min(open_least, v)
let watch_x = (hid_c % W) * TILE + TILE / 2 + 6 * TILE
let watch_y = (hid_c / W) * TILE + TILE / 2
expect(hid >= 60 and open_least <= 10, "the wood hides a man well in summer and the open ground does not ({hid} and {open_least} in a hundred)")
expect(not spots(watch_x, watch_y, hid_c, 8 * TILE), "a watcher six tiles off does not spot him under the leaves")
year_force = 2000
let hid_winter = cover_at(hid_c)
expect(hid_winter < hid * 2 / 3, "in winter the same tile hides him far less ({hid_winter})")
expect(spots(watch_x, watch_y, hid_c, 8 * TILE), "and the same watcher spots him")
year_force = -1
// the weather (#15): no snow on the ground, so the men walk at their own pace whatever the sky does
expect(weather_pace() == 100, "nothing slows the men in summer ({weather_pace()})")
let first_sky, first_hard = weather_now()
expect(first_sky == "clear" and first_hard == 0, "the men leave on a clear morning")
// they walk in, and one of them fells the nearest young tree
for(200):
    step()
    route_tick()
expect(gates_armed, "the men walked in clear of the west gate")
let tree = str_index(tr_names, "young_tree")
let stump = str_index(tr_names, "stump")
var cut = -1
var best = 1 << 40
for(terrain) t, c:
    if t == tree:
        let d = dist2(u_x[0], u_y[0], (c % W) * TILE + 500, (c / W) * TILE + 500)
        if d < best:
            best = d
            cut = c
let cutter = men[0]
issue_cmd(0, CMD_GATHER, [ cutter.uid ], cut, 0, 0, 0)
var felled_at = -1
for(4000) n:
    if felled_at < 0:
        step()
        route_tick()
        if terrain[cut] == stump: felled_at = n
expect(felled_at >= 0, "a man felled a young tree (after {felled_at} ticks): a stump is left")
// (cover, #9: the tile beside the stump is less hidden than it was beside the tree)
let beside = cut + 1
let cover_stump = cover_at(beside)
terrain[cut] = tree
let cover_tree = cover_at(beside)
terrain[cut] = stump
expect(cover_stump < cover_tree, "felling the tree took its cover from the tile beside it ({cover_tree} to {cover_stump})")
let i0 = index_of(cutter.uid)
expect(u_carry[i0] == r_carry, "he carries a full load of wood ({u_carry[i0]})")
u_hp[index_of(men[1].uid)] = 17  // (a hurt man, to see his health carried)
let clock_before = clock_uh
// east, to the fir woods
let year_before = year_m
go_on(walk_to_gate("east"), "all the men reached the east gate")
expect(place_now() == "fir_woods" and arrived_by == "west", "the fir woods are loaded, the men at its west edge")
expect(u_x.length == 20, "all twenty arrived")
let i1 = index_of(cutter.uid)
expect(i1 >= 0 and u_carry[i1] == r_carry and resource_names[u_carry_kind[i1] - 1] == "wood", "the load of wood came with its man")
expect(u_hp[index_of(men[1].uid)] == 17, "the hurt man is still hurt")
// (the season moved while they were in the valley, no further than the leg lets it, and the walk brought it on)
expect(year_before > gint(gobj(route, "season"), "start", 0) and year_before <= 800, "the season moved on while they were in the valley (year {year_before})")
expect(year_m >= 800 and year_here() > year_m and season_now() == "autumn", "it is autumn in the fir woods, further on up there than in the valley (year {year_m}, {year_here()} here)")
expect(clock_uh - clock_before > 5 * 1000000, "the clock moved on by the walk between the places")
// they walk in, turn round and go home by the gate they came by
walk_in_clear(300)
// the landslide on the pass (#20): four men dig one heap of it away
let heap_t = str_index(tr_names, "rubble")
let heap = find(terrain): _ == heap_t
expect(heap >= 0, "the pass in the fir woods has a landslide across it")
let diggers = map(4) n: men[n + 2].uid
// (they walk up to it by the trail, then are set to dig)
issue_cmd(0, CMD_MOVE, diggers, (heap % W - 3) * TILE + 500, (heap / W) * TILE + 500, 0, 0)
for(1500):
    step()
    route_tick()
expect(abs(u_x[index_of(diggers[0])] / TILE - heap % W) <= 6, "the diggers walked up the pass to the landslide")
issue_cmd(0, CMD_GATHER, diggers, heap, 0, 0, 0)
var dug_at = -1
for(6000) n:
    if dug_at < 0:
        step()
        route_tick()
        if terrain[heap] != heap_t: dug_at = n
expect(dug_at >= 0 and tr_names[terrain[heap]] == "bare", "four men dug a heap of the landslide away (after {dug_at} ticks): bare ground is left")
expect(u_carry[index_of(men[2].uid)] == 0, "a digger carries nothing away")
// east past what is left of the slide, to the gorge: its bridge is found broken (#20)
go_on(walk_to_gate("east"), "all the men got by the landslide to the east gate")
expect(place_now() == "gorge" and br_up.length == 1 and br_up[0] == 0, "the gorge: its bridge is down")
let wood_k = str_index(resource_names, "wood") + 1
expect(not mend_bridge([ men[5].uid ], 0), "a man with no wood cannot mend the bridge")
// (the cutter still has his load from the beech valley; a second man is given one)
let menders = [ cutter.uid, men[1].uid ]
u_carry[index_of(men[1].uid)] = r_carry
u_carry_kind[index_of(men[1].uid)] = wood_k
issue_cmd(0, CMD_MOVE, ids_alive(), br_x0[0] - 3 * TILE, br_y0[0] + 500, 0, 0)
// (one man is sent to the far bank while the bridge is down: the only way is the ford downstream)
issue_cmd(0, CMD_MOVE, [ men[6].uid ], br_x1[0] + 3 * TILE, br_y0[0] + 500, 0, 0)
for(1500):
    step()
    route_tick()
expect(u_x[index_of(men[6].uid)] > br_x1[0], "a man sent across with the bridge down went round by the ford")
// (the ford, #20: a loaded man wades slower than one walking light, and both slower in high water)
expect(wade_pace(true) < wade_pace(false) and wade_pace(false) < 100, "a loaded man wades slower than one walking light ({wade_pace(true)} and {wade_pace(false)} in a hundred)")
let dry_wade = wade_pace(true)
year_force = 2700
expect(high_water() == 1000 and wade_pace(true) < dry_wade and ford_cold() > 50, "in the thaw the water is high and cold, and the ford slower ({wade_pace(true)})")
year_force = -1
expect(mend_bridge(menders, 0), "two men with a load of wood each set to mending it")
expect(u_carry[index_of(menders[0])] + u_carry[index_of(menders[1])] == 2 * r_carry - br_cost[wood_k - 1], "the wood came off their backs")
var mended_at = -1
for(3000) n:
    if mended_at < 0:
        step()
        route_tick()
        if br_up[0] == 1: mended_at = n
expect(mended_at >= 0, "the bridge stands again (after {mended_at} ticks)")
go_on(walk_to_gate("east"), "all the men crossed it to the east gate")
// on to the Roman ruins (#53): a shelf above the river, the old road on it
expect(place_now() == "ruins" and arrived_by == "west" and season_now() == "autumn", "the Roman ruins, from the west, in autumn")
expect(glist(su_map, "ruins").length > 20, "the old road and its ruins stand on the shelf")
let river_t = str_index(tr_names, "water")
expect(exists(terrain.length) c: terrain[c] == river_t and level[c] == 0, "the river runs on a floor below the shelf")
walk_in_clear(300)
go_on(walk_to_gate("east"), "the men crossed the ruins to the east gate")
// the pass (#54): the trail on a shelf, a valley path far below it (D-076)
expect(place_now() == "pass" and arrived_by == "west" and place_wood() == "high", "the pass, from the west, its last trees pine and spruce")
let trail_t = str_index(tr_names, "trail")
let shelf = level[cell_of(u_x[0], u_y[0])]
expect(shelf >= 7, "the men stand on the shelf, {shelf} levels up")
expect(exists(terrain.length) c: terrain[c] == trail_t and shelf - level[c] >= 7, "a path runs in the valley seven levels below them")
expect(season_now() == "autumn" and year_here() > year_m, "late autumn, further on up here than in the valleys (year {year_m}, {year_here()} here)")
walk_in_clear(300)
go_on(walk_to_gate("east"), "the men walked the shelf to the east gate")
// the high ridge (#55): one gate, the turn for home
expect(place_now() == "ridge" and arrived_by == "west" and gate_names.length == 1, "the high ridge, from the west: its only gate is the one they came by")
expect(snow_lying() > 0, "the first snow lies on the ridge ({snow_lying()})")
walk_in_clear(300)
// (they walk out to the end of the trail, the lookout over the far valley, then turn back)
let look_c = find(terrain.length) c: terrain[c] == trail_t and c % W > W / 2 and level[c] >= 7
expect(look_c >= 0, "the trail runs out east to a lookout on the ridge")
issue_cmd(0, CMD_MOVE, ids_alive(), (look_c % W) * TILE + 500, (look_c / W) * TILE + 500, 0, 0)
for(2500):
    step()
    route_tick()
expect(abs(u_x[index_of(men[0].uid)] / TILE - look_c % W) <= 8, "the men reached the lookout")
go_on(walk_to_gate("west"), "the men turned for home and walked back to the west gate")
expect(place_now() == "pass" and arrived_by == "east" and season_now() == "winter", "the pass again, from the east, in the first snow")
walk_in_clear(300)
go_on(walk_to_gate("west"), "the men walked the shelf back to the west gate")
expect(place_now() == "ruins" and arrived_by == "east" and season_now() == "winter", "the Roman ruins again, from the east, in winter")
walk_in_clear(300)
go_on(walk_to_gate("west"), "the men crossed the ruins back to the west gate")
expect(place_now() == "gorge" and arrived_by == "east" and season_now() == "winter", "the gorge again, from the east, in winter")
expect(br_up[0] == 1, "the bridge they mended still stands")
expect(leaf_stage_at(0) == "winter" and snow_lying() == 1000 and winter_depth() > 900, "midwinter: the trees are bare, snow lies, the days are at their shortest (year {year_m})")
// (the weather in the snow: the men are slowed; a spell of weather is the same every time it is asked for, and over
// the winter's spells snow falls and rain does not)
let pace_snow = weather_pace()
expect(pace_snow <= 75 and pace_snow >= 60, "lying snow slows the men ({pace_snow} in a hundred)")
let clock_was = clock_uh
var snows = 0
var rains = 0
var changed = 0
for(40) n:
    clock_uh = clock_was + n * 3000000 + 1500000
    let kind, hard = weather_now()
    let again, hard2 = weather_now()
    if kind != again or hard != hard2 or hard < 0 or hard > 1000: changed++
    if kind == "snow": snows++
    if kind == "rain": rains++
clock_uh = clock_was
expect(changed == 0, "a spell of weather is the same each time it is asked for")
expect(snows > 5 and rains == 0, "over forty spells of midwinter it snows ({snows}) and never rains ({rains})")
for(300):
    step()
    route_tick()
let slowed = index_of(men[0].uid)
expect(u_speed[slowed] < t_speed[u_kind[slowed]] and u_speed[slowed] > 0, "a man in the snow walks slower ({u_speed[slowed]} for {t_speed[u_kind[slowed]]})")
go_on(walk_to_gate("west"), "the men crossed back to the west gate")
expect(place_now() == "fir_woods" and arrived_by == "east" and season_now() == "winter", "the fir woods again, from the east, in winter")
expect(tr_names[terrain[heap]] == "bare", "the heap they dug away is still gone")
walk_in_clear(300)
go_on(walk_to_gate("west"), "all the men are back at the west gate")
expect(place_now() == "beech_valley" and arrived_by == "east" and season_now() == "spring", "the beech valley again, from the east, in spring")
expect(terrain[cut] == stump, "the tree felled on the way out is still a stump")
expect(snow_lying() > 0 and snow_lying() < 1000, "the last of the snow is going in the valley (year {year_m})")
walk_in_clear(300)
go_on(walk_to_gate("west"), "the men crossed the valley to the west gate")
expect(place_now() == "village_edge" and arrived_by == "east" and season_now() == "spring", "the village edge again, from the east, in spring")
walk_in_clear(300)
go_on(walk_to_gate("west"), "the men walked down to the lane")
expect(run_over() and men_alive() == 20, "home: the run is over, twenty men alive")
expect(leg_ids.length == 13, "the run had thirteen legs ({leg_ids.length})")
// (the legs as played, #57: the men walk straight to each gate, except where the check has them fell, dig, mend the
// bridge or go to the lookout; a sim tick is 1/TICK_HZ s)
var all_ticks = 0
for(leg_ids) id, k:
    all_ticks += leg_ticks[k]
    print "leg {k + 1} {id}: {leg_ticks[k] / TICK_HZ} s in it, loaded in {leg_loads[k]} s"
print "walking in all: {all_ticks / TICK_HZ / 60} min {all_ticks / TICK_HZ % 60} s"
print (if failed: "run_check: {failed} FAILED" else: "run_check: ok")
