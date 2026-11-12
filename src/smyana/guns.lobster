// ------------------------------------------------------------------ the rifles, sim side (#58)
// Creel's combat fires the shot and hurts what it hits. What's Smyana's: a man takes his own time to aim when he is told
// to fire, and his own time over every reload, so twenty rifles go off in ones and twos and never as one volley
// (data/guns.json). It changes only the men's cooldowns, from the sim's own numbers, so a run plays the same every time.
// The mark: a board on a post to fire at (the range, for judging the sound and the smoke on their own).
// Sim side only (no window): the game's view of a shot is smyana/gunfire.lobster.

var guns_cfg = jobj()

def guns_load(): guns_cfg = lib_data("guns.json")

// A spread of ticks between two numbers of seconds in guns.json, picked by a hash of a and b.
def guns_ticks(key:string, a:int, b:int) -> int:
    let r = glist(guns_cfg, key)
    let lo = int(as_float(r[0]) * float(TICK_HZ))
    let hi = int(as_float(r[1]) * float(TICK_HZ))
    let h = (((a * 2654435761) ^ (b * 40503 + 977)) >> 7) & 0xFFFF
    return lo + h * (hi - lo + 1) / 0x10000

// The men told to fire at a target (a unit's id): each brings his rifle up in his own time.
def guns_order(ids:[int], target:int):
    issue_cmd(0, CMD_ATTACK, ids, target, 0, 0, 0)
    for(ids) id:
        let i = index_of(id)
        if i >= 0: u_cooldown[i] = max(u_cooldown[i], guns_ticks("aim_s", id, tick))

// After each sim tick: who fired (their ids). Each of them takes a little longer or shorter over this reload.
def guns_after_step() -> [int]:
    let fired = []::int
    for(events) e:
        if e.kind == EV_SHOT and man_of(e.a):
            let i = index_of(e.a)
            if i >= 0:
                u_cooldown[i] += guns_ticks("reload_jitter_s", e.a, tick)
                fired.push(e.a)
    return fired

// The mark, put up at (x, y) in milli-tiles: its id. Only when the place was set up with_mark.
def guns_mark(x:int, y:int) -> int:
    let k = type_of_slot(1, "mark")
    if k < 0: return 0
    let i = add_unit(1, k, x, y)
    grow_scratch()
    return u_id[i]
