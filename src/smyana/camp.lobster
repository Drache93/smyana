// ------------------------------------------------------------------ the camp
// The men's camp (Dominic, 2026-11-10: "the tents, fireplace, and our horses"): a canvas tent, a lean-to of striped
// rugs, the fireplace with its tripod and cauldron, a woodpile, the riding horses and the pack mules. Each is a .vox
// model (art/camp/vox/, made by tools/camp_vox.py) at one voxel a pixel of the art, as the men and the trees are, in
// its palette's own colours, lit as the props are and baked once into the "camp" sheet with its shadow. The fire
// itself is the game's own (D-038): the fireplace is its ring of stones, its logs and the tripod over it.
//
// Frames, each with its .shadow: tent0 (canvas), tent1 (rugs), fireplace, woodpile, horse0..7 and mule0..7. A horse or
// mule n is the animal n % 4 facing one way (n < 4) or the other: they face the camera's right or its left.

let CAMP_BAKE = "camp 3"
let CAMP_DIR = "../art/camp/vox"
let CAMP_ANIMALS = 4
let CAMP_THINGS = [ "tent0", "tent_canvas", "tent1", "tent_rugs", "fireplace", "fireplace", "woodpile", "woodpile" ]
// (how each is turned, in quarter turns: the rugs' striped slope comes down toward the camera)
let CAMP_THING_TURNS = [ 0, 2, 0, 0 ]
let CAMP_HORSES = [ "horse_0_bay", "horse_1_grey", "horse_2_chestnut", "horse_3_dark" ]
let CAMP_RIDERS = [ "rider_0_bay", "rider_1_grey", "rider_2_chestnut", "rider_3_dark" ]  // (rider0..7: a horseman up, for a patrol)
let CAMP_BANNER = "rider_banner"                                                         // (riderbanner0..3: the patrol's standard-bearer, facing as rider0, 4, 8 and 12 do; D-084)
let CAMP_MULES = [ "mule_0_mule_sacks", "mule_1_mule_dun_kegs", "mule_2_bay_baskets", "mule_3_mule_poles" ]
// (the two ways an animal faces, in quarter turns: its side to the camera, its head to the right, then to the left)
let CAMP_TURNS = [ 3, 1 ]
// (a rider faces any of four ways: rider0..3 and 4..7 as the horses, 8..11 down the screen to the right, as one who
// rides along the men's own path, 12..15 up it to the left)
let CAMP_RIDER_TURNS = [ 3, 1, 0, 2 ]
var camp_feet = []::string
var camp_bake_s = 0.0  // how long the last bake took (0: read from bake_cache/)

// A model as a grid: every voxel solid (VG_BARK), its tone the palette index; the palette, 0xRRGGBB. Turned by `turn`
// quarter turns about its foot.
def camp_grid(name:string, turn:int, seed:int) -> vgrid, [int]:
    if not camp_feet.length: camp_feet = tokenize(read_file(CAMP_DIR + "/feet.txt") or "", " \n", "")
    let at = find(camp_feet): _ == name
    assert at >= 0
    let foot = int3 { string_to_int(camp_feet[at + 1]), string_to_int(camp_feet[at + 2]), 0 }
    let v = vox_parse(read_file("{CAMP_DIR}/{name}.vox") or "")
    assert v.error == "" and v.models.length == 1
    let m = v.models[0]
    def turned(p:int3) -> int3:
        let q = p - foot
        return [ q, int3 { -q.y, q.x, q.z }, int3 { -q.x, -q.y, q.z }, int3 { q.y, -q.x, q.z } ][turn % 4]
    var lo = int3_1 * 1000000
    var hi = int3_1 * -1000000
    for(m.xyz) p:
        lo = min(lo, turned(p))
        hi = max(hi, turned(p))
    let look = vglook { [], [], [], false, false, false }
    let g = vg_new(look, float(lo - int3_1) / VOX_K, float(hi + int3_1 * 2) / VOX_K, VOX_K, seed)
    for(m.xyz) p, i:
        let q = turned(p) - g.lo
        let c = vg_index(g, q.x, q.y, q.z)
        write_int8_le(g.mat, c, VG_BARK)
        write_int8_le(g.tone, c, m.idx[i])
    return g, v.palette

