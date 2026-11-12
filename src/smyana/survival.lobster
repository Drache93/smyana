// ------------------------------------------------------------------ surviving: the needs, the camp and the fire
// docs/survival.md, issues #65 and #68: every night is a choice between eating and being found (D-009). Each man is
// fed, warm and rested, from 100 (fine) to 0 (spent), kept on him between places. They fall with the hours, the work,
// the load and the cold; a camp at night gives back rest, a lit fire warmth and a hot meal; a need run low slows a
// man, and run out costs him health. The fire is seen: wolves keep off it, a patrol comes to look, the bear smells
// the food. Numbers in data/survival.json. Sim side only: the game draws from it, run_check.lobster plays it headless.

let NEED_FULL = 100000  // a need is kept in thousandths of a point

class Camp:
    x:int  // its fire, sim units
    y:int
    lit:bool = false      // the fire burns
    lit_at:int = 0        // the tick the fire catches (it is being laid till then)
    empty_since:int = -1  // the tick the last man walked off from it (-1: men in it)
    meal_day:int = -1     // the evening it last fed the men

var survival_cfg = jobj()
var sv_camps = []::Camp
var needs_uh = 0     // the clock (clock_uh) when the needs were last brought up to it
var woken_until = 0  // a shot in the night: the men stay up till then
var meal_day = -1    // the evening the men last ate
var meals_hot = 0    // how many meals have been eaten, hot or cold (for the checks)
var meals_cold = 0
var needs_kept = false                 // (for the walk check: nobody gets hungry, cold or tired)
let asleep = dictionary<int, int>(32)  // a man's id: 1 while he sleeps
let sv_hp = dictionary<int, int>(32)   // a man's id: his hp at the last look (a hurt man wakes)

def survival_load(): survival_cfg = lib_data("survival.json")

def sv_cfg(k:string) -> JV: return gobj(survival_cfg, k)

// A number from the data in thousandths (a rate of 2.5 an hour is 2500).
def sv_milli(o:JV, k:string, fallback:float) -> int: return int((if has(o, k): as_float(at(o, k)) else: fallback) * 1000.0)

// What the men leave the village with (run_begin).
def survival_begin():
    for(men) m:
        m.fed = NEED_FULL
        m.warm = NEED_FULL
        m.rested = NEED_FULL
        m.food = gint(survival_cfg, "start_food", 4)
    meal_day = -1
    meals_hot = 0
    meals_cold = 0
    needs_uh = clock_uh

// A place set up (enter_leg): no camp in it yet, and nobody asleep.
def survival_enter():
    sv_camps = []
    asleep.clear()
    sv_hp.clear()
    woken_until = 0

def need_set(n:int) -> int: return clamp(n, 0, NEED_FULL)

// ---- the air: how warm a man would get standing in it (0 .. 100)
def season_air() -> int:
    let air = glist(sv_cfg("warm"), "air")
    let y = year_here() % 4000
    let s = y / 1000
    let f = y % 1000
    let a = if air.length >= 4: as_int(air[s]) else: 60
    let b = if air.length >= 4: as_int(air[(s + 1) % 4]) else: 60
    return a + (b - a) * f / 1000

def air_warmth() -> int:
    let w = sv_cfg("warm")
    let kind, hard = weather_now()
    var t = season_air() - gint(leg_now(), "altitude", 0) * gint(w, "altitude", 4) / 100
    if is_night(): t -= gint(w, "night", 22)
    t -= gint(w, "wind", 10) * wind_now() / 1000
    if kind == "rain": t -= gint(w, "rain", 18) * hard / 1000
    if kind == "snow": t -= gint(w, "snow", 12) * hard / 1000
    return t

// The lit fire this man is close enough to be warmed by, or -1.
def fire_near(i:int) -> int:
    let r = gint(sv_cfg("warm"), "fire_tiles", 4) * TILE
    return find(sv_camps) cp: cp.lit and dist2(u_x[i], u_y[i], cp.x, cp.y) <= r * r

// The camp this man is in, or -1.
def camp_of(i:int) -> int:
    let r = gint(sv_cfg("camp"), "in_tiles", 5) * TILE
    return find(sv_camps) cp: dist2(u_x[i], u_y[i], cp.x, cp.y) <= r * r

def is_asleep(uid:int) -> bool: return asleep.get(uid, 0) == 1

