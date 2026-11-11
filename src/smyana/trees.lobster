// ------------------------------------------------------------------ the trees
// Baked voxel by voxel with Creel's prop baker (view/voxel_grid.lobster), in the Rhodopes' own kinds, at the size of
// the route mock-ups (archive/images/2026-11-10/19 to 23; Dominic, 2026-11-10: "Need to keep to the designs"; D-036):
// an old tree is five or six men tall with a trunk a quarter to a third of a man wide; a young tree is two or three
// men tall. The whole trees are .vox models (art/trees/vox/, made by tools/tree_vox.py). An old tree is three
// pictures: its wood, its shadow on the ground, and its leaves, which fade when a man is under them so he can be
// seen. The leaves are baked once a season (their colour), behind the letter home, and kept in bake_cache/.

let TREE_K = 64.0  // voxels a tile for the load of wood (baked at twice this)
let TREE_BAKE = "trees 52"
// Voxels a tile in the trees, rocks and undergrowth: one voxel is one pixel of Creel's art (WB_PX at its art scale of
// 3), as the men's are, so they are as crisp as the men (Dominic, 2026-11-10: "evryhting crisp and sharp").
let VOX_K = 135.7645
// The baker's light, shade and occlusion reach a few of the grid's units. A grid here is built in tiles, far too big a
// unit (everything shaded flat), so before a grid is drawn its unit is made a sixteenth of a tile.
let LIGHT_UNITS = 16.0
let PINE_KINDS = 3
let SPRUCE_KINDS = 3
let YOUNG_KINDS = 2
let ROCK_KINDS = 4
let CRAG_KINDS = 4
let SLAB_KINDS = 2
var tree_draw_k = 1.0  // art px a baked px (set at the bake: Creel's art scale decides)
def vox_draw_k() -> float: return WB_PX / ART_K / VOX_K
var trees_bake_s = 0.0  // how long the last bake took (0: read from bake_cache/)
var trees_season = ""   // the season whose crowns are loaded

// The Rhodopes' trees (D-012, and Dominic's list of 2026-11-10). Broadleaves of the valleys: beech (smooth silver-grey
// bark, leaves in flat layers), oak (a short thick dark trunk, a wide round crown), hornbeam (smaller, grey, dense).
// Conifers of the high woods: Scots pine (a tall bare trunk, a flat grey-green top), Norway spruce and silver fir (a
// dark narrow spire). Autumn is the game's richest season: every broadleaf turns its own colour, and each tree of a
// kind a little differently (kind), from yellow through orange to red.
let BROADLEAVES = [ "beech", "oak", "hornbeam" ]
let LEAF_KINDS = 3
let OTHER_CONIFERS = [ "fir", "bpine" ]

let LATE_KEEP = 0.56     // how much of a crown still hangs after leaf-fall (of its noise field: about half its leaves)
let BRISTLE = 0.05       // how many of a thin branch's voxels sprout a fine twig after leaf-fall
var late_leaves = false  // (set while the "late" stage is baked)
def autumn_leaf(sp:string, kind:int) -> [float3]:
    // sun, mid, shade, dry
    let gold = [ float3 { 1.0, 0.76, 0.14 }, float3 { 0.82, 0.52, 0.08 }, float3 { 0.36, 0.20, 0.05 }, float3 { 1.0, 0.88, 0.36 } ]
    let orange = [ float3 { 1.0, 0.52, 0.10 }, float3 { 0.78, 0.32, 0.06 }, float3 { 0.30, 0.11, 0.04 }, float3 { 1.0, 0.70, 0.18 } ]
    let red = [ float3 { 0.92, 0.25, 0.10 }, float3 { 0.64, 0.13, 0.07 }, float3 { 0.26, 0.05, 0.05 }, float3 { 0.98, 0.46, 0.12 } ]
    let russet = [ float3 { 0.84, 0.44, 0.14 }, float3 { 0.60, 0.27, 0.09 }, float3 { 0.26, 0.11, 0.05 }, float3 { 0.90, 0.62, 0.20 } ]
    // (late, after leaf-fall: what still hangs has gone rust and brown, as in the mock-up: no gold, no red)
    let burnt = [ float3 { 0.80, 0.40, 0.12 }, float3 { 0.58, 0.25, 0.08 }, float3 { 0.25, 0.10, 0.05 }, float3 { 0.88, 0.54, 0.18 } ]
    let brown = [ float3 { 0.62, 0.36, 0.16 }, float3 { 0.44, 0.23, 0.10 }, float3 { 0.21, 0.10, 0.05 }, float3 { 0.72, 0.48, 0.22 } ]
    // (Dominic, 2026-11-11 07:39: "Trees are a bit naked there ... the rhodope autumn trees are rich with shades. Some
    // tree yellowz some red, some orange. Like our pallette that was designed for the trees": after leaf-fall a tree keeps
    // its own colour, and one in three has gone to rust)
    if late_leaves and kind % 3 == 2 and sp != "beech": return [ russet, burnt, brown ][(kind / 3) % 3]
    if sp == "beech": return [ orange, gold, red ][kind % 3]
    if sp == "oak": return [ russet, orange, russet ][kind % 3]
    return [ gold, gold, orange ][kind % 3]

