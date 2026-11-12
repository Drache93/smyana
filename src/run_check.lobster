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
// (the walk and the threats are checked on their own: the men are kept fed, warm and rested; the needs are checked at
// the end)
needs_kept = true
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
expect((filter(u_owner) o: o == 0).length == 20, "all twenty arrived")
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

// the rifles (#58): on the range, twenty men told to fire at a mark go off in ones and twos, and none is ready again
// for 18 s
guns_load()
threats_load()
with_mark = true
enter_leg("village_out", "west")
with_mark = false
for(u_x.length) i:
    u_x[i] = 14 * TILE + 500 - (i % 2) * 700
    u_y[i] = 46 * TILE + 500 + (i / 2) * 800
let mark = guns_mark(19 * TILE + 500, 50 * TILE + 500)
expect(mark != 0, "a mark is put up on the range")
guns_order(ids_alive(), mark)
let first_shot = dictionary<int, int>(32)
var most_at_once = 0
var shortest = 1 << 30  // ticks between a man's first two shots, the shortest
for(60 * TICK_HZ):
    step()
    let fired = guns_after_step()
    most_at_once = max(most_at_once, fired.length)
    for(fired) id:
        let first = first_shot.get(id, -1)
        if first < 0: first_shot.set(id, tick)
        elif first < 1 << 30:
            shortest = min(shortest, tick - first)
            first_shot.set(id, 1 << 30)  // (only the first two of each)
expect(shortest >= 18 * TICK_HZ and shortest < 1 << 30, "a man fires again only after his reload (the quickest {shortest / TICK_HZ} s)")
expect(first_shot.get_keys().length == 20, "all twenty men fired ({first_shot.get_keys().length})")
expect(most_at_once <= 2, "never more than two rifles go off in one tick ({most_at_once})")

// the patrol (#62, docs/threats.md): it walks its road past the men in the autumn beeches; they open fire when it is
// close, it hears the shots, sees the men by their smoke and fights back; balls miss and hit, men fall on both sides,
// and when half of them are down the rest fall back the way they came
with_patrol = true
enter_leg("beech_valley_out", "west")
with_patrol = false
for(u_x.length) i:
    u_x[i] = 20 * TILE + 500 - (i % 3) * 900
    u_y[i] = 39 * TILE + 500 + (i / 3) * 900
    issue_cmd(0, CMD_MOVE, [ u_id[i] ], u_x[i], u_y[i], 0, 0)
let pk = patrol_spawn(map([ 44, 30, 26, 44, 20, 70 ]) v: v * TILE + TILE / 2, 7)
expect(pk >= 0, "a patrol is set on its road")
var opened = false
var states = ""
var patrol_shots = 0
var men_shots = 0
var hits = 0
var misses = 0
var danger_seen = ""
for(150 * TICK_HZ):
    step()
    let fired = guns_after_step()
    threats_after_step(fired)
    route_tick()
    for(fired) id: if man_of(id): men_shots++ else: patrol_shots++
    for(threats_landed()) l: if l.hit: hits++ else: misses++
    let st = "{patrols[0].state}"
    if not ends_with(states, st): states += st
    let dz = threats_danger()
    if dz != "" and find_string(danger_seen, dz) < 0: danger_seen += dz + " "
    if not opened:
        // (they open fire when the first of the patrol is within the rifle's reach of any of them)
        for(patrol_alive(patrols[0])) pid:
            let pi = index_of(pid)
            for(ids_alive()) mid:
                let mi = index_of(mid)
                if not opened and mi >= 0 and dist2(u_x[pi], u_y[pi], u_x[mi], u_y[mi]) < 7 * TILE * 7 * TILE:
                    opened = true
                    guns_order(ids_alive(), pid)
let patrol_fell = (filter(fallen) f: f.patrol).length
print "fight: patrol states {states}, shots {men_shots} by the men and {patrol_shots} by the patrol, {hits} hits and {misses} misses, {men_killed} men and {patrol_fell} patrolmen fell, music {danger_seen}"
expect(opened, "the men open fire on the patrol")
expect(find_string(states, "02") >= 0 or find_string(states, "012") >= 0, "the patrol hears or sees them and fights ({states})")
expect(patrol_shots > 0, "the patrol fires back ({patrol_shots})")
expect(hits > 0 and misses > 0, "balls both hit and miss ({hits}, {misses})")
expect(patrol_fell > 0, "patrolmen fall ({patrol_fell})")
expect(find_string(danger_seen, "ottomans") >= 0, "the music turns to the patrol\'s")
expect(patrols[0].state == P_FALLBACK or patrols[0].state == P_GONE, "the patrol breaks off ({patrols[0].state})")