// The evening it is: it turns at the meal hour, so a night belongs to the evening before it.
def evening_now() -> int:
    let h = gint(route, "start_hour", 7) * 1000000 + clock_uh - gint(sv_cfg("camp"), "meal_hour", 17) * 1000000
    return if h < 0: -1 else: h / 24000000

def meal_time() -> bool:
    let h = hour_now()
    return h >= float(gint(sv_cfg("camp"), "meal_hour", 17)) or is_night()

// ---- reading a man: how much his needs take off his pace (hundredths kept), and what he looks like
def needs_pace(m:Man) -> int:
    let p = sv_cfg("pace")
    let low = gint(p, "low", 30) * 1000
    let most = gint(p, "most", 12)
    var kept = 100
    for([ m.fed, m.warm, m.rested ]) n: if n < low: kept -= most * (low - n) / low
    return kept

// A few plain words on how a man is (the one panel: docs/survival.md), "" when he is well.
def man_state(m:Man) -> string:
    let words = []::string
    if m.wounded: words.push("wounded")
    if m.warm < 15000: words.push("freezing") elif m.warm < 40000: words.push("cold")
    if m.fed < 15000: words.push("starving") elif m.fed < 40000: words.push("hungry")
    if m.rested < 15000: words.push("worn out") elif m.rested < 40000: words.push("tired")
    if is_asleep(m.uid): words.push("asleep")
    if not words.length: return "well"
    var s = words[0]
    for(words) w, k:
        if k > 0: s += if k == words.length - 1: " and " + w else: ", " + w
    return s

// ---- the orders
// Make camp where the chosen men stand (C), or, if they are in a camp already, put its fire out, or light it again.
// The fire costs wood off their backs; with none carried it takes longer, while they find dead wood. Whether a new
// camp was made.
def camp_order(ids:[int]) -> bool:
    let here = filter(ids) id: index_of(id) >= 0
    if not here.length: return false
    let c = sv_cfg("camp")
    // (in a camp already: its fire out, or lit again)
    for(here) id:
        let k = camp_of(index_of(id))
        if k >= 0:
            let cp = sv_camps[k]
            if cp.lit or tick < cp.lit_at:
                cp.lit = false
                cp.lit_at = 0
            else: camp_light(cp, here)
            return false
    var cx = 0
    var cy = 0
    for(here) id:
        let i = index_of(id)
        cx += u_x[i] / here.length
        cy += u_y[i] / here.length
    // (on the most open ground near them, where the men can lie round it)
    let best = open_spot(cell_of(cx, cy))
    cx = (best % W) * TILE + TILE / 2
    cy = (best / W) * TILE + TILE / 2
    sv_camps = filter(sv_camps) cp: cp.lit
    let cp = Camp { cx, cy }
    sv_camps.push(cp)
    camp_light(cp, here)
    // each man to his place in a ring round the fire
    let ring_d = int(as_float(at(c, "ring_tiles")) * float(TILE))
    for(here) id, n:
        // (round its far side and its flanks: nobody stands between the fire and the camera)
        let a = 100.0 + float(n) * 250.0 / float(max(1, here.length - 1))
        let r = ring_d + (n % 2) * TILE * 2 / 3
        var tx = clamp(cx + int(cos(a) * float(r)), TILE, (W - 1) * TILE)
        var ty = clamp(cy + int(sin(a) * float(r)), TILE, (H - 1) * TILE)
        // (a tree where he would lie: the nearest open ground to it)
        let tc = cell_of(tx, ty)
        if walks[0][tc] != 1:
            let oc = camp_ground_near(tc, cell_of(cx, cy))
            tx = (oc % W) * TILE + 200 + (n * 137) % 600
            ty = (oc / W) * TILE + 200 + (n * 251) % 600
        issue_cmd(0, CMD_MOVE, [ id ], tx, ty, 0, 0)
    return true

// The fire laid and lit: two bundles of wood off the men's backs, quick; with none, slow.
def camp_light(cp:Camp, ids:[int]):
    let c = sv_cfg("camp")
    let wood = str_index(resource_names, "wood") + 1
    var need = gint(c, "wood", 2)
    for(ids) id:
        let i = index_of(id)
        if i >= 0 and u_carry_kind[i] == wood and need > 0:
            let n = min(need, u_carry[i])
            u_carry[i] -= n
            need -= n
    cp.lit = true
    cp.lit_at = tick + gint(c, if need > 0: "lay_bare_s" else: "lay_s", 4) * TICK_HZ

