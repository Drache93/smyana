// ------------------------------------------------------------------ what hunts the men (docs/threats.md, #49)
// Each threat has a small mind: on its way (the patrol on its road), wary (it heard a shot and comes to look), hunting
// (it has seen a man) and gone. It finds the men only by their cover (route.lobster's spots, D-064), and a man who
// has fired is seen through his cover while his smoke hangs over him. A shot is heard a long way (data/threats.json).
// How a ball lands is here too: a flintlock misses more the further it is fired and the better the target is hidden,
// a first hit wounds a man and a second kills him.
// The Ottoman patrol (#62) is the first threat; the wolves (#60) and the bear (#61) come next.
// Sim side only (no window), and every chance is a hash of the sim's own numbers, so a fight plays the same every time.

let P_ROAD = 0      // walking their road
let P_WARY = 1      // a shot was heard: going to look
let P_HUNT = 2      // a man was seen: fighting
let P_FALLBACK = 3  // too many down: back the way they came
let P_GONE = 4      // off the map, or all dead

class Patrol:
    ids:[int]
    road:[int]    // x0, y0, x1, y1 ... milli-tiles: where they walk, and the way they came
    start:int     // how many set out
    next:int = 1  // the road's point they are walking to
    state:int = P_ROAD
    goal_x:int = 0  // where they go to look (the shot heard) or to close in (the man last seen)
    goal_y:int = 0
    since:int = 0  // the tick a man was last seen (hunting), or the search began (wary)

// A ball landing (the view shows it): on whom, whether it hit, and where.
class Landed:
    by:int
    to:int
    hit:bool
    x:int
    y:int

// One who fell where he was hit (the view draws him lying there).
class Fallen:
    uid:int
    x:int
    y:int
    look:int  // which baked look (the men's, then the patrol's)
    patrol:bool
    by_x:int  // where the shot that killed him came from: he falls back, away from it
    by_y:int

var threats_cfg = jobj()
var patrols = []::Patrol
var landed = []::Landed
var fallen = []::Fallen
var men_killed = 0        // men killed in this place
var patrol_due = []::int  // a patrol's road, due to set out on it at patrol_due_at (patrol_later)
var patrol_due_n = 0
var patrol_due_at = 0
let shot_seen = dictionary<int, int>(32)     // a rifleman's id: the tick he last fired
let patrol_looks = dictionary<int, int>(32)  // a patrolman's id: his look among the patrol's
let patrol_hurt = dictionary<int, int>(32)   // a patrolman's id: 1 if a ball has hit him
let men_firing = dictionary<int, int>(32)    // a man told to fire (guns_order): 1 till he is told to walk somewhere
let aim_seen = dictionary<int, int>(32)      // a rifleman's id: the tick he last saw the one he is firing at

def threats_load(): threats_cfg = lib_data("threats.json")

def patrol_cfg() -> JV: return gobj(threats_cfg, "patrol")

// A new place: nothing of the last one's threats carries over.
def threats_clear():
    patrols = []
    patrol_due = []
    landed = []
    fallen = []
    men_killed = 0
    shot_seen.clear()
    patrol_looks.clear()
    patrol_hurt.clear()
    men_firing.clear()
    aim_seen.clear()

def threat_hash(a:int, b:int, c:int) -> int: return (((a * 2654435761) ^ (b * 40503 + 977) ^ (c * 69069 + 12345)) >> 7) & 0xFFFF

// The patrol in which this unit walks, or -1.
def patrol_of(uid:int) -> int:
    for(patrols) p, k: if (find(p.ids): _ == uid) >= 0: return k
    return -1

// His look among the patrol's (data/threats.json patrol.looks), or -1 if he isn't one of them.
def patrol_look(uid:int) -> int: return patrol_looks.get(uid, -1)

def rifleman(uid:int) -> bool: return man_of(uid) != nil or patrol_look(uid) >= 0

// ---- how a ball lands

