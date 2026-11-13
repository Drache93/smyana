// ------------------------------------------------------------------ the men, drawn
// Each look in data/men.json is a voxel body (data/voxel/bodies/man_NN.json over its .vox in art/men/vox/samples),
// baked by Creel's voxel module into sprites: standing and eight steps of the walk, from eight sides, and his shadow.
// The patrol's men (data/threats.json patrol.looks, data/voxel/bodies/patrol_NN.json) are the same rig, baked after
// the men's looks.

let MEN_STEPS = 8
// Baked a .vox voxel to a pixel. The men are drawn from .vox art (art/men/vox), a voxel half a body unit (Creel's
// vx_VOX_RES) on a man 0.73 of a body (his size in data/voxel/bodies): at Creel's own 2 voxels a body unit, each art
// voxel was squeezed into 0.73 of a baked one, so one in four was lost and the cloaks broke up into flecks of the coat
// under them (Dominic, 2026-11-13: "a bit spotty ... reads as a bit low-res, a bit fuzzy").
// Now a little over a voxel a pixel (exactly one put rows on the half pixel, and the coats showed holes), the shading
// smoothed, and drawn smaller to the same size.
let MEN_SIZE = 0.73
let MEN_RES = vx_VOX_RES / MEN_SIZE * 1.15
let MEN_DRAW_K = 1.1 / MEN_RES  // art px a baked px
let BEAST_DRAW_K = 1.1 / vx_RES
let MEN_BAKE = "men 4"  // (raise the number when the bake changes: the saved sheets are made again)

// The poses past the walk (data/voxel/gear.json has the holds): the rifle brought up and fired (its kick), held aimed,
// and the reload's two, the rifle stood upright and the rod up, then down the barrel.
let POSE_FIRE = MEN_STEPS + 1
let POSE_AIM = MEN_STEPS + 2
let POSE_RAM_UP = MEN_STEPS + 3
let POSE_RAM_DOWN = MEN_STEPS + 4
let POSE_DOWN = MEN_STEPS + 5  // fallen: lying on his back where he was hit (smyana/threats.lobster)
let MEN_POSES = MEN_STEPS + 6
let men_looks = []::vx_unit_def
var men_bake_s = 0.0  // how long the bake took (0: read from baked/)

def man_frame_name(look:int, pose:int, facing:int) -> string: return "man{look}.{pose}.{facing}"  // pose 0: standing, 1..8: the walk, then POSE_*
def man_shadow_name(look:int, facing:int) -> string: return "man{look}.shadow.{facing}"

// The men's bake (and the riders'): at MEN_RES, their shading evened out (Creel's own flecked the coats); off, Creel's
// own again.
def men_bake_look(on:bool):
    vx_set_res(if on: MEN_RES else: 2.0)
    vx_smooth_normals = if on: 2 else: 0
    vx_despeckle = if on: 1 else: 0

// One look's sheet, baked (or read back). between(): called now and then, so the window can draw.
def bake_look(look:int, key:string, between):
    let s = sheet_new("man{look}", key, 1024)
    if sheet_load(s, MEN_DRAW_K): return
    vx_need()
    let t0 = seconds_elapsed()
    let u = men_looks[look]
    vx_set_look(u, 0)
    vx_mat_cols[vx_mat_team] = float3 { 0.85, 0.12, 0.85 }  // (the sprite shader's key for the team colour: the sash)
    men_bake_look(true)
    vx_pat_scale = vx_RES * vx_size_of(u)
    for(MEN_POSES) pose:
        vx_stand = pose == 0 or pose > MEN_STEPS
        vx_act = if pose == POSE_FIRE or pose == POSE_AIM: "attack" else: ""
        u.gear = if pose == POSE_RAM_UP: [ "rifle_up", "ram_high" ] elif pose == POSE_RAM_DOWN: [ "rifle_up", "ram_low" ] else: [ "rifle" ]
        let ph = if pose == POSE_FIRE: 0.0 elif pose == POSE_AIM: 0.6 * 360.0 elif pose == 0 or pose > MEN_STEPS: 0.0 else: float(pose - 1) * 360.0 / float(MEN_STEPS)
        let parts = if pose == POSE_DOWN: map(vx_unit_prims(u, 0.0)) q: vx_lying(q) else: vx_unit_prims(u, ph)
        let sh = vx_fill(parts, vx_size_of(u), false)
        for(8) facing:
            let cell = vx_cell(sh, facing)
            sheet_add_cell(s, man_frame_name(look, pose, facing), cell, vx_CELL.x, vx_box, vx_ANCHOR)
            if pose == 0:
                let sc = vx_ground_shadow(sh, facing)
                sheet_add_cell(s, man_shadow_name(look, facing), sc, vx_SCELL.x, vx_sbox, vx_SANCHOR)
        between()
    vx_stand = false
    vx_act = ""
    men_bake_look(false)
    sheet_finish(s, MEN_DRAW_K, true)
    men_bake_s += seconds_elapsed() - t0