// The most open cell within four tiles of c (the most open ground within two tiles round it), the nearest of those.
def open_spot(c:int) -> int:
    var best = c
    var best_score = -1
    for(9) j: for(9) i:
        let x = c % W + i - 4
        let y = c / W + j - 4
        if x >= 2 and y >= 2 and x < W - 2 and y < H - 2 and walks[0][y * W + x] == 1:
            var open = 0
            for(5) v: for(5) u: if walks[0][(y + v - 2) * W + x + u - 2] == 1: open++
            let score = open * 16 - abs(i - 4) - abs(j - 4)
            if score > best_score:
                best_score = score
                best = y * W + x
    return best

// The nearest open cell to c, not `but` (the fire's).
def camp_ground_near(c:int, but:int) -> int:
    for(6) r:
        for(r * 2 + 1) j: for(r * 2 + 1) i:
            let x = c % W + i - r
            let y = c / W + j - r
            if x >= 0 and y >= 0 and x < W and y < H and walks[0][y * W + x] == 1 and y * W + x != but: return y * W + x
    return c

def fire_burning(cp:Camp) -> bool: return cp.lit and tick >= cp.lit_at

// The lit fires, burning (for the view and the threats).
def fires_lit() -> [Camp]: return filter(sv_camps) cp: fire_burning(cp)

// A shot in the night: the men wake and stay up a while.
def survival_heard_shot(): woken_until = tick + gint(sv_cfg("camp"), "woken_s", 40) * TICK_HZ

// ---- every 10 sim ticks (route_tick): the needs brought up to the clock, sleep, the meal, the camp struck
def survival_tick():
    let duh = clock_uh - needs_uh
    needs_uh = clock_uh
    if duh <= 0: return
    if needs_kept:
        for(men) m:
            m.fed = NEED_FULL
            m.warm = NEED_FULL
            m.rested = NEED_FULL
        return
    let fd = sv_cfg("fed")
    let wm = sv_cfg("warm")
    let rs = sv_cfg("rested")
    let cc = sv_cfg("camp")
    let air = air_warmth()
    let night = is_night()
    let ford = str_index(tr_names, "ford")
    // (who is in a camp, and its meal)
    for(sv_camps) cp: cp.empty_since = if cp.empty_since < 0: tick else: cp.empty_since
    let ev = evening_now()
    let eating = meal_time() and ev > meal_day
    var ate = false
    for(men) m:
        if not m.alive: continue
        let i = index_of(m.uid)
        if i < 0: continue
        let k = camp_of(i)
        if k >= 0: sv_camps[k].empty_since = -1
        // (asleep: in a camp, at night, standing still, nobody shooting, and not just hurt)
        let was_hp = sv_hp.get(m.uid, u_hp[i])
        sv_hp.set(m.uid, u_hp[i])
        let sleeps = k >= 0 and night and u_moving[i] == 0 and u_task[i] != GATHER and u_task[i] != BUILD and tick >= woken_until and u_hp[i] >= was_hp and u_foe[i] == 0
        asleep.set(m.uid, if sleeps: 1 else: 0)
        // the meal: at the first camp of the evening, one portion each, hot at a lit fire
        if eating and k >= 0 and sv_camps[k].lit_at <= tick:
            ate = true
            let hot = fire_burning(sv_camps[k])
            if take_portion(m):
                m.fed = if hot: NEED_FULL else: need_set(m.fed + gint(fd, "cold_meal", 50) * 1000)
                if hot: meals_hot++ else: meals_cold++
        let working = u_task[i] == GATHER or u_task[i] == BUILD
        let loaded = u_carry[i] > 0
        // hunger
        var hunger = sv_milli(fd, if sleeps: "asleep" else: "per_hour", 2.5)
        if working: hunger = hunger * gint(fd, "work", 150) / 100
        elif loaded and not sleeps: hunger = hunger * gint(fd, "loaded", 125) / 100
        m.fed = need_set(m.fed - hunger * duh / 1000000)
        // warmth: toward the air's, faster up by a fire
        var to = air
        let fire = fire_near(i)
        if fire >= 0: to += gint(wm, "fire", 70)
        if sleeps and k >= 0: to += gint(wm, "huddle", 12)
        if terrain[cell_of(u_x[i], u_y[i])] == ford: to -= gint(wm, "wading", 40) * ford_cold() / 100
        let target = clamp(to, 0, 100) * 1000
        let rate = if m.warm > target: gint(wm, "fall", 18) elif fire >= 0: gint(wm, "fire_rise", 80) else: gint(wm, "rise", 30)
        let step = rate * 1000 * duh / 1000000
        m.warm = if m.warm > target: max(target, m.warm - step) else: min(target, m.warm + step)
        // rest
        if sleeps: m.rested = need_set(m.rested + sv_milli(rs, "asleep", 13.0) * duh / 1000000)
        else: m.rested = need_set(m.rested - sv_milli(rs, "per_hour", 4.5) * (if loaded and u_moving[i] == 1: gint(rs, "loaded", 130) else: 100) / 100 * duh / 1000000)
        // health: lost to cold and hunger, a little back asleep fed and warm
        m.hurt_uh += duh * ((if m.warm == 0: sv_milli(wm, "freezing_hp", 3.0) else: 0) + (if m.fed == 0: sv_milli(fd, "starving_hp", 1.5) else: 0)) / 1000
        if sleeps and m.fed > 50000 and m.warm > 50000: m.heal_uh += duh * sv_milli(rs, "heal_hp", 1.0) / 1000
        while m.hurt_uh >= 1000000:
            m.hurt_uh -= 1000000
            u_hp[i] -= 1
            sv_hp.set(m.uid, u_hp[i])
        while m.heal_uh >= 1000000:
            m.heal_uh -= 1000000
            if u_hp[i] < t_hp[u_kind[i]]: u_hp[i]++
            sv_hp.set(m.uid, u_hp[i])
        if u_hp[i] <= 0:
            // (dead of the cold or of hunger: he lies where he was)
            hook_on_death(i, 0)
            remove_unit(i)
            m.alive = false
    if ate: meal_day = ev
    // (a camp nobody has been in for a while is struck, its fire left to die)
    sv_camps = filter(sv_camps) cp: cp.empty_since < 0 or tick - cp.empty_since < gint(cc, "struck_s", 30) * TICK_HZ

