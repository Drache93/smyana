// ------------------------------------------------------------------ game: hunting with the rifles
// docs/survival.md (game). Dominic, 2026-11-13: "Foraging and hunting needed yeh". The men leave with four days' food;
// the wood and the rifle make up the rest. Each place has its game (data/hunting.json, from the sources): roe deer and
// wild boar in the woods, chamois on the rocky slopes. They graze about their place, look up at a man they can see
// (cover hides him, as from the patrol), watch him a moment and run; every shot within hearing sends them off. A ball
// kills a deer or a chamois; a boar takes two and charges the one who hit it. The shot is a shot: the patrol hears it
// as any other (threats_after_step). Right-click a carcass with men chosen and they butcher it into their packs.
// What is shot stays shot. Sim side only.

let G_GRAZE = 0   // about its own business
let G_ALERT = 1   // head up, watching a man it has seen
let G_FLEE = 2    // off at a run
let G_CHARGE = 3  // a hit boar, at the one who shot it
let G_DEAD = 4

class Game:
    id:int
    kind:string
    herd:int
    home_x:int
    home_y:int
    reach:[int]
    state:int = G_GRAZE
    since:int = 0
    foe:int = 0

class Carcass:
    uid:int  // the beast it was (its Fallen in threats.lobster draws it)
    kind:string
    x:int
    y:int
    meat:int
    hides:int

class Butcher:
    id:int         // the man
    uid:int        // the carcass's
    work:int       // ticks at it
    since:int = 0  // the tick he was sent

var hunt_cfg = jobj()
var game_off = false  // (run_check: its men walk a set script; game has its own check)
var game = []::Game
var carcasses = []::Carcass
var butchers = []::Butcher
let game_ids = dictionary<int, int>(32)        // a beast of the game's id: its index in game
let hunt_memory = dictionary<string, int>(17)  // a place: how many of its game the men have shot there
var game_shot = 0                              // in the run (for the checks and the tally)
var meat_taken = 0

def hunting_load(): hunt_cfg = lib_data("hunting.json")

def kind_cfg(kind:string) -> JV: return gobj(gobj(hunt_cfg, "kinds"), kind)

// The units of the game that lives in this place now, for its side (route.lobster's enter_leg).
def game_units() -> [JV]:
    let out = []::JV
    if game_off: return out
    let kinds = []::string
    for(glist(gobj(hunt_cfg, "places"), place_now())) h:
        let k = gstr(h, "kind", "")
        if (find(kinds): _ == k) < 0 and game_in_season(h):
            kinds.push(k)
            out.push(shallow_copy(at(kind_cfg(k), "unit")))
    return out

def game_in_season(h:JV) -> bool:
    let ss = gstrs(h, "seasons")
    return not ss.length or (find(ss): _ == season_now()) >= 0

// The run from its start: nothing shot anywhere.
def hunt_begin():
    hunt_memory.clear()
    game_shot = 0
    meat_taken = 0

def game_of(uid:int) -> int: return game_ids.get(uid, -1)

// Its body's name for the view: the winter coat in winter.
def game_body(uid:int) -> string:
    let k = game_of(uid)
    if k < 0: return ""
    let c = kind_cfg(game[k].kind)
    return if season_now() == "winter" and has(c, "winter"): gstr(c, "winter", "") else: gstr(c, "body", game[k].kind)

def game_name(k:int) -> string: return gstr(kind_cfg(game[k].kind), "name", game[k].kind)

