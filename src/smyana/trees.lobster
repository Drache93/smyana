// ------------------------------------------------------------------ the trees, grey-boxed
// Stand-ins built voxel by voxel with Creel's prop baker (view/voxel_grid.lobster), so the size of the forest can be
// felt before the real trees are drawn (issue #5): an old giant is a trunk you walk beside, with its crown high over
// you, and a young tree is the size Age of Anything's were. A giant is three pictures: its trunk, its shadow on the
// ground, and its crown, which fades when a man is under it so he can be seen. The crowns are baked once a season
// (their colour), behind the letter home, and kept in bake_cache/.
// Baked coarse (TREE_K voxels a tile) and drawn larger: a giant at the men's fineness would take minutes to bake.

let TREE_K = 44.0  // voxels a tile
let TREE_BAKE = "trees 4"
let OLD_KINDS = 3
let YOUNG_KINDS = 2
let CROWN_UP = 4.3      // tiles: about where a giant's crown is centred, over its foot
let CROWN_REACH = 2.3   // tiles: about how far it spreads
var tree_draw_k = 1.0   // art px a baked px (set at the bake: Creel's art scale decides)
var trees_bake_s = 0.0  // how long the last bake took (0: read from bake_cache/)
var trees_season = ""   // the season whose crowns are loaded

