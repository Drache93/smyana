// The run with no window: twenty men walk through the beech valley, fell a tree on the way, cross to the fir woods, dig
// at the landslide, mend the gorge's bridge, and come back the same way: the valley still has its stump. Proves issue #4's swap: one map per place, the men, their loads and
// the clock carried across, the place remembered. Run from src/: lobster run_check.lobster (./check.sh does).
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
    return steps_until_gate(6000)

lib_load("../data")
route_load()
run_begin()
expect(place_now() == "beech_valley" and u_x.length == 20, "the run starts in the beech valley with twenty men ({u_x.length})")
expect(over_budget() == "", "the place is inside the size budget")
// the season clock (#10): the run starts in late summer, every beech in leaf
expect(season_now() == "summer" and year_m == gint(gobj(route, "season"), "start", -1), "the season clock starts in late summer (year {year_m})")
expect(not exists(terrain.length) c: leaf_stage_at(c) != "summer", "every tree still wears the leaves of summer")
expect(leaves_down() == 0 and snow_lying() == 0, "no leaves are down yet and no snow lies")
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
let load0 = last_load_s
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
let out = walk_to_gate("east")
expect(out == "east", "all the men reached the east gate")
let year_before = year_m
route_leave(out)
route_arrive(out)
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
for(300):
    step()
    route_tick()
expect(gates_armed, "the men walked in clear of the gate")
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
let east = walk_to_gate("east")
expect(east == "east", "all the men got by the landslide to the east gate")
route_leave(east)
route_arrive(east)
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
expect(mend_bridge(menders, 0), "two men with a load of wood each set to mending it")
expect(u_carry[index_of(menders[0])] + u_carry[index_of(menders[1])] == 2 * r_carry - br_cost[wood_k - 1], "the wood came off their backs")
var mended_at = -1
for(3000) n:
    if mended_at < 0:
        step()
        route_tick()
        if br_up[0] == 1: mended_at = n
expect(mended_at >= 0, "the bridge stands again (after {mended_at} ticks)")
let over = walk_to_gate("east")
expect(over == "east", "all the men crossed it to the east gate")
// the season's work is beyond that gate: they come back in by it in winter, and the bridge is as they left it
route_leave(over)
route_arrive(over)
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
let west1 = walk_to_gate("west")
expect(west1 == "west", "the men crossed back to the west gate")
route_leave(west1)
route_arrive(west1)
expect(place_now() == "fir_woods" and arrived_by == "east" and season_now() == "winter", "the fir woods again, from the east, in winter")
expect(tr_names[terrain[heap]] == "bare", "the heap they dug away is still gone")
for(300):
    step()
    route_tick()
let back = walk_to_gate("west")
expect(back == "west", "all the men are back at the west gate")
route_leave(back)
route_arrive(back)
expect(place_now() == "beech_valley" and arrived_by == "east" and season_now() == "spring", "the beech valley again, from the east, in spring")
expect(terrain[cut] == stump, "the tree felled on the way out is still a stump")
expect(snow_lying() > 0 and snow_lying() < 1000, "the last of the snow is going in the valley (year {year_m})")
let home = walk_to_gate("west")
expect(home == "west", "the men crossed the valley to the west gate")
route_leave(home)
route_arrive(home)
expect(run_over() and men_alive() == 20, "home: the run is over, twenty men alive")
print "loads: first place {load0} s, last place {last_load_s} s"
print (if failed: "run_check: {failed} FAILED" else: "run_check: ok")