// the set piece in the pass (leg 8, D-076, D-077): the patrol sets out on the valley path far below the shelf, is not
// seen from it nor sees the men up there, comes up the ramp near the east gate, and finds men who have waited on the
// trail
enter_leg("pass_home", "east")
expect(not patrols.length, "no patrol in the pass when the men come in")
for(u_x.length) i: issue_cmd(0, CMD_MOVE, [ u_id[i] ], (86 + i % 5) * TILE + 500, (22 + i / 5) * TILE + 500, 0, 0)
var below_saw = false
var came_up = false
var hunted_on_shelf = false
for(150 * TICK_HZ):
    step()
    threats_after_step(guns_after_step())
    route_tick()
    if patrols.length:
        let lead = patrol_alive(patrols[0])
        if lead.length:
            let ly = u_y[index_of(lead[0])] / TILE
            if ly > 40 and patrols[0].state == P_HUNT: below_saw = true
            if ly < 30: came_up = true
            if ly < 30 and patrols[0].state == P_HUNT: hunted_on_shelf = true
expect(patrols.length == 1, "the patrol sets out after the men")
expect(not below_saw, "from the valley path it does not see the men on the shelf")
expect(came_up, "it comes up the ramp onto the shelf")
expect(hunted_on_shelf, "and finds the men who waited on the trail")

// the wolves (#60): in early autumn they follow the men at a distance, never close in, and a shot scatters them
enter_leg("fir_woods_out", "west")
expect(packs.length == 1 and pack_alive(packs[0]).length == 5, "five wolves in the fir woods")
var closest = 1 << 30
var bit = false
for(90 * TICK_HZ):
    step()
    route_tick()
    for(threats_landed()) l: if is_wolf(l.by): bit = true
    for(pack_alive(packs[0])) wid: for(men_here()) mi: closest = min(closest, int(sqrt(float(dist2(u_x[index_of(wid)], u_y[index_of(wid)], u_x[mi], u_y[mi])))) / TILE)
expect(not bit and closest >= 6, "they follow and never close in ({closest} tiles at the closest)")
expect(threats_danger() == "wary", "the music is wary while they follow")
let shooter = men_here()[0]
threats_after_step([ u_id[shooter] ])
expect(packs[0].state == W_SCATTER, "a shot scatters them")
// in deep winter, at night, they go for a man on his own; the men fire, and when two are down the pack runs
hour_force = 23.0
enter_leg("fir_woods_home", "east")
let lone = men_here()[0]
for(men_here()) mi: if mi != lone: issue_cmd(0, CMD_MOVE, [ u_id[mi] ], u_x[mi], u_y[mi], 0, 0)
issue_cmd(0, CMD_MOVE, [ u_id[lone] ], 70 * TILE, 62 * TILE, 0, 0)
var hunted = false
var wolves_bit = 0
var fired_on = false
for(120 * TICK_HZ):
    step()
    let fired = guns_after_step()
    threats_after_step(fired)
    route_tick()
    for(threats_landed()) l: if is_wolf(l.by): wolves_bit++
    if packs[0].state == W_HUNT: hunted = true
    if hunted and not fired_on:
        fired_on = true
        guns_order(map(filter(men_here()) mi: mi != index_of(packs[0].prey)) mi: u_id[mi], pack_alive(packs[0])[0])
hour_force = -1.0
let wolves_down = (filter(fallen) f: f.beast == "wolf").length
print "wolves: winter pack hunted {hunted}, {wolves_bit} bites, {wolves_down} wolves down, state {packs[0].state}"
expect(hunted, "at night the winter wolves go for a man on his own")
expect(wolves_bit > 0, "they bite him ({wolves_bit})")
expect(packs[0].state == W_FLED or packs[0].state == W_SCATTER, "shot at, they scatter or run ({packs[0].state})")
// the bear (#61): at the thaw in the beech valley it wanders; a man it sees close makes it rear up and huff, then
// bluff, stopping short; shot at, it charges for real, and runs when it is badly hurt
enter_leg("beech_valley_home", "east")
expect(bears.length == 1, "a bear in the beech valley at the thaw")
let bear_men = men_here()
let bi0 = index_of(bears[0].id)
// (the men walk up to it)
for(bear_men) mi: issue_cmd(0, CMD_MOVE, [ u_id[mi] ], u_x[bi0] + 5 * TILE, u_y[bi0], 0, 0)
var reared = false
var bluffed = false
var swiped_in_bluff = false
for(90 * TICK_HZ):
    step()
    route_tick()
    if bears[0].state == B_REAR: reared = true
    if bears[0].state == B_BLUFF: bluffed = true
    for(threats_landed()) l: if bear_of(l.by) >= 0: swiped_in_bluff = true
    if bluffed and bears[0].state == B_WANDER: break
