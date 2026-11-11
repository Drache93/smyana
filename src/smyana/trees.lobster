// ------------------------------------------------------------------ the trees
// Baked voxel by voxel with Creel's prop baker (view/voxel_grid.lobster), in the Rhodopes' own kinds, at the size of
// the route mock-ups (archive/images/2026-11-10/19 to 23; Dominic, 2026-11-10: "Need to keep to the designs"; D-036):
// an old tree is five or six men tall with a trunk a quarter to a third of a man wide; a young tree is two or three
// men tall. The whole trees are .vox models (art/trees/vox/, made by tools/tree_vox.py). An old tree is three
// pictures: its wood, its shadow on the ground, and its leaves, which fade when a man is under them so he can be
// seen. The leaves are baked once a season (their colour), behind the letter home, and kept in bake_cache/.

let TREE_K = 64.0  // voxels a tile for the load of wood (baked at twice this)
let TREE_BAKE = "trees 32"
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
    var bark = [ float3 { 0.17, 0.16, 0.16 }, float3 { 0.29, 0.28, 0.27 }, float3 { 0.42, 0.41, 0.39 }, float3 { 0.58, 0.57, 0.53 } ]
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
def crown_up(sp:string) -> float: return if sp == "beech": 1.35 elif sp == "oak": 1.2 elif sp == "hornbeam": 1.0 elif sp == "pine": 1.7 else: 1.2
def crown_reach(sp:string) -> float: return if sp == "beech": 0.8 elif sp == "oak": 0.8 elif sp == "hornbeam": 0.55 elif sp == "pine": 0.55 else: 0.45

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
    let g = fine_grid(look, 0.14, 0.14, 1470 + kind)
    let tall = 0.05 + 0.014 * float(kind % 3)
    for(3 + kind % 3):
        // (a few feet close together, so a tuft is a clump and not a fan)
        let foot = float3 { randf_range(rng, -0.04, 0.04), randf_range(rng, -0.04, 0.04), 0.0 }
        for(5 + kind % 2):
            let a = randf_range(rng, 0.0, 360.0)
            let lean = randf_range(rng, 0.008, 0.034)
            let top = foot + float3 { cos(a) * lean, sin(a) * lean, tall * randf_range(rng, 0.55, 1.2) }
            let steps = 7
            for(steps) n:
                let u = float(n) / float(steps - 1)
                // (a stem bows out as it rises; dark at the foot, pale at the tip)
                let p = foot + (top - foot) * u + float3 { cos(a), sin(a), 0.0 } * lean * 0.5 * u * u
                leaf_dab(g, p, 0.0085, -0.75 + 1.6 * u + randf_range(rng, -0.1, 0.1))
            // a leaf or two off the stem, in its upper half
            for(1):
                let u = randf_range(rng, 0.45, 0.95)
                let p = foot + (top - foot) * u + float3 { randf_range(rng, -0.014, 0.014), randf_range(rng, -0.014, 0.014), 0.0 }
                leaf_dab(g, p, 0.0098, -0.2 + 1.1 * u)
    return g

// The soft grass' colours: straw yellow tips over olive in autumn, fresh green in spring and summer.
def tuft_look(season:string, kind:int) -> vglook:
    var leaf = [ float3 { 0.56, 0.70, 0.30 }, float3 { 0.38, 0.54, 0.22 }, float3 { 0.20, 0.32, 0.14 }, float3 { 0.74, 0.82, 0.42 } ]
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

// The low herbs: pale yellow green, paler still in autumn.
def herb_look(season:string, kind:int) -> vglook:
    var leaf = [ float3 { 0.66, 0.76, 0.34 }, float3 { 0.46, 0.60, 0.26 }, float3 { 0.24, 0.36, 0.16 }, float3 { 0.80, 0.84, 0.44 } ]
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
        for(LOG_KINDS) kind: tree_onto(vs, "log{kind}", fallen_log(under_look("summer", kind, true), kind), true)
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
    let rs = sheet_new("rocks", "{TREE_BAKE} {VOX_K} {WB_PX}", 2048)
    let ls = sheet_new("load", "{TREE_BAKE} {TREE_K} {WB_PX}", 256)
    if sheet_load(rs, vox_draw_k()) and sheet_load(ls, tree_draw_k / 2.0): return
    let gneiss = gneiss_look()
    for(ROCK_KINDS) kind: tree_onto(rs, "rock{kind}", outcrop(gneiss, kind), true)
    for(SLAB_KINDS) kind: tree_onto(rs, "slabs{kind}", slab_pile(gneiss, kind), true)
    let debris = gneiss_look()
    debris.bark = [ float3 { 0.19, 0.15, 0.11 }, float3 { 0.27, 0.21, 0.15 }, float3 { 0.35, 0.28, 0.20 }, float3 { 0.44, 0.36, 0.26 } ]
    for(RUBBLE_KINDS) kind: tree_onto(rs, "rubble{kind}", rubble(debris, kind), true)
    sheet_finish(rs, vox_draw_k(), true)
    // (the load is baked finer still: a sheet of its own, drawn at its own size)
    tree_onto(ls, "load.wood", wood_load(beech), false)
    sheet_finish(ls, tree_draw_k / 2.0, false)
    trees_bake_s = seconds_elapsed() - t0

// This season's leaves on the broadleaves, old and young, and the undergrowth's (winter has none: the bare wood shows).
def bake_season(season:string, between):
    if season == trees_season or season == "winter": return
    trees_season = season
    if frame_at.get("beech0.crown.{season}", -1) >= 0: return  // (baked or read earlier this run)
    let t0 = seconds_elapsed()
    let vs = sheet_new("leaves_{season}", "{TREE_BAKE} {VOX_K} {WB_PX} {vox_tree_text()}", 4096)
    if sheet_load(vs, vox_draw_k()): return
    // (after leaf-fall an old tree keeps only some of its leaves: the oak most; the young ones keep theirs)
    for(BROADLEAVES) sp: for(LEAF_KINDS) kind:
        tree_onto(vs, "{sp}{kind}.crown.{season}", vox_tree(leaf_look(sp, season, kind), vox_name(sp, kind), true, season == "autumn"), true, 1.5)
        between()
    for(YOUNG_KINDS) kind: tree_onto(vs, "young{kind}.{season}", vox_tree(leaf_look("beech", season, kind + 1), "beech_young_{kind}", true), true)
    tree_onto(vs, "sapling.{season}", vox_tree(leaf_look("beech", season, 0), "beech_sapling_0", true), true)
    for(FERN_KINDS) kind: tree_onto(vs, "fern{kind}.{season}", fern(under_look(season, kind, false), kind), true)
    for(BUSH_KINDS) kind: tree_onto(vs, "bush{kind}.{season}", bush(under_look(season, kind + 1, false), kind), true)
    for(HERB_KINDS) kind: tree_onto(vs, "herb{kind}.{season}", herbs(herb_look(season, kind), kind), true)
    for(TUFT_KINDS) kind: tree_onto(vs, "tuft{kind}.{season}", grass_tuft(tuft_look(season, kind), kind), true)
    sheet_finish(vs, vox_draw_k(), true)
    trees_bake_s = seconds_elapsed() - t0