// A part of him laid down on his back: turned a quarter about the across axis, his feet where he stood and his head
// back along it (the bake puts the ground under his lowest part).
def vx_lying(q:vx_prim) -> vx_prim:
    def turn(v:float3) -> float3: return float3 { v.x, -v.z, v.y }
    def at(v:float3) -> float3: return float3 { v.x, 18.0 - v.z, v.y }
    return vx_prim { at(q.a), at(q.b), q.ra, q.rb, q.mat, q.hard, q.disc, q.box, model: q.model, mx: turn(q.mx), mz: turn(q.mz) }

// The men's .vox files, as text: part of the bake's key, so a changed man is baked again.
def men_vox_text() -> string:
    var t = ""
    for([ "../art/men/vox/samples", "../art/men/vox/patrol" ]) dir:
        let names = scan_folder(dir, false)
        if names: for(sorted_strs(names)) n: t += n + (read_file(dir + "/" + n) or "")
    return t

// The voxel bodies are read only when something has to be baked: reading the twenty men's models took two seconds
// of every start (2026-11-12, Dominic: "we shouldnt be baking at load"). The bake keys need only the data's text.
def vx_need(): vx_load([ "../data/voxel" ])

// A body's walk cycle, kept beside the sheets under the same key, so a start with every sheet baked needs no bodies.
let cycles = dictionary<string, float>(8)
def cycle_of(name:string, key:string, u:vx_unit_def) -> float:
    let file = "{BAKE_DIR}/cycle_{name}.txt"
    let t = tokenize(read_file(file) or "", "\n", "")
    if t.length == 2 and t[0] == key: return string_to_float(t[1])
    vx_need()
    let c = vx_walk_cycle(u)
    write_file(file, "{key}\n{c}\n")
    return c

def bake_men(between):
    vx_data_dirs = [ "../data/voxel" ]
    let key = "{MEN_BAKE} {MEN_RES} {sha256_text(vx_data_text() + men_vox_text())}"
    for(append(gstrs(men_data, "looks"), gstrs(gobj(lib_data("threats.json"), "patrol"), "looks"))) id, look:
        men_looks.push(vx_unit_def { id, id, float3_0, float3_0, float3_0, [], "", false, float3_0, float3_0, float3_0, nil })
        bake_look(look, key, between)
    cycles.set("man", cycle_of("man", key, men_looks[0]))

// How far a man walks in one cycle of his steps, milli-tiles.
def man_cycle() -> float: return cycles.get("man", 1000.0)

// ---- the beasts (docs/threats.md): the wolf and the bear, each body data/voxel/bodies/<id>.json. Baked as the men
// are: standing and eight steps of its walk, fallen on its side, and reared up on its hind legs, from eight sides, and
// its shadow.
let BEAST_DOWN = MEN_STEPS + 1
let BEAST_UP = MEN_STEPS + 2
let BEAST_POSES = MEN_STEPS + 3
let BEAST_BAKE = "beasts 2"

def beast_frame_name(id:string, pose:int, facing:int) -> string: return "{id}.{pose}.{facing}"
def beast_shadow_name(id:string, facing:int) -> string: return "{id}.shadow.{facing}"

// A beast's part laid on its right side (turned a quarter about its length).
def vx_on_side(q:vx_prim) -> vx_prim:
    def turn(v:float3) -> float3: return float3 { v.z, v.y, -v.x }
    def at(v:float3) -> float3: return float3 { v.z - 12.0, v.y, -v.x }
    return vx_prim { at(q.a), at(q.b), q.ra, q.rb, q.mat, q.hard, q.disc, q.box, model: q.model, mx: turn(q.mx), mz: turn(q.mz) }

// A beast's part reared up: what is ahead of its hips turned up about them, `deg` degrees (data/threats.json "rear":
// the hips' [ y, z ], the angle, and the shoulders' [ y, z ], body units). Its hind legs and tail stay on the ground,
// and its forelegs hang straight down from where the shoulders went.
def vx_reared(q:vx_prim, r:[float]) -> vx_prim:
    let mid = (q.a + q.b) * 0.5
    if mid.y < r[0] + 2.0: return q
    let c = cos(r[2])
    let s = sin(r[2])
    def up(v:float3) -> float3: return float3 { v.x, r[0] + (v.y - r[0]) * c - (v.z - r[1]) * s, r[1] + (v.y - r[0]) * s + (v.z - r[1]) * c }
    if max(q.a.z, q.b.z) < r[4] + 1.0 and abs(mid.y - r[3]) < 5.0:
        let shoulder = float3 { 0.0, r[3], r[4] }
        let by = up(shoulder) - shoulder
        return vx_prim { q.a + by, q.b + by, q.ra, q.rb, q.mat, q.hard, q.disc, q.box, model: q.model, mx: q.mx, mz: q.mz }
    def turn(v:float3) -> float3: return float3 { v.x, v.y * c - v.z * s, v.y * s + v.z * c }
    return vx_prim { up(q.a), up(q.b), q.ra, q.rb, q.mat, q.hard, q.disc, q.box, model: q.model, mx: turn(q.mx), mz: turn(q.mz) }