// Hit or miss, for a shot fired by `by` (an id) landing on unit j (an index), and the damage it does: Creel's
// hook_on_hit.
def threats_on_hit(by:int, j:int, damage:int) -> int:
    let i = index_of(by)
    if i < 0 or not rifleman(by): return damage
    let h = gobj(threats_cfg, "hit")
    let d = sqrt(float(dist2(u_x[i], u_y[i], u_x[j], u_y[j]))) / float(TILE)
    let near = float(gint(h, "near_tiles", 2))
    let reach = max(near + 1.0, float(t_reach[u_kind[i]]) / float(TILE))
    let k = clamp((d - near) / (reach - near), 0.0, 1.0)
    let chance = int(float(gint(h, "near", 90)) + (float(gint(h, "far", 25)) - float(gint(h, "near", 90))) * k)
    let hidden = if t_hp[u_kind[j]] > 100000: 0 else: cover_at(cell_of(u_x[j], u_y[j]))  // (the mark on the range has none)
    let p = chance * (100 - hidden * gint(h, "cover_halves", 50) / 100) / 100
    let hit = threat_hash(by, u_id[j], tick) % 100 < p
    landed.push(Landed { by, u_id[j], hit, u_x[j], u_y[j] })
    if not hit: return 0
    if t_hp[u_kind[j]] > 100000: return damage
    let m = man_of(u_id[j])
    if m: m.wounded = true
    if patrol_look(u_id[j]) >= 0: patrol_hurt.set(u_id[j], 1)
    return if d <= float(gint(h, "kill_tiles", 1)): u_hp[j] else: gint(h, "wound", 25)

// Creel's hook_on_death: a man or a patrolman falls where he was, back from the one who shot him.
def threats_on_death(i:int, killer:int):
    let k = index_of(killer)
    let bx = if k >= 0: u_x[k] else: u_x[i] + 1000
    let by = if k >= 0: u_y[k] else: u_y[i]
    let m = man_of(u_id[i])
    if m:
        fallen.push(Fallen { u_id[i], u_x[i], u_y[i], m.look, false, bx, by })
        men_killed++
    let pk = patrol_look(u_id[i])
    if pk >= 0: fallen.push(Fallen { u_id[i], u_x[i], u_y[i], gstrs(men_data, "looks").length + pk, true, bx, by })

// How fast this unit walks for its wounds, in hundredths: slowly once a ball has hit him.
def wound_pace(i:int) -> int:
    let m = man_of(u_id[i])
    let hurt = if m: m.wounded else: patrol_hurt.get(u_id[i], 0) == 1
    return if hurt: gint(threats_cfg, "wounded_pace", 55) else: 100

// The ball, the dust and the dead the view has drawn: take them.
def threats_landed() -> [Landed]:
    let l = landed
    landed = []
    return l

// ---- the patrol

// A patrol of n men set on its road (x, y pairs, milli-tiles), at its first point.
def patrol_spawn(road:[int], n:int) -> int:
    let k = type_of_slot(1, "patrol")
    if k < 0 or road.length < 4: return -1
    let ids = []::int
    let dx = road[2] - road[0]
    let dy = road[3] - road[1]
    let len = max(1, int(sqrt(float(dx * dx + dy * dy))))
    let nlooks = gstrs(patrol_cfg(), "looks").length
    let reach = reach_from(k, cell_of(road[2], road[3]))
    for(n) m:
        // (in a knot at the road's start, three abreast, on along the way they go: on the road, so none is set down in
        // a pocket of the wood he can't walk out of)
        let ahead = (n / 3 - m / 3) * 800
        let side = (m % 3 - 1) * 700
        let x, y = reachable_near(reach, road[0] + dx * ahead / len - dy * side / len, road[1] + dy * ahead / len + dx * side / len)
        let i = add_unit(1, k, x, y)
        u_posture[i] = PASSIVE  // (they fire at what they see, not at all Creel's sight finds: patrol_think)
        ids.push(u_id[i])
        patrol_looks.set(u_id[i], (m * 7 + 3) % max(1, nlooks))
    grow_scratch()
    let p = Patrol { ids, road, n }
    patrols.push(p)
    patrol_walk(p, road[2], road[3])
    return patrols.length - 1

// The tiles a unit of kind k of the patrol's side can walk to from cell c (1), and those it can't (0).
def reach_from(k:int, c:int) -> [int]:
    let ln = lane_base[1] + t_mclass[k]
    let seen = map(W * H): 0
    if walks[ln][c] != 1: return seen
    seen[c] = 1
    let todo = [ c ]
    while todo.length:
        let n = todo.pop()
        let x = n % W
        let y = n / W
        for([ int2 { 1, 0 }, int2 { -1, 0 }, int2 { 0, 1 }, int2 { 0, -1 } ]) d:
            let u = x + d.x
            let v = y + d.y
            if u >= 0 and v >= 0 and u < W and v < H and seen[v * W + u] == 0 and walks[ln][v * W + u] == 1:
                seen[v * W + u] = 1
                todo.push(v * W + u)
    return seen

// The nearest place to (x, y) on the tiles `reach` marks, milli-tiles (a patrol set down in a thicket, or in a pocket
// of the wood with no way out to its road, is set down beside it).
def reachable_near(reach:[int], x:int, y:int) -> int, int:
    let cx = clamp(x / TILE, 0, W - 1)
    let cy = clamp(y / TILE, 0, H - 1)
    for(12) r:
        for(r * 2 + 1) j: for(r * 2 + 1) i:
            let u = cx + i - r
            let v = cy + j - r
            if u >= 0 and v >= 0 and u < W and v < H and reach[v * W + u] == 1:
                return if r == 0: (x, y) else: (u * TILE + TILE / 2, v * TILE + TILE / 2)
    return x, y

