// ------------------------------------------------------------------ the men, drawn
// Each look in data/men.json is a voxel body (data/voxel/bodies/man_NN.json over its .vox in art/men/vox/samples),
// baked by Creel's voxel module into sprites: standing and eight steps of the walk, from eight sides, and his shadow.
// The patrol's men (data/threats.json patrol.looks, data/voxel/bodies/patrol_NN.json) are the same rig, baked after
// the men's looks.

let MEN_STEPS = 8
let MEN_DRAW_K = 1.1 / vx_RES  // art px a baked px
let MEN_BAKE = "men 3"         // (raise the number when the bake changes: the saved sheets are made again)

// The poses past the walk (data/voxel/gear.json has the holds): the rifle brought up and fired (its kick), held aimed,
// and the reload's two, the rifle stood upright and the rod up, then down the barrel.
let POSE_FIRE = MEN_STEPS + 1
let POSE_AIM = MEN_STEPS + 2
let POSE_RAM_UP = MEN_STEPS + 3
let POSE_RAM_DOWN = MEN_STEPS + 4
let POSE_DOWN = MEN_STEPS + 5  // fallen: lying on his back where he was hit (smyana/threats.lobster)
let MEN_POSES = MEN_STEPS + 6
let men_looks = []::vx_unit_def
var men_bake_s = 0.0  // how long the bake took (0: read from bake_cache/)

def man_frame_name(look:int, pose:int, facing:int) -> string: return "man{look}.{pose}.{facing}"  // pose 0: standing, 1..8: the walk, then POSE_*
def man_shadow_name(look:int, facing:int) -> string: return "man{look}.shadow.{facing}"

// One look's sheet, baked (or read back). between(): called now and then, so the window can draw.
def bake_look(look:int, key:string, between):
    let s = sheet_new("man{look}", key, 1024)
    if sheet_load(s, MEN_DRAW_K): return
    let t0 = seconds_elapsed()
    let u = men_looks[look]
    vx_set_look(u, 0)
    vx_mat_cols[vx_mat_team] = float3 { 0.85, 0.12, 0.85 }  // (the sprite shader's key for the team colour: the sash)
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

def bake_men(between):
    vx_load([ "../data/voxel" ])
    let key = "{MEN_BAKE} {vx_RES} {sha256_text(vx_data_text() + men_vox_text())}"
    for(append(gstrs(men_data, "looks"), gstrs(gobj(lib_data("threats.json"), "patrol"), "looks"))) id, look:
        men_looks.push(vx_unit_def { id, id, float3_0, float3_0, float3_0, [], "", false, float3_0, float3_0, float3_0, nil })
        bake_look(look, key, between)

// How far a man walks in one cycle of his steps, milli-tiles.
def man_cycle() -> float: return vx_walk_cycle(men_looks[0])