expect(reared, "it rears up at a man close by")
expect(bluffed and not swiped_in_bluff, "it bluffs, and stops short")
expect(threats_danger() == "", "and leaves them be ({threats_danger()})")
// shot at: it charges the men, and the men keep firing
guns_order(map(men_here()) mi: u_id[mi], bears[0].id)
var charged = false
var swipes = 0
var bear_hit = 0
for(150 * TICK_HZ):
    step()
    let fired = guns_after_step()
    threats_after_step(fired)
    route_tick()
    if bears[0].state == B_CHARGE: charged = true
    for(threats_landed()) l:
        if bear_of(l.by) >= 0: swipes++
        if l.hit and bear_of(l.to) >= 0: bear_hit++
    if bears[0].state >= B_FLED: break
print "bear: charged {charged}, {swipes} swipes, {bear_hit} hits on it, state {bears[0].state}"
expect(charged, "shot at, it charges")
expect(bears[0].state == B_FLED or bears[0].state == B_DEAD, "badly hurt it runs, or it falls ({bear_hit} hits)")

// surviving (#65, #68, docs/survival.md): a winter night in the fir woods, half the men in a camp round a fire and half
// standing out in the cold; the camp sleeps, eats hot and stays warm, the others don't, and the wolves keep off the fire
needs_kept = false
hour_force = 22.0
enter_leg("fir_woods_home", "east")
let all_ids = ids_alive()
for(men) m: if m.alive: m.warm = 60000
let campers = slice(all_ids, 0, all_ids.length / 2)
let cold_ones = slice(all_ids, all_ids.length / 2, -1)
for(cold_ones) id, n: issue_cmd(0, CMD_MOVE, [ id ], u_x[index_of(id)] - 12 * TILE + (n % 4) * 700, u_y[index_of(id)] + (n / 4) * 700, 0, 0)
let food_before = (fold(men, 0) a, m: a + m.food)
expect(camp_order(campers), "the men make camp")
var slept = 0
var wolves_near_fire = 1 << 30
for(80 * TICK_HZ):
    step()
    threats_after_step(guns_after_step())
    route_tick()
    for(campers) id: if is_asleep(id): slept = max(slept, (filter(campers) c: is_asleep(c)).length)
    let fl = fires_lit()
    if fl.length and packs.length: for(pack_alive(packs[0])) wid: wolves_near_fire = min(wolves_near_fire, int(sqrt(float(dist2(u_x[index_of(wid)], u_y[index_of(wid)], fl[0].x, fl[0].y)))) / TILE)
hour_force = -1.0
def warm_of(ids:[int]) -> int:
    var w = 0
    for(ids) id:
        let m = man_of(id)
        if m: w += m.warm / 1000 / ids.length
    return w
def rested_of(ids:[int]) -> int:
    var r = 0
    for(ids) id:
        let m = man_of(id)
        if m: r += m.rested / 1000 / ids.length
    return r
let food_after = (fold(men, 0) a, m: a + m.food)
print "camp: {slept} asleep, warmth {warm_of(campers)} by the fire and {warm_of(cold_ones)} out in the cold, rest {rested_of(campers)} and {rested_of(cold_ones)}, {meals_hot} hot meals, food {food_before} to {food_after}, wolves {wolves_near_fire} tiles from the fire at the closest"
expect(fires_lit().length == 1, "its fire burns")
expect(slept > campers.length / 2, "the camp sleeps at night ({slept})")
expect(warm_of(campers) > warm_of(cold_ones) + 20, "the fire keeps them warm, the others get cold")
expect(rested_of(campers) > rested_of(cold_ones) + 10, "they get their rest back")
expect(meals_hot > 0 and food_after < food_before, "they eat a hot meal from what they carry")
expect(wolves_near_fire >= fire_keep_tiles(), "the wolves keep off the fire")
// a fire is seen at night: a patrol passing sixteen tiles off, too far to see the men, comes to look
hour_force = 23.0
with_patrol = true
enter_leg("beech_valley_out", "west")
with_patrol = false
for(80): step()
let mid = men_here()[0]
let fx = u_x[mid] / TILE
let fy = u_y[mid] / TILE
// (two of them carry wood for the fire)
for(2) n:
    u_carry[men_here()[n]] = r_carry
    u_carry_kind[men_here()[n]] = wood_k
camp_order(ids_alive())
for(10 * TICK_HZ):
    step()
    route_tick()
let road_x = min(W - 3, fx + 16)
patrol_spawn(map([ road_x, max(2, fy - 20), road_x, min(H - 3, fy + 20) ]) v: v * TILE + TILE / 2, 6)
var came_to_look = false
for(60 * TICK_HZ):
    step()
    threats_after_step(guns_after_step())
    route_tick()
    if patrols[0].state == P_WARY: came_to_look = true
