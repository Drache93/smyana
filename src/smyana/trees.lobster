// ------------------------------------------------------------------ the trees, grey-boxed
// Stand-ins built voxel by voxel with Creel's prop baker (view/voxel_grid.lobster), so the size of the forest can be
// felt before the real trees are drawn (issue #6), in the Rhodopes' own kinds, at the size of the route mock-ups (archive/images/2026-11-10/19 to
// 23; Dominic, 2026-11-10: "Need to keep to the designs"): an old tree is about six men tall with a trunk a man wide
// and a crown five or six men across; a young tree is two or three men tall (a man is about 0.57 of a tile). A giant is three pictures: its trunk, its shadow on the
// ground, and its crown, which fades when a man is under it so he can be seen. The crowns are baked once a season
// (their colour), behind the letter home, and kept in bake_cache/.
// Baked coarse (TREE_K voxels a tile) and drawn larger: a giant at the men's fineness would take minutes to bake.

let TREE_K = 64.0  // voxels a tile (the .vox trees are made at this: tools/tree_vox.py)
let TREE_BAKE = "trees 12"
let PINE_KINDS = 2
let SPRUCE_KINDS = 3
let YOUNG_KINDS = 2
let ROCK_KINDS = 4
let SLAB_KINDS = 2
var tree_draw_k = 1.0   // art px a baked px (set at the bake: Creel's art scale decides)
var trees_bake_s = 0.0  // how long the last bake took (0: read from bake_cache/)
var trees_season = ""   // the season whose crowns are loaded

// The Rhodopes' trees (D-012, and Dominic's list of 2026-11-10). Broadleaves of the valleys: beech (smooth silver-grey
// bark, leaves in flat layers), oak (a short thick dark trunk, a wide round crown), hornbeam (smaller, grey, dense).
// Conifers of the high woods: Scots pine (a tall bare trunk, a flat grey-green top), Norway spruce and silver fir (a
// dark narrow spire). Autumn is the game's richest season: every broadleaf turns its own colour, and each tree of a
// kind a little differently (kind), from yellow through orange to red.
let BROADLEAVES = [ "beech", "oak", "hornbeam" ]
let LEAF_KINDS = 3

def autumn_leaf(sp:string, kind:int) -> [float3]:
    // sun, mid, shade, dry
    let gold = [ float3 { 1.0, 0.76, 0.14 }, float3 { 0.82, 0.52, 0.08 }, float3 { 0.36, 0.20, 0.05 }, float3 { 1.0, 0.88, 0.36 } ]
    let orange = [ float3 { 1.0, 0.52, 0.10 }, float3 { 0.78, 0.32, 0.06 }, float3 { 0.30, 0.11, 0.04 }, float3 { 1.0, 0.70, 0.18 } ]
    let red = [ float3 { 0.92, 0.25, 0.10 }, float3 { 0.64, 0.13, 0.07 }, float3 { 0.26, 0.05, 0.05 }, float3 { 0.98, 0.46, 0.12 } ]
    let russet = [ float3 { 0.84, 0.44, 0.14 }, float3 { 0.60, 0.27, 0.09 }, float3 { 0.26, 0.11, 0.05 }, float3 { 0.90, 0.62, 0.20 } ]
    if sp == "beech": return [ orange, gold, red ][kind % 3]
    if sp == "oak": return [ russet, orange, russet ][kind % 3]
    return [ gold, gold, orange ][kind % 3]