// The grid as a sprite (view/voxel_grid's vg_sprite, lit the same way, as the rocks and the logs are), each voxel in
// its own colour: the light in four crisp bands, no speckle (the men's and the props' crispness).
def camp_sprite(g:vgrid, palette:[int], shadow:bool) -> string, int, int, float2:
    let cell = []::int
    let pos = []::int3
    for(g.n.z) z:
        bake_pulse()
        for(g.n.y) y:
            var i = vg_index(g, 0, y, z)
            for(g.n.x) x:
                if g.mat[i] and (vg_get(g, x - 1, y, z) == 0 or vg_get(g, x + 1, y, z) == 0 or vg_get(g, x, y - 1, z) == 0 or
                                 vg_get(g, x, y + 1, z) == 0 or vg_get(g, x, y, z - 1) == 0 or vg_get(g, x, y, z + 1) == 0):
                    cell.push(i)
                    pos.push(int3 { x + g.lo.x, z + g.lo.z, y + g.lo.y })  // (the world's y is up)
                i++
    let sh = vm_shell { VG_PX / WB_PX, int3_0, int3_0, int3_0, [], pos, [], [], [], [] }
    def grid(w:float3) -> float3: return float3 { w.x, w.z, w.y }
    let to_light = grid(-light_along(VM_SUN))
    let to_eye = grid(euler(VM_VIEW).z)
    let k = g.k
    def solid(p:float3) -> bool: return vg_get(g, int(floor(p.x)), int(floor(p.y)), int(floor(p.z))) != 0
    def share(c:float3, r:float) -> float:  // how much of what's round c (radius r) is filled
        var hit = 0
        for(VG_DIRS) d:
            if solid(c + d * r): hit++
            if solid(c + d * r * 2.0): hit++
        return float(hit) / float(VG_DIRS.length * 2)
    return vm_draw(sh, shadow) slot:
        let i = cell[slot]
        let x = i % g.n.x
        let y = (i / g.n.x) % g.n.y
        let z = i / (g.n.x * g.n.y)
        let c = float3 { float(x), float(y), float(z) } + float3_1 * 0.5
        // the normal: away from what's filled round it, out to a few voxels (a canvas or a rug a voxel or two thick reads flat,
        // not banded in blotches; a pole stays round)
        var nsum = float3_0
        for(VG_DIRS) d:
            for([ 1.5, 3.0, 4.5, 6.0 ]) r: if solid(c + d * r): nsum -= d
        let n = if magnitude(nsum) > 0.0: normalize(nsum) else: float3 { 0.0, 0.0, 1.0 }
        // its own shadow: anything between it and the sun
        var dark = 0.0
        var r = c + n * 2.5
        for(60):
            if solid(r): dark = 1.0
            r += to_light * 1.5
        let diff = clamp(dot(n, to_light), 0.0, 1.0) * (1.0 - 0.8 * dark)
        let ao = 1.0 - clamp(share(c, 0.3 * k) - 0.35, 0.0, 1.0) * 0.9
        let rim = pow(clamp(1.0 - abs(dot(n, to_eye)), 0.0, 1.0), 3.0) * (if n.z > -0.2: 1.0 else: 0.0)
        let light = 0.42 + 0.80 * diff * ao + 0.12 * ao + 0.10 * rim
        let band = float(clamp(int(floor(clamp(light / 1.25, 0.0, 0.999) * 4.0)), 0, 3))
        let rgb = palette[max(g.tone[i] - 1, 0)]
        let base = float3 { float((rgb >> 16) & 255), float((rgb >> 8) & 255), float(rgb & 255) } / 255.0
        // (the shade a little cooler than the light, as the men's)
        let f = 0.52 + band * 0.2
        let col = base * f + (float3 { 0.10, 0.11, 0.14 } - base * 0.1) * (if band < 1.5: 0.35 else: 0.0)
        min(max(col, float3_0), float3_1)

def camp_onto(s:Sheet, name:string, model:string, turn:int, seed:int):
    let g, palette = camp_grid(model, turn, seed)
    g.k = g.k / LIGHT_UNITS
    let bytes, w, h, origin = camp_sprite(g, palette, true)
    let art, shade = vm_split_shadow(bytes, w, h)
    sheet_add_bytes(s, name, art, w, h, origin)
    sheet_add_bytes(s, name + ".shadow", shade, w, h, origin)

// The camp's .vox files, as text: part of the bake's key, so a changed model is baked again.
def camp_vox_text() -> string:
    var t = read_file(CAMP_DIR + "/feet.txt") or ""
    for(CAMP_HORSES.length) i: t += (read_file("{CAMP_DIR}/{CAMP_HORSES[i]}.vox") or "") + (read_file("{CAMP_DIR}/{CAMP_MULES[i]}.vox") or "") + (read_file("{CAMP_DIR}/{CAMP_RIDERS[i]}.vox") or "")
    for(CAMP_THINGS.length / 2) i: t += read_file("{CAMP_DIR}/{CAMP_THINGS[i * 2 + 1]}.vox") or ""
    t += read_file("{CAMP_DIR}/{CAMP_BANNER}.vox") or ""
    return sha256_text(t)

// The camp's sheet, baked (or read back from bake_cache/). between(): so the window can draw.
def bake_camp(between):
    let s = sheet_new("camp", "{CAMP_BAKE} {VOX_K} {WB_PX} {camp_vox_text()}", 2048)
    if sheet_load(s, vox_draw_k()): return
    let t0 = seconds_elapsed()
    for(CAMP_THINGS.length / 2) i:
        camp_onto(s, CAMP_THINGS[i * 2], CAMP_THINGS[i * 2 + 1], CAMP_THING_TURNS[i], 3000 + i)
        between()
    for(CAMP_TURNS) turn, side:
        for(CAMP_ANIMALS) i:
            camp_onto(s, "horse{side * CAMP_ANIMALS + i}", CAMP_HORSES[i], turn, 3100 + i)
            camp_onto(s, "mule{side * CAMP_ANIMALS + i}", CAMP_MULES[i], turn, 3200 + i)
            between()
    for(CAMP_RIDER_TURNS) turn, side:
        for(CAMP_ANIMALS) i: camp_onto(s, "rider{side * CAMP_ANIMALS + i}", CAMP_RIDERS[i], turn, 3300 + i)
        camp_onto(s, "riderbanner{side}", CAMP_BANNER, turn, 3400)
        between()
    sheet_finish(s, vox_draw_k(), true)
    camp_bake_s = seconds_elapsed() - t0