// A place set up: its game set down about it, away from where the men come in, fewer for what was shot here before.
def hunt_enter(place:string):
    game = []
    carcasses = []
    butchers = []
    game_ids.clear()
    let here = men_here()
    if not here.length or game_off: return
    var missing = hunt_memory.get(place, 0)
    let mx = u_x[here[0]]
    let my = u_y[here[0]]
    var n_herd = 0
    let trail = str_index(tr_names, "trail")
    let trail_cells = filter(W * H) c: terrain[c] == trail
    for(glist(gobj(hunt_cfg, "places"), place)) h, hk:
        if not game_in_season(h): continue
        let kind = gstr(h, "kind", "")
        let k = type_of_slot(1, kind)
        if k < 0: continue
        let reach = reach_from(k, cell_of(mx, my))
        for(gint(h, "herds", 1)) herd:
            let nn = glist(h, "n")
            let lo = if nn.length: as_int(nn[0]) else: 1
            let hi = if nn.length > 1: as_int(nn[1]) else: lo
            var n = lo + threat_hash(run_seed + hk, herd, leg_hash(place)) % (hi - lo + 1)
            let gone = min(n, missing)
            n -= gone
            missing -= gone
            if n <= 0: continue
            // (a spot the men can walk to, off in the wood and at least twenty tiles from where they came in: the
            // deer and the boar at the clearings the side paths lead to, the first herds, or eight to twenty tiles off
            // a path; the chamois anywhere off the trail, on their rocks; docs/off-the-path.md)
            var hx = -1
            var hy = -1
            let at_end = kind != "chamois" and n_herd < side_paths.length
            for(60) tries:
                let hh = threat_hash(run_seed + herd * 7 + hk * 31, tries, leg_hash(place) + n_herd)
                let ends = if at_end: side_paths[(n_herd + run_seed) % side_paths.length].cells else: []
                let c = if at_end: ends[ends.length - 1] elif trail_cells.length: trail_cells[hh % trail_cells.length] else: hh % (W * H)
                let a = float(hh / 7 % 360)
                let r = float((if at_end: 1 + hh / 13 % 3 else: 8 + hh / 13 % 13) * TILE)
                let x, y = reachable_near(reach, (c % W) * TILE + TILE / 2 + int(cos(a) * r), (c / W) * TILE + TILE / 2 + int(sin(a) * r))
                if hx < 0 and dist2(x, y, mx, my) > sq(20 * TILE) and x > 3 * TILE and y > 3 * TILE and x < (W - 3) * TILE and y < (H - 3) * TILE:
                    hx = x
                    hy = y
            if hx < 0: continue
            for(n) a:
                let x, y = reachable_near(reach, hx + (a % 3 - 1) * TILE * 2, hy + (a / 3 - 1) * TILE * 2)
                let i = add_unit(1, k, x, y)
                u_posture[i] = PASSIVE
                game_ids.set(u_id[i], game.length)
                game.push(Game { u_id[i], kind, n_herd, hx, hy, reach })
            print "game: {place} {kind} x{n} at {hx / TILE},{hy / TILE}"
            n_herd++
    grow_scratch()

// The men walk off: the place remembers what they shot.
def hunt_leave(place:string):
    var shot = 0
    for(game) g: if g.state == G_DEAD: shot++
    hunt_memory.set(place, hunt_memory.get(place, 0) + shot)

def game_set(g:Game, state:int):
    g.state = state
    g.since = tick

// Off at a run, away from (x, y), and the rest of its herd with it.
def herd_flee(herd:int, x:int, y:int):
    for(game) g:
        if g.herd == herd and g.state != G_DEAD and g.state != G_CHARGE: game_run(g, x, y)

def game_run(g:Game, x:int, y:int):
    let i = index_of(g.id)
    if i < 0: return
    let c = kind_cfg(g.kind)
    let dx = u_x[i] - x
    let dy = u_y[i] - y
    let d = max(1, int(sqrt(float(dx * dx + dy * dy))))
    let far = gint(c, "run_tiles", 24) * TILE
    let tx, ty = reachable_near(g.reach, clamp(u_x[i] + dx * far / d, 2 * TILE, (W - 2) * TILE), clamp(u_y[i] + dy * far / d, 2 * TILE, (H - 2) * TILE))
    game_set(g, G_FLEE)
    u_speed[i] = gint(c, "run_speed", 16)
    issue_cmd(1, CMD_MOVE, [ g.id ], tx, ty, 0, 0)