hour_force = -1.0
expect(came_to_look, "a patrol sees the fire at night and comes to look")
// put out, the fire is not seen
camp_order(ids_alive())
expect(not fires_lit().length, "the fire is put out")
// gathering (#66): in the autumn beeches there are nuts and mushrooms to find; men sent to a patch gather it into their
// packs, and it stays taken when they come back
year_force = 1000
enter_leg("beech_valley_out", "west")
for(60): step()
let patches_before = forage_patches().length
let gatherers = slice(ids_alive(), 0, 4)
let food0 = fold(men, 0) a, m: a + m.food
let gi = index_of(gatherers[0])
var nearest_patch = -1
for(forage_patches()) c: if nearest_patch < 0 or dist2((c % W) * TILE, (c / W) * TILE, u_x[gi], u_y[gi]) < dist2((nearest_patch % W) * TILE, (nearest_patch / W) * TILE, u_x[gi], u_y[gi]): nearest_patch = c
expect(patches_before > 10 and forage_order(gatherers, nearest_patch), "autumn beeches give patches to gather ({patches_before}), and men go to them")
for(60 * TICK_HZ):
    step()
    route_tick()
let food1 = fold(men, 0) a, m: a + m.food
let patches_after = forage_patches().length
print "gathering: {patches_before} patches, {patches_before - patches_after} gathered, food {food0} to {food1}"
expect(food1 > food0 and patches_after < patches_before, "they gather it into their packs")
forage_leave(place_now())
forage_enter(place_now())
expect(forage_patches().length == patches_after, "what is taken stays taken")
year_force = -1
// packs (#67, #69): a full pack slows a man; the men drop their packs and pick them up again; a pile in the open is
// found by a patrol that passes
year_force = 1000
with_patrol = true
enter_leg("beech_valley_out", "west")
with_patrol = false
for(80): step()
let carriers = ids_alive()
for(men) m: if m.alive: m.food = 2
let first = man_of(carriers[0])
if first: first.food = 12
for(20):
    step()
    route_tick()
let heavy = u_speed[index_of(carriers[0])]
let light = u_speed[index_of(carriers[1])]
expect(heavy < light, "a full pack slows a man ({heavy} against {light})")
let food_pk = fold(men, 0) a, m: a + m.food
expect(packs_drop(carriers) and piles.length == 1, "the men drop their packs")
let left = fold(men, 0) a, m: a + m.food
expect(left == carriers.length and piles[0].food == food_pk - left, "keeping a day\'s food each ({left})")
packs_fetch(carriers, 0)
for(20 * TICK_HZ):
    step()
    route_tick()
expect(not piles.length and (fold(men, 0) a, m: a + m.food) == food_pk, "and pick them up again")
// (a pile left out in the open, and a patrol down a road past it)
packs_drop(carriers)
let pile_x = piles[0].x / TILE
let pile_y = piles[0].y / TILE
for(men) m:
    if m.alive:
        let mi = index_of(m.uid)
        if mi >= 0: issue_cmd(0, CMD_MOVE, [ m.uid ], 4 * TILE, u_y[mi], 0, 0)
patrol_spawn(map([ pile_x + 14, pile_y - 12, pile_x + 1, pile_y, pile_x + 1, min(H - 3, pile_y + 20) ]) v: v * TILE + TILE / 2, 6)
for(60 * TICK_HZ):
    step()
    threats_after_step(guns_after_step())
    route_tick()
expect(piles_lost > 0 and not piles.length, "a patrol passing finds the pile and takes it")
year_force = -1
// the Roman drain (#70): eight men study it at the ruins and learn it; the tally (#72) says so, and names the fallen
needs_kept = true
enter_leg("ruins_out", "west")
for(40): step()
let scholars = slice(ids_alive(), 0, 8)
expect(study_order(scholars), "the men go to study the drain")
var learned_after = -1
for(150 * TICK_HZ) n:
    step()
    route_tick()
    if learned_after < 0 and drain_learned(): learned_after = n / TICK_HZ
let knowers = (filter(men) m: m.alive and knows_drain(m)).length
print "drain: learned after {learned_after} s by {knowers} men"
expect(learned_after > 0 and knowers == 8, "they learn it, and those eight know it")
let said = tally_lines()
print "tally: {said}"
expect((find(said) l: find_string(l, "Romans") >= 0) >= 0, "the tally says what they learned")
expect(men_alive() == men.length or (find(said) l: find_string(l, " lies in ") >= 0) >= 0, "and names the fallen")
print (if failed: "run_check: {failed} FAILED" else: "run_check: ok")