def leaf_look(sp:string, season:string, kind:int) -> vglook:
    // (summer, Dominic 2026-11-11: "the green scene ... is too green, and lacking variation. the lighter coloured trees
    // are almost invisible on the grass". The crowns are a cooler, deeper green than the meadow under them, each kind
    // of tree its own green, and each tree of a kind a little different: one fresher and yellower, one darker and bluer)
    var leaf = [ float3 { 0.40, 0.58, 0.20 }, float3 { 0.23, 0.42, 0.16 }, float3 { 0.10, 0.24, 0.12 }, float3 { 0.50, 0.60, 0.22 } ]
    if sp == "oak": leaf = [ float3 { 0.30, 0.45, 0.19 }, float3 { 0.17, 0.32, 0.14 }, float3 { 0.08, 0.18, 0.10 }, float3 { 0.40, 0.48, 0.22 } ]
    if sp == "hornbeam": leaf = [ float3 { 0.34, 0.54, 0.28 }, float3 { 0.20, 0.39, 0.21 }, float3 { 0.09, 0.23, 0.14 }, float3 { 0.44, 0.56, 0.30 } ]
    let tint = [ float3 { 1.0, 1.0, 1.0 }, float3 { 0.86, 0.94, 1.12 }, float3 { 1.1, 1.04, 0.84 } ][kind % 3]
    leaf = map(leaf) c: c * tint
    if season == "spring": leaf = map(leaf) c: c * 1.12 + float3 { 0.12, 0.14, 0.06 }
    if season == "autumn": leaf = autumn_leaf(sp, kind)
    // (beech and hornbeam bark is pale silver grey)
    var bark = [ float3 { 0.25, 0.24, 0.24 }, float3 { 0.39, 0.38, 0.36 }, float3 { 0.54, 0.53, 0.50 }, float3 { 0.70, 0.69, 0.64 } ]
    if sp == "oak": bark = [ float3 { 0.20, 0.17, 0.14 }, float3 { 0.28, 0.24, 0.20 }, float3 { 0.37, 0.32, 0.26 }, float3 { 0.46, 0.40, 0.33 } ]
    // (a beech's bark is smooth: no ridges up it)
    return vglook { leaf, bark, [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, true, sp != "beech" }

def beech_look(season:string) -> vglook: return leaf_look("beech", season, 0)

def pine_look() -> vglook:
    return vglook { [ float3 { 0.36, 0.50, 0.30 }, float3 { 0.23, 0.37, 0.24 }, float3 { 0.12, 0.23, 0.17 }, float3 { 0.44, 0.52, 0.30 } ],
                    [ float3 { 0.25, 0.19, 0.15 }, float3 { 0.36, 0.26, 0.19 }, float3 { 0.49, 0.33, 0.22 }, float3 { 0.62, 0.41, 0.26 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, true, true }

// Silver fir: dark glossy needles with a silver underside, smooth silver grey bark.
def fir_look() -> vglook:
    return vglook { [ float3 { 0.25, 0.40, 0.30 }, float3 { 0.15, 0.29, 0.23 }, float3 { 0.08, 0.17, 0.15 }, float3 { 0.36, 0.46, 0.40 } ],
                    [ float3 { 0.27, 0.27, 0.27 }, float3 { 0.40, 0.40, 0.39 }, float3 { 0.53, 0.53, 0.51 }, float3 { 0.64, 0.64, 0.61 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, true, true }

// Black pine: long dark needles in dense tufts, bark nearly black, deeply furrowed.
def bpine_look() -> vglook:
    return vglook { [ float3 { 0.26, 0.37, 0.22 }, float3 { 0.15, 0.25, 0.16 }, float3 { 0.07, 0.14, 0.10 }, float3 { 0.32, 0.40, 0.23 } ],
                    [ float3 { 0.12, 0.11, 0.11 }, float3 { 0.20, 0.19, 0.18 }, float3 { 0.29, 0.27, 0.25 }, float3 { 0.39, 0.36, 0.33 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, true, true }

def spruce_look() -> vglook:
    return vglook { [ float3 { 0.21, 0.36, 0.24 }, float3 { 0.13, 0.26, 0.19 }, float3 { 0.07, 0.15, 0.13 }, float3 { 0.27, 0.40, 0.25 } ],
                    [ float3 { 0.10, 0.08, 0.07 }, float3 { 0.17, 0.13, 0.11 }, float3 { 0.25, 0.20, 0.16 }, float3 { 0.35, 0.28, 0.23 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, true, true }

// The Rhodopes' rock: gneiss, warm grey, splitting along its bedding into flat slabs (the stone of the houses' walls
// and roofs). Creel's rock light adds the lichen, the moss, the mica and the quartz.
def gneiss_look() -> vglook:
    return vglook { [ float3 { 0.40, 0.50, 0.22 }, float3 { 0.30, 0.40, 0.18 }, float3 { 0.20, 0.28, 0.14 }, float3 { 0.5, 0.5, 0.25 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.4, 0.4, 0.4 }, float3 { 0.5, 0.5, 0.5 }, float3 { 0.6, 0.6, 0.6 } ],
                    [ float3 { 0.33, 0.31, 0.28 }, float3 { 0.44, 0.41, 0.37 }, float3 { 0.55, 0.52, 0.46 }, float3 { 0.66, 0.62, 0.54 }, float3 { 0.75, 0.71, 0.62 } ],
                    true, false, false }

// Where a tree's crown is centred over its foot, and how far it spreads (tiles): what fades over a man.
def crown_up(sp:string) -> float:
    return if sp == "beech": 1.35 elif sp == "oak": 1.2 elif sp == "hornbeam": 1.0 elif sp == "pine": 1.7 elif sp == "bpine": 1.6 elif sp == "fir": 1.3 else: 1.2

def crown_reach(sp:string) -> float:
    return if sp == "beech": 0.8 elif sp == "oak": 0.8 elif sp == "hornbeam": 0.55 elif sp == "pine": 0.55 elif sp == "bpine": 0.75 elif sp == "fir": 0.5 else: 0.45

// A deep wood's spruce or fir: a bare dark trunk with dead snags, far taller than the picture shows. Its top is
// faded out when it's baked (tree_onto's fade), so the trunks run up out of sight: the canopy is over the camera.
let TALL_H = 5.0
def tall_trunk(look:vglook, kind:int) -> vgrid:
    let rng = grng(560 + kind)
    let g = vg_new(look, float3 { -0.4, -0.4, 0.0 }, float3 { 0.4, 0.4, TALL_H }, VOX_K, 560 + kind)
    // (a quarter to a third of a man wide, as in the deep-wood mock-up)
    let r = 0.042 + float(kind) * 0.007
    vg_capsule(g, float3_0, float3 { randf_range(rng, -0.05, 0.05), randf_range(rng, -0.03, 0.03), TALL_H }, r, r * 0.62, VG_BARK)
    vg_cylinder(g, float3_0, float3 { 0.0, 0.0, 0.1 }, r * 1.7, r, VG_BARK)
    // dead snags: thin, short, drooping a little, more of them higher up
    for(11) n:
        let z = 0.5 + pow(float(n) / 11.0, 0.8) * (TALL_H - 0.8) + randf_range(rng, -0.12, 0.12)
        let a = randf_range(rng, 0.0, 360.0)
        let l = randf_range(rng, 0.1, 0.3)
        let tip = float3 { cos(a) * l, sin(a) * l, z - l * randf_range(rng, 0.05, 0.3) }
        vg_capsule(g, float3 { 0.0, 0.0, z }, tip, 0.011, 0.006, VG_BARK)
        if n % 3 == 0: vg_capsule(g, tip * 0.6 + float3 { 0.0, 0.0, z * 0.4 }, tip + float3 { 0.03, -0.02, -0.06 }, 0.006, 0.005, VG_BARK)
    return g

// A young spruce, whole.
def young_spruce(look:vglook, kind:int) -> vgrid:
    // (one and a half to two and a half men tall: whorls of drooping boughs, each a twig with needles in dabs)
    let rng = grng(940 + kind)
    let h = 0.55 + float(kind) * 0.3
    let g = vg_new(look, float3 { -0.3, -0.3, 0.0 }, float3 { 0.3, 0.3, h + 0.1 }, VOX_K, 940 + kind)
    vg_capsule(g, float3_0, float3 { 0.0, 0.0, h }, 0.018, 0.006, VG_BARK)
    var z = 0.07
    while z < h:
        let t = z / h
        let reach = (0.17 + float(kind) * 0.04) * pow(1.0 - t, 0.8) + 0.015
        let n = if t > 0.8: 4 else: 7
        let turn = randf_range(rng, 0.0, 360.0)
        for(n) i:
            let a = turn + float(i) * 360.0 / float(n) + randf_range(rng, -12.0, 12.0)
            let l = reach * randf_range(rng, 0.8, 1.1)
            let droop = l * (0.45 - t * 0.5)
            let tone = randf_range(rng, -0.5, 0.5)
            for(5) k:
                let u = float(k + 1) / 5.0
                let at = float3 { cos(a) * l * u, sin(a) * l * u, z - droop * u * u + (if k == 4: droop * 0.15 else: 0.0) }
                vg_capsule(g, at, at + float3 { 0.0, 0.0, 0.004 }, 0.02 * (1.0 - u * 0.45), 0.016 * (1.0 - u * 0.45), VG_LEAF, false, tone + (if k % 2 == 0: 0.2 else: -0.2))
        z += 0.055 + 0.03 * t
    return g

def tree_stump(look:vglook) -> vgrid:
    let g = vg_new(look, float3 { -0.3, -0.3, 0.0 }, float3 { 0.3, 0.3, 0.3 }, VOX_K, 990)
    // (a young beech's stump: a third of a man high, as thick as its trunk was)
    vg_cylinder(g, float3_0, float3 { 0.0, 0.0, 0.1 }, 0.04, 0.03, VG_BARK)
    vg_cylinder(g, float3 { 0.0, 0.0, 0.1 }, float3 { 0.0, 0.0, 0.115 }, 0.03, 0.03, VG_WOOD, true)
    return g

// What is left when the men have felled a young tree and sawn it up (#6, D-068): its top and boughs, lopped and
// lying where it fell, the leaves withering on them, and a round or two sawn off the trunk that they have not carried
// away. Beside every stump.
let BRASH_KINDS = 2
def brash(look:vglook, kind:int) -> vgrid:
    let rng = grng(1600 + kind)
    let g = vg_new(look, float3 { -0.6, -0.6, 0.0 }, float3 { 0.6, 0.6, 0.3 }, VOX_K, 1600 + kind)
    let a = randf_range(rng, 0.0, 360.0)
    let d = float3 { cos(a), sin(a), 0.0 }
    let side = float3 { -sin(a), cos(a), 0.0 }
    // the lopped top: a thin pole with its boughs, lying
    let base = d * -0.35 + float3 { 0.0, 0.0, 0.025 }
    let tip = d * 0.45 + float3 { 0.0, 0.0, 0.02 }
    vg_capsule(g, base, tip, 0.025, 0.008, VG_BARK)
    vg_cylinder(g, base - d * 0.01, base, 0.024, 0.024, VG_WOOD, true)
    let rough = vg_field(g, 0.1, 1601 + kind)
    for(7) n:
        let t = randf_range(rng, 0.15, 0.95)
        let at = base + (tip - base) * t
        let s = if n % 2: 1.0 else: -1.0
        let out = at + (d * randf_range(rng, 0.05, 0.15) + side * s * randf_range(rng, 0.12, 0.24)) + float3 { 0.0, 0.0, randf_range(rng, 0.0, 0.06) }
        vg_capsule(g, at, out, 0.009, 0.004, VG_BARK)
        vg_blob(g, out, 0.045, 1.6, 0.6, rough, VG_LEAF, randf_range(rng, -0.5, 0.3), 0.35, nil, 0.0)
    // rounds sawn off the trunk, one on its side
    let r0 = base + side * 0.22 - d * 0.1
    vg_cylinder(g, float3 { r0.x, r0.y, 0.0 }, float3 { r0.x, r0.y, 0.07 }, 0.035, 0.035, VG_BARK)
    vg_cylinder(g, float3 { r0.x, r0.y, 0.07 }, float3 { r0.x, r0.y, 0.078 }, 0.032, 0.032, VG_WOOD, true)
    if kind == 1:
        let r1 = r0 + side * 0.09 + d * 0.05 + float3 { 0.0, 0.0, 0.035 }
        vg_cylinder(g, r1 - d * 0.035, r1 + d * 0.035, 0.035, 0.035, VG_BARK)
        vg_cylinder(g, r1 + d * 0.035, r1 + d * 0.042, 0.032, 0.032, VG_WOOD, true)
    return g

// ------------------------------------------------------------------ trees made as .vox (D-035)
// A tree designed in 2D (art/trees/design/) and made as a voxel model (art/trees/vox/, tools/tree_vox.py). Its palette
// index says what each voxel is: 1..4 bark, 10 leaves lit from above, 11 mid, 12 their underside. The model is baked
// as two pictures, its wood and its leaves, so the leaves can be coloured by the season and fade over a man.
// An old tree's three looks are two old models and a mature one.
def vox_name(sp:string, kind:int) -> string: return sp + [ "_old_0", "_old_1", "_mature_0" ][kind]
var vox_feet = []::string  // art/trees/vox/feet.txt, in tokens: name, x, y, ...

// A model's pieces (a .vox model is 256 voxels a side at most: tools/tree_vox.py saves a bigger tree in pieces).
def vox_pieces(name:string) -> [string], [int3]:
    let files = []
    let offs = []
    for(2) z: for(2) y: for(2) x:
        let f = read_file("../art/trees/vox/{name}" + (if x + y + z == 0: "" else: ".c{x}{y}{z}") + ".vox")
        if f:
            files.push(f)
            offs.push(int3 { x, y, z } * 256)
    return files, offs

def vox_tree_text() -> string:
    var t = read_file("../art/trees/vox/feet.txt") or ""
    let names = tokenize(t, " \n", "")
    for(names.length / 3) i:
        let files = vox_pieces(names[i * 3])
        for(files) f: t += sha256_text(f)
    return sha256_text(t)

// leaves: the model's leaves alone, or its wood alone.
def vox_tree(look:vglook, name:string, leaves:bool, cling:bool = false) -> vgrid:
    if not vox_feet.length: vox_feet = tokenize(read_file("../art/trees/vox/feet.txt") or "", " \n", "")
    let at = find(vox_feet): _ == name
    assert at >= 0
    let foot = int3 { string_to_int(vox_feet[at + 1]), string_to_int(vox_feet[at + 2]), 0 }
    let files, offs = vox_pieces(name)
    assert files.length > 0
    let models = map(files) f:
        let v = vox_parse(f)
        assert v.error == "" and v.models.length == 1
        v.models[0]
    var size = int3_0
    for(models) m, k: size = max(size, m.size + offs[k])
    let g = vg_new(look, float(int3_0 - foot - int3_1) / VOX_K, float(size - foot + int3_1) / VOX_K, VOX_K, 2000 + at)
    for(models) m, k:
        for(m.xyz) p, i:
            let idx = m.idx[i]
            let q = p + offs[k] - foot - g.lo
            // (13, 14: the leaves that cling after leaf-fall; cling: only those, on the bare twigs)
            if leaves and idx >= (if cling: 13 else: 10): vg_set(g, vg_index(g, q.x, q.y, q.z), VG_LEAF, if idx == 10 or idx == 13: 0.5 elif idx == 11: 0.0 else: -0.6)
            elif not leaves and idx < 10: vg_set(g, vg_index(g, q.x, q.y, q.z), VG_BARK, 0.0)
    return g

// ------------------------------------------------------------------ the undergrowth (issue #8), grey-boxed
let FERN_KINDS = 3
let BUSH_KINDS = 2
let LOG_KINDS = 2

// The undergrowth is made as fine as the .vox trees (sizes in tiles).
def fine_grid(look:vglook, reach:float, h:float, seed:int) -> vgrid:
    return vg_new(look, float3 { -reach, -reach, 0.0 }, float3 { reach, reach, h }, VOX_K, seed)

// One leaf: a dab two or three voxels across (c and r in tiles).
def leaf_dab(g:vgrid, c:float3, r:float, tone:float):
    vg_capsule(g, c, c + float3 { 0.0, 0.0, r * 0.2 }, r, r * 0.8, VG_LEAF, false, tone)

def twig(g:vgrid, a:float3, b:float3, r:float, m:int, tone:float):
    vg_capsule(g, a, b, r, r * 0.8, m, false, tone)

// A fern (bracken): fronds arching out from one foot and drooping at their tips, each a rib with leaflets down both
// sides, shorter toward the tip.
def fern(look:vglook, kind:int) -> vgrid:
    let rng = grng(1300 + kind)
    let g = fine_grid(look, 0.42, 0.34, 1300 + kind)
    let n = 6 + kind
    for(n) i:
        let a = float(i) * 360.0 / float(n) + randf_range(rng, -20.0, 20.0)
        let reach = randf_range(rng, 0.22, 0.34)
        let rise = randf_range(rng, 0.13, 0.2)
        let d = float3 { cos(a), sin(a), 0.0 }
        let side = float3 { -sin(a), cos(a), 0.0 }
        let tone = randf_range(rng, -0.5, 0.6)
        var last = float3_0
        let steps = 9
        for(steps) k:
            let t = float(k + 1) / float(steps)
            // (up fast, then over and down a little at the tip)
            let at = d * (reach * t) + float3 { 0.0, 0.0, rise * sin(t * 125.0) + 0.02 }
            twig(g, last, at, 0.008, VG_LEAF, tone - 0.3)
            let w = 0.075 * (1.0 - t * 0.85) * (if t < 0.25: t * 4.0 else: 1.0)
            if w > 0.012:
                for(2) sd:
                    let out = side * (if sd == 0: w else: -w)
                    twig(g, at, at + out + float3 { 0.0, 0.0, -w * 0.25 }, 0.011, VG_LEAF, tone + (if sd == 0: 0.2 else: -0.1))
            last = at
    return g

// A low bush: a few stems, and its leaves as dabs in clusters at their ends.
def bush(look:vglook, kind:int) -> vgrid:
    // stems that fan from the foot and show, each ending in a few twigs with leaves at their tips (not a ball of leaf)
    let rng = grng(1400 + kind)
    let g = fine_grid(look, 0.46, 0.52, 1400 + kind)
    for(5 + kind * 2):
        let a = randf_range(rng, 0.0, 360.0)
        let out = randf_range(rng, 0.06, 0.24)
        let c = float3 { cos(a) * out, sin(a) * out, randf_range(rng, 0.14, 0.34) }
        let foot = float3 { c.x * 0.15, c.y * 0.15, 0.0 }
        twig(g, foot, c, 0.011, VG_BARK, 0.0)
        let tone = randf_range(rng, -0.5, 0.7)
        for(3):
            let t = c + float3 { randf_range(rng, -0.09, 0.09), randf_range(rng, -0.09, 0.09), randf_range(rng, -0.02, 0.09) }
            twig(g, foot + (c - foot) * randf_range(rng, 0.5, 0.9), t, 0.007, VG_BARK, 0.0)
            for(4):
                let p = t + float3 { randf_range(rng, -0.035, 0.035), randf_range(rng, -0.035, 0.035), randf_range(rng, -0.02, 0.03) }
                leaf_dab(g, p, randf_range(rng, 0.014, 0.021), tone + randf_range(rng, -0.3, 0.3))
    return g

// A bramble (#8): long canes that arch up out of one foot and come down to the ground again a tile away, crossing each
// other, their leaves in threes along them. A tangle you see through, lower than a man's waist, broader than a bush.
let BRAMBLE_KINDS = 2
def bramble(look:vglook, kind:int) -> vgrid:
    let rng = grng(1480 + kind)
    let g = fine_grid(look, 0.62, 0.36, 1480 + kind)
    for(7 + kind * 3):
        let a = randf_range(rng, 0.0, 360.0)
        let foot = float3 { randf_range(rng, -0.1, 0.1), randf_range(rng, -0.1, 0.1), 0.0 }
        let reach = randf_range(rng, 0.28, 0.52)
        let rise = randf_range(rng, 0.07, 0.17)
        let bend = randf_range(rng, -0.12, 0.12)
        let d = float3 { cos(a), sin(a), 0.0 }
        let side = float3 { -sin(a), cos(a), 0.0 }
        let tone = randf_range(rng, -0.5, 0.5)
        var last = foot
        let steps = 12
        for(steps) k:
            let t = float(k + 1) / float(steps)
            let at = foot + d * (reach * t) + side * (bend * sin(t * 180.0)) + float3 { 0.0, 0.0, max(0.0, rise * sin(t * 170.0)) }
            twig(g, last, at, 0.0066, VG_BARK, -0.2)
            if randf(rng) < 0.85:
                // (a leaf of three on a short stalk, to one side)
                let stalk = at + side * (if k % 2: 0.032 else: -0.032) + float3 { 0.0, 0.0, 0.014 }
                for(3) l: leaf_dab(g, stalk + float3 { randf_range(rng, -0.02, 0.02), randf_range(rng, -0.02, 0.02), randf_range(rng, 0.0, 0.014) }, randf_range(rng, 0.016, 0.022), tone + float(l) * 0.25 - 0.2)
            last = at
    return g

// The bramble's canes are dark red purple; its leaves stay on late, dark green going wine red in autumn.
def bramble_look(season:string, kind:int) -> vglook:
    var leaf = [ float3 { 0.34, 0.50, 0.20 }, float3 { 0.22, 0.38, 0.16 }, float3 { 0.13, 0.24, 0.12 }, float3 { 0.46, 0.58, 0.24 } ]
    if season == "autumn" and kind == 1: leaf = [ float3 { 0.62, 0.24, 0.16 }, float3 { 0.44, 0.30, 0.15 }, float3 { 0.24, 0.26, 0.12 }, float3 { 0.74, 0.40, 0.18 } ]
    if season == "autumn" and kind == 0: leaf = [ float3 { 0.42, 0.46, 0.18 }, float3 { 0.28, 0.36, 0.15 }, float3 { 0.36, 0.18, 0.12 }, float3 { 0.60, 0.52, 0.22 } ]
    return vglook { leaf, [ float3 { 0.22, 0.11, 0.13 }, float3 { 0.31, 0.15, 0.17 }, float3 { 0.40, 0.20, 0.21 }, float3 { 0.50, 0.27, 0.26 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, false, false }

// A patch of low herbs: many small pale leaves on short stems, ragged at its edge (the pale drifts of the target
// picture's clearing).
let HERB_KINDS = 3
def herbs(look:vglook, kind:int) -> vgrid:
    // (no stems that show: small leaves close to the ground, thick at a lobe's middle and thinning to single plants)
    let rng = grng(1450 + kind)
    let g = fine_grid(look, 0.5, 0.2, 1450 + kind)
    let lobes = 3 + kind
    for(lobes):
        let lc = float3 { randf_range(rng, -0.2, 0.2), randf_range(rng, -0.2, 0.2), 0.0 }
        let lr = randf_range(rng, 0.14, 0.27)
        for(int(lr * 150.0)):
            let a = randf_range(rng, 0.0, 360.0)
            let rr = lr * randf(rng)
            let low = randf(rng) < 0.35
            let top = lc + float3 { cos(a) * rr, sin(a) * rr, if low: 0.012 else: randf_range(rng, 0.025, 0.07) }
            if abs(top.x) < 0.47 and abs(top.y) < 0.47:
                leaf_dab(g, top, randf_range(rng, 0.008, 0.013), if low: randf_range(rng, -0.9, -0.4) else: randf_range(rng, -0.2, 0.8))
    return g

// A tuft of soft grass (Dominic, 2026-11-11: "missing all the soft grass"): the mock-up's clearing is full of pale
// upright tufts standing out of the fallen leaves, shin to knee high, dark at the foot and straw yellow at the tips.
// Many thin stems from one foot, leaning a little apart, a small leaf or two up each. Many stand close in a drift.
let TUFT_KINDS = 6
def grass_tuft(look:vglook, kind:int) -> vgrid:
    let rng = grng(1470 + kind)
    let g = fine_grid(look, 0.2, 0.16, 1470 + kind)
    // (low: ankle to shin high, as the mock-up's drifts are; the review of 2026-11-11: "about half the height, with a
    // dark green base under the pale tips")
    let tall = 0.034 + 0.01 * float(kind % 3)
    // the base: short dark blades close to the ground, thick at the middle and ragged at the edge
    for(26 + (kind % 2) * 8):
        let a = randf_range(rng, 0.0, 360.0)
        let rr = 0.13 * sqrt(randf(rng))
        let at = float3 { cos(a) * rr, sin(a) * rr, randf_range(rng, 0.004, 0.016) }
        leaf_dab(g, at, 0.0066, randf_range(rng, -1.0, -0.55))
    // (airy: single stems a voxel thick standing a little apart over a hand's breadth of ground, so tufts side by
    // side run into one soft mass and no tuft is a ball)
    for(13 + (kind % 2) * 4):
        let foot = float3 { randf_range(rng, -0.12, 0.12), randf_range(rng, -0.12, 0.12), 0.0 }
        let a = randf_range(rng, 0.0, 360.0)
        let lean = randf_range(rng, 0.004, 0.022)
        let top = foot + float3 { cos(a) * lean, sin(a) * lean, tall * randf_range(rng, 0.5, 1.2) }
        let steps = 6
        for(steps) n:
            let u = float(n) / float(steps - 1)
            // (a stem bows out as it rises; dark at the foot, pale at the tip)
            let p = foot + (top - foot) * u + float3 { cos(a), sin(a), 0.0 } * lean * 0.5 * u * u
            leaf_dab(g, p, 0.0064, -0.9 + 1.5 * u * u + randf_range(rng, -0.1, 0.1))
        // its pale head: a dab or two at the tip (the mock-up's yellow dots over the olive)
        leaf_dab(g, top + float3 { 0.0, 0.0, 0.004 }, 0.009, randf_range(rng, 0.7, 1.0))
        if randf(rng) < 0.5: leaf_dab(g, top + float3 { randf_range(rng, -0.014, 0.014), randf_range(rng, -0.014, 0.014), -0.004 }, 0.0076, randf_range(rng, 0.4, 0.9))
    return g

// The soft grass' colours: straw yellow tips over olive in autumn, fresh green in spring and summer.
def tuft_look(season:string, kind:int) -> vglook:
    // (late summer: one fresh, one deep green, one gone straw; warmer than the crowns over them)
    var leaf = [ [ float3 { 0.54, 0.64, 0.28 }, float3 { 0.36, 0.48, 0.20 }, float3 { 0.19, 0.29, 0.13 }, float3 { 0.70, 0.76, 0.40 } ],
                 [ float3 { 0.46, 0.60, 0.30 }, float3 { 0.30, 0.44, 0.21 }, float3 { 0.16, 0.27, 0.13 }, float3 { 0.60, 0.70, 0.40 } ],
                 [ float3 { 0.72, 0.70, 0.40 }, float3 { 0.52, 0.52, 0.27 }, float3 { 0.26, 0.28, 0.14 }, float3 { 0.84, 0.80, 0.54 } ] ][kind % 3]
    if season == "spring": leaf = [ float3 { 0.56, 0.70, 0.30 }, float3 { 0.38, 0.54, 0.22 }, float3 { 0.20, 0.32, 0.14 }, float3 { 0.74, 0.82, 0.42 } ]
    if season == "autumn": leaf = [ float3 { 0.86, 0.82, 0.42 }, float3 { 0.64, 0.62, 0.27 }, float3 { 0.32, 0.33, 0.14 }, float3 { 0.97, 0.94, 0.64 } ]
    if season == "autumn" and kind % 3 == 2: leaf = [ float3 { 0.70, 0.72, 0.34 }, float3 { 0.48, 0.54, 0.24 }, float3 { 0.25, 0.31, 0.14 }, float3 { 0.86, 0.86, 0.50 } ]
    return vglook { leaf, [ float3 { 0.20, 0.17, 0.14 }, float3 { 0.28, 0.24, 0.20 }, float3 { 0.37, 0.32, 0.26 }, float3 { 0.46, 0.40, 0.33 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, false, false }

// A fallen trunk, long down, moss along its top.
def fallen_log(look:vglook, kind:int) -> vgrid:
    let rng = grng(1500 + kind)
    let g = vg_new(look, float3 { -0.7, -0.7, 0.0 }, float3 { 0.7, 0.7, 0.3 }, VOX_K, 1500 + kind)
    let a = randf_range(rng, 0.0, 180.0)
    let d = float3 { cos(a), sin(a), 0.0 } * (0.45 + float(kind) * 0.15)
    let up = float3 { 0.0, 0.0, 0.055 }
    let rough = vg_field(g, 0.1, 1501 + kind)
    for(4):
        let t = randf_range(rng, -0.8, 0.8)
        vg_blob(g, d * t + float3 { 0.0, 0.0, 0.1 }, 0.05, 2.0, 0.6, rough, VG_LEAF, randf_range(rng, -0.4, 0.2), 0.2, nil, 0.0)
    vg_cylinder(g, up - d, up + d, 0.055, 0.045, VG_BARK)
    vg_cylinder(g, up - d * 1.03, up - d, 0.05, 0.05, VG_WOOD, true)
    vg_cylinder(g, up + d, up + d * 1.03, 0.04, 0.04, VG_WOOD, true)
    return g

// What lies on a wood's floor (Dominic, 2026-11-11: the ground "not rich enough yet"): a dead branch dropped from a
// crown, crooked, a finger to a wrist thick, with a side twig or two; and a stone a foot across, moss on its top.
let BRANCH_KINDS = 4
def fallen_branch(look:vglook, kind:int) -> vgrid:
    let rng = grng(1530 + kind)
    let g = fine_grid(look, 0.45, 0.1, 1530 + kind)
    let a = randf_range(rng, 0.0, 360.0)
    let l = 0.16 + 0.07 * float(kind)
    let r = 0.009 + 0.003 * float(kind % 2)
    var at = float3 { -cos(a) * l, -sin(a) * l, r }
    var turn = a
    for(4) n:
        turn += randf_range(rng, -22.0, 22.0)
        let next = at + float3 { cos(turn), sin(turn), 0.0 } * l * 0.5
        vg_capsule(g, at, next, r * (1.0 - 0.15 * float(n)), r * (0.85 - 0.15 * float(n)), VG_BARK)
        if n > 0 and randf(rng) < 0.7:
            let side = turn + (if randf(rng) < 0.5: 50.0 else: -50.0)
            vg_capsule(g, at, at + float3 { cos(side), sin(side), 0.1 } * l * randf_range(rng, 0.25, 0.45), r * 0.5, 0.004, VG_BARK)
        at = next
    return g

let STONE_KINDS = 3
def moss_stone(look:vglook, kind:int) -> vgrid:
    let rng = grng(1560 + kind)
    let g = fine_grid(look, 0.3, 0.14, 1560 + kind)
    let w = 0.05 + 0.02 * float(kind)
    let turn = randf_range(rng, 0.0, 180.0)
    rock_plate(g, float3_0, w, w * 0.7, 0.03 + 0.008 * float(kind), turn, VG_ROCK, 0.0, 0.0, 1560 + kind)
    rock_plate(g, float3 { 0.008, 0.004, 0.03 + 0.008 * float(kind) }, w * 0.7, w * 0.5, 0.014, turn + 12.0, VG_ROCK, 0.2, 0.0, 1570 + kind)
    // moss over its top, thicker on one side
    for(26 + kind * 10):
        let p = float3 { randf_range(rng, -w * 0.75, w * 0.4), randf_range(rng, -w * 0.5, w * 0.5), 0.06 + 0.008 * float(kind) }
        leaf_dab(g, p, 0.007, randf_range(rng, -0.6, 0.5))
    return g

// The undergrowth's leaves by season: bracken goes bronze and gold in autumn, the bushes yellow and red.
def under_look(season:string, kind:int, moss:bool) -> vglook:
    var leaf = [ [ float3 { 0.38, 0.58, 0.22 }, float3 { 0.24, 0.43, 0.17 }, float3 { 0.12, 0.27, 0.13 }, float3 { 0.52, 0.64, 0.26 } ],
                 [ float3 { 0.30, 0.48, 0.24 }, float3 { 0.18, 0.35, 0.18 }, float3 { 0.09, 0.21, 0.12 }, float3 { 0.42, 0.54, 0.28 } ],
                 [ float3 { 0.48, 0.60, 0.24 }, float3 { 0.32, 0.46, 0.18 }, float3 { 0.17, 0.29, 0.13 }, float3 { 0.62, 0.68, 0.30 } ] ][kind % 3]
    if season == "spring": leaf = [ float3 { 0.56, 0.74, 0.30 }, float3 { 0.40, 0.60, 0.24 }, float3 { 0.22, 0.38, 0.16 }, float3 { 0.70, 0.80, 0.40 } ]
    // (autumn: one bracken bronze, one still green, one gone pale yellow)
    if season == "autumn" and not moss and kind % 3 == 0: leaf = autumn_leaf("oak", 0)
    if season == "autumn" and not moss and kind % 3 == 2: leaf = [ float3 { 0.93, 0.86, 0.38 }, float3 { 0.74, 0.68, 0.26 }, float3 { 0.42, 0.40, 0.14 }, float3 { 0.98, 0.94, 0.56 } ]
    if moss: leaf = [ float3 { 0.36, 0.50, 0.20 }, float3 { 0.26, 0.38, 0.16 }, float3 { 0.16, 0.25, 0.12 }, float3 { 0.44, 0.52, 0.22 } ]
    return vglook { leaf, [ float3 { 0.20, 0.17, 0.14 }, float3 { 0.28, 0.24, 0.20 }, float3 { 0.37, 0.32, 0.26 }, float3 { 0.46, 0.40, 0.33 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, false, false }

// The low herbs: pale yellow green, paler still in autumn.
def herb_look(season:string, kind:int) -> vglook:
    var leaf = [ float3 { 0.66, 0.76, 0.34 }, float3 { 0.46, 0.60, 0.26 }, float3 { 0.24, 0.36, 0.16 }, float3 { 0.80, 0.84, 0.44 } ]
    // (summer: one patch pale and silvery, one warm, one the herbs' own green)
    if season == "summer" and kind == 0: leaf = [ float3 { 0.62, 0.70, 0.50 }, float3 { 0.44, 0.52, 0.36 }, float3 { 0.22, 0.30, 0.20 }, float3 { 0.76, 0.80, 0.60 } ]
    if season == "summer" and kind == 1: leaf = [ float3 { 0.66, 0.70, 0.38 }, float3 { 0.48, 0.54, 0.27 }, float3 { 0.25, 0.31, 0.15 }, float3 { 0.80, 0.80, 0.50 } ]
    if season == "autumn": leaf = [ float3 { 0.80, 0.79, 0.30 }, float3 { 0.60, 0.65, 0.25 }, float3 { 0.31, 0.38, 0.15 }, float3 { 0.91, 0.87, 0.42 } ]
    if season == "autumn" and kind == 2: leaf = [ float3 { 0.74, 0.78, 0.36 }, float3 { 0.52, 0.60, 0.26 }, float3 { 0.28, 0.36, 0.15 }, float3 { 0.86, 0.86, 0.46 } ]
    return vglook { leaf, [ float3 { 0.20, 0.17, 0.14 }, float3 { 0.28, 0.24, 0.20 }, float3 { 0.37, 0.32, 0.26 }, float3 { 0.46, 0.40, 0.33 } ],
                    [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, false, false }

// A slab of rock: about w by d by th, turned by `turn` degrees about c, its foot at c.z, its outline broken (no two
// alike, none square), and dipping: its bed rises `dip` for each tile along its length, as gneiss beds lie tilted.
def rock_plate(g:vgrid, c:float3, w:float, d:float, th:float, turn:float, m:int, tone:float, dip:float = 0.0, seed:int = 0):
    let reach = max(w, d) * 1.4
    let rise = abs(dip) * reach
    let p1 = float(seed % 360)
    let p2 = float((seed / 7) % 360)
    vg_box(g, float3 { c.x - reach, c.y - reach, c.z - rise }, float3 { c.x + reach, c.y + reach, c.z + th + rise }) i, p:
        let u = (p.x - c.x) * cos(turn) + (p.y - c.y) * sin(turn)
        let v = -(p.x - c.x) * sin(turn) + (p.y - c.y) * cos(turn)
        let a = atan2(float2 { u / w, v / d })
        let edge = 1.0 + 0.16 * sin(a * 3.0 + p1) + 0.1 * sin(a * 5.0 + p2) + 0.06 * sin(a * 9.0 + p1 * 2.0)
        let z = p.z - u * dip
        // (blunt corners, not round ones: a slab breaks along joints)
        if pow(abs(u / w), 8.0) + pow(abs(v / d), 8.0) < pow(edge, 8.0) * 0.8 and z >= c.z and z < c.z + th and p.z >= 0.0: vg_set(g, i, m, tone)

// A gneiss outcrop: many thin beds lying one on another and dipping the same way, each stepping back and a little
// turned, a man or two high (the rock splits along its bedding: that's what makes it a building stone).
def outcrop(look:vglook, kind:int) -> vgrid:
    let rng = grng(1100 + kind)
    let beds = [ 7, 9, 12, 5 ][kind]
    let g = vg_new(look, float3 { -0.95, -0.95, 0.0 }, float3 { 0.95, 0.95, 1.1 }, VOX_K, 1100 + kind)
    var z = 0.0
    var c = float2 { 0.0, 0.0 }
    var w = randf_range(rng, 0.55, 0.7)
    var d = randf_range(rng, 0.42, 0.56)
    let turn0 = randf_range(rng, -25.0, 25.0)
    let dip = randf_range(rng, 0.12, 0.3) * (if kind % 2: 1.0 else: -1.0)
    for(beds) n:
        let th = randf_range(rng, 0.035, 0.085)
        rock_plate(g, float3 { c.x, c.y, z }, w, d, th, turn0 + randf_range(rng, -7.0, 7.0), VG_ROCK, randf_range(rng, -0.4, 0.4), dip, 1100 + kind * 31 + n * 97)
        z += th
        c += float2 { randf_range(rng, -0.1, 0.06), randf_range(rng, -0.07, 0.07) }
        w *= randf_range(rng, 0.8, 0.97)
        d *= randf_range(rng, 0.8, 0.97)
    // blocks that have come off it
    for(3) n:
        let at = float3 { randf_range(rng, 0.4, 0.75) * (if n == 1: -1.0 else: 1.0), randf_range(rng, -0.6, 0.6), 0.0 }
        rock_plate(g, at, randf_range(rng, 0.06, 0.13), randf_range(rng, 0.05, 0.1), randf_range(rng, 0.03, 0.07), randf_range(rng, 0.0, 180.0), VG_ROCK, 0.1, randf_range(rng, -0.3, 0.3), 1190 + n)
    return g

// A crag at a cliff's foot (#20): a buttress of the same beds standing against the face, most of the face's height,
// narrow from front to back and broad along the face (`turn` 0: a face that runs along x; 90: along y). It breaks the
// straight foot and the square corners of a cliff made of whole tiles.
def crag(look:vglook, kind:int, turn:float) -> vgrid:
    let rng = grng(1500 + kind)
    let g = vg_new(look, float3 { -0.95, -0.95, 0.0 }, float3 { 0.95, 0.95, 1.2 }, VOX_K, 1500 + kind)
    let top = [ 0.95, 0.7, 0.45, 1.1 ][kind]
    let dip = randf_range(rng, 0.1, 0.24) * (if kind % 2: 1.0 else: -1.0)
    var z = 0.0
    var c = float2 { 0.0, 0.0 }
    var w = randf_range(rng, 0.36, 0.5)
    var d = randf_range(rng, 0.2, 0.26)
    var n = 0
    while z < top:
        let th = randf_range(rng, 0.09, 0.24)
        let at = if turn > 45.0: float3 { c.y, c.x, z } else: float3 { c.x, c.y, z }
        rock_plate(g, at, w, d, th, turn + randf_range(rng, -9.0, 9.0), VG_ROCK, randf_range(rng, -0.9, -0.3), dip, 1500 + kind * 31 + n * 97)
        z += th
        n++
        // (it leans back to the face as it rises, and now and then a bed steps in or juts)
        c += float2 { randf_range(rng, -0.05, 0.05), randf_range(rng, -0.03, 0.0) }
        w = clamp(w * randf_range(rng, 0.8, 1.1), 0.2, 0.5)
        d = clamp(d * randf_range(rng, 0.88, 1.04), 0.12, 0.26)
    // what has come off it lies at its foot
    for(4) k:
        let side = if k % 2: -1.0 else: 1.0
        let u = randf_range(rng, 0.3, 0.7) * side
        let v = randf_range(rng, 0.05, 0.45)
        let at = if turn > 45.0: float3 { v, u, 0.0 } else: float3 { u, v, 0.0 }
        rock_plate(g, at, randf_range(rng, 0.06, 0.15), randf_range(rng, 0.05, 0.11), randf_range(rng, 0.03, 0.09), randf_range(rng, 0.0, 180.0), VG_ROCK, 0.1, randf_range(rng, -0.3, 0.3), 1590 + k)
    return g

// A timber bridge over a river (#20), a tile of it at a time, its deck running along x: two round beams from bank to
// bank on trestle posts, split planks laid across them. part 0: a whole tile of deck. part 1, 2: what is left at the
// west and the east bank when it is broken: the beams' stumps, a few planks, one hanging.
def bridge_part(look:vglook, part:int) -> vgrid:
    let rng = grng(1700 + part)
    let g = vg_new(look, float3 { -0.6, -0.6, 0.0 }, float3 { 0.6, 0.6, 0.5 }, VOX_K, 1700 + part)
    def timber(lo:float3, hi:float3, tone:float):
        vg_box(g, lo, hi) i, p:
            if p.x >= lo.x and p.x < hi.x and p.y >= lo.y and p.y < hi.y and p.z >= lo.z and p.z < hi.z: vg_set(g, i, VG_BARK, tone)
    // (how far the deck still runs along this tile: all of it, or a bank's end of it)
    let x0 = if part == 2: 0.12 else: -0.5
    let x1 = if part == 1: -0.12 else: 0.5
    let top = 0.2
    for([ -0.3, 0.3 ]) y:
        vg_cylinder(g, float3 { x0, y, top - 0.045 }, float3 { x1, y, top - 0.045 }, 0.04, 0.04, VG_BARK)
        // a trestle post under each beam at the bank's end (and at both ends of a whole tile)
        for([ -0.42, 0.42 ]) x: if x > x0 and x < x1: vg_cylinder(g, float3 { x, y, 0.0 }, float3 { x, y, top - 0.05 }, 0.035, 0.035, VG_BARK)
    var x = x0
    while x < x1 - 0.05:
        let wide = randf_range(rng, 0.075, 0.11)
        let over = randf_range(rng, 0.0, 0.05)
        timber(float3 { x, -0.4 - over, top }, float3 { min(x1, x + wide - 0.012), 0.4 + randf_range(rng, 0.0, 0.05), top + 0.03 }, randf_range(rng, -0.1, 0.9))
        x += wide
    if part > 0:
        // the broken end: a beam's splintered stump, a plank hanging down from it
        let bx = if part == 1: x1 else: x0
        let out = if part == 1: 1.0 else: -1.0
        vg_cylinder(g, float3 { bx, 0.3, top - 0.045 }, float3 { bx + out * 0.16, 0.3, top - 0.09 }, 0.04, 0.02, VG_BARK)
        vg_cylinder(g, float3 { bx, 0.3, top - 0.045 }, float3 { bx + out * 0.02, 0.3, top - 0.045 }, 0.035, 0.035, VG_WOOD, true)
        timber(float3 { min(bx, bx + out * 0.05), -0.38, 0.03 }, float3 { max(bx, bx + out * 0.05), -0.3, top }, 0.5)
    return g

// A landslide's debris on one tile (#20): a low heap of earth with broken rock in it at every size, from fist stones to
// a block as big as a man, lying at all angles. Its look's bark is the earth.
let RUBBLE_KINDS = 6
def rubble(look:vglook, kind:int) -> vgrid:
    let rng = grng(1250 + kind)
    // (wider than its tile, so the heaps run into one another and no tile shows)
    let g = vg_new(look, float3 { -1.0, -1.0, 0.0 }, float3 { 1.0, 1.0, 0.6 }, VOX_K, 1250 + kind)
    // the rock in it: many small, some middling, in some heaps one block as big as a man; nothing in the middle
    let bigs = if kind % 3 == 0: 1 else: 0
    let mids = 6 + (kind * 5) % 7
    for(60 + kind * 9) n:
        let big = n < bigs
        let mid = n < bigs + mids
        let sz = if big: randf_range(rng, 0.13, 0.19) elif mid: randf_range(rng, 0.05, 0.1) else: randf_range(rng, 0.016, 0.042)
        let at = float3 { randf_range(rng, -0.7, 0.7), randf_range(rng, -0.7, 0.7), randf_range(rng, 0.0, 0.05) }
        rock_plate(g, at, sz, sz * randf_range(rng, 0.5, 0.9), sz * randf_range(rng, 0.4, 0.85), randf_range(rng, 0.0, 180.0), VG_ROCK, randf_range(rng, -0.5, 0.5), randf_range(rng, -0.8, 0.8), 1300 + n * 53 + kind)
    // the earth between and under them: low rounded mounds (not plates), round the rock already lying there
    let lumpy = vg_field(g, 0.09, 1251 + kind)
    for(6):
        let at = float3 { randf_range(rng, -0.45, 0.45), randf_range(rng, -0.45, 0.45), 0.0 }
        let r = randf_range(rng, 0.2, 0.4)
        vg_blob(g, at, r, randf_range(rng, 3.0, 5.0), 0.5, lumpy, VG_BARK, randf_range(rng, -0.5, 0.4), 0.0, nil, 0.0)
    return g

// Loose slabs split from the rock: the stone a wall or a roof is made of.
def slab_pile(look:vglook, kind:int) -> vgrid:
    let rng = grng(1200 + kind)
    let g = vg_new(look, float3 { -0.5, -0.5, 0.0 }, float3 { 0.5, 0.5, 0.4 }, VOX_K, 1200 + kind)
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
    g.k = g.k / LIGHT_UNITS
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

// ------------------------------------------------------------------ the Roman ruins (#17)
// What the Romans left on the trail (D-067): a paved road, a drain, the stubs of walls and columns, columns fallen in
// their drums. Their stone is a pale limestone, worked square, not the gneiss's split beds; the walls have courses of
// red brick between the stone, as Roman walls in Thrace do. Moss and ivy grow on them (the rock light adds lichen on
// their tops and moss low on their shaded sides); the undergrowth round them turns with the year as everywhere else.
let RUIN_KINDS = 2
let PAVING_KINDS = 4

def fract1(x:float) -> float: return x - floor(x)

def roman_look() -> vglook:
    return vglook { [ float3 { 0.30, 0.42, 0.18 }, float3 { 0.20, 0.31, 0.14 }, float3 { 0.11, 0.19, 0.10 }, float3 { 0.42, 0.48, 0.22 } ],
                    [ float3 { 0.33, 0.16, 0.11 }, float3 { 0.47, 0.24, 0.15 }, float3 { 0.60, 0.33, 0.21 }, float3 { 0.70, 0.43, 0.29 } ],
                    [ float3 { 0.35, 0.33, 0.29 }, float3 { 0.46, 0.43, 0.38 }, float3 { 0.57, 0.53, 0.46 }, float3 { 0.67, 0.63, 0.55 }, float3 { 0.77, 0.73, 0.64 } ],
                    false, false, false }

// (u along the thing, v across it: `along_y` turns it to run along the map's y)
def ruin_uv(p:float3, along_y:bool) -> float2: return if along_y: float2 { p.y, -p.x } else: float2 { p.x, p.y }

// A broken top: how high the stone still stands at u, between lo and hi, ragged.
def broken_top(u:float, lo:float, hi:float, seed:int) -> float:
    let a = float(seed % 97)
    let t = 0.5 + 0.3 * sin(u * 290.0 + a) + 0.2 * sin(u * 745.0 + a * 2.0)  // (degrees)
    return lo + (hi - lo) * clamp(t, 0.0, 1.0)

// A column still standing on its square base, its shaft fluted and its top broken off.
def column_stub(look:vglook, kind:int) -> vgrid:
    let rng = grng(2100 + kind)
    let tall = [ 1.2, 0.5 ][kind]
    let g = vg_new(look, float3 { -0.4, -0.4, 0.0 }, float3 { 0.4, 0.4, tall + 0.1 }, VOX_K, 2100 + kind)
    let r = 0.105
    let lean = float2 { randf_range(rng, -0.02, 0.02), randf_range(rng, -0.02, 0.02) }
    vg_box(g, float3 { -0.4, -0.4, 0.0 }, float3 { 0.4, 0.4, tall + 0.1 }) i, p:
        let base = abs(p.x) < 0.17 and abs(p.y) < 0.17 and p.z < 0.07
        let torus = p.z >= 0.07 and p.z < 0.11 and magnitude(float2 { p.x, p.y }) < r + 0.025
        let q = float2 { p.x, p.y } - lean * (p.z / tall)
        let a = atan2(q)
        let flute = 0.008 * max(0.0, cos(a * 20.0))
        let top = broken_top(a / 60.0, tall * 0.8, tall, 2100 + kind)
        if base: vg_set(g, i, VG_ROCK, 0.1)
        elif torus: vg_set(g, i, VG_ROCK, 0.0)
        elif p.z >= 0.11 and p.z < top and magnitude(q) < r - flute: vg_set(g, i, VG_ROCK, -0.1)
    // (ivy up its shaded side)
    for(18):
        let z = randf_range(rng, 0.05, tall * 0.7)
        let a = randf_range(rng, 120.0, 240.0)
        vg_capsule(g, float3 { cos(a) * (r + 0.01), sin(a) * (r + 0.01), z }, float3 { cos(a) * (r + 0.02), sin(a) * (r + 0.02), z + 0.05 }, 0.02, 0.012, VG_LEAF)
    return g

// A column fallen in its drums, lying along the ground where it fell, one drum rolled off, and its capital.
def column_fallen(look:vglook, kind:int, along_y:bool) -> vgrid:
    let rng = grng(2200 + kind)
    let g = vg_new(look, float3 { -0.7, -0.7, 0.0 }, float3 { 0.7, 0.7, 0.35 }, VOX_K, 2200 + kind)
    let r = 0.1
    var u = -0.6
    for(3 + kind) n:
        let len = randf_range(rng, 0.24, 0.32)
        let off = if n == 1 + kind: randf_range(rng, 0.12, 0.2) else: randf_range(rng, -0.02, 0.02)
        let tilt = randf_range(rng, -0.04, 0.04)
        let a2 = float2 { u, off }
        let b2 = float2 { u + len, off + tilt }
        let a = if along_y: float3 { -a2.y, a2.x, r } else: float3 { a2.x, a2.y, r }
        let b = if along_y: float3 { -b2.y, b2.x, r } else: float3 { b2.x, b2.y, r }
        vg_cylinder(g, a, b, r, r, VG_ROCK, false, randf_range(rng, -0.2, 0.2))
        u += len + randf_range(rng, 0.01, 0.06)
    // the capital at its end: a square block, a little bigger than the shaft, on its side
    vg_box(g, float3 { -0.7, -0.7, 0.0 }, float3 { 0.7, 0.7, 0.3 }) i, p:
        let uv = ruin_uv(p, along_y)
        if uv.x > u + 0.02 and uv.x < u + 0.2 and abs(uv.y + 0.04) < 0.15 and p.z < 0.24: vg_set(g, i, VG_ROCK, 0.2)
    return g

// A tile of the paved road: big flat stones fitted to each other, a few gone and the ground showing, kerbs each side.
def paving(look:vglook, kind:int, along_y:bool) -> vgrid:
    let rng = grng(2300 + kind)
    let g = vg_new(look, float3 { -0.55, -0.55, 0.0 }, float3 { 0.55, 0.55, 0.12 }, VOX_K, 2300 + kind)
    let seeds = map(9): float2 { randf_range(rng, -0.5, 0.5), randf_range(rng, -0.36, 0.36) }
    let gone = map(9): randf(rng) < 0.1 + 0.06 * float(kind)
    let lift = map(9): randf_range(rng, 0.0, 0.025)
    vg_box(g, float3 { -0.5, -0.5, 0.0 }, float3 { 0.5, 0.5, 0.12 }) i, p:
        let uv = ruin_uv(p, along_y)
        if abs(uv.y) > 0.4:
            // a kerb: long stones set on edge
            let joint = abs(fract1(uv.x * 2.2 + (if uv.y > 0.0: 0.3 else: 0.0)) - 0.5) > 0.47
            if not joint and abs(uv.y) < 0.48 and p.z < 0.07 + 0.015 * sin(uv.x * 515.0): vg_set(g, i, VG_ROCK, 0.1)
        else:
            var best = 9.0
            var next = 9.0
            var k = 0
            for(seeds) q, n:
                let d = magnitude(q - uv)
                if d < best:
                    next = best
                    best = d
                    k = n
                elif d < next: next = d
            if next - best > 0.026 and not gone[k] and p.z < 0.03 + lift[k]: vg_set(g, i, VG_ROCK, float(k % 3) * 0.15 - 0.3)
    return g

// A Roman drain: a channel of dressed stone running under the road's edge, lidded with slabs, some fallen in.
def drain(look:vglook, kind:int, along_y:bool) -> vgrid:
    let rng = grng(2400 + kind)
    let g = vg_new(look, float3 { -0.55, -0.55, 0.0 }, float3 { 0.55, 0.55, 0.2 }, VOX_K, 2400 + kind)
    let lids = map(4): randf(rng) < (if kind == 0: 0.75 else: 0.35)
    vg_box(g, float3 { -0.5, -0.5, 0.0 }, float3 { 0.5, 0.5, 0.2 }) i, p:
        let uv = ruin_uv(p, along_y)
        let block = int(floor((uv.x + 0.5) * 4.0))
        let joint = abs(fract1((uv.x + 0.5) * 4.0) - 0.5) > 0.46
        let side = abs(uv.y) > 0.07 and abs(uv.y) < 0.17
        if side and p.z < 0.1 and not joint: vg_set(g, i, VG_ROCK, if uv.y > 0.0: 0.05 else: -0.05)
        elif abs(uv.y) <= 0.07 and p.z < 0.02: vg_set(g, i, VG_ROCK, -0.3)
        elif lids[clamp(block, 0, 3)] and abs(uv.y) < 0.2 and p.z >= 0.1 and p.z < 0.135 and not joint: vg_set(g, i, VG_ROCK, 0.25)
    // a lid fallen in, aslant across the channel
    if kind == 1:
        let c = if along_y: float3 { 0.0, 0.18, 0.03 } else: float3 { 0.18, 0.0, 0.03 }
        rock_plate(g, c, 0.1, 0.17, 0.03, if along_y: 90.0 else: 0.0, VG_ROCK, 0.2, 0.25, 2490)
    return g

// The stub of a wall: courses of squared stone with a band of red brick through it, broken off at the top, ivy on it.
def wall_stub(look:vglook, kind:int, along_y:bool) -> vgrid:
    let rng = grng(2500 + kind)
    let hi = [ 0.62, 0.34 ][kind]
    let g = vg_new(look, float3 { -0.6, -0.6, 0.0 }, float3 { 0.6, 0.6, hi + 0.1 }, VOX_K, 2500 + kind)
    let course = 0.06
    let brick_lo = 0.2
    let brick_hi = 0.27
    vg_box(g, float3 { -0.6, -0.6, 0.0 }, float3 { 0.6, 0.6, hi + 0.1 }) i, p:
        let uv = ruin_uv(p, along_y)
        let top = broken_top(uv.x, hi * 0.35, hi, 2500 + kind)
        let wide = if p.z < 0.05: 0.15 else: 0.12
        if abs(uv.x) < 0.5 and abs(uv.y) < wide and p.z < top:
            if p.z >= brick_lo and p.z < brick_hi:
                let row = int(floor(p.z / 0.018))
                let bj = abs(fract1(uv.x / 0.07 + float(row % 2) * 0.5) - 0.5) > 0.42 or fract1(p.z / 0.018) < 0.18
                if not bj: vg_set(g, i, VG_BARK, 0.0)
            else:
                let row = int(floor(p.z / course))
                let len = 0.11 + 0.04 * float(row % 3)
                let jv = fract1(p.z / course) < 0.12
                let ju = abs(fract1(uv.x / len + float(row) * 0.37) - 0.5) > 0.45
                if not jv and not ju: vg_set(g, i, VG_ROCK, float(row % 4) * 0.1 - 0.15)
    // fallen stones at its foot, and ivy over its top and down its shaded face
    for(4) n:
        let u = randf_range(rng, -0.45, 0.45)
        let v = randf_range(rng, 0.17, 0.35) * (if n % 2: 1.0 else: -1.0)
        rock_plate(g, (if along_y: float3 { -v, u, 0.0 } else: float3 { u, v, 0.0 }), 0.06, 0.04, 0.05, randf_range(rng, 0.0, 90.0), VG_ROCK, 0.1, 0.0, 2580 + n)
    for(26):
        let u = randf_range(rng, -0.45, 0.45)
        let z = broken_top(u, hi * 0.35, hi, 2500 + kind) - randf_range(rng, 0.0, 0.2)
        let v = -0.13 + randf_range(rng, -0.01, 0.02)
        let a = if along_y: float3 { -v, u, z } else: float3 { u, v, z }
        vg_capsule(g, a, a + float3 { randf_range(rng, -0.04, 0.04), 0.0, -randf_range(rng, 0.02, 0.08) }, 0.022, 0.014, VG_LEAF)
    return g

def bake_ruins(rs:Sheet):
    let roman = roman_look()
    for(RUIN_KINDS) kind:
        tree_onto(rs, "column{kind}", column_stub(roman, kind), true)
        for([ false, true ]) ay:
            let d = if ay: "y" else: "x"
            tree_onto(rs, "drums{d}{kind}", column_fallen(roman, kind, ay), true)
            tree_onto(rs, "drain{d}{kind}", drain(roman, kind, ay), true)
            tree_onto(rs, "wall{d}{kind}", wall_stub(roman, kind, ay), true)
    for(PAVING_KINDS) kind: for([ false, true ]) ay: tree_onto(rs, "paving{if ay: "y" else: "x"}{kind}", paving(roman, kind, ay), true)

// What every season shares: trunks, the evergreens' crowns, bare young trees, the stump, the rock, the load of wood.
// between(): so the window can draw.
def bake_trees(between):
    tree_draw_k = WB_PX / ART_K / TREE_K
    let t0 = seconds_elapsed()
    let beech = beech_look("summer")
    let spruce = spruce_look()
    let pine = pine_look()
    // the broadleaves' wood, and what stands or lies under them
    let vs = sheet_new("wood", "{TREE_BAKE} {VOX_K} {WB_PX} {vox_tree_text()}", 4096)
    if not sheet_load(vs, vox_draw_k()):
        for(BROADLEAVES) sp: for(LEAF_KINDS) kind:
            tree_onto(vs, "{sp}{kind}", vox_tree(leaf_look(sp, "summer", kind), vox_name(sp, kind), false), true)
            between()
        for(YOUNG_KINDS) kind: tree_onto(vs, "young{kind}.bare", vox_tree(beech, "beech_young_{kind}", false), true)
        tree_onto(vs, "stump", tree_stump(beech), true)
        let withered = [ float3 { 0.62, 0.42, 0.20 }, float3 { 0.48, 0.32, 0.16 }, float3 { 0.30, 0.21, 0.12 }, float3 { 0.70, 0.55, 0.30 } ]
        for(BRASH_KINDS) kind: tree_onto(vs, "brash{kind}", brash(dead_look(withered, false), kind), true)
        for(LOG_KINDS) kind: tree_onto(vs, "log{kind}", fallen_log(under_look("summer", kind, true), kind), true)
        for(BRANCH_KINDS) kind: tree_onto(vs, "branch{kind}", fallen_branch(leaf_look("oak", "summer", 0), kind), true)
        sheet_finish(vs, vox_draw_k(), true)
        trees_bake_s = seconds_elapsed() - t0
    // the evergreens, whole, and the deep wood's trunks
    let cs = sheet_new("conifers", "{TREE_BAKE} {VOX_K} {WB_PX} {vox_tree_text()}", 4096)
    if not sheet_load(cs, vox_draw_k()):
        for(LEAF_KINDS) kind:
            tree_onto(cs, "pine{kind}", vox_tree(pine, vox_name("pine", kind), false), true)
            tree_onto(cs, "pine{kind}.crown.ever", vox_tree(pine, vox_name("pine", kind), true), true, 0.6)
            tree_onto(cs, "spruce{kind}", vox_tree(spruce, vox_name("spruce", kind), false), true)
            tree_onto(cs, "spruce{kind}.crown.ever", vox_tree(spruce, vox_name("spruce", kind), true), true, 0.8)
            tree_onto(cs, "tall{kind}", tall_trunk(spruce, kind), true, 0.5, 0.22)
            between()
        for(YOUNG_KINDS) kind: tree_onto(cs, "yspruce{kind}", young_spruce(spruce, kind), true)
        sheet_finish(cs, vox_draw_k(), true)
        trees_bake_s = seconds_elapsed() - t0
    // the Rhodopes' other conifers (#6): silver fir and black pine, each its own shape
    let fs = sheet_new("conifers2", "{TREE_BAKE} {VOX_K} {WB_PX} {vox_tree_text()}", 4096)
    if not sheet_load(fs, vox_draw_k()):
        for(OTHER_CONIFERS) sp: for(LEAF_KINDS) kind:
            let look = if sp == "fir": fir_look() else: bpine_look()
            tree_onto(fs, "{sp}{kind}", vox_tree(look, vox_name(sp, kind), false), true)
            tree_onto(fs, "{sp}{kind}.crown.ever", vox_tree(look, vox_name(sp, kind), true), true, if sp == "fir": 0.8 else: 0.6)
            between()
        sheet_finish(fs, vox_draw_k(), true)
        trees_bake_s = seconds_elapsed() - t0
    let rs = sheet_new("rocks", "{TREE_BAKE} {VOX_K} {WB_PX}", 2048)
    let ls = sheet_new("load", "{TREE_BAKE} {TREE_K} {WB_PX}", 256)
    // (the load is baked finer still: a sheet of its own, drawn at its own size)
    if not sheet_load(ls, tree_draw_k / 2.0):
        tree_onto(ls, "load.wood", wood_load(beech), false)
        sheet_finish(ls, tree_draw_k / 2.0, true)
    if sheet_load(rs, vox_draw_k()): return
    let gneiss = gneiss_look()
    for(ROCK_KINDS) kind: tree_onto(rs, "rock{kind}", outcrop(gneiss, kind), true)
    for(CRAG_KINDS) kind:
        tree_onto(rs, "cragx{kind}", crag(gneiss, kind, 0.0), true)
        tree_onto(rs, "cragy{kind}", crag(gneiss, kind, 90.0), true)
    // (a bridge's timber: weathered grey brown, split faces paler)
    let timber_look = vglook { beech.leaf, [ float3 { 0.26, 0.21, 0.16 }, float3 { 0.37, 0.30, 0.22 }, float3 { 0.49, 0.41, 0.30 }, float3 { 0.62, 0.53, 0.40 } ], gneiss.rock, false, false, false }
    for(3) part: tree_onto(rs, "bridge{part}", bridge_part(timber_look, part), true)
    for(SLAB_KINDS) kind: tree_onto(rs, "slabs{kind}", slab_pile(gneiss, kind), true)
    for(STONE_KINDS) kind: tree_onto(rs, "stone{kind}", moss_stone(gneiss, kind), true)
    let debris = gneiss_look()
    debris.bark = [ float3 { 0.19, 0.15, 0.11 }, float3 { 0.27, 0.21, 0.15 }, float3 { 0.35, 0.28, 0.20 }, float3 { 0.44, 0.36, 0.26 } ]
    for(RUBBLE_KINDS) kind: tree_onto(rs, "rubble{kind}", rubble(debris, kind), true)
    bake_ruins(rs)
    sheet_finish(rs, vox_draw_k(), true)
    trees_bake_s = seconds_elapsed() - t0

// What winter leaves of the undergrowth (#8): the bracken dead and rust brown, the grass as straw, the brambles' canes
// with a few dark leaves still on. The bushes and herbs are gone.
def dead_look(leaf:[float3], canes:bool) -> vglook:
    let bark = if canes: [ float3 { 0.22, 0.11, 0.13 }, float3 { 0.31, 0.15, 0.17 }, float3 { 0.40, 0.20, 0.21 }, float3 { 0.50, 0.27, 0.26 } ] else: [ float3 { 0.20, 0.17, 0.14 }, float3 { 0.28, 0.24, 0.20 }, float3 { 0.37, 0.32, 0.26 }, float3 { 0.46, 0.40, 0.33 } ]
    return vglook { leaf, bark, [ float3 { 0.3, 0.3, 0.3 }, float3 { 0.5, 0.5, 0.5 } ], false, false, false }

def bake_winter():
    if frame_at.get("fern0.winter", -1) >= 0: return
    let vs = sheet_new("leaves_winter", "{TREE_BAKE} {VOX_K} {WB_PX}", 2048)
    if sheet_load(vs, vox_draw_k()): return
    let rust = [ float3 { 0.52, 0.34, 0.19 }, float3 { 0.40, 0.26, 0.15 }, float3 { 0.25, 0.17, 0.11 }, float3 { 0.62, 0.44, 0.26 } ]
    let straw = [ float3 { 0.80, 0.72, 0.48 }, float3 { 0.63, 0.55, 0.35 }, float3 { 0.42, 0.36, 0.22 }, float3 { 0.90, 0.84, 0.62 } ]
    let wine = [ float3 { 0.40, 0.20, 0.17 }, float3 { 0.30, 0.17, 0.15 }, float3 { 0.20, 0.13, 0.12 }, float3 { 0.48, 0.27, 0.20 } ]
    for(FERN_KINDS) kind: tree_onto(vs, "fern{kind}.winter", fern(dead_look(rust, false), kind), true)
    for(BRAMBLE_KINDS) kind: tree_onto(vs, "bramble{kind}.winter", bramble(dead_look(wine, true), kind), true)
    for(TUFT_KINDS) kind: tree_onto(vs, "tuft{kind}.winter", grass_tuft(dead_look(straw, false), kind), true)
    sheet_finish(vs, vox_draw_k(), true)

// Snow on the boughs (#15): the same models with snow lying two voxels deep on whatever is open to the sky above it,
// a little of it missing so it reads as a dusting and not a slab. The bare broadleaves, old and young, and the
// evergreens' crowns. Baked with winter; each casts the shadow of the tree without its snow.
let SNOW_LOOK = [ float3 { 0.62, 0.69, 0.83 }, float3 { 0.80, 0.86, 0.95 }, float3 { 0.95, 0.97, 1.0 } ]

def snowed(g:vgrid) -> vgrid:
    g.look = vglook { g.look.leaf, g.look.bark, SNOW_LOOK, false, g.look.tree, g.look.standing }
    for(g.n.y) y: for(g.n.x) x:
        var open = 99  // (empty voxels above, counted going down the column)
        for(g.n.z) k:
            let z = g.n.z - 1 - k
            let i = vg_index(g, x, y, z)
            if g.mat[i] != 0 and g.mat[i] != VG_CUT:
                if open >= 6 and vg_hash(g.seed + 5, x / 2, y / 2, z / 3) < 0.82:
                    for(2) up: if z + 1 + up < g.n.z: vg_set(g, vg_index(g, x, y, z + 1 + up), VG_CUT, 0.0)
                open = 0
            elif g.mat[i] == 0: open++
    return g

def bake_snow(between):
    if frame_at.get("beech0.snow", -1) >= 0: return
    let vs = sheet_new("snow", "{TREE_BAKE} {VOX_K} {WB_PX} {vox_tree_text()}", 4096)
    if sheet_load(vs, vox_draw_k()): return
    let beech = beech_look("summer")
    for(BROADLEAVES) sp: for(LEAF_KINDS) kind:
        tree_onto(vs, "{sp}{kind}.snow", snowed(vox_tree(leaf_look(sp, "summer", kind), vox_name(sp, kind), false)), false)
        between()
    for(LEAF_KINDS) kind:
        tree_onto(vs, "pine{kind}.crown.ever.snow", snowed(vox_tree(pine_look(), vox_name("pine", kind), true)), false)
        tree_onto(vs, "spruce{kind}.crown.ever.snow", snowed(vox_tree(spruce_look(), vox_name("spruce", kind), true)), false)
        between()
    for(YOUNG_KINDS) kind:
        tree_onto(vs, "young{kind}.bare.snow", snowed(vox_tree(beech, "beech_young_{kind}", false)), false)
        tree_onto(vs, "yspruce{kind}.snow", snowed(young_spruce(spruce_look(), kind)), false)
    sheet_finish(vs, vox_draw_k(), true)

// Snow on the fir's and the black pine's crowns: a sheet of their own.
def bake_snow_conifers(between):
    if frame_at.get("fir0.crown.ever.snow", -1) >= 0: return
    let vs = sheet_new("snow2", "{TREE_BAKE} {VOX_K} {WB_PX} {vox_tree_text()}", 4096)
    if sheet_load(vs, vox_draw_k()): return
    for(OTHER_CONIFERS) sp: for(LEAF_KINDS) kind:
        tree_onto(vs, "{sp}{kind}.crown.ever.snow", snowed(vox_tree(if sp == "fir": fir_look() else: bpine_look(), vox_name(sp, kind), true)), false)
        between()
    sheet_finish(vs, vox_draw_k(), true)

// This season's leaves on the broadleaves, old and young, and the undergrowth's (in winter the bare wood shows, and
// what is left of the undergrowth).
def bake_season(stage:string, between):
    if stage == "winter":
        bake_winter()
        bake_snow(between)
        bake_snow_conifers(between)
    if stage == trees_season or stage == "winter": return
    trees_season = stage
    if frame_at.get("beech0.crown.{stage}", -1) >= 0: return  // (baked or read earlier this run)
    // ("late": autumn's colours, most of the leaves down)
    let late = stage == "late"
    late_leaves = late
    let season = if late: "autumn" else: stage
    let t0 = seconds_elapsed()
    let vs = sheet_new("leaves_{stage}", "{TREE_BAKE} {VOX_K} {WB_PX} {vox_tree_text()}", 4096)
    if sheet_load(vs, vox_draw_k()): return
    // the last leaves hang on in clumps, a bough here still dressed and the next one bare
    def fallen(g:vgrid, keep:float) -> vgrid:
        if late:
            let f = vg_field(g, 0.09, g.seed + 77)
            for(g.n.z) z: for(g.n.y) y: for(g.n.x) x:
                let i = vg_index(g, x, y, z)
                if g.mat[i] == VG_LEAF and vg_at(f, float(x), float(y), float(z)) > keep: write_int8_le(g.mat, i, 0)
        return g
    // After leaf-fall the twigs are the crown (the mock-up, and the review of 2026-11-11: "a dense mass of fine dark
    // twigs, like a bristle, with leaves as a sparse scatter of round dabs inside it"). Every thin branch of the wood
    // sprouts fine dark twigs a voxel thick, out and up from the tree's middle, into the picture of its last leaves.
    def bristle(g:vgrid, name:string) -> vgrid:
        let wood = vox_tree(g.look, name, false)
        let rng = grng(g.seed + 311)
        def is_bark(x:int, y:int, z:int) -> int:
            return if x >= 0 and y >= 0 and z >= 0 and x < wood.n.x and y < wood.n.y and z < wood.n.z and wood.mat[vg_index(wood, x, y, z)] == VG_BARK: 1 else: 0
        for(wood.n.z) z: for(wood.n.y) y: for(wood.n.x) x:
            if wood.mat[vg_index(wood, x, y, z)] == VG_BARK and z > wood.n.z / 4:
                // (thin: wood two voxels off on few sides)
                let thick = is_bark(x + 2, y, z) + is_bark(x - 2, y, z) + is_bark(x, y + 2, z) + is_bark(x, y - 2, z) + is_bark(x, y, z + 2) + is_bark(x, y, z - 2)
                if thick <= 2 and randf(rng) < BRISTLE:
                    let at = (float(int3 { x, y, z } + wood.lo) + 0.5) / VOX_K
                    let out = normalize(float3 { at.x, at.y, 0.0 } + float3 { 0.0001, 0.0, 0.0 })
                    let dir = normalize(out * randf_range(rng, 0.2, 1.0) + float3 { randf_range(rng, -0.7, 0.7), randf_range(rng, -0.7, 0.7), randf_range(rng, 0.1, 1.1) })
                    let l = randf_range(rng, 0.05, 0.15)
                    let mid = at + dir * l * 0.5 + float3 { randf_range(rng, -0.012, 0.012), randf_range(rng, -0.012, 0.012), 0.0 }
                    vg_capsule(g, at, mid, 0.55 / VOX_K, 0.5 / VOX_K, VG_BARK)
                    vg_capsule(g, mid, at + dir * l, 0.5 / VOX_K, 0.45 / VOX_K, VG_BARK)
        return g
    def twig_look(sp:string, kind:int) -> vglook:
        let look = leaf_look(sp, season, kind)
        look.bark = [ float3 { 0.09, 0.08, 0.08 }, float3 { 0.15, 0.13, 0.13 }, float3 { 0.22, 0.20, 0.19 }, float3 { 0.31, 0.28, 0.26 } ]
        return look
    // (after leaf-fall an old tree keeps only some of its leaves: the oak most; the young ones keep theirs)
    for(BROADLEAVES) sp: for(LEAF_KINDS) kind:
        let crown = "{sp}{kind}.crown.{stage}"
        let whole = vox_tree(leaf_look(sp, season, kind), vox_name(sp, kind), true, season == "autumn")
        if late:
            // (the wood's shade stays whole under thinned crowns: the boughs and twigs still shade the ground, and a
            // shade full of holes flickers; so the picture is the thinned crown's, the shade the whole one's)
            whole.k = whole.k / LIGHT_UNITS
            let bytes, w, h, origin = vg_sprite(whole, true)
            let _, shade = vm_split_shadow(bytes, w, h)
            for(w * h) px: write_int8_le(shade, px * 4 + 3, min(235, int(float(shade[px * 4 + 3]) * 1.5)))
            sheet_add_bytes(vs, crown + ".shadow", shade, w, h, origin)
            tree_onto(vs, crown, bristle(fallen(vox_tree(twig_look(sp, kind), vox_name(sp, kind), true), if sp == "oak": LATE_KEEP + 0.08 else: LATE_KEEP), vox_name(sp, kind)), false)
        else: tree_onto(vs, crown, whole, true, 1.5)
        between()
    for(YOUNG_KINDS) kind: tree_onto(vs, "young{kind}.{stage}", fallen(vox_tree(leaf_look("beech", season, kind + 1), "beech_young_{kind}", true), 0.55), true)
    tree_onto(vs, "sapling.{stage}", vox_tree(leaf_look("beech", season, 0), "beech_sapling_0", true), true)
    for(FERN_KINDS) kind: tree_onto(vs, "fern{kind}.{stage}", fern(under_look(season, kind, false), kind), true)
    for(BUSH_KINDS) kind: tree_onto(vs, "bush{kind}.{stage}", bush(under_look(season, kind + 1, false), kind), true)
    for(BRAMBLE_KINDS) kind: tree_onto(vs, "bramble{kind}.{stage}", bramble(bramble_look(season, kind), kind), true)
    for(HERB_KINDS) kind: tree_onto(vs, "herb{kind}.{stage}", herbs(herb_look(season, kind), kind), true)
    for(TUFT_KINDS) kind: tree_onto(vs, "tuft{kind}.{stage}", grass_tuft(tuft_look(season, kind), kind), true)
    sheet_finish(vs, vox_draw_k(), true)
    trees_bake_s = seconds_elapsed() - t0