def tree_look(season:string) -> vglook:
    var leaf = [ float3 { 0.50, 0.65, 0.23 }, float3 { 0.31, 0.49, 0.17 }, float3 { 0.17, 0.32, 0.13 }, float3 { 0.60, 0.60, 0.23 } ]
    if season == "autumn": leaf = [ float3 { 0.88, 0.63, 0.19 }, float3 { 0.77, 0.44, 0.12 }, float3 { 0.48, 0.24, 0.09 }, float3 { 0.54, 0.35, 0.13 } ]
    if season == "spring": leaf = [ float3 { 0.66, 0.81, 0.33 }, float3 { 0.50, 0.69, 0.25 }, float3 { 0.29, 0.48, 0.17 }, float3 { 0.78, 0.82, 0.44 } ]
    // a beech's smooth grey bark, dark to light
    return vglook { leaf, [ float3 { 0.27, 0.27, 0.25 }, float3 { 0.37, 0.37, 0.34 }, float3 { 0.47, 0.46, 0.42 }, float3 { 0.58, 0.57, 0.52 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, true, true }

// A giant's frame: where its trunk tops out, and where each bough ends (tiles from its foot).
def old_frame(kind:int) -> float3, [float3]:
    let rng = grng(500 + kind)
    let top = float3 { randf_range(rng, -0.2, 0.2), randf_range(rng, -0.2, 0.2), randf_range(rng, 2.7, 3.2) }
    let ends = map(4 + kind % 2) n:
        let a = float(n) * 360.0 / float(4 + kind % 2) + randf_range(rng, -25.0, 25.0)
        let out = randf_range(rng, 1.1, 1.6)
        top + float3 { cos(a) * out, sin(a) * out, randf_range(rng, 0.7, 1.3) }
    return top, ends

def old_trunk(look:vglook, kind:int) -> vgrid:
    let top, ends = old_frame(kind)
    let g = vg_new(look, float3 { -2.2, -2.2, 0.0 }, float3 { 2.2, 2.2, 5.0 }, TREE_K, 500 + kind)
    vg_capsule(g, float3_0, top, 0.34, 0.22, VG_BARK)
    vg_cylinder(g, float3_0, float3 { 0.0, 0.0, 0.4 }, 0.5, 0.33, VG_BARK)  // the foot's flare
    for(ends) e: vg_capsule(g, top * 0.86, e, 0.15, 0.06, VG_BARK)
    vg_capsule(g, top, top + float3 { 0.0, 0.0, 1.2 }, 0.2, 0.07, VG_BARK)
    return g

def old_crown(look:vglook, kind:int) -> vgrid:
    let top, ends = old_frame(kind)
    let rng = grng(700 + kind)
    let g = vg_new(look, float3 { -4.4, -4.4, 2.0 }, float3 { 4.4, 4.4, 7.4 }, TREE_K, 700 + kind)
    let rough = vg_field(g, 0.45, 701 + kind)
    let gaps = vg_field(g, 0.7, 702 + kind)
    for(ends) e:
        // each bough's leaves: a big clump and two smaller beside it, so the crown is lumpy against the sky
        vg_blob(g, e + float3 { 0.0, 0.0, 0.3 }, randf_range(rng, 0.95, 1.2), 1.45, 0.6, rough, VG_LEAF, randf_range(rng, -0.5, 0.5), 0.1, gaps, 0.66)
        for(2):
            let off = float3 { randf_range(rng, -0.8, 0.8), randf_range(rng, -0.8, 0.8), randf_range(rng, 0.1, 0.8) }
            vg_blob(g, e + off, randf_range(rng, 0.55, 0.8), 1.3, 0.6, rough, VG_LEAF, randf_range(rng, -0.6, 0.6), 0.1, gaps, 0.66)
    vg_blob(g, top + float3 { 0.0, 0.0, 1.5 }, 1.3, 1.35, 0.6, rough, VG_LEAF, 0.3, 0.1, gaps, 0.66)
    return g

// A young tree, whole: thin, a couple of men tall. bare: no leaves (winter).
def young_tree(look:vglook, kind:int, bare:bool) -> vgrid:
    let rng = grng(900 + kind)
    let g = vg_new(look, float3 { -0.8, -0.8, 0.0 }, float3 { 0.8, 0.8, 2.3 }, TREE_K, 900 + kind)
    let top = float3 { randf_range(rng, -0.08, 0.08), randf_range(rng, -0.08, 0.08), randf_range(rng, 1.1, 1.4) }
    vg_capsule(g, float3_0, top, 0.09, 0.05, VG_BARK)
    for(3) n:
        let a = float(n) * 120.0 + randf_range(rng, 0.0, 60.0)
        vg_capsule(g, top * 0.7, top + float3 { cos(a) * 0.35, sin(a) * 0.35, 0.25 }, 0.04, 0.03, VG_BARK)
    if not bare:
        let rough = vg_field(g, 0.3, 901 + kind)
        vg_blob(g, top + float3 { 0.0, 0.0, 0.3 }, randf_range(rng, 0.5, 0.62), 1.1, 0.5, rough, VG_LEAF, randf_range(rng, -0.3, 0.3), 0.12, nil, 0.0)
    return g

def tree_stump(look:vglook) -> vgrid:
    let g = vg_new(look, float3 { -0.3, -0.3, 0.0 }, float3 { 0.3, 0.3, 0.3 }, TREE_K, 990)
    vg_cylinder(g, float3_0, float3 { 0.0, 0.0, 0.16 }, 0.12, 0.1, VG_BARK)
    vg_cylinder(g, float3 { 0.0, 0.0, 0.16 }, float3 { 0.0, 0.0, 0.2 }, 0.1, 0.1, VG_WOOD, true)
    return g

// A load of wood on a man's shoulder: a short log.
def wood_load(look:vglook) -> vgrid:
    let l = vglook { look.leaf, look.bark, look.rock, false, false, false }
    let g = vg_new(l, float3 { -0.3, -0.3, 0.0 }, float3 { 0.3, 0.3, 0.3 }, TREE_K * 2.0, 995)
    vg_cylinder(g, float3 { -0.2, 0.0, 0.06 }, float3 { 0.2, 0.0, 0.06 }, 0.055, 0.055, VG_BARK)
    vg_cylinder(g, float3 { -0.21, 0.0, 0.06 }, float3 { -0.2, 0.0, 0.06 }, 0.05, 0.05, VG_WOOD, true)
    vg_cylinder(g, float3 { 0.2, 0.0, 0.06 }, float3 { 0.21, 0.0, 0.06 }, 0.05, 0.05, VG_WOOD, true)
    return g

// A grid baked onto a sheet: its picture under `name`, and (with shadow) its shadow on the ground under name.shadow.
// shade_k: how strong the shadow is (crowns overlap, and their shadows with them: full strength piles up black).
def tree_onto(s:Sheet, name:string, g:vgrid, shadow:bool, shade_k:float = 1.0):
    let bytes, w, h, origin = vg_sprite(g, shadow)
    if shadow:
        let art, shade = vm_split_shadow(bytes, w, h)
        if shade_k != 1.0:
            for(w * h) px: write_int8_le(shade, px * 4 + 3, int(float(shade[px * 4 + 3]) * shade_k))
        sheet_add_bytes(s, name, art, w, h, origin)
        sheet_add_bytes(s, name + ".shadow", shade, w, h, origin)
    else: sheet_add_bytes(s, name, bytes, w, h, origin)

// What every season shares: trunks, bare young trees, the stump, the load of wood. between(): so the window can draw.
def bake_trees(between):
    tree_draw_k = WB_PX / ART_K / TREE_K
    let s = sheet_new("trees", "{TREE_BAKE} {TREE_K} {WB_PX}", 2048)
    if sheet_load(s, tree_draw_k): return
    let t0 = seconds_elapsed()
    let look = tree_look("summer")
    for(OLD_KINDS) kind:
        tree_onto(s, "old{kind}", old_trunk(look, kind), true)
        between()
    for(YOUNG_KINDS) kind: tree_onto(s, "young{kind}.bare", young_tree(look, kind, true), true)
    tree_onto(s, "stump", tree_stump(look), true)
    sheet_finish(s, tree_draw_k, true)
    // (the load is baked finer than the trees: a sheet of its own, drawn at its own size)
    let ls = sheet_new("load", "{TREE_BAKE} {TREE_K} {WB_PX}", 256)
    tree_onto(ls, "load.wood", wood_load(look), false)
    sheet_finish(ls, tree_draw_k / 2.0, false)
    trees_bake_s = seconds_elapsed() - t0

// This season's crowns and young trees (winter has none: the bare ones are drawn).
def bake_season(season:string, between):
    if season == trees_season or season == "winter": return
    trees_season = season
    if frame_at.get("old0.crown.{season}", -1) >= 0: return  // (baked or read earlier this run)
    let s = sheet_new("trees_{season}", "{TREE_BAKE} {TREE_K} {WB_PX}", 2048)
    if sheet_load(s, tree_draw_k): return
    let t0 = seconds_elapsed()
    let look = tree_look(season)
    for(OLD_KINDS) kind:
        tree_onto(s, "old{kind}.crown.{season}", old_crown(look, kind), true, 0.45)
        between()
    for(YOUNG_KINDS) kind: tree_onto(s, "young{kind}.{season}", young_tree(look, kind, false), true)
    sheet_finish(s, tree_draw_k, true)
    trees_bake_s = seconds_elapsed() - t0