let beast_defs = dictionary<string, vx_unit_def>(4)

def bake_beast(id:string, between):
    vx_data_dirs = [ "../data/voxel" ]
    let rj = glist(gobj(lib_data("threats.json"), "rear"), id)
    let rear = if rj.length == 5: map(rj) v: as_float(v) else: [ 0.0, 15.0, 60.0, 6.0, 13.0 ]
    let key = "{BEAST_BAKE} {vx_RES} {rear} {sha256_text(vx_data_text() + (read_file("../data/voxel/bodies/{id}.json") or ""))}"
    let u = vx_unit_def { id, id, float3_0, float3_0, float3_0, [], "", false, float3_0, float3_0, float3_0, nil }
    beast_defs.set(id, u)
    cycles.set(id, cycle_of(id, key, u))
    let s = sheet_new(id, key, 1024)
    if sheet_load(s, BEAST_DRAW_K): return
    vx_need()
    vx_set_look(u, 0)
    vx_pat_scale = vx_RES * vx_size_of(u)
    for(BEAST_POSES) pose:
        vx_stand = pose == 0 or pose >= BEAST_DOWN
        let ph = if pose == 0 or pose >= BEAST_DOWN: 0.0 else: float(pose - 1) * 360.0 / float(MEN_STEPS)
        var parts = vx_unit_prims(u, ph)
        if pose == BEAST_DOWN: parts = map(parts) q: vx_on_side(q)
        if pose == BEAST_UP: parts = map(parts) q: vx_reared(q, rear)
        let sh = vx_fill(parts, vx_size_of(u), false)
        for(8) facing:
            sheet_add_cell(s, beast_frame_name(id, pose, facing), vx_cell(sh, facing), vx_CELL.x, vx_box, vx_ANCHOR)
            if pose == 0: sheet_add_cell(s, beast_shadow_name(id, facing), vx_ground_shadow(sh, facing), vx_SCELL.x, vx_sbox, vx_SANCHOR)
        between()
    vx_stand = false
    sheet_finish(s, BEAST_DRAW_K, true)

// How far a beast walks in one cycle of its steps, milli-tiles.
def beast_cycle(id:string) -> float: return cycles.get(id, man_cycle())

// ---- the patrol's riders (docs/threats.md, riders): each patrolman's look on a horse (data/voxel/bodies/horse.json,
// Creel's mount: he sits astride, his legs down its sides), its coat by his look. Baked as the men are: standing and
// eight steps of the horse's walk, from eight sides, and the shadow. The horse alone is a beast (bake_beast).
let RIDER_BAKE = "riders 3"
let RIDER_COATS = [ float3 { 0.45, 0.29, 0.18 }, float3 { 0.74, 0.72, 0.68 }, float3 { 0.55, 0.30, 0.15 }, float3 { 0.22, 0.16, 0.12 } ]
let rider_defs = []::vx_unit_def

def rider_frame_name(look:int, pose:int, facing:int) -> string: return "rider{look}.{pose}.{facing}"
def rider_shadow_name(look:int, facing:int) -> string: return "rider{look}.shadow.{facing}"

def bake_riders(between):
    vx_data_dirs = [ "../data/voxel" ]
    let ids = gstrs(gobj(lib_data("threats.json"), "patrol"), "looks")
    let key = "{RIDER_BAKE} {MEN_RES} {RIDER_COATS} {sha256_text(vx_data_text() + men_vox_text())}"
    for(ids) id, look:
        let c = RIDER_COATS[look % RIDER_COATS.length]
        rider_defs.push(vx_unit_def { id, id, float3_0, float3_0, float3_0, [ "rifle" ], "horse", false, c, float3 { 0.16, 0.12, 0.1 }, c * 1.3, nil })
    let s = sheet_new("riders", key, 1024)
    if sheet_load(s, MEN_DRAW_K): return
    vx_need()
    men_bake_look(true)
    for(rider_defs) u, look:
        vx_set_look(u, 0)
        vx_mat_cols[vx_mat_team] = float3 { 0.85, 0.12, 0.85 }
        vx_pat_scale = vx_RES * vx_size_of(u)
        for(MEN_STEPS + 1) pose:
            vx_stand = pose == 0
            let ph = if pose == 0: 0.0 else: float(pose - 1) * 360.0 / float(MEN_STEPS)
            let sh = vx_fill(vx_unit_prims(u, ph), vx_size_of(u), false)
            for(8) facing:
                sheet_add_cell(s, rider_frame_name(look, pose, facing), vx_cell(sh, facing), vx_CELL.x, vx_box, vx_ANCHOR)
                if pose == 0: sheet_add_cell(s, rider_shadow_name(look, facing), vx_ground_shadow(sh, facing), vx_SCELL.x, vx_sbox, vx_SANCHOR)
            between()
    vx_stand = false
    men_bake_look(false)
    sheet_finish(s, MEN_DRAW_K, true)