def patrol_alive(p:Patrol) -> [int]: return filter(p.ids) id: index_of(id) >= 0

def patrol_walk(p:Patrol, x:int, y:int):
    let ids = patrol_alive(p)
    if ids.length: issue_cmd(1, CMD_MOVE, ids, x, y, 0, 0)

// Whether unit i, who sees `sight` (milli-tiles) on a clear day in the open, sees unit j: by j's cover (spots), and
// through it while the smoke of a shot j has just fired hangs over him.
def sees(i:int, j:int, sight:int) -> bool:
    let after = gint(threats_cfg, "seen_after_shot_s", 12) * TICK_HZ
    if tick - shot_seen.get(u_id[j], -(1 << 30)) < after:
        let reach = sight * sight_pct() / 100
        return dist2(u_x[i], u_y[i], u_x[j], u_y[j]) <= reach * reach
    return spots(u_x[i], u_y[i], cell_of(u_x[j], u_y[j]), sight)

// Whether rifleman i keeps on the foe he is firing at: he can see him, or saw him a moment ago and he is not far
// off (one glimpse lost behind a trunk doesn't end it: "keep_s").
def keeps_on(i:int, foe:int, sight:int) -> bool:
    if sees(i, foe, sight):
        aim_seen.set(u_id[i], tick)
        return true
    return tick - aim_seen.get(u_id[i], -(1 << 30)) < gint(threats_cfg, "keep_s", 6) * TICK_HZ and dist2(u_x[i], u_y[i], u_x[foe], u_y[foe]) <= sight * sight

// The man patrolman i sees (an index), the nearest, or -1.
def seen_by(i:int) -> int:
    let sight = gint(patrol_cfg(), "sight", 10) * TILE
    var best = -1
    var best_d = 1 << 62
    for(men) m:
        if m.alive:
            let j = index_of(m.uid)
            if j >= 0:
                let d = dist2(u_x[i], u_y[i], u_x[j], u_y[j])
                if d < best_d and sees(i, j, sight):
                    best = j
                    best_d = d
    return best

// A shot heard at (x, y): a patrol on its road, or searching, comes to look.
def patrol_hear(p:Patrol, by:int, x:int, y:int):
    if p.state != P_ROAD and p.state != P_WARY: return
    let spread = gint(patrol_cfg(), "heard_spread", 3) * TILE
    p.state = P_WARY
    p.since = tick
    p.goal_x = x + threat_hash(by, tick, 1) % (spread * 2 + 1) - spread
    p.goal_y = y + threat_hash(by, tick, 2) % (spread * 2 + 1) - spread
    patrol_walk(p, p.goal_x, p.goal_y)

def patrol_think(p:Patrol):
    if p.state == P_GONE: return
    let alive = patrol_alive(p)
    if not alive.length:
        p.state = P_GONE
        return
    let pc = patrol_cfg()
    for(alive) id:
        let i = index_of(id)
        u_speed[i] = max(1, t_speed[u_kind[i]] * wound_pace(i) / 100)
    // too many down: back the way they came, and off the map there
    if p.state != P_FALLBACK and alive.length * 100 < p.start * gint(pc, "break_share", 50):
        p.state = P_FALLBACK
        patrol_walk(p, p.road[0], p.road[1])
        return
    let lead = index_of(alive[0])
    if p.state == P_FALLBACK or (p.state == P_ROAD and p.next * 2 >= p.road.length):
        let ex = if p.state == P_FALLBACK: p.road[0] else: p.road[p.road.length - 2]
        let ey = if p.state == P_FALLBACK: p.road[1] else: p.road[p.road.length - 1]
        if dist2(u_x[lead], u_y[lead], ex, ey) < 2 * TILE * 2 * TILE:
            var n = u_id.length - 1
            while n >= 0:
                if (find(alive): _ == u_id[n]) >= 0: remove_unit(n)
                n--
            p.state = P_GONE
        return
    // who of them sees a man
    let sees = map(alive) id: seen_by(index_of(id))
    for(sees) j:
        if j >= 0:
            p.goal_x = u_x[j]
            p.goal_y = u_y[j]
            p.since = tick
            p.state = P_HUNT
    if p.state == P_HUNT:
        for(alive) id, n:
            let i = index_of(id)
            let j = sees[n]
            let foe = if u_foe[i] != 0: index_of(u_foe[i]) else: -1
            let keep = foe >= 0 and keeps_on(i, foe, gint(pc, "sight", 10) * TILE)
            if j >= 0 and not keep:
                // (onto the nearest man he sees, bringing the rifle up in his own time)
                issue_cmd(1, CMD_ATTACK, [ id ], u_id[j], 0, 0, 0)
                aim_seen.set(id, tick)
                u_cooldown[i] = max(u_cooldown[i], guns_ticks("aim_s", id, tick))
            elif keep:
                pass()
            elif foe >= 0 or (u_moving[i] == 0 and dist2(u_x[i], u_y[i], p.goal_x, p.goal_y) > 3 * TILE * 3 * TILE):
                // (the man he was firing at is hidden again, or he stands idle far from the last place one was seen:
                // closing in on it)
                issue_cmd(1, CMD_MOVE, [ id ], p.goal_x + (n % 3 - 1) * 900, p.goal_y + (n / 3 % 3 - 1) * 900, 0, 0)
        if tick - p.since > gint(pc, "lose_s", 40) * TICK_HZ:
            p.state = P_WARY
            p.since = tick
            patrol_walk(p, p.goal_x, p.goal_y)
    elif p.state == P_WARY:
        if tick - p.since > gint(pc, "search_s", 25) * TICK_HZ:
            p.state = P_ROAD
            patrol_walk(p, p.road[p.next * 2], p.road[p.next * 2 + 1])
    elif p.state == P_ROAD:
        if dist2(u_x[lead], u_y[lead], p.road[p.next * 2], p.road[p.next * 2 + 1]) < 2 * TILE * 2 * TILE:
            p.next++
            if p.next * 2 < p.road.length: patrol_walk(p, p.road[p.next * 2], p.road[p.next * 2 + 1])

