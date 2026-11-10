// ------------------------------------------------------------------ the men, drawn
// Each look in data/men.json is a voxel body (data/voxel/bodies/man_NN.json over its .vox in art/men/vox/samples),
// baked by Creel's voxel module into sprites: standing and eight steps of the walk, from eight sides, and his shadow.

let MEN_STEPS = 8
var MEN_DRAW_K = 1.1 / vx_RES  // art px a baked px
let MEN_BAKE = "men 1"         // (raise the number when the bake changes: the saved sheets are made again)
var men_looks = []::vx_unit_def
var men_bake_s = 0.0  // how long the bake took (0: read from bake_cache/)

def man_frame_name(look:int, pose:int, facing:int) -> string: return "man{look}.{pose}.{facing}"  // pose 0: standing, 1..8: the walk
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
    vx_act = ""
    for(MEN_STEPS + 1) pose:
        vx_stand = pose == 0
        let parts = vx_unit_prims(u, if pose == 0: 0.0 else: float(pose - 1) * 360.0 / float(MEN_STEPS))
        let sh = vx_fill(parts, vx_size_of(u), false)
        for(8) facing:
            let cell = vx_cell(sh, facing)
            sheet_add_cell(s, man_frame_name(look, pose, facing), cell, vx_CELL.x, vx_box, vx_ANCHOR)
            if pose == 0:
                let sc = vx_ground_shadow(sh, facing)
                sheet_add_cell(s, man_shadow_name(look, facing), sc, vx_SCELL.x, vx_sbox, vx_SANCHOR)
        between()
    vx_stand = false
    sheet_finish(s, MEN_DRAW_K, true)
    men_bake_s += seconds_elapsed() - t0

def bake_men(between):
    vx_load([ "../data/voxel" ])
    let key = "{MEN_BAKE} {vx_RES} {sha256_hex(vx_data_text())}"
    for(gstrs(men_data, "looks")) id, look:
        men_looks.push(vx_unit_def { id, id, float3_0, float3_0, float3_0, [], "", false, float3_0, float3_0, float3_0, nil })
        bake_look(look, key, between)

// How far a man walks in one cycle of his steps, milli-tiles.
def man_cycle() -> float: return vx_walk_cycle(men_looks[0])
