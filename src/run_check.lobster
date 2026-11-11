// The run with no window: twenty men walk through the beech valley, fell a tree on the way, cross to the fir woods and
// come back, and the valley still has its stump. Proves issue #4's swap: one map per place, the men, their loads and
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
let i0 = index_of(cutter.uid)
expect(u_carry[i0] == r_carry, "he carries a full load of wood ({u_carry[i0]})")
u_hp[index_of(men[1].uid)] = 17  // (a hurt man, to see his health carried)
let clock_before = run_ticks
// east, to the fir woods
let out = walk_to_gate("east")
expect(out == "east", "all the men reached the east gate")
route_leave(out)
route_arrive(out)
expect(place_now() == "fir_woods" and arrived_by == "west", "the fir woods are loaded, the men at its west edge")
expect(u_x.length == 20, "all twenty arrived")
let i1 = index_of(cutter.uid)
expect(i1 >= 0 and u_carry[i1] == r_carry and resource_names[u_carry_kind[i1] - 1] == "wood", "the load of wood came with its man")
expect(u_hp[index_of(men[1].uid)] == 17, "the hurt man is still hurt")
expect(run_ticks - clock_before > 5 * ticks_per_hour(), "the clock moved on by the walk between the places")
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
let back = walk_to_gate("west")
expect(back == "west", "all the men are back at the west gate")
route_leave(back)
route_arrive(back)
expect(place_now() == "beech_valley" and arrived_by == "east" and season_now() == "spring", "the beech valley again, from the east, in spring")
expect(terrain[cut] == stump, "the tree felled on the way out is still a stump")
let mem = place_memory.get("fir_woods")
expect(mem != nil, "the fir woods are remembered too")
let home = walk_to_gate("west")
expect(home == "west", "the men crossed the valley to the west gate")
route_leave(home)
route_arrive(home)
expect(run_over() and men_alive() == 20, "home: the run is over, twenty men alive")
print "loads: first place {load0} s, last place {last_load_s} s"
print (if failed: "run_check: {failed} FAILED" else: "run_check: ok")