// A shot fired at (x, y): game within hearing runs from it (threats_after_step).
def game_heard_shot(x:int, y:int):
    let r = gint(hunt_cfg, "hear_tiles", 30) * TILE
    let herds = []::int
    for(game) g:
        let i = index_of(g.id)
        if i >= 0 and g.state != G_DEAD and g.state != G_CHARGE and dist2(u_x[i], u_y[i], x, y) <= r * r and (find(herds): _ == g.herd) < 0: herds.push(g.herd)
    for(herds) h: herd_flee(h, x, y)

// A ball hit one of the game (threats_on_hit): a boar that lives through it charges the one who fired.
def game_hit(j:int, by:int):
    let k = game_of(u_id[j])
    if k < 0: return
    let g = game[k]
    hurt_units.set(g.id, 1)
    if has(kind_cfg(g.kind), "charge_speed") and index_of(by) >= 0:
        game_set(g, G_CHARGE)
        g.foe = by
        u_speed[j] = gint(kind_cfg(g.kind), "charge_speed", 16)
        issue_cmd(1, CMD_ATTACK, [ g.id ], by, 0, 0, 0)

// One of the game killed (threats_on_death): it lies where it fell, its meat to butcher.
def game_died(i:int) -> bool:
    let k = game_of(u_id[i])
    if k < 0: return false
    let g = game[k]
    game_set(g, G_DEAD)
    game_shot++
    let c = kind_cfg(g.kind)
    carcasses.push(Carcass { g.id, g.kind, u_x[i], u_y[i], gint(c, "meat", 6), gint(c, "hides", 0) })
    return true

def game_think(g:Game):
    if g.state == G_DEAD: return
    let i = index_of(g.id)
    if i < 0: return
    let c = kind_cfg(g.kind)
    if g.state == G_CHARGE:
        if index_of(g.foe) >= 0 and u_foe[i] == g.foe and tick - g.since < 20 * TICK_HZ: return
        game_run(g, u_x[i] - 1, u_y[i])
        return
    if g.state == G_FLEE:
        if tick - g.since < gint(c, "settle_s", 50) * TICK_HZ: return
        // (it settles where it ran to: that is its place now)
        g.home_x = u_x[i]
        g.home_y = u_y[i]
        game_set(g, G_GRAZE)
    let sight = gint(gobj(kind_cfg(g.kind), "unit"), "sight", 12) * TILE
    let notice = gint(c, "notice_tiles", 12) * TILE
    let flee = gint(c, "flee_tiles", 7) * TILE
    var seen = -1
    var seen_d = 1 << 62
    for(men_here()) j:
        let d = dist2(u_x[i], u_y[i], u_x[j], u_y[j])
        if d <= notice * notice and d < seen_d and sees(i, j, sight):
            seen = j
            seen_d = d
    if seen >= 0 and seen_d <= flee * flee:
        herd_flee(g.herd, u_x[seen], u_y[seen])
        return
    if g.state == G_ALERT:
        // (a man who stands still while it watches: it puts its head down again in a while. One who moves: it runs)
        if tick - g.since > (if seen < 0: 2 else: 3) * gint(c, "alert_s", 4) * TICK_HZ: game_set(g, G_GRAZE)
        // (one who comes on while it watches, to within two tiles of where it would run anyway: it runs. A careful
        // man who stops at a rifle's range, and keeps still, gets his shot; a playthrough found the old line, halfway
        // in from where it saw him, inside the rifle's range, so no stalk ever came to a shot)
        elif seen >= 0 and tick - g.since > gint(c, "alert_s", 4) * TICK_HZ and u_moving[seen] == 1 and seen_d <= sq(flee + 2 * TILE): herd_flee(g.herd, u_x[seen], u_y[seen])
        return
    if seen >= 0:
        game_set(g, G_ALERT)
        issue_cmd(1, CMD_MOVE, [ g.id ], u_x[i], u_y[i], 0, 0)
        return
    // grazing: a few slow steps about its place now and then
    u_speed[i] = max(1, t_speed[u_kind[i]] / 2)
    if u_moving[i] == 0 and threat_hash(g.id, tick, 11) % 9 == 0:
        let r = gint(c, "wander_tiles", 6) * TILE
        let a = float(threat_hash(g.id, tick, 5) % 360)
        let tx, ty = reachable_near(g.reach, clamp(g.home_x + int(cos(a) * float(r)), TILE, (W - 1) * TILE), clamp(g.home_y + int(sin(a) * float(r)), TILE, (H - 1) * TILE))
        issue_cmd(1, CMD_MOVE, [ g.id ], tx, ty, 0, 0)