// A portion for this man: his own, or from whoever carries the most.
def take_portion(m:Man) -> bool:
    if m.food > 0:
        m.food--
        return true
    var best = -1
    for(men) o, k: if o.alive and o.food > 0 and (best < 0 or o.food > men[best].food): best = k
    if best < 0: return false
    men[best].food--
    return true

// The walk between two places (route_arrive): the hours pass on the men awake and walking, no meal and no fire.
def survival_walk(hours:int):
    let fd = sv_cfg("fed")
    let wm = sv_cfg("warm")
    let rs = sv_cfg("rested")
    let target = clamp(air_warmth() + 8, 0, 100) * 1000  // (walking keeps a man a little warmer)
    for(men) m:
        if m.alive:
            m.fed = need_set(m.fed - sv_milli(fd, "per_hour", 2.5) * hours)
            m.rested = need_set(m.rested - sv_milli(rs, "per_hour", 4.5) * hours)
            if m.warm > target: m.warm = max(target, m.warm - gint(wm, "fall", 18) * 1000 * hours)
            else: m.warm = min(target, m.warm + gint(wm, "rise", 30) * 1000 * hours)
            if m.fed == 0: m.hp = max(1, m.hp - hours * sv_milli(fd, "starving_hp", 1.5) / 1000)
    needs_uh = clock_uh

// ---- the fire draws the threats
// Whether a lit fire is seen from (x, y): at night across `night_tiles` through any cover, by day its smoke closer.
def fire_seen_from(x:int, y:int) -> int:
    let fs = sv_cfg("fire_seen")
    let r = gint(fs, if is_night(): "night_tiles" else: "day_tiles", 18) * TILE * sight_pct() / 100
    return find(fires_lit()) cp: dist2(x, y, cp.x, cp.y) <= r * r

// How far wolves keep off any lit fire, sim units (0: no fire).
def fire_keeps_off(x:int, y:int) -> bool:
    let r = gint(sv_cfg("fire_seen"), "wolves_keep_tiles", 7) * TILE
    return (find(fires_lit()) cp: dist2(x, y, cp.x, cp.y) <= r * r) >= 0

def fire_keep_tiles() -> int: return gint(sv_cfg("fire_seen"), "wolves_keep_tiles", 7)

def camp_xy(k:int) -> int, int: return sv_camps[k].x, sv_camps[k].y

// A camp with food in it within the bear's smell of (x, y): its index, or -1.
def camp_smelled(x:int, y:int) -> int:
    var food = 0
    for(men) m: if m.alive: food += m.food
    if food == 0: return -1
    let r = gint(sv_cfg("fire_seen"), "bear_smell_tiles", 16) * TILE
    return find(sv_camps) cp: dist2(x, y, cp.x, cp.y) <= r * r