def leaf_look(sp:string, season:string, kind:int) -> vglook:
    var leaf = [ float3 { 0.47, 0.62, 0.22 }, float3 { 0.30, 0.47, 0.17 }, float3 { 0.16, 0.30, 0.13 }, float3 { 0.58, 0.60, 0.24 } ]
    if sp == "oak": leaf = [ float3 { 0.38, 0.54, 0.20 }, float3 { 0.24, 0.40, 0.15 }, float3 { 0.13, 0.25, 0.11 }, float3 { 0.48, 0.54, 0.22 } ]
    if sp == "hornbeam": leaf = [ float3 { 0.52, 0.66, 0.26 }, float3 { 0.35, 0.51, 0.19 }, float3 { 0.19, 0.33, 0.14 }, float3 { 0.62, 0.66, 0.28 } ]
    if season == "spring": leaf = map(leaf) c: c * 1.12 + float3 { 0.12, 0.14, 0.06 }
    if season == "autumn": leaf = autumn_leaf(sp, kind)
    var bark = [ float3 { 0.30, 0.30, 0.28 }, float3 { 0.42, 0.42, 0.39 }, float3 { 0.54, 0.53, 0.49 }, float3 { 0.66, 0.65, 0.60 } ]
    if sp == "oak": bark = [ float3 { 0.20, 0.17, 0.14 }, float3 { 0.28, 0.24, 0.20 }, float3 { 0.37, 0.32, 0.26 }, float3 { 0.46, 0.40, 0.33 } ]
    // (a beech's bark is smooth: no ridges up it)
    return vglook { leaf, bark, [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, true, sp != "beech" }

def beech_look(season:string) -> vglook: return leaf_look("beech", season, 0)

def pine_look() -> vglook:
    return vglook { [ float3 { 0.36, 0.50, 0.30 }, float3 { 0.23, 0.37, 0.24 }, float3 { 0.12, 0.23, 0.17 }, float3 { 0.44, 0.52, 0.30 } ],
                    [ float3 { 0.25, 0.19, 0.15 }, float3 { 0.36, 0.26, 0.19 }, float3 { 0.49, 0.33, 0.22 }, float3 { 0.62, 0.41, 0.26 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, true, true }

def spruce_look() -> vglook:
    return vglook { [ float3 { 0.21, 0.36, 0.24 }, float3 { 0.13, 0.26, 0.19 }, float3 { 0.07, 0.15, 0.13 }, float3 { 0.27, 0.40, 0.25 } ],
                    [ float3 { 0.20, 0.16, 0.13 }, float3 { 0.29, 0.23, 0.19 }, float3 { 0.38, 0.31, 0.25 }, float3 { 0.47, 0.39, 0.32 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, true, true }

// The Rhodopes' rock: gneiss, warm grey, splitting along its bedding into flat slabs (the stone of the houses' walls
// and roofs). Creel's rock light adds the lichen, the moss, the mica and the quartz.
def gneiss_look() -> vglook:
    return vglook { [ float3 { 0.40, 0.50, 0.22 }, float3 { 0.30, 0.40, 0.18 }, float3 { 0.20, 0.28, 0.14 }, float3 { 0.5, 0.5, 0.25 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.4, 0.4, 0.4 }, float3 { 0.5, 0.5, 0.5 }, float3 { 0.6, 0.6, 0.6 } ],
                    [ float3 { 0.33, 0.31, 0.28 }, float3 { 0.44, 0.41, 0.37 }, float3 { 0.55, 0.52, 0.46 }, float3 { 0.66, 0.62, 0.54 }, float3 { 0.75, 0.71, 0.62 } ],
                    true, false, false }

// Where a tree's crown is centred over its foot, and how far it spreads (tiles): what fades over a man.
def crown_up(sp:string) -> float: return if sp == "beech": 2.3 elif sp == "oak": 1.7 elif sp == "hornbeam": 1.5 elif sp == "pine": 2.6 else: 1.9
def crown_reach(sp:string) -> float: return if sp == "beech": 1.5 elif sp == "oak": 1.4 elif sp == "hornbeam": 0.85 elif sp == "pine": 0.8 else: 0.7

// A broadleaf's build: fork height from..to, bough reach from..to, trunk radius, a leaf layer's radius, how flat it is.
def leaf_build(sp:string) -> [float]:
    return if sp == "oak": [ 0.95, 1.2, 0.7, 0.95, 0.17, 0.6, 1.45 ] elif sp == "hornbeam": [ 0.85, 1.05, 0.32, 0.48, 0.085, 0.42, 1.35 ] else: [ 1.3, 1.6, 0.55, 0.8, 0.13, 0.56, 2.1 ]

def leaf_seed(sp:string, kind:int) -> int: return 500 + (if sp == "oak": 37 elif sp == "hornbeam": 74 else: 0) + kind

// An old broadleaf's frame: where its trunk forks, where each bough ends, and the twigs off each bough (tiles from
// its foot). The trunk's picture has the wood; the crown's has the leaves, clustered at the twigs' tips.
def leaf_frame(sp:string, kind:int) -> float3, [float3], [float3]:
    let rng = grng(leaf_seed(sp, kind))
    let b = leaf_build(sp)
    let top = float3 { randf_range(rng, -0.1, 0.1), randf_range(rng, -0.1, 0.1), randf_range(rng, b[0], b[1]) }
    let n = 5 + kind % 2
    let ends = map(n) i:
        let a = float(i) * 360.0 / float(n) + randf_range(rng, -25.0, 25.0)
        let out = randf_range(rng, b[2], b[3])
        // (the last goes nearly straight up: the leader)
        if i == n - 1: top + float3 { cos(a) * out * 0.2, sin(a) * out * 0.2, b[3] * 1.15 }
        else: top + float3 { cos(a) * out, sin(a) * out, randf_range(rng, 0.3, 0.75) * b[3] / 0.8 }
    let twigs = []::float3
    for(ends) e:
        for(4) t:
            let a = randf_range(rng, 0.0, 360.0)
            let out = randf_range(rng, 0.18, 0.4) * b[3] / 0.8
            twigs.push(e + float3 { cos(a) * out, sin(a) * out, randf_range(rng, 0.0, 0.35) * b[3] / 0.8 })
    return top, ends, twigs

def leaf_trunk(look:vglook, sp:string, kind:int) -> vgrid:
    let top, ends, twigs = leaf_frame(sp, kind)
    let r = leaf_build(sp)[4]
    let g = vg_new(look, float3 { -1.6, -1.6, 0.0 }, float3 { 1.6, 1.6, 3.2 }, TREE_K, leaf_seed(sp, kind))
    vg_capsule(g, float3_0, top, r, r * 0.7, VG_BARK)
    vg_cylinder(g, float3_0, float3 { 0.0, 0.0, 0.18 }, r * 1.45, r, VG_BARK)  // the foot's flare
    for(ends) e, i:
        vg_capsule(g, top * 0.86, e, r * 0.5, r * 0.2, VG_BARK)
        for(4) t: vg_capsule(g, top * 0.86 + (e - top * 0.86) * (0.55 + 0.15 * float(t)), twigs[i * 4 + t], r * 0.2, r * 0.1, VG_BARK)
    return g

// A broadleaf's leaves: small clusters at the tips of its twigs and along its boughs, each its own tone, with the
// branches and the sky showing between them. full: how much of its leaf it has (autumn's are thinning).
def leaf_crown(look:vglook, sp:string, kind:int, full:float) -> vgrid:
    let top, ends, twigs = leaf_frame(sp, kind)
    let b = leaf_build(sp)
    let pr = b[5] / 0.56
    let rng = grng(leaf_seed(sp, kind) + 200)
    let g = vg_new(look, float3 { -2.1, -2.1, 0.5 }, float3 { 2.1, 2.1, 3.5 }, TREE_K, leaf_seed(sp, kind) + 200)
    let rough = vg_field(g, 0.1, leaf_seed(sp, kind) + 201)
    def cluster(c:float3, n:int, spread:float, size:float):
        for(n) i:
            if randf(rng) < full:
                let at = c + vg_gauss3(rng) * spread
                vg_blob(g, at, randf_range(rng, 0.1, 0.17) * size, 1.25, 0.8, rough, VG_LEAF, randf_range(rng, -0.4, 0.5), 0.22, nil, 0.0)
    for(twigs) t: cluster(t, 6, 0.13 * pr, pr)
    for(ends) e: cluster(e, 7, 0.17 * pr, pr * 1.15)
    for(ends) e: cluster(top * 0.86 + (e - top * 0.86) * 0.6, 3, 0.12 * pr, pr)
    return g

def pine_frame(kind:int) -> float3, [float3]:
    let rng = grng(520 + kind)
    let top = float3 { randf_range(rng, -0.2, 0.2), randf_range(rng, -0.1, 0.1), randf_range(rng, 2.3, 2.7) }
    let ends = map(3) n:
        let a = float(n) * 120.0 + randf_range(rng, -30.0, 30.0)
        let out = randf_range(rng, 0.4, 0.55)
        top + float3 { cos(a) * out, sin(a) * out, randf_range(rng, -0.1, 0.15) }
    return top, ends

def pine_trunk(look:vglook, kind:int) -> vgrid:
    let top, ends = pine_frame(kind)
    let g = vg_new(look, float3 { -0.9, -0.9, 0.0 }, float3 { 0.9, 0.9, 3.1 }, TREE_K, 520 + kind)
    vg_capsule(g, float3_0, top, 0.1, 0.055, VG_BARK)
    for(ends) e: vg_capsule(g, top * 0.9, e, 0.04, 0.02, VG_BARK)
    // a dead snag or two lower down
    vg_capsule(g, top * 0.6, top * 0.6 + float3 { 0.22, 0.1, 0.05 }, 0.025, 0.012, VG_BARK)
    return g

def pine_crown(look:vglook, kind:int) -> vgrid:
    let top, ends = pine_frame(kind)
    let rng = grng(720 + kind)
    let g = vg_new(look, float3 { -1.3, -1.3, 1.8 }, float3 { 1.3, 1.3, 3.4 }, TREE_K, 720 + kind)
    let rough = vg_field(g, 0.25, 721 + kind)
    let gaps = vg_field(g, 0.35, 722 + kind)
    for(ends) e: vg_blob(g, e + float3 { 0.0, 0.0, 0.08 }, randf_range(rng, 0.36, 0.46), 1.9, 0.6, rough, VG_LEAF, randf_range(rng, -0.5, 0.4), 0.14, gaps, 0.66)
    vg_blob(g, top + float3 { 0.0, 0.0, 0.3 }, 0.5, 1.8, 0.6, rough, VG_LEAF, 0.3, 0.14, gaps, 0.66)
    return g

def spruce_height(kind:int) -> float: return 3.1 + float(kind) * 0.3

def spruce_trunk(look:vglook, kind:int) -> vgrid:
    let h = spruce_height(kind)
    let g = vg_new(look, float3 { -0.4, -0.4, 0.0 }, float3 { 0.4, 0.4, h + 0.1 }, TREE_K, 540 + kind)
    vg_capsule(g, float3_0, float3 { 0.0, 0.0, h }, 0.1, 0.02, VG_BARK)
    vg_cylinder(g, float3_0, float3 { 0.0, 0.0, 0.14 }, 0.15, 0.1, VG_BARK)
    return g

// A deep wood's spruce or fir: a bare dark trunk with dead snags, far taller than the picture shows. Its top is
// faded out when it's baked (tree_onto's fade), so the trunks run up out of sight: the canopy is over the camera.
let TALL_H = 6.5
def tall_trunk(look:vglook, kind:int) -> vgrid:
    let rng = grng(560 + kind)
    let g = vg_new(look, float3 { -0.5, -0.5, 0.0 }, float3 { 0.5, 0.5, TALL_H }, TREE_K, 560 + kind)
    let r = 0.11 + float(kind) * 0.02
    vg_capsule(g, float3_0, float3 { randf_range(rng, -0.08, 0.08), 0.0, TALL_H }, r, r * 0.6, VG_BARK)
    vg_cylinder(g, float3_0, float3 { 0.0, 0.0, 0.16 }, r * 1.5, r, VG_BARK)
    for(7) n:
        let z = 1.0 + float(n) * 0.75 + randf_range(rng, -0.2, 0.2)
        let a = randf_range(rng, 0.0, 360.0)
        let l = randf_range(rng, 0.15, 0.35)
        vg_capsule(g, float3 { 0.0, 0.0, z }, float3 { cos(a) * l, sin(a) * l, z - 0.04 }, 0.022, 0.012, VG_BARK)
    return g

// A spire of drooping tiers, wide at the bottom, from `low` to the tip (the young one's start at the ground).
def spire(g:vgrid, seed:int, low:float, h:float, wide:float, step:float):
    let rng = grng(seed)
    let rough = vg_field(g, 0.2, seed + 1)
    var z = low
    while z < h:
        let t = (z - low) / (h - low)
        let r = wide * pow(1.0 - t, 0.85) + 0.05
        let c = float3 { randf_range(rng, -0.05, 0.05), randf_range(rng, -0.05, 0.05), z }
        vg_blob(g, c, r, 2.6, 0.55, rough, VG_LEAF, randf_range(rng, -0.5, 0.5), 0.18, nil, 0.0)
        z += step * (0.85 + 0.3 * randf(rng))

def spruce_crown(look:vglook, kind:int) -> vgrid:
    let h = spruce_height(kind)
    let g = vg_new(look, float3 { -1.0, -1.0, 0.5 }, float3 { 1.0, 1.0, h + 0.3 }, TREE_K, 740 + kind)
    spire(g, 740 + kind, 0.75, h + 0.1, 0.62 + float(kind) * 0.05, 0.2)
    return g

// A young beech, whole: thin, two or three men tall. bare: no leaves (winter).
def young_tree(look:vglook, kind:int, bare:bool) -> vgrid:
    let rng = grng(900 + kind)
    let g = vg_new(look, float3 { -0.6, -0.6, 0.0 }, float3 { 0.6, 0.6, 1.7 }, TREE_K, 900 + kind)
    let top = float3 { randf_range(rng, -0.08, 0.08), randf_range(rng, -0.08, 0.08), randf_range(rng, 0.75, 1.0) }
    vg_capsule(g, float3_0, top, 0.06, 0.035, VG_BARK)
    for(3) n:
        let a = float(n) * 120.0 + randf_range(rng, 0.0, 60.0)
        vg_capsule(g, top * 0.7, top + float3 { cos(a) * 0.25, sin(a) * 0.25, 0.2 }, 0.03, 0.02, VG_BARK)
    if not bare:
        let rough = vg_field(g, 0.2, 901 + kind)
        vg_blob(g, top + float3 { 0.0, 0.0, 0.12 }, randf_range(rng, 0.36, 0.44), 1.7, 0.5, rough, VG_LEAF, randf_range(rng, -0.3, 0.3), 0.12, nil, 0.0)
        vg_blob(g, top + float3 { 0.05, 0.0, 0.36 }, randf_range(rng, 0.24, 0.3), 1.6, 0.5, rough, VG_LEAF, randf_range(rng, -0.3, 0.3), 0.12, nil, 0.0)
    return g

def young_spruce(look:vglook, kind:int) -> vgrid:
    let h = 1.15 + float(kind) * 0.25
    let g = vg_new(look, float3 { -0.5, -0.5, 0.0 }, float3 { 0.5, 0.5, h + 0.2 }, TREE_K, 940 + kind)
    vg_capsule(g, float3_0, float3 { 0.0, 0.0, h }, 0.045, 0.015, VG_BARK)
    spire(g, 940 + kind, 0.22, h + 0.05, 0.3, 0.13)
    return g

def tree_stump(look:vglook) -> vgrid:
    let g = vg_new(look, float3 { -0.3, -0.3, 0.0 }, float3 { 0.3, 0.3, 0.3 }, TREE_K, 990)
    vg_cylinder(g, float3_0, float3 { 0.0, 0.0, 0.16 }, 0.08, 0.07, VG_BARK)
    vg_cylinder(g, float3 { 0.0, 0.0, 0.16 }, float3 { 0.0, 0.0, 0.2 }, 0.07, 0.07, VG_WOOD, true)
    return g

// ------------------------------------------------------------------ trees made as .vox (D-035)
// A tree designed in 2D (art/trees/design/) and made as a voxel model (art/trees/vox/, tools/tree_vox.py). Its palette
// index says what each voxel is: 1..4 bark, 10 leaves lit from above, 11 mid, 12 their underside. The model is baked
// as two pictures, its wood and its leaves, so the leaves can be coloured by the season and fade over a man.
let VOX_TREES = [ "beech_old_0", "beech_old_1", "beech_mature_0", "beech_mature_1", "beech_young_0", "beech_young_1", "beech_sapling_0" ]
var vox_feet = []::string  // art/trees/vox/feet.txt, in tokens: name, x, y, ...

def vox_tree_text() -> string:
    var t = read_file("../art/trees/vox/feet.txt") or ""
    for(VOX_TREES) name: t += sha256_text(read_file("../art/trees/vox/{name}.vox") or "")
    return sha256_text(t)

// leaves: the model's leaves alone, or its wood alone.
def vox_tree(look:vglook, name:string, leaves:bool) -> vgrid:
    if not vox_feet.length: vox_feet = tokenize(read_file("../art/trees/vox/feet.txt") or "", " \n", "")
    let at = find(vox_feet): _ == name
    assert at >= 0
    let foot = int3 { string_to_int(vox_feet[at + 1]), string_to_int(vox_feet[at + 2]), 0 }
    let f = vox_parse(assert read_file("../art/trees/vox/{name}.vox"))
    assert f.error == "" and f.models.length == 1
    let m = f.models[0]
    let g = vg_new(look, float(int3_0 - foot - int3_1) / TREE_K, float(m.size - foot + int3_1) / TREE_K, TREE_K, 2000 + at)
    for(m.xyz) p, i:
        let idx = m.idx[i]
        let q = p - foot - g.lo
        if leaves and idx >= 10: vg_set(g, vg_index(g, q.x, q.y, q.z), VG_LEAF, if idx == 10: 0.5 elif idx == 11: 0.0 else: -0.6)
        elif not leaves and idx < 10: vg_set(g, vg_index(g, q.x, q.y, q.z), VG_BARK, 0.0)
    return g

// ------------------------------------------------------------------ the undergrowth (issue #8), grey-boxed
let FERN_KINDS = 3
let BUSH_KINDS = 2
let LOG_KINDS = 2

// A fern (bracken): fronds arching out from one foot and drooping at their tips.
def fern(look:vglook, kind:int) -> vgrid:
    let rng = grng(1300 + kind)
    let g = vg_new(look, float3 { -0.4, -0.4, 0.0 }, float3 { 0.4, 0.4, 0.4 }, TREE_K, 1300 + kind)
    let n = 6 + kind
    for(n) i:
        let a = float(i) * 360.0 / float(n) + randf_range(rng, -20.0, 20.0)
        let reach = randf_range(rng, 0.2, 0.32)
        let d = float3 { cos(a), sin(a), 0.0 }
        let mid = d * (reach * 0.5) + float3 { 0.0, 0.0, randf_range(rng, 0.13, 0.2) }
        let tone = randf_range(rng, -0.6, 0.7)
        vg_capsule(g, float3_0, mid, 0.022, 0.034, VG_LEAF, false, tone)
        vg_capsule(g, mid, d * reach + float3 { 0.0, 0.0, 0.07 }, 0.034, 0.014, VG_LEAF, false, tone)
    return g

// A low bush: a few stems and a heap of small leaf clumps.
def bush(look:vglook, kind:int) -> vgrid:
    let rng = grng(1400 + kind)
    let g = vg_new(look, float3 { -0.45, -0.45, 0.0 }, float3 { 0.45, 0.45, 0.55 }, TREE_K, 1400 + kind)
    let rough = vg_field(g, 0.12, 1401 + kind)
    for(5 + kind * 2) i:
        let c = float3 { randf_range(rng, -0.2, 0.2), randf_range(rng, -0.2, 0.2), randf_range(rng, 0.12, 0.3) }
        vg_capsule(g, float3 { c.x * 0.3, c.y * 0.3, 0.0 }, c, 0.015, 0.01, VG_BARK)
        vg_blob(g, c, randf_range(rng, 0.09, 0.15), 1.1, 0.7, rough, VG_LEAF, randf_range(rng, -0.7, 0.8), 0.2, nil, 0.0)
    return g

// A fallen trunk, long down, moss along its top.
def fallen_log(look:vglook, kind:int) -> vgrid:
    let rng = grng(1500 + kind)
    let g = vg_new(look, float3 { -0.7, -0.7, 0.0 }, float3 { 0.7, 0.7, 0.3 }, TREE_K, 1500 + kind)
    let a = randf_range(rng, 0.0, 180.0)
    let d = float3 { cos(a), sin(a), 0.0 } * (0.45 + float(kind) * 0.15)
    let up = float3 { 0.0, 0.0, 0.075 }
    let rough = vg_field(g, 0.1, 1501 + kind)
    for(4) i:
        let t = randf_range(rng, -0.8, 0.8)
        vg_blob(g, d * t + float3 { 0.0, 0.0, 0.14 }, 0.07, 2.0, 0.6, rough, VG_LEAF, randf_range(rng, -0.4, 0.2), 0.2, nil, 0.0)
    vg_cylinder(g, up - d, up + d, 0.075, 0.06, VG_BARK)
    vg_cylinder(g, up - d * 1.03, up - d, 0.068, 0.068, VG_WOOD, true)
    vg_cylinder(g, up + d, up + d * 1.03, 0.055, 0.055, VG_WOOD, true)
    return g

// The undergrowth's leaves by season: bracken goes bronze and gold in autumn, the bushes yellow and red.
def under_look(season:string, kind:int, moss:bool) -> vglook:
    var leaf = [ float3 { 0.44, 0.62, 0.24 }, float3 { 0.29, 0.47, 0.19 }, float3 { 0.16, 0.30, 0.14 }, float3 { 0.60, 0.68, 0.28 } ]
    if season == "spring": leaf = [ float3 { 0.56, 0.74, 0.30 }, float3 { 0.40, 0.60, 0.24 }, float3 { 0.22, 0.38, 0.16 }, float3 { 0.70, 0.80, 0.40 } ]
    // (autumn: one bracken bronze, one still green, one gone pale yellow)
    if season == "autumn" and not moss and kind % 3 == 0: leaf = autumn_leaf("oak", 0)
    if season == "autumn" and not moss and kind % 3 == 2: leaf = [ float3 { 0.93, 0.86, 0.38 }, float3 { 0.74, 0.68, 0.26 }, float3 { 0.42, 0.40, 0.14 }, float3 { 0.98, 0.94, 0.56 } ]
    if moss: leaf = [ float3 { 0.36, 0.50, 0.20 }, float3 { 0.26, 0.38, 0.16 }, float3 { 0.16, 0.25, 0.12 }, float3 { 0.44, 0.52, 0.22 } ]
    return vglook { leaf, [ float3 { 0.20, 0.17, 0.14 }, float3 { 0.28, 0.24, 0.20 }, float3 { 0.37, 0.32, 0.26 }, float3 { 0.46, 0.40, 0.33 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, false, false }

// A plate of rock: w by d by th, turned by `turn` degrees about c, its foot at c.z.
def rock_plate(g:vgrid, c:float3, w:float, d:float, th:float, turn:float, m:int, tone:float):
    let reach = max(w, d) * 1.5
    vg_box(g, float3 { c.x - reach, c.y - reach, c.z }, float3 { c.x + reach, c.y + reach, c.z + th }) i, p:
        let u = (p.x - c.x) * cos(turn) + (p.y - c.y) * sin(turn)
        let v = -(p.x - c.x) * sin(turn) + (p.y - c.y) * cos(turn)
        // (a corner knocked off, so no two plates are the same oblong)
        if abs(u) < w and abs(v) < d and abs(u) / w + abs(v) / d < 1.7 and p.z >= c.z and p.z < c.z + th: vg_set(g, i, m, tone)

// A gneiss outcrop: thick flat beds lying one on another, each a little smaller and a little turned, so it stands in
// steps of slabs (the rock splits along its bedding: that's what makes it a building stone).
def outcrop(look:vglook, kind:int) -> vgrid:
    let rng = grng(1100 + kind)
    let beds = [ 3, 4, 6, 2 ][kind]
    let g = vg_new(look, float3 { -0.95, -0.95, 0.0 }, float3 { 0.95, 0.95, 1.2 }, TREE_K, 1100 + kind)
    var z = 0.0
    var c = float2 { 0.0, 0.0 }
    var w = randf_range(rng, 0.6, 0.72)
    var d = randf_range(rng, 0.5, 0.62)
    let turn0 = randf_range(rng, -20.0, 20.0)
    for(beds) n:
        let th = randf_range(rng, 0.1, 0.19)
        rock_plate(g, float3 { c.x, c.y, z }, w, d, th, turn0 + randf_range(rng, -9.0, 9.0), VG_ROCK, if n % 2: 0.3 else: -0.25)
        z += th
        c += float2 { randf_range(rng, -0.12, 0.12), randf_range(rng, -0.1, 0.1) }
        w *= randf_range(rng, 0.66, 0.9)
        d *= randf_range(rng, 0.66, 0.9)
    // a fallen block at its foot
    rock_plate(g, float3 { 0.55, -0.45, 0.0 }, 0.2, 0.14, 0.1, turn0 + 30.0, VG_ROCK, 0.1)
    return g

// Loose slabs split from the rock: the stone a wall or a roof is made of.
def slab_pile(look:vglook, kind:int) -> vgrid:
    let rng = grng(1200 + kind)
    let g = vg_new(look, float3 { -0.5, -0.5, 0.0 }, float3 { 0.5, 0.5, 0.4 }, TREE_K, 1200 + kind)
    var z = 0.0
    for(3 + kind * 2) n:
        let w = randf_range(rng, 0.16, 0.27)
        let d = randf_range(rng, 0.11, 0.18)
        let th = randf_range(rng, 0.03, 0.05)
        let c = float2 { randf_range(rng, -0.08, 0.08), randf_range(rng, -0.08, 0.08) } + (if n >= 4: float2 { 0.25, -0.12 } else: float2_0)
        if n == 4: z = 0.0
        rock_plate(g, float3 { c.x, c.y, z }, w, d, th, randf_range(rng, -30.0, 30.0), if n % 2: VG_CUT else: VG_ROCK, if n % 2: 0.3 else: -0.2)
        z += th
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
// fade: the top of the picture thins out to nothing from this far up it (0: not).
def tree_onto(s:Sheet, name:string, g:vgrid, shadow:bool, shade_k:float = 1.0, fade:float = 0.0):
    let bytes, w, h, origin = vg_sprite(g, shadow)
    if shadow:
        let art, shade = vm_split_shadow(bytes, w, h)
        if shade_k != 1.0:
            for(w * h) px: write_int8_le(shade, px * 4 + 3, min(235, int(float(shade[px * 4 + 3]) * shade_k)))
        if fade > 0.0:
            let rows = int(float(h) * fade)
            for(rows) y: for(w) x:
                let px = (y * w + x) * 4 + 3
                let keep = float(y) / float(rows)
                write_int8_le(art, px, int(float(art[px]) * keep * keep))
        sheet_add_bytes(s, name, art, w, h, origin)
        sheet_add_bytes(s, name + ".shadow", shade, w, h, origin)
    else: sheet_add_bytes(s, name, bytes, w, h, origin)

// What every season shares: trunks, the evergreens' crowns, bare young trees, the stump, the rock, the load of wood.
// between(): so the window can draw.
def bake_trees(between):
    tree_draw_k = WB_PX / ART_K / TREE_K
    let s = sheet_new("trees", "{TREE_BAKE} {TREE_K} {WB_PX} {vox_tree_text()}", 4096)
    let rs = sheet_new("rocks", "{TREE_BAKE} {TREE_K} {WB_PX}", 1024)
    let ls = sheet_new("load", "{TREE_BAKE} {TREE_K} {WB_PX}", 256)
    if sheet_load(s, tree_draw_k) and sheet_load(rs, tree_draw_k) and sheet_load(ls, tree_draw_k / 2.0): return
    let t0 = seconds_elapsed()
    let beech = beech_look("summer")
    let pine = pine_look()
    let spruce = spruce_look()
    for(BROADLEAVES) sp: for(LEAF_KINDS) kind:
        // (beech is made as .vox, from its design sheet: two old ones and a mature one)
        if sp == "beech": tree_onto(s, "beech{kind}", vox_tree(beech, VOX_TREES[kind], false), true)
        else: tree_onto(s, "{sp}{kind}", leaf_trunk(leaf_look(sp, "summer", kind), sp, kind), true)
        between()
    between()
    for(PINE_KINDS) kind:
        tree_onto(s, "pine{kind}", pine_trunk(pine, kind), true)
        tree_onto(s, "pine{kind}.crown.ever", pine_crown(pine, kind), true, 0.45)
    between()
    for(SPRUCE_KINDS) kind:
        tree_onto(s, "spruce{kind}", spruce_trunk(spruce, kind), true)
        tree_onto(s, "spruce{kind}.crown.ever", spruce_crown(spruce, kind), true, 0.6)
        tree_onto(s, "tall{kind}", tall_trunk(spruce, kind), true, 0.5, 0.62)
        between()
    for(YOUNG_KINDS) kind:
        tree_onto(s, "young{kind}.bare", vox_tree(beech, VOX_TREES[4 + kind], false), true)
        tree_onto(s, "yspruce{kind}", young_spruce(spruce, kind), true)
    tree_onto(s, "stump", tree_stump(beech), true)
    for(LOG_KINDS) kind: tree_onto(s, "log{kind}", fallen_log(under_look("summer", kind, true), kind), true)
    sheet_finish(s, tree_draw_k, true)
    let gneiss = gneiss_look()
    for(ROCK_KINDS) kind: tree_onto(rs, "rock{kind}", outcrop(gneiss, kind), true)
    for(SLAB_KINDS) kind: tree_onto(rs, "slabs{kind}", slab_pile(gneiss, kind), true)
    sheet_finish(rs, tree_draw_k, true)
    // (the load is baked finer than the trees: a sheet of its own, drawn at its own size)
    tree_onto(ls, "load.wood", wood_load(beech), false)
    sheet_finish(ls, tree_draw_k / 2.0, false)
    trees_bake_s = seconds_elapsed() - t0

// This season's leaves on the beeches, old and young (winter has none: the bare ones are drawn).
def bake_season(season:string, between):
    if season == trees_season or season == "winter": return
    trees_season = season
    if frame_at.get("beech0.crown.{season}", -1) >= 0: return  // (baked or read earlier this run)
    let s = sheet_new("trees_{season}", "{TREE_BAKE} {TREE_K} {WB_PX} {vox_tree_text()}", 4096)
    if sheet_load(s, tree_draw_k): return
    let t0 = seconds_elapsed()
    for(BROADLEAVES) sp: for(LEAF_KINDS) kind:
        if sp == "beech": tree_onto(s, "beech{kind}.crown.{season}", vox_tree(leaf_look(sp, season, kind), VOX_TREES[kind], true), true, 1.5)
        else: tree_onto(s, "{sp}{kind}.crown.{season}", leaf_crown(leaf_look(sp, season, kind), sp, kind, if season == "autumn": 0.8 else: 1.0), true, 1.5)
        between()
    // the young ones turn too: one gold, one red
    // (a young beech: its wood is in the shared sheet as young<k>.bare, its leaves here)
    for(YOUNG_KINDS) kind: tree_onto(s, "young{kind}.{season}", vox_tree(leaf_look("beech", season, kind + 1), VOX_TREES[4 + kind], true), true)
    tree_onto(s, "sapling.{season}", vox_tree(leaf_look("beech", season, 0), "beech_sapling_0", true), true)
    for(FERN_KINDS) kind: tree_onto(s, "fern{kind}.{season}", fern(under_look(season, kind, false), kind), true)
    for(BUSH_KINDS) kind: tree_onto(s, "bush{kind}.{season}", bush(under_look(season, kind + 1, false), kind), true)
    sheet_finish(s, tree_draw_k, true)
    trees_bake_s = seconds_elapsed() - t0