// After each sim tick, with the riflemen who fired in it: the patrols hear the men's shots.
def threats_after_step(fired:[int]):
    let hearing = gint(gobj(threats_cfg, "hearing"), gstr(gobj(guns_cfg, "places"), place_now(), "valley"), 30) * TILE
    for(fired) id:
        shot_seen.set(id, tick)
        let i = index_of(id)
        if i >= 0 and man_of(id):
            for(patrols) p:
                let near = find(patrol_alive(p)) pid: dist2(u_x[index_of(pid)], u_y[index_of(pid)], u_x[i], u_y[i]) <= hearing * hearing
                if near >= 0: patrol_hear(p, id, u_x[i], u_y[i])

// Every sim tick of the run (route_tick): a patrol due on its road sets out, and now and then they all think.
def threats_tick():
    if patrol_due.length and tick >= patrol_due_at:
        patrol_spawn(patrol_due, patrol_due_n)
        patrol_due = []
    if tick % 5 == 0:
        for(patrols) p: patrol_think(p)
        men_fight()

// A patrol that sets out on its road after so many seconds in the place (a leg's "patrol": "after_s").
def patrol_later(road:[int], n:int, after_s:int):
    if after_s <= 0:
        patrol_spawn(road, n)
        return
    patrol_due = road
    patrol_due_n = n
    patrol_due_at = tick + after_s * TICK_HZ

def men_told_to_fire(id:int): men_firing.set(id, 1)

// The men told to fire keep at it, each at the nearest enemy he can see, till they are told to walk somewhere: when
// the one he fired at falls or is hidden, he turns to the next. (Creel's workers never pick a target by themselves.)
def men_fight():
    let sight = gint(threats_cfg, "men_sight", 10) * TILE
    for(men_firing.get_keys()) id:
        let i = index_of(id)
        if i < 0 or (u_foe[i] == 0 and u_moving[i] == 1):
            men_firing.del(id)
            continue
        let foe = if u_foe[i] != 0: index_of(u_foe[i]) else: -1
        if foe >= 0 and (t_hp[u_kind[foe]] > 100000 or keeps_on(i, foe, sight)): continue
        var best = -1
        var best_d = 1 << 62
        for(patrols) p:
            for(patrol_alive(p)) pid:
                let j = index_of(pid)
                let d = dist2(u_x[i], u_y[i], u_x[j], u_y[j])
                if d < best_d and sees(i, j, sight):
                    best = j
                    best_d = d
        if best >= 0:
            issue_cmd(0, CMD_ATTACK, [ id ], u_id[best], 0, 0, 0)
            aim_seen.set(id, tick)
            u_cooldown[i] = max(u_cooldown[i], guns_ticks("aim_s", id, tick))

// What the danger is now, for the music: "" (none), "wary" (a threat is coming to look) or the hunting threat's kind.
def threats_danger() -> string:
    var d = ""
    for(patrols) p:
        if p.state == P_HUNT: return "ottomans"
        if p.state == P_WARY: d = "wary"
    return d