// Whether any man here can see unit i.
def men_see(i:int) -> bool:
    let sight = gint(threats_cfg, "men_sight", 10) * TILE
    return (find(men_here()) j: sees(j, i, sight)) >= 0

// Whether any of the game in this place is watching the men or running from them (for the view: a deer's bark).
def game_alarmed() -> bool: return (find(game) g: g.state == G_ALERT or g.state == G_FLEE) >= 0

// ---- the carcass

// The carcass near (x, y), within reach, with meat left on it, or -1.
def carcass_near(x:int, y:int) -> int:
    let r = TILE * 3 / 2
    return find(carcasses) cc: cc.meat + cc.hides > 0 and dist2(cc.x, cc.y, x, y) <= r * r

def carcass_name(k:int) -> string:
    let cc = carcasses[k]
    let name = gstr(kind_cfg(cc.kind), "name", cc.kind)
    return "{name}, shot: meat for {cc.meat} men a day"

// The chosen men sent to butcher carcass k: each walks to it and takes his share into his pack.
def butcher_order(ids:[int], k:int) -> bool:
    let cc = carcasses[k]
    var sent = false
    for(ids) id:
        let m = man_of(id)
        if m and index_of(id) >= 0:
            butchers = filter(butchers) b: b.id != id
            butchers.push(Butcher { id, cc.uid, 0, since: tick })
            issue_cmd(0, CMD_MOVE, [ id ], cc.x + (id % 3 - 1) * 400, cc.y + (id / 3 % 3 - 1) * 400, 0, 0)
            sent = true
    return sent

// Whether this man is butchering (he works: his hunger falls faster).
def butchering(uid:int) -> bool: return (find(butchers) b: b.id == uid) >= 0

// Every sim tick of ten (route_tick): game thinks; a man stood at his carcass takes his share when he is done.
def hunt_tick():
    for(game) g: game_think(g)
    let need = gint(hunt_cfg, "butcher_s", 12) * TICK_HZ
    let reach = gint(hunt_cfg, "reach_tiles", 3) * TILE
    butchers = filter(butchers) b:
        let i = index_of(b.id)
        let m = man_of(b.id)
        let ck = find(carcasses) cc: cc.uid == b.uid
        if i < 0 or not m or ck < 0: false
        else:
            let cc = carcasses[ck]
            if cc.meat + cc.hides <= 0: false
            elif u_moving[i] == 1 or dist2(u_x[i], u_y[i], cc.x, cc.y) > reach * reach:
                // (sent somewhere else: he has given it up)
                tick <= b.since + TICK_HZ or dist2(u_tx[i], u_ty[i], cc.x, cc.y) <= reach * reach
            else:
                b.work += 10
                if b.work < need: true
                else:
                    let take = min(pack_room(m), cc.meat)
                    m.food += take
                    cc.meat -= take
                    meat_taken += take
                    if cc.hides > 0 and pack_room(m) >= 1:
                        m.wares.push(WARE_HIDES)
                        cc.hides--
                    false
    // (picked clean: it is gone from the ground)
    let gone = filter(carcasses) cc: cc.meat + cc.hides <= 0
    if gone.length:
        carcasses = filter(carcasses) cc: cc.meat + cc.hides > 0
        fallen = filter(fallen) f: (find(gone) cc: cc.uid == f.uid) < 0
