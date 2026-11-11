// ------------------------------------------------------------------ Smyana: the game
// The window, the camera, what's drawn and how the men are told what to do, on Creel. The run itself (the route, one
// map per place, what carries across) is smyana/route.lobster; this shows it and plays the letter home between places.
// Run from src/ (../play.sh does):  lobster smyana.lobster -- [windowed] [shot:<png> at:<seconds>] [script:tour] [debug]
// No panels or bars (D-021): what there is to read is in the world. Left click or drag picks men, right click sends
// them (onto a young tree: fell it), the arrows or WASD move the camera, the wheel zooms, F finds the men, Space pauses.
import from "../creel/src"
import color
import gl
import texture
import smyana.sim
import view.facing
import view.shot_look
import view.node
import view.art
import view.bake_cache
import view.atmosphere
import net.lockstep
import net.lan
import game.audio
import game.pack
import game.relief
import game.fog_look
import game.ground
import game.doodads
import game.fx
import game.topbar_fit
import game.ui
import game.text_cache
import game.levels
import game.perf
import game.pace
import game.window_mode
import game.window_switch
import model.kit
import model.grng
import model.base
import model.flat
import view.voxel_mesh
import view.voxel_grid
import view.vox
import view.voxel
import smyana.sheets
import smyana.men_view
import smyana.trees
import smyana.cliff
import smyana.camp

// ------------------------------------------------------------------ what it was started with

let args = command_line_arguments()
def arg_of(key:string) -> string:
    for(args) a: if starts_with(a, key + ":"): return substring(a, key.length + 1, -1)
    return ""
let shot = arg_of("shot")
let shot_at = if arg_of("at") != "": string_to_float(arg_of("at")) else: 4.0
let script = arg_of("script")  // "tour": the men walk the whole route by themselves (captures, and timing the loads)
let debug_line = has_s(args, "debug")
hour_force = if arg_of("hour") != "": string_to_float(arg_of("hour")) else: -1.0  // hour:16.5: this place at that hour, for a look
season_force = arg_of("season")                                                   // season:autumn: this place in another season, for a look
let shots_dir = arg_of("shots")                                                   // a picture every few seconds into this folder (with script:tour)
var shots_n = 0
var shots_next = 3.0
var wall_s = 0.0
let capture = shot != "" or script != "" or arg_of("shots") != ""

// ------------------------------------------------------------------ the camera (art px: a tile is 96 x 48)

var cam = float2_0  // art px at the middle of the window
var zoom = 1.5      // screen px an art px

def to_screen(p:float2) -> float2: return (p - cam) * zoom + float(gl.window_size()) / 2.0
def from_screen(p:float2) -> float2: return (p - float(gl.window_size()) / 2.0) / zoom + cam
// Where a point of the place (milli-tiles) is drawn, in art px: on the ground, however high it lies there.
def gp(x:float, y:float) -> float2: return on_ground(float2 { x, y })

def mouse_milli() -> float2: return pick_milli(from_screen(mouse_px()))

// Where the men are, taken together (art px).
def men_centre() -> float2:
    var sum = float2_0
    for(u_x.length) i: sum += gp(float(u_x[i]), float(u_y[i]))
    return if u_x.length: sum / float(u_x.length) else: cam

// ------------------------------------------------------------------ what the view remembers of a place

class Prop:
    kind:int     // 0 an old tree, 1 a young tree, 2 a stump, 3 a rock outcrop, 4 loose slabs or a thing of the camp, 5 undergrowth (its leaves by season), 6 a fallen log
    pick:int     // which of its shapes
    name:string  // its picture (an old tree's trunk; a young beech's without its season)
    sp:string    // an old tree's kind: beech, pine, spruce
    at:float2    // its foot, art px
    cell:int

var props = []::Prop
// How closed the wood is overhead round each prop (0 open .. 1 deep in a wood; old trees only): deep in a wood an old
// tree's crown shade spreads till it meets its neighbours', so the floor under the canopy lies in shade and a clearing
// is the lit room in it (the mock-ups' look, picture 23). From atmosphere.json sun: canopy (how far a crown's shade
// spreads at most, 0 off), canopy_reach (tiles round it that count), canopy_trees (that many old trees there: fully closed).
var canopy = []::float
var canopy_spread = 0.0
var canopy_reach = 3
var canopy_trees = 14.0
var canopy_dim = 0.0  // (sun.canopy_dim: how much darker a tree under a closed canopy is drawn)
class Canopy:
    f:int
    x:float
    y:float
    s:float
var canopies = []::Canopy
// Sunflecks: deep in a wood, small spots of sun that get through the canopy and come and go as the boughs move
// (sun.flecks a tree, 0 off; by day only). Each one: where (art px) and its own seed.
var canopy_flecks = 0
var flecks = []::float3
var props_version = -1
var wear_tick = -1000
var clock_s = 0.0
var p_id = []::int  // the last tick's positions, to draw between ticks
var p_x = []::int
var p_y = []::int
let man_dir = dictionary<int, int>(64)
let man_walked = dictionary<int, float>(64)  // milli-tiles each has walked here: his step
var selected = []::int
var view_load_s = 0.0  // how long the last place took to load, the view's part included

def cell_hash(c:int) -> int: return ((c * 2654435761) >> 7) & 0xFFFF

// Which trees stand in this place (the map's "wood": beech or conifer), picked per cell.
// (deep: the high dark woods, where the trunks run up out of sight and only the understorey is a tree's whole height)
def old_kind(wood:string, pick:int) -> string, int:
    let r = (pick / 3) % 8
    var sp = if r < 4: "beech" elif r < 6: "oak" elif r < 7: "hornbeam" else: "pine"
    if wood == "deep": sp = if r < 6: "tall" elif r < 7: "spruce" else: "beech"
    if wood == "conifer": sp = if r < 5: "spruce" elif r < 7: "pine" else: "beech"
    return sp, pick % (if sp == "pine": PINE_KINDS else: 3)

def leafy(sp:string) -> bool: return sp == "beech" or sp == "oak" or sp == "hornbeam"

// Where the year's leaves lie thin in a broadleaf wood (x, y in mask samples): grass shows and herbs grow there.
def open_ground(x:int, y:int) -> bool:
    return cell_hash((y / 11) * W * MASK_K + x / 11 + 6007) % 100 < 45

def build_canopy():
    let old = str_index(tr_names, "tree")
    canopy = map(props) pr:
        if pr.kind != 0 or canopy_spread <= 0.0: 0.0
        else:
            let x = pr.cell % W
            let y = pr.cell / W
            var n = 0
            for(canopy_reach * 2 + 1) j:
                for(canopy_reach * 2 + 1) i:
                    let u = x + i - canopy_reach
                    let v = y + j - canopy_reach
                    if u >= 0 and v >= 0 and u < W and v < H and terrain[v * W + u] == old: n++
            smoothstep(canopy_trees * 0.35, canopy_trees, float(n - 1))

// Where the soft grass grows, 0 (none) to 1 (thick), x and y in tiles: smooth drifts a few tiles across, and thin
// single tufts between them.
// A whole number stirred well (cell_hash's low bits march in step for numbers in a row).
def mixed(n:int) -> int:
    var v = (n + 0x9E3779B9) & 0xFFFFFFFF
    v = ((v ^ (v >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
    v = ((v ^ (v >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
    return v ^ (v >> 16)

let TUFTS_A_TILE = 24
def drift_at(x:float, y:float, grain:int) -> float:
    def lattice(ix:int, iy:int, seed:int) -> float: return float(cell_hash(iy * 4099 + ix + seed) % 1000) / 1000.0
    def smooth(px:float, py:float, seed:int) -> float:
        let ix = int(floor(px))
        let iy = int(floor(py))
        let u = px - float(ix)
        let v = py - float(iy)
        let su = u * u * (3.0 - 2.0 * u)
        let sv = v * v * (3.0 - 2.0 * v)
        return (lattice(ix, iy, seed) * (1.0 - su) + lattice(ix + 1, iy, seed) * su) * (1.0 - sv) + (lattice(ix, iy + 1, seed) * (1.0 - su) + lattice(ix + 1, iy + 1, seed) * su) * sv
    let n = smooth(x * 0.3, y * 0.3, grain) * 0.8 + smooth(x * 0.95, y * 0.95, grain + 49) * 0.2
    return clamp((n - 0.42) * 7.0, 0.006, 1.0)

def build_props():
    props = []
    let debris_t = str_index(tr_names, "rubble")
    props_version = map_version
    let wood = gstr(su_map, "wood", "beech")
    let grass_seed = gint(su_map, "grass_seed", 9001)  // (which way this place's drifts of grass fall)
    let old = str_index(tr_names, "tree")
    let young = str_index(tr_names, "young_tree")
    let stump = str_index(tr_names, "stump")
    let rock = str_index(tr_names, "rock")
    let grass = str_index(tr_names, "grass")
    let bare_p = str_index(tr_names, "bare")
    for(terrain) t, c:
        let h = cell_hash(c)
        let centre = gp(float((c % W) * 1000 + 500), float((c / W) * 1000 + 500))
        // (not dead centre: a wood isn't planted in rows)
        let off = gp(float((c % W) * 1000 + 500 + (h % 400) - 200), float((c / W) * 1000 + 500 + ((h / 400) % 400) - 200))
        if t == old:
            let sp, k = old_kind(wood, h / 7)
            props.push(Prop { 0, k, "{sp}{k}", sp, off, c })
        elif t == young:
            let fir = wood != "beech" and (h / 7) % 4 != 0
            props.push(Prop { 1, h / 7, if fir: "yspruce{(h / 7) % YOUNG_KINDS}" else: "young{(h / 7) % YOUNG_KINDS}", if fir: "spruce" else: "beech", centre, c })
        elif t == stump: props.push(Prop { 2, 0, "stump", "", centre, c })
        elif t == rock:
            props.push(Prop { 3, 0, "rock{(h / 7) % ROCK_KINDS}", "", off, c })
        elif t == debris_t:
            // a landslide's debris (#20): a heap of earth and broken rock on each tile, a broken trunk here and there
            props.push(Prop { 3, 0, "rubble{(h / 7) % RUBBLE_KINDS}", "", off + iso(float((h / 5) % 500) - 250.0, float((h / 23) % 500) - 250.0), c })
            if (h / 3) % 5 == 0: props.push(Prop { 6, 0, "log{h % LOG_KINDS}", "", off + iso(float(h % 500) - 250.0, float((h / 9) % 500) - 250.0), c })
        // a cliff's foot (#20): crags stand against the face behind this tile (to its north, or to its west), more
        // of them where the face turns a corner, and loose rock lies between them
        if t != debris_t and t != rock:
            let cx = c % W
            for([ -W, -1 ]) d, side:
                let n = c + d
                if n >= 0 and (side == 0 or cx > 0) and level[n] - level[c] >= 2:
                    let hs = mixed(c * 2 + side + 77001)
                    let o = c + (if side == 0: -1 else: -W)  // (the tile beside this one, along the face)
                    let corner = o >= 0 and (level[o] != level[c] or level[o + d] != level[n])
                    let along = float(hs % 700 + 150)
                    let out = float((hs / 700) % 140 + 150)
                    let at = if side == 0: gp(float(cx * 1000) + along, float((c / W) * 1000) + out) else: gp(float(cx * 1000) + out, float((c / W) * 1000) + along)
                    let tall = level[n] - level[c] >= 4
                    if corner or (hs / 100000) % 10 < 3:
                        let k = if tall: [ 0, 3, 1, 0 ][(hs / 9) % 4] else: 2
                        props.push(Prop { 3, 0, (if side == 0: "cragx" else: "cragy") + "{k}", "", at, c })
                    elif (hs / 100000) % 10 < 7:
                        props.push(Prop { 4, 0, "slabs{(hs / 7) % SLAB_KINDS}", "", at, c })
        if t == bare_p and level[c] > 0 and (h / 13) % 6 == 0:
            // bare mountain ground: a few loose slabs and stones lie on it
            props.push(Prop { 4, 0, "slabs{(h / 7) % SLAB_KINDS}", "", off, c })
        elif t == grass and (h / 11) % 3 == 0:
            // slabs lie loose beside the rock they split from
            let x = c % W
            let y = c / W
            var by_rock = false
            for([ -1, 1, -W, W ]) d:
                let n = c + d
                if n >= 0 and n < W * H and abs(n % W - x) <= 1 and terrain[n] == rock: by_rock = true
            if by_rock and y >= 0: props.push(Prop { 4, 0, "slabs{(h / 7) % SLAB_KINDS}", "", off, c })
        if t == grass:
            // the undergrowth (#8): bracken in drifts, a bush here and there, now and then a fallen trunk
            let drift = cell_hash((c / W / 4) * W + (c % W) / 4 + 9001) % 8 < 3
            let h2 = cell_hash(c + 40507)
            if h2 % 100 < (if drift: 62 else: 7): props.push(Prop { 5, 0, "fern{h2 % FERN_KINDS}", "", off, c })
            if drift and h2 % 7 < 3:
                props.push(Prop { 5, 0, "fern{(h2 / 3) % FERN_KINDS}", "", centre + iso(float((h2 / 11) % 700) - 350.0, float((h2 / 17) % 700) - 350.0), c })
            // (soft grass: pale tufts standing out of the leaves in drifts a few tiles across, thick at a drift's
            // middle and thinning to single tufts at its edge; a low herb here and there among them)
            var shading = 0
            for(5) dy: for(5) dx:
                let nx = c % W + dx - 2
                let ny = c / W + dy - 2
                if nx >= 0 and ny >= 0 and nx < W and ny < H and terrain[ny * W + nx] == old: shading++
            let sunny = clamp(1.15 - float(shading) / 7.0, 0.08, 1.0)
            for(TUFTS_A_TILE) k:
                // (three well-mixed numbers a tuft: where in the tile, and its chance)
                let h3 = mixed(c * TUFTS_A_TILE + k)
                let at = float2 { float((c % W) * 1000 + h3 % 1000), float((c / W) * 1000 + (h3 / 1000) % 1000) }
                // (grass wants light: thick in a clearing, thin under a close wood)
                let thick = drift_at(at.x / 1000.0, at.y / 1000.0, grass_seed) * sunny
                if thick * 100.0 > float((h3 / 1000000) % 100): props.push(Prop { 5, 0, "tuft{(h3 / 7) % TUFT_KINDS}", "", gp(at.x, at.y), c })
                elif k < 2 and thick > 0.5 and (h3 / 3) % 10 < 2: props.push(Prop { 5, 0, "herb{(h3 / 5) % HERB_KINDS}", "", gp(at.x, at.y), c })
            // brambles (#8): at a wood's edge, where a tree or two gives half shade, in thickets of a few tiles
            let thicket = mixed((c / W / 3) * W + (c % W) / 3 + 5501) % 10 < 3
            let hb = mixed(c + 88001)
            if shading >= 1 and shading <= 4 and hb % 100 < (if thicket: 45 else: 3):
                props.push(Prop { 5, 0, "bramble{(hb / 100) % BRAMBLE_KINDS}", "", gp(float((c % W) * 1000 + (hb / 1000) % 1000), float((c / W) * 1000 + (hb / 1000000) % 1000)), c })
            if (h2 / 100) % 100 >= 90 and (h2 / 100) % 100 < 94: props.push(Prop { 5, 0, "sapling", "", centre, c })
            if (h2 / 100) % 100 < 6: props.push(Prop { 5, 0, "bush{h2 % BUSH_KINDS}", "", centre + iso(float((h2 / 13) % 600) - 300.0, float((h2 / 19) % 600) - 300.0), c })
            elif (h2 / 100) % 100 == 99: props.push(Prop { 6, 0, "log{h2 % LOG_KINDS}", "", centre, c })
    // the camp, where the place has one laid out ("camp": [name, x, y in milli-tiles] each: the tents, the woodpile,
    // the horses and the mules; the fireplace comes with the fire): nothing grows under it
    let camp = glist(su_map, "camp")
    if camp.length:
        let stands = map(camp) e: gp(as_float(e.a[1]), as_float(e.a[2]))
        props = filter(props) pr: pr.kind != 5 or not exists(stands) q: abs(pr.at.x - q.x) < 60.0 and abs(pr.at.y - q.y) < 34.0
        // (nor round the fire, where the men tread: "fire", x and y in milli-tiles)
        let hearth = glist(su_map, "fire")
        if hearth.length:
            let f = gp(as_float(hearth[0]), as_float(hearth[1]))
            props = filter(props) pr: pr.kind != 5 or abs(pr.at.x - f.x) > 46.0 or abs(pr.at.y - f.y) > 26.0
        for(camp) e, i: props.push(Prop { 4, 0, as_str(e.a[0]), "", stands[i], 0 })

    build_canopy()

// The trail is a path a man or two wide, not a road a tile wide (the mock-ups: a thin tan line through the leaves).
// Creel's worn ground is kept a tile at a time and spreads, so the trail itself is painted finer into the paths'
// texture (its "trail" channel): through the middle of the trail's tiles, eased where they step, a third of a tile
// wide. Where the men wear the ground off the trail still shows as Creel draws it.
let TRAIL_K = 8  // samples a tile

def build_trail():
    let trail = str_index(tr_names, "trail")
    let ford = str_index(tr_names, "ford")
    def on(x:int, y:int) -> bool: return x >= 0 and y >= 0 and x < W and y < H and (terrain[y * W + x] == trail or terrain[y * W + x] == ford)
    // each trail tile's point on the path: the middle of the trail tiles round it
    def mid(x:int, y:int) -> float2:
        var sum = float2_0
        var n = 0.0
        for(5) dy: for(5) dx:
            if on(x + dx - 2, y + dy - 2):
                let wgt = if dx == 2 and dy == 2: 2.0 else: 1.0
                sum += float2 { float(x + dx - 2) + 0.5, float(y + dy - 2) + 0.5 } * wgt
                n += wgt
        return sum / n
    let w = W * TRAIL_K
    let h = H * TRAIL_K
    let a = map(w * h): 0.0
    let r = 0.2
    for(H) y: for(W) x:
        if on(x, y):
            let p = mid(x, y)
            for([ int2 { 1, 0 }, int2 { 0, 1 }, int2 { 1, 1 }, int2 { -1, 1 } ]) d:
                if on(x + d.x, y + d.y):
                    let q = mid(x + d.x, y + d.y)
                    let lo = min(p, q) - r * 2.0
                    let hi = max(p, q) + r * 2.0
                    for(int((hi.y - lo.y) * float(TRAIL_K)) + 1) j: for(int((hi.x - lo.x) * float(TRAIL_K)) + 1) i:
                        let sx = int(lo.x * float(TRAIL_K)) + i
                        let sy = int(lo.y * float(TRAIL_K)) + j
                        if sx >= 0 and sy >= 0 and sx < w and sy < h:
                            let c = float2 { (float(sx) + 0.5) / float(TRAIL_K), (float(sy) + 0.5) / float(TRAIL_K) }
                            let t = clamp(dot(c - p, q - p) / max(dot(q - p, q - p), 0.0001), 0.0, 1.0)
                            let v = clamp(1.5 - magnitude(c - p - (q - p) * t) / r, 0.0, 1.0)
                            if v > a[sy * w + sx]: a[sy * w + sx] = v
    paths_tex = gl.create_texture(map(h) y: map(w) x: float4 { a[y * w + x], 0.0, 0.0, 0.0 }, texture_format_clamp | texture_format_nomipmap)
    ground_stale = true

// A stream is narrower than its tiles and its banks slope (Dominic, 2026-11-11: "The ebankment is too sharp, should be
// softly going down"). Creel's water mask is a tile's worth of water, blurred; so after build_masks the water is
// painted again here, finer: a line through the middle of the water's tiles, eased where they step, falling off evenly
// to each side, so the shader has a waterline (0.5) and a slope beyond it. Open water (water all round) stays whole.
let STREAM_K = 8   // samples a tile
let BANK_W = 0.36  // how far back from the waterline the bank begins to fall, tiles

def build_stream(half:float):
    let wet = map(tr_names) nm: nm == "water" or nm == "ford" or nm == "river" or nm == "shallows"
    def on(x:int, y:int) -> bool: return x >= 0 and y >= 0 and x < W and y < H and wet[terrain[y * W + x]]
    if not (exists(terrain): wet[_]): return
    def mid(x:int, y:int) -> float2:
        var sum = float2_0
        var n = 0.0
        for(3) dy: for(3) dx:
            if on(x + dx - 1, y + dy - 1):
                let wgt = if dx == 1 and dy == 1: 2.0 else: 1.0
                sum += float2 { float(x + dx - 1) + 0.5, float(y + dy - 1) + 0.5 } * wgt
                n += wgt
        return sum / n
    let w = W * STREAM_K
    let h = H * STREAM_K
    let a = map(w * h): 0.0
    def stroke(p:float2, q:float2, r:float):
        let lo = min(p, q) - r - BANK_W
        let hi = max(p, q) + r + BANK_W
        for(int((hi.y - lo.y) * float(STREAM_K)) + 2) j: for(int((hi.x - lo.x) * float(STREAM_K)) + 2) i:
            let sx = int(lo.x * float(STREAM_K)) + i
            let sy = int(lo.y * float(STREAM_K)) + j
            if sx >= 0 and sy >= 0 and sx < w and sy < h:
                let c = float2 { (float(sx) + 0.5) / float(STREAM_K), (float(sy) + 0.5) / float(STREAM_K) }
                let t = clamp(dot(c - p, q - p) / max(dot(q - p, q - p), 0.0001), 0.0, 1.0)
                // (1 in midstream, 0.5 at the waterline, then the bank: down to 0 over BANK_W tiles more)
                let d = magnitude(c - p - (q - p) * t)
                let v = if d <= r: 1.0 - 0.5 * d / r else: clamp(0.5 * (1.0 - (d - r) / BANK_W), 0.0, 0.5)
                if v > a[sy * w + sx]: a[sy * w + sx] = v
    // (a place may give its streams' own lines: "streams", each a list of x, y in milli-tiles; else through the tiles)
    let courses = glist(su_map, "streams")
    for(courses) ln:
        for(ln.a.length / 2 - 1) i:
            stroke(float2 { as_float(ln.a[i * 2]), as_float(ln.a[i * 2 + 1]) } / 1000.0, float2 { as_float(ln.a[i * 2 + 2]), as_float(ln.a[i * 2 + 3]) } / 1000.0, half)
    for(if courses.length: 0 else: H) y: for(W) x:
        if on(x, y):
            var open = true
            for(3) dy: for(3) dx: if not on(x + dx - 1, y + dy - 1): open = false
            let p = mid(x, y)
            if open: stroke(float2 { float(x) + 0.5, float(y) + 0.5 }, float2 { float(x) + 0.5, float(y) + 0.5 }, 1.2)
            for([ int2 { 1, 0 }, int2 { 0, 1 }, int2 { 1, 1 }, int2 { -1, 1 } ]) d:
                if on(x + d.x, y + d.y): stroke(p, mid(x + d.x, y + d.y), half)
    // (the other masks as Creel made them, between its samples)
    let mw = W * MASK_K
    let mh = H * MASK_K
    def other(x:int, y:int, ch:int) -> float:
        let fx = (float(x) + 0.5) * float(MASK_K) / float(STREAM_K) - 0.5
        let fy = (float(y) + 0.5) * float(MASK_K) / float(STREAM_K) - 0.5
        let x0 = clamp(int(floor(fx)), 0, mw - 1)
        let y0 = clamp(int(floor(fy)), 0, mh - 1)
        let x1 = min(x0 + 1, mw - 1)
        let y1 = min(y0 + 1, mh - 1)
        let u = clamp(fx - float(x0), 0.0, 1.0)
        let v = clamp(fy - float(y0), 0.0, 1.0)
        def b(xx:int, yy:int) -> float: return float(mask_bytes[(yy * mw + xx) * 4 + ch]) / 255.0
        return (b(x0, y0) * (1.0 - u) + b(x1, y0) * u) * (1.0 - v) + (b(x0, y1) * (1.0 - u) + b(x1, y1) * u) * v
    mask_tex = gl.create_texture(map(h) y: map(w) x: float4 { a[y * w + x], other(x, y, 1), other(x, y, 2), other(x, y, 3) }, texture_format_clamp | texture_format_nomipmap)
    ground_stale = true

// The worn ground for the shader, without the trail's own tiles (build_trail draws those).
def trail_wear():
    let trail = str_index(tr_names, "trail")
    wear_tex = gl.create_texture(map(H) y: map(W) x: float4 { (if y * W + x < wear.length and terrain[y * W + x] != trail: float(wear[y * W + x]) else: 0.0) / 255.0, 0.0, 0.0, 0.0 }, texture_format_clamp | texture_format_nomipmap)
    ground_stale = true

// Leaf litter on the ground under the giants: Creel's ground shader lays its forest floor where prop_tex's red is
// strong, and its own masks only make it so in a solid wood, not under one great tree. So after build_masks, the
// litter is painted here: full under each giant's crown, fading out at its edge.
let LITTER_REACH = 1.5  // tiles

def build_litter():
    let w = W * MASK_K
    let h = H * MASK_K
    let a = map(w * h): 0.0
    let r = int(LITTER_REACH * 3.2 * float(MASK_K)) + 1
    for(props) pr:
        if pr.kind == 0 or pr.kind == 2:
            let reach = (if pr.kind == 0: (if leafy(pr.sp): LITTER_REACH else: 1.0) else: 0.6) * (if season_now() == "autumn" and leafy(pr.sp): 1.25 else: 1.0) * (0.8 + 0.4 * float(cell_hash(pr.cell) % 100) / 100.0)
            let cx = float(pr.cell % W) + 0.5
            let cy = float(pr.cell / W) + 0.5
            let lobe = float(cell_hash(pr.cell) % 360)
            let sx = int(cx * float(MASK_K))
            let sy = int(cy * float(MASK_K))
            for(r * 2 + 1) dy: for(r * 2 + 1) dx:
                let x = sx + dx - r
                let y = sy + dy - r
                if x >= 0 and y >= 0 and x < w and y < h:
                    let o = float2 { (float(x) + 0.5) / float(MASK_K) - cx, (float(y) + 0.5) / float(MASK_K) - cy }
                    // (ragged: leaves drift, they don't fall in a ring)
                    let d = magnitude(o) / (reach * (1.0 + 0.28 * sin(atan2(o) * 3.0 + lobe) + 0.15 * sin(atan2(o) * 7.0 + lobe * 2.0)))
                    let v = clamp((1.0 - d) * 1.3, 0.0, 0.85)
                    if v > a[y * w + x]: a[y * w + x] = v
    // autumn in a broadleaf wood: the year's leaves lie over nearly everything, thinner in the open
    if season_now() == "autumn" and gstr(su_map, "wood", "beech") == "beech":
        for(h) y: for(w) x:
            // (2026-11-11: the leaves lie over all of it, only a worn spot of turf here and there: the mock-up's grass
            // stands out of the leaves in tufts, it isn't a green floor between drifts of them)
            let patch = float(cell_hash((y / 3) * w + x / 3 + 5003) % 100) / 100.0
            a[y * w + x] = max(a[y * w + x], if patch < 0.05 and open_ground(x, y): 0.36 else: 0.62 + 0.2 * patch)
    // scree under a landslide's debris (the shader's G), reaching a little past it and ragged
    let sc = map(w * h): 0.0
    let debris_t = str_index(tr_names, "rubble")
    let bare_t = str_index(tr_names, "bare")
    for(terrain) t, c:
        if t == debris_t or t == bare_t:
            let sx = (c % W) * MASK_K + MASK_K / 2
            let sy = (c / W) * MASK_K + MASK_K / 2
            let rr = MASK_K
            for(rr * 2 + 1) dy: for(rr * 2 + 1) dx:
                let x = sx + dx - rr
                let y = sy + dy - rr
                if x >= 0 and y >= 0 and x < w and y < h:
                    let v = clamp(1.4 - magnitude(float2 { float(dx - rr), float(dy - rr) }) / float(rr) * (0.9 + 0.3 * float(cell_hash(c + x * 7 + y * 13) % 100) / 100.0), 0.0, 1.0)
                    if v > sc[y * w + x]: sc[y * w + x] = v
    prop_tex = gl.create_texture(map(h) y: map(w) x: float4 { a[y * w + x], sc[y * w + x], 0.0, 0.0 }, texture_format_clamp | texture_format_nomipmap)
    ground_stale = true

// The view of a place just loaded: its ground and its trees in this season, the camera on the men.
def view_enter(between):
    ground_quad = nil
    props_version = -1
    wear_tick = -1000
    p_id = []
    p_x = []
    p_y = []
    man_dir.clear()
    man_walked.clear()
    selected = []
    if run_over(): return
    // the ground's own textures: a beech wood's leaf litter and grass, or a conifer wood's needles and moss
    ground_atlas_tex = gl.load_texture("../data/ground/atlas" + (if gstr(su_map, "wood", "beech") != "beech": "_conifer" else: "") + (if season_now() == "autumn": "_autumn" elif season_now() == "winter": "_winter" else: "") + ".png", texture_format_clamp | texture_format_nomipmap | texture_format_nearest_mag | texture_format_nearest_min)
    // (a stream is narrower than its tiles and runs a little below its banks, as in the mock-ups)
    // (the water: a narrow stream between banks that slope, pale under the sky as the mock-up's is)
    ground_bank_px = gfloat(su_map, "bank_px", 0.0)
    ground_water_edge = gfloat(su_map, "water_edge", 0.5)
    ground_shore_soft = gfloat(su_map, "shore_soft", 0.5)
    ground_litter_fringe = if season_now() == "winter": 0.1 else: 0.3  // (no drawn line where the fallen leaves and needles end: they thin out onto the grass)
    ground_water_shallow = float3 { 0.60, 0.71, 0.84 }
    ground_water_deep = float3 { 0.40, 0.52, 0.72 }
    build_masks()
    build_stream(gfloat(su_map, "stream", 0.25))
    // (a mountain's cliffs are sheer and jog square: no corner of high ground is cut down to a slope)
    relief_sharp = true
    build_relief()
    trail_wear()
    build_trail()
    bake_season(leaf_stage(), between)
    build_props()
    build_litter()
    cam = men_centre()

// ------------------------------------------------------------------ the light, by the hour

var atmo_data = jobj()

def mood_now() -> string:
    let hours = gobj(atmo_data, "hours")
    let h = hour_now()
    var best = ""
    var best_at = -1.0
    var last = ""
    var last_at = -1.0
    for(hours.keys) name, k:
        if not starts_with(name, "_"):
            let at = as_float(hours.a[k])
            if at <= h and at > best_at:
                best = name
                best_at = at
            if at > last_at:
                last = name
                last_at = at
    return if best != "": best else: last  // (before the day's first: still the night before)

// The sun the art is baked under (atmosphere.json's "sun"): how high it stands, degrees. Low, it casts the long
// shadows of the mock-ups (a late autumn afternoon). The shafts in the air point back at it on the screen.
def sun_from_data():
    let sun = gobj(atmo_data, "sun")
    let elev = gfloat(sun, "elevation", 48.0)
    VM_SUN = float3 { -elev, VM_SUN.y, 0.0 }
    let view = euler(VM_VIEW)
    let d = light_along(VM_SUN)  // where the light goes; on the screen, the way the shadows fall
    let fall = normalize(float2 { dot(d, view.x), -dot(d, view.y) })
    // the men's shadows the same way (their baker's ground is x right, y away, seen at 30 degrees: half as deep)
    let toward = normalize(float2 { -fall.x, 2.0 * fall.y })
    vx_SUN = normalize(float3 { toward.x, toward.y, tan(elev) })
    atmo_sun_dir = normalize(float2 { -fall.x, fall.y })  // (towards the sun, y up)
    // crisp art (Dominic: "evryhting crisp and sharp" in the mock-ups): little jitter in the voxels' light, and a leaf's
    // light in four hard bands
    vg_dither = gfloat(sun, "dither", 1.0)
    vg_leaf_tones = gfloat(sun, "leaf_tones", 5.0)
    // (a model's own shadow, exact to a voxel: a crown shades its boughs and trunk; and how deep that shade is)
    vg_sun_shadow = gint(sun, "self_shadow", 1) != 0
    vg_shade = gfloat(sun, "self_shade", 0.4)
    bake_light = "sun {elev} {vg_dither} {vg_leaf_tones} {vg_sun_shadow} {vg_shade}"
    canopy_spread = gfloat(sun, "canopy", 0.0)
    canopy_reach = int(gfloat(sun, "canopy_reach", 3.0))
    canopy_trees = gfloat(sun, "canopy_trees", 14.0)
    canopy_dim = gfloat(sun, "canopy_dim", 0.0)
    canopy_flecks = int(gfloat(sun, "flecks", 0.0))

// The mood of the hour and the next one, and how far into the turn from one to the next (0 .. 1): the last
// hours.blend hours (atmosphere.json) before a mood starts, the one before it turns into it, so dawn comes up and dusk
// falls instead of switching on the hour.
def mood_turn() -> string, string, float:
    let hours = gobj(atmo_data, "hours")
    let blend = gfloat(hours, "_blend", 0.0)
    let h = hour_now()
    let now = mood_now()
    var next = ""
    var next_at = 99.0
    var first = ""
    var first_at = 99.0
    for(hours.keys) name, k:
        if not starts_with(name, "_"):
            let at = as_float(hours.a[k])
            if at > h and at < next_at:
                next = name
                next_at = at
            if at < first_at:
                first = name
                first_at = at
    if next == "":  // (after the day's last: the next is tomorrow's first)
        next = first
        next_at = first_at + 24.0
    let t = if blend > 0.0: clamp((h - (next_at - blend)) / blend, 0.0, 1.0) else: 0.0
    return now, next, t

// A mood's own light this season where there is one ("day.autumn").
def mood_in_season(m:string) -> string:
    let own = m + "." + season_now()
    let has = exists(gobj(atmo_data, "moods").keys) name: name == own
    return if has: own else: m

var mood_key = ""

def mood_tick():
    let now, next, t = mood_turn()
    if now == "": return
    let a = mood_in_season(now)
    let b = mood_in_season(next)
    let step = int(t * 48.0)  // (the turn in small steps: the light set again only when it has moved)
    let key = "{a} {b} {step}"
    if key == mood_key: return
    mood_key = key
    let why = atmo_set_between(atmo_data, a, b, float(step) / 48.0)
    if why != "": print why

// ------------------------------------------------------------------ drawing the world

class Drawable:
    y:float  // sort point (art px)
    seq:int
    f:int
    x:float
    ay:float
    col:float4
    fade:float  // 1 whole .. 0 gone
    kind:int    // 0 what stands up (it hides the shade under it), 1 a shadow on the ground, 2 what stands in the shade,
    // 3 drawn by hand (rings, fires), 4 a man (in the shade, and kept readable: atmo_shade_unit)

var draws = []::Drawable
var fires = []::float2  // the camp's fires, art px: where each one's foot is (draw_fire)
var view_lo = float2_0
var view_hi = float2_0

def add(f:int, x:float, y:float, sort_y:float, col:float4, fade:float = 1.0, kind:int = -1):
    if f < 0: return
    let fr = frames[f]
    let x0 = x - float(fr.ox) * fr.k
    let y0 = y - float(fr.oy) * fr.k
    if x0 < view_hi.x and y0 < view_hi.y and x0 + float(fr.w) * fr.k > view_lo.x and y0 + float(fr.h) * fr.k > view_lo.y:
        draws.push(Drawable { sort_y, draws.length, f, x, y, col, fade, if kind >= 0: kind elif sort_y < -39000.0: 1 else: 0 })

def prev_pos(i:int) -> int, int:
    let found, at = binary_search(p_id, u_id[i])
    return if found: p_x[at] else: u_x[i], if found: p_y[at] else: u_y[i]

let SASH = float4 { 0.66, 0.19, 0.16, 1.0 }  // the sash's red (the men's 'team' colour)
let ART_UP = 58.8                            // art px a tile of height
var eyes = []::float2                        // where the men are on the picture: crowns over them fade

def collect_men(alpha:float):
    eyes = []
    for(u_x.length) i:
        let m = man_of(u_id[i])
        if m:
            let px, py = prev_pos(i)
            let x = float(px) + float(u_x[i] - px) * alpha
            let y = float(py) + float(u_y[i] - py) * alpha
            let moving, walking_d = unit_walk(i, man_dir.get(u_id[i], 2), px, py)
            var d = walking_d
            if not moving and u_task[i] == GATHER and u_target[i] >= 0:
                let nd = dir_of(iso(float((u_target[i] % W) * 1000 + 500) - x, float((u_target[i] / W) * 1000 + 500) - y))
                if nd >= 0: d = nd
            man_dir.set(u_id[i], d)
            let step = int(man_walked.get(u_id[i], 0.0) / man_cycle() * float(MEN_STEPS)) % MEN_STEPS
            let facing = (d + 2) % 8
            let p = gp(x, y)
            add(frame_at.get(man_shadow_name(m.look, facing), -1), p.x, p.y, p.y - 0.5, float4_1, 1.0, 1)
            add(frame_at.get(man_frame_name(m.look, if moving: 1 + step else: 0, facing), -1), p.x, p.y, p.y, SASH, 1.0, 4)
            if u_carry[i] > 0: add(frame_at.get("load.wood", -1), p.x + 3.0, p.y - 27.0, p.y + 0.1, float4_1, 1.0, 2)
            eyes.push(p - float2 { 0.0, 16.0 })

// How much of a giant's crown shows: it thins out over any man it would hide.
def crown_fade(foot:float2, sp:string) -> float:
    let c = foot - float2 { 0.0, crown_up(sp) * ART_UP }
    let r = crown_reach(sp) * 68.0
    var least = 1.0
    for(eyes) e:
        let d = magnitude(float2 { (e.x - c.x) / r, (e.y - c.y) / (r * (if leafy(sp): 0.8 else: 1.6)) })
        least = min(least, clamp((d - 0.8) / 0.45, 0.07, 1.0))
    return least

def collect_props():
    let season = leaf_stage()
    let bare = season == "winter"
    canopies = []
    flecks = []
    let day = hour_now() > 6.5 and hour_now() < 19.0
    for(props) pr, pidx:
        if pr.at.x > view_lo.x - 700.0 and pr.at.x < view_hi.x + 250.0 and pr.at.y > view_lo.y - 300.0 and pr.at.y < view_hi.y + 620.0:
            if pr.kind == 0:
                // (deep in a wood a tree stands under its neighbours' crowns: drawn darker, as the floor round it is)
                let dim = float4 { 1.0, 1.0, 1.0, 1.0 - canopy_dim * (if pidx < canopy.length: canopy[pidx] else: 0.0) }
                add(frame_at.get(pr.name + ".shadow", -1), pr.at.x, pr.at.y, -40000.0, float4_1)
                add(frame_at.get(pr.name, -1), pr.at.x, pr.at.y, pr.at.y, dim)
                let crown = if pr.sp == "tall": "spruce{pr.pick}.crown.ever" else: pr.name + ".crown." + (if leafy(pr.sp): season else: "ever")
                if pr.sp == "tall":
                    // its crown is out of sight overhead: only its shade reaches the ground
                    add(frame_at.get(crown + ".shadow", -1), pr.at.x, pr.at.y, -39999.0, float4_1)
                elif not leafy(pr.sp) or not bare:
                    add(frame_at.get(crown + ".shadow", -1), pr.at.x, pr.at.y, -39999.0, float4_1)
                    add(frame_at.get(crown, -1), pr.at.x, pr.at.y, pr.at.y + 0.2, dim, crown_fade(pr.at, pr.sp))
                if (pr.sp == "tall" or not leafy(pr.sp) or not bare) and pidx < canopy.length and canopy[pidx] > 0.0:
                    let f = frame_at.get(crown + ".shadow", -1)
                    if f >= 0: canopies.push(Canopy { f, pr.at.x, pr.at.y, 1.0 + (canopy_spread - 1.0) * canopy[pidx] })
                    if day and canopy[pidx] > 0.5 and (pr.sp == "tall" or not bare):
                        for(canopy_flecks) k:
                            let h = cell_hash(pr.cell * 13 + k + 17)
                            flecks.push(float3 { pr.at.x + float(h % 160) - 80.0, pr.at.y + float((h / 160) % 90) - 45.0, float(h % 997) })
            elif pr.kind == 1:
                if pr.sp == "spruce":
                    add(frame_at.get(pr.name + ".shadow", -1), pr.at.x, pr.at.y, -39998.0, float4_1)
                    add(frame_at.get(pr.name, -1), pr.at.x, pr.at.y, pr.at.y, float4_1, 1.0, 2)
                else:
                    // (a young beech: its wood, and over it this season's leaves)
                    add(frame_at.get(pr.name + ".bare.shadow", -1), pr.at.x, pr.at.y, -39998.0, float4_1)
                    add(frame_at.get(pr.name + ".bare", -1), pr.at.x, pr.at.y, pr.at.y, float4_1, 1.0, 2)
                    if not bare:
                        add(frame_at.get(pr.name + "." + season + ".shadow", -1), pr.at.x, pr.at.y, -39998.0, float4_1)
                        add(frame_at.get(pr.name + "." + season, -1), pr.at.x, pr.at.y, pr.at.y + 0.1, float4_1, 1.0, 2)
            elif pr.kind == 2:
                add(frame_at.get("stump", -1), pr.at.x, pr.at.y, pr.at.y, float4_1, 1.0, 2)
            elif pr.kind == 5:
                // (winter: the bushes and herbs are gone (they have no winter frame), two tufts in three are under the
                // snow, and what's left stands dead)
                if not bare or pr.name[0] != 't' or pidx % 3 == 0:
                    // (grass casts no shade of its own: a dot of shade under every tuft made the ground spotty)
                    if pr.name[0] != 't': add(frame_at.get(pr.name + "." + season + ".shadow", -1), pr.at.x, pr.at.y, -39996.0, float4_1)
                    add(frame_at.get(pr.name + "." + season, -1), pr.at.x, pr.at.y, pr.at.y, float4_1, 1.0, 2)
            else:
                add(frame_at.get(pr.name + ".shadow", -1), pr.at.x, pr.at.y, -39997.0, float4_1)
                // (the camp's horses and mules are marked like the men, so they keep their colour in the shade
                // instead of reading as grey ghosts)
                let beast = starts_with(pr.name, "horse") or starts_with(pr.name, "mule")
                add(frame_at.get(pr.name, -1), pr.at.x, pr.at.y, pr.at.y, float4_1, 1.0,
                    if pr.kind == 3: 0 elif beast: 4 else: 2)

    // the map's bridges (#20): a standing one's deck tile by tile, a broken one's two ends
    for(br_id.length) k:
        let cells = br_cells[k]
        for(cells) c, n:
            let part = if br_up[k] == 1: 0 elif n == 0: 1 elif n == cells.length - 1: 2 else: -1
            if part >= 0:
                let at = gp(float((c % W) * 1000 + 500), float((c / W) * 1000 + 500))
                add(frame_at.get("bridge{part}.shadow", -1), at.x, at.y, -39997.0, float4_1)
                add(frame_at.get("bridge{part}", -1), at.x, at.y, at.y - 20.0, float4_1, 1.0, 0)

// An ellipse on the ground round p, as flat as the camera sees the ground.
def draw_ring(p:float2, r:float, col:float4):
    let n = 24
    for(n) k:
        let a0 = 360.0 * float(k) / float(n)
        let a1 = 360.0 * float(k + 1) / float(n)
        ui_line(p + float2 { cos(a0) * r, sin(a0) * r * iso_k / 0.048 }, p + float2 { cos(a1) * r, sin(a1) * r * iso_k / 0.048 }, 1.2, col)

var mark_at = float2_0  // where the last order pointed (art px), and when
var mark_t = -10.0

def draw_rings(alpha:float):
    ui_batch():
        for(selected) id:
            let i = index_of(id)
            if i >= 0:
                let px, py = prev_pos(i)
                draw_ring(gp(float(px) + float(u_x[i] - px) * alpha, float(py) + float(u_y[i] - py) * alpha), 9.0, float4 { 0.95, 0.91, 0.79, 0.85 })
        let since = gl.time() - mark_t
        if since < 0.7: draw_ring(mark_at, 6.0 + since * 14.0, float4 { 0.95, 0.91, 0.79, 0.8 * (1.0 - since / 0.7) })

def draw_world(alpha:float):
    atlas_pack()
    if map_version != props_version:
        build_props()
        build_masks()
        build_stream(gfloat(su_map, "stream", 0.25))
        build_litter()
    if tick - wear_tick >= 40:
        trail_wear()
        wear_tick = tick
    let ws = float(gl.window_size())
    let cam_px = float2 { floor(cam.x * zoom), floor(cam.y * zoom) } / zoom
    sprite_snap = zoom
    view_lo = from_screen(float2_0) - float2_1
    view_hi = from_screen(ws) + float2_1
    draws = []
    collect_men(alpha)
    collect_props()
    draws.push(Drawable { -30000.0, draws.length, -4, 0.0, 0.0, float4_1, 1.0, 3 })  // the rings: on the ground, over the shadows
    for(fires) p, i:
        // (the fireplace: its ring of stones, its logs and the tripod with the cauldron; the flames are the game's own)
        add(frame_at.get("fireplace.shadow", -1), p.x, p.y, -39997.0, float4_1)
        add(frame_at.get("fireplace", -1), p.x, p.y, p.y, float4_1, 1.0, 2)
        draws.push(Drawable { p.y + 0.05, draws.length, -5, float(i), 0.0, float4_1, 1.0, 3 })
    qsort_in_place(draws) a, b: a.y < b.y or (a.y == b.y and a.seq < b.seq)
    // the ground's shadows into the light's shade buffer, where they join into one shade (a low sun's long shadows
    // overlap everywhere in a wood), then what stands up out of them wipes them off itself: the trees and rocks are lit
    // by their own bake; the men keep the shade they stand in
    let shading = atmo_shading()
    if shading:
        atmo_shade_begin()
        gl.blend(blend_none)
        if true:
            gl.translate(ws / 2.0):
                gl.scale(zoom):
                    gl.translate(-cam_px):
                        b_sheet = -1
                        sprite_shader = "atmo_shade_cast"
                        for(draws) d: if d.kind == 1: sprite(d.f, d.x, d.ay, d.col)
                        flush_sprites()
                        b_sheet = -1
                        sprite_shader = "atmo_shade_canopy"
                        // (the canopy overhead: a crown's shade spread round itself, as far as the wood is closed: drawn again
                        // at a ring of offsets rather than scaled up, so its pixels stay the art's size and its edge stays fine)
                        for(canopies) cp:
                            let fr = frames[cp.f]
                            let rx = float(fr.w) * fr.k * (cp.s - 1.0) * 0.5
                            let ry = float(fr.h) * fr.k * (cp.s - 1.0) * 0.5
                            sprite(cp.f, cp.x, cp.y, float4_1)
                            if rx > 0.5:
                                for(8) a:
                                    let ang = float(a) * 45.0 + 22.5
                                    sprite(cp.f, cp.x + cos(ang) * rx, cp.y + sin(ang) * ry, float4_1)
                        flush_sprites()
                        // the sunflecks: a spot of sun on the floor of the wood, swelling and gone as the boughs sway
                        if flecks.length:
                            gl.set_shader("color")
                            let t = gl.time()
                            gl.color(float4 { 0.0, 0.0, 0.0, 1.0 }):
                                for(flecks) fl:
                                    let s = sin((t * 9.0 + fl.z * 0.37) * 1.0) * 0.5 + 0.5
                                    if s > 0.3:
                                        let r = floor((3.0 + fl.z % 4.0) * s + 0.5)
                                        if r >= 1.0:
                                            // (a little lying oval, pixel cut: lit spots on the ground seen from above)
                                            let w = floor(r * 1.4)
                                            gl.translate(float2 { floor(fl.x) - r, floor(fl.y) - floor(r * 0.25) }): gl.rect(float2 { r * 2.0, max(1.0, floor(r * 0.5)) })
                                            gl.translate(float2 { floor(fl.x) - floor(w / 2.0), floor(fl.y) - floor(r * 0.5) }): gl.rect(float2 { w, r })
                        // back to front: what stands up wipes the shade off itself, and where a man stands is marked
                        // (blue, added: he keeps his shade) so the light can keep him readable; a tree in front wipes that too
                        var now = -1
                        for(draws) d:
                            if (d.kind == 0 or d.kind == 4) and d.f >= 0:
                                if d.kind != now:
                                    flush_sprites()
                                    b_sheet = -1
                                    now = d.kind
                                    sprite_shader = if now == 0: "atmo_shade_clear" else: "atmo_shade_unit"
                                    gl.blend(if now == 0: blend_alpha else: blend_add)
                                sprite(d.f, d.x, d.ay, if d.kind == 0: float4 { d.fade, 0.0, 0.0, 1.0 } else: float4_1)
                        flush_sprites()
                        gl.blend(blend_alpha)
                        sprite_shader = "sprite"
        gl.blend(blend_alpha)
    let atmo_drawn = atmo_begin(float4 { 0.04, 0.05, 0.04, 1.0 })
    let stale_was = ground_stale
    let step_was = ground_tex_step
    draw_ground_cached(gl.window_size(), cam_px, zoom, zoom / ART_K)
    if atmo_drawn and ((stale_was and not ground_stale) or ground_tex_step != step_was):
        atmo_rebind()
        draw_ground_cached(gl.window_size(), cam_px, zoom, zoom / ART_K)
    gl.translate(ws / 2.0):
        gl.scale(zoom):
            gl.translate(-cam_px):
                b_sheet = -1
                for(draws) d:
                    if d.f == -4:
                        flush_sprites()
                        draw_rings(alpha)
                        b_sheet = -1
                    elif d.f == -5:
                        flush_sprites()
                        draw_fire(int(d.x))
                        b_sheet = -1
                    elif shading and d.kind == 1: pass()
                    elif d.fade < 1.0: sprite_faded(d.f, d.x, d.ay, d.col, d.fade)
                    else: sprite(d.f, d.x, d.ay, d.col)
                flush_sprites()
                fires_glow()
    sprite_snap = 1.0
    if atmo_on: atmo_end(cam_px, zoom, 1.5)

// The camp's fires (for now only for a look: the camp option lights one among the men at dusk): the fireplace's model,
// flames drawn unlit, a glow each in the light (atmosphere.json's "glows": "building_fire"), and a thread of smoke.

def draw_fire(i:int):
    let p = fires[i]
    let t = gl.time()
    gl.set_shader("color")
    gl.translate(p): gl.scale(1.7):
        // the flames, a pixel of the art at a time: a red flame, an orange one inside it and a yellow heart, each a row
        // of columns under a pointed outline that licks up and falls back
        for(3) layer:
            let half = 6 - layer * 2
            let col = [ float4 { 0.84, 0.26, 0.07, 1.0 }, float4 { 0.98, 0.56, 0.13, 1.0 }, float4 { 1.0, 0.87, 0.42, 1.0 } ][layer]
            for(half * 2 + 1) n:
                let cx = float(n - half)
                let ph = t * (4.0 + float((n * 7 + layer * 3) % 5)) * 57.29578 + float(n * 53 + layer * 97 + i * 13)
                let shape = 1.0 - abs(cx + sin(t * 140.0 + float(i)) * 0.8) / float(half + 1)
                let h = floor((15.0 - float(layer) * 4.0) * shape * (0.72 + 0.28 * sin(ph)) + 0.5)
                if h > 0.0: gl.color(col): gl.translate(float2 { cx - 0.5, -h - 2.0 } / 1.7): gl.rect(float2 { 1.0, h } / 1.7)
        for(6) k:  // a thread of smoke, drifting
            let u = (t * 0.35 + float(k) / 6.0) % 1.0
            gl.color(float4 { 0.62, 0.6, 0.58, 0.28 * (1.0 - u) }):
                gl.translate(float2 { sin(u * 200.0 + float(i) * 40.0) * 3.0 + u * 10.0 - 2.0, -12.0 - u * 46.0 }): gl.rect(float2 { 3.0 + u * 7.0, 3.0 + u * 5.0 })

def fires_glow():
    if not atmo_on or not fires.length: return
    let src = atmo_source("building_fire")
    for(fires) p, i: atmo_glow(src, (p - float2 { 0.0, 4.0 }) / 1.5, float3 { 1.0, 0.6, 0.25 }, 1.0, float(i) * 3.1)

// ------------------------------------------------------------------ words on the screen (the letter, the end)

let FONT = "data/fonts/Droid_Sans/DroidSans.ttf"  // (Lobster's own, as Creel uses)

def veil(a:float):
    if a <= 0.0: return
    let ws = float(gl.window_size())
    gl.set_shader("color_attr")
    gl.draw_mesh("PC", [ float3 { 0.0, 0.0, 0.0 }, float3 { ws.x, 0.0, 0.0 }, float3 { ws.x, ws.y, 0.0 }, float3 { 0.0, ws.y, 0.0 } ],
                 map(4): float4 { 0.03, 0.03, 0.025, min(a, 1.0) }, []::float3, []::float2, []::float2, [ 0, 2, 1, 0, 3, 2 ])

// Lines of text down the middle of the window, each fading in after the one before it (t seconds in).
def draw_lines(texts:[string], t:float, size:int):
    let ws = float(gl.window_size())
    gl.set_shader("color")
    gl.set_font_name(FONT)
    gl.set_font_size(size)
    let gap = float(size) * 1.9
    var y = ws.y / 2.0 - gap * float(texts.length) / 2.0
    for(texts) l, n:
        let a = clamp((t - 0.6 - float(n) * 1.4) / 1.2, 0.0, 1.0)
        if a > 0.0:
            let w = float(gl.text_size(l).x)
            gl.color(float4 { 0.93, 0.89, 0.78, a }):
                gl.translate(float2 { floor(ws.x / 2.0 - min(w, ws.x * 0.7) / 2.0), floor(y) }): gl.text(l)
        y += gap

// ------------------------------------------------------------------ orders

def unit_at_screen(m:float2) -> int:
    var best = -1
    var best_d = 22.0 * zoom
    for(u_x.length) i:
        let s = to_screen(gp(float(u_x[i]), float(u_y[i])) - float2 { 0.0, 14.0 })
        let d = magnitude(float2 { (s.x - m.x) * 1.6, s.y - m.y })
        if d < best_d:
            best_d = d
            best = i
    return best

var drag_from = float2_0
var dragging = false
var last_click = -10.0

def select_tick():
    let m = mouse_px()
    if gl.button("mouse1") == 1:
        drag_from = m
        dragging = true
    if dragging and gl.button("mouse1") < 1:
        dragging = false
        if magnitude(m - drag_from) > 6.0:
            let lo = min(m, drag_from)
            let hi = max(m, drag_from)
            selected = []
            for(u_x.length) i:
                let s = to_screen(gp(float(u_x[i]), float(u_y[i])))
                if s.x >= lo.x and s.x <= hi.x and s.y >= lo.y - 10.0 and s.y <= hi.y + 20.0 * zoom: selected.push(u_id[i])
        else:
            let i = unit_at_screen(m)
            if i >= 0 and gl.time() - last_click < 0.4: selected = copy(u_id)  // (a second click: every man)
            elif i >= 0: selected = [ u_id[i] ]
            else: selected = []
            last_click = gl.time()
    if gl.button("escape") == 1: selected = []

// The young tree the mouse is on: its cell, or the one its picture stands on (a tree is drawn up from its foot). Or
// the heap of a landslide's debris the mouse is on (#20): the men dig that away as they fell a tree.
def young_tree_at(mm:float2) -> int:
    let young = str_index(tr_names, "young_tree")
    let heap = str_index(tr_names, "rubble")
    for(3) n:
        let x = int(mm.x / 1000.0) + n
        let y = int(mm.y / 1000.0) + n
        if x >= 0 and y >= 0 and x < W and y < H and (terrain[y * W + x] == young or (n == 0 and terrain[y * W + x] == heap)): return y * W + x
    return -1

def order_tick():
    if gl.button("mouse2") != 1: return
    let ids = filter(selected) id: index_of(id) >= 0
    if not ids.length: return
    let mm = mouse_milli()
    let tree = young_tree_at(mm)
    // (a broken bridge under the mouse: mend it, if the chosen men carry the wood for it)
    let mc = clamp(int(mm.y / 1000.0), 0, H - 1) * W + clamp(int(mm.x / 1000.0), 0, W - 1)
    var broken = -1
    for(br_cells) cells, k:
        let under = find(cells): _ == mc
        if br_up[k] == 0 and under >= 0: broken = k
    if broken >= 0:
        if mend_bridge(ids, broken): mark_at = gp(mm.x, mm.y)
    elif tree >= 0:
        issue_cmd(0, CMD_GATHER, ids, tree, 0, 0, 0)
        mark_at = gp(float((tree % W) * 1000 + 500), float((tree / W) * 1000 + 500))
    else:
        let x = clamp(int(mm.x), 0, W * TILE - 1)
        let y = clamp(int(mm.y), 0, H * TILE - 1)
        issue_cmd(0, CMD_MOVE, ids, x, y, 0, 0)
        mark_at = gp(float(x), float(y))
    mark_t = gl.time()

// The camera stays over the place, far enough in from its edge that the view never runs off the map (the place has a
// rim of forest that deep: the map's "rim").
def cam_keep():
    let rim = float(gint(su_map, "rim", 0)) * 1000.0
    let t = pick_milli(cam)
    cam = gp(clamp(t.x, rim, float(W * 1000) - rim), clamp(t.y, rim, float(H * 1000) - rim))

def camera_tick():
    let ws = float(gl.window_size())
    let m = mouse_px()
    let sp = 900.0 * gl.delta_time() / zoom
    var d = float2_0
    if gl.button("left") >= 1 or gl.button("a") >= 1: d.x -= 1.0
    if gl.button("right") >= 1 or gl.button("d") >= 1: d.x += 1.0
    if gl.button("up") >= 1 or gl.button("w") >= 1: d.y -= 1.0
    if gl.button("down") >= 1 or gl.button("s") >= 1: d.y += 1.0
    let inside = m.x > 0.0 and m.y > 0.0 and m.x < ws.x and m.y < ws.y
    if inside and not capture and gl.window_focused():
        if m.x <= 3.0: d.x -= 1.0
        if m.y <= 3.0: d.y -= 1.0
        if m.x >= ws.x - 4.0: d.x += 1.0
        if m.y >= ws.y - 4.0: d.y += 1.0
    cam += d * sp
    let wheel = gl.mousewheel_delta()
    if wheel > 0: zoom = min(4.0, zoom + 0.25)
    if wheel < 0: zoom = max(0.75, zoom - 0.25)
    if gl.button("f") == 1: cam = men_centre()
    // (the camera stays over the place)
    cam_keep()

// ------------------------------------------------------------------ the tour (script:tour): the men walk the route alone

var tour_sent = ""
var tour_cut = false

def tour_tick():
    if script != "tour" or run_over(): return
    let ids = map(filter(men) m: m.alive) m: m.uid
    if not ids.length: return
    if not gates_armed: return
    // one man fells the first young tree he finds, once, on the way out
    if not tour_cut and leg_id == gstr(route, "start", ""):
        tour_cut = true
        let young = str_index(tr_names, "young_tree")
        var best = -1
        var best_d = 1 << 40
        let i = index_of(ids[0])
        for(terrain) t, c:
            if t == young:
                let d = dist2(u_x[i], u_y[i], (c % W) * TILE + 500, (c / W) * TILE + 500)
                if d < best_d:
                    best_d = d
                    best = c
        if best >= 0: issue_cmd(0, CMD_GATHER, [ ids[0] ], best, 0, 0, 0)
    let waiting = tour_cut and leg_id == gstr(route, "start", "") and u_carry[index_of(ids[0])] < r_carry and tick < 3000
    if tour_sent != leg_id and not waiting:
        tour_sent = leg_id
        let exits = gobj(leg_now(), "exits")
        if exits.keys.length:
            let r = gate_rects[gate_index(exits.keys[0])]
            issue_cmd(0, CMD_MOVE, ids, (r[0] + r[2] + 1) * TILE / 2, (r[1] + r[3] + 1) * TILE / 2, 0, 0)
    if tick % 5 == 0:
        cam += (men_centre() - cam) * 0.08
        cam_keep()

// ------------------------------------------------------------------ the start

fatal(gl.window("Smyana", 1600, 900, window_flags(false, not capture and not has_s(args, "windowed"))))
fatal(gl.load_materials(SPRITE_SHADERS, true))
fatal(gl.load_materials(TERRAIN_SHADERS, true))
fatal(gl.load_materials(cliff_shaders(), true))
fatal(gl.load_materials(ATMO_SHADERS, true))
pace_background = not capture
pace(PACE_MATCH)
lib_load("../data")
route_load()
// The camera's angle is the game's own setting (D-051; Dominic: "Camera angle should be game setting not engine
// enforced"): route.json's "camera_elev", degrees down from level, 22 where Creel's own is 30. Lower, so the wood
// stands taller and you see further into it, as in the mock-ups. Creel's settings for it all follow from the one
// angle, and are set here before anything is baked or drawn (elev:<degrees> for a look at another).
let view_elev = if arg_of("elev") != "": string_to_float(arg_of("elev")) else: gfloat(route, "camera_elev", 30.0)
iso_k = 0.048 * sin(view_elev)
vx_ELEV = view_elev
VM_VIEW = float3 { -view_elev, 45.0, 0.0 }
LEVEL_PX = 20.0 * cos(view_elev) / cos(30.0)
atmo_data = lib_data("atmosphere.json")
for(atmo_problems(atmo_data)) why: print why
sun_from_data()
zoom = max(1.0, floor(float(gl.window_size().y) / 325.0 * 4.0) / 4.0)
if arg_of("zoom") != "": zoom = string_to_float(arg_of("zoom"))  // zoom:2.75: the camera this close, for a look beside a mock-up

// A frame of words while something long is made (the first start bakes the men and the trees).
let waiting_lines = [ "Smyana" ]
let waiting_t0 = seconds_elapsed()
def waiting_frame():
    if not gl.frame(): return
    gl.clear(float4 { 0.03, 0.03, 0.025, 1.0 })
    gl.blend(1)
    draw_lines(waiting_lines, 10.0 + seconds_elapsed() - waiting_t0, int(float(gl.window_size().y) / 36.0))

waiting_frame()
waiting_frame()
let boot0 = seconds_elapsed()
bake_men(): waiting_frame()
bake_trees(): waiting_frame()
bake_camp(): waiting_frame()
run_begin()
if arg_of("leg") != "": enter_leg(arg_of("leg"), "west")  // leg:<id>: start at this leg of the route, for a look
if has_s(args, "mended"):
    // (mended: this place's broken bridges standing again, for a look)
    for(br_id.length) k:
        br_up[k] = 1
        set_deck(br_cells[k], true)
// camp or camp:<x>,<y>: the men round a fire (at that tile), for a look at the camp's light
if has_s(args, "camp") or arg_of("camp") != "":
    let at = arg_of("camp")
    if at != "":
        let xy = map(tokenize(at, ",", " ")) v: string_to_int(v)
        let c = int2 { xy[0] * TILE + 500, xy[1] * TILE + 500 }
        // (a place laid out as a scene says where some of them stand, "men": x, y in milli-tiles; the rest sit close
        // round the fire)
        let apart = glist(su_map, "men")
        let round_fire = max(1, u_x.length - apart.length)
        for(u_x.length) i:
            if i < apart.length:
                u_x[i] = as_int(apart[i].a[0])
                u_y[i] = as_int(apart[i].a[1])
            else:
                // (round its far side and its flanks: nobody stands between the fire and the camera)
                let a = 100.0 + float(i - apart.length) * 250.0 / float(max(1, round_fire - 1))
                let r = if apart.length: 620.0 + float((i * 7) % 3) * 230.0 else: 1300.0 + float((i * 7) % 5) * 380.0
                u_x[i] = c.x + int(cos(a) * r)
                u_y[i] = c.y + int(sin(a) * r)
        // (they stay where they are put: the order that walked them in from the gate is called off)
        issue_cmd(0, CMD_STOP, copy(u_id), 0, 0, 0, 0)
        p_id = []
        // (and a clearing in a close wood round it, as in the mock-up: open within three tiles, thick trees beyond)
        let tx = c.x / TILE
        let ty = c.y / TILE
        let old = str_index(tr_names, "tree")
        let grass = str_index(tr_names, "grass")
        // (a place laid out as a scene keeps its own trees)
        for(if gint(su_map, "scene", 0) != 0: 0 else: 31) dy: for(31) dx:
            let x = tx + dx - 15
            let y = ty + dy - 15
            if x >= 0 and y >= 0 and x < W and y < H:
                let cell = y * W + x
                let d = sqrt(float((dx - 15) * (dx - 15) + (dy - 15) * (dy - 15)))
                if d < 3.0 and terrain[cell] == old: terrain[cell] = grass
                elif d >= 3.6 and terrain[cell] == grass and cell_hash(cell + 777) % 100 < int(min(60.0, (d - 3.0) * 25.0)): terrain[cell] = old
        map_version++
        cam = gp(float(c.x), float(c.y))
        fires = [ cam ]
    else:
        fires = [ men_centre() + float2 { 0.0, 6.0 } ]
view_enter(): waiting_frame()
// (round a camp's fire the men face it)
for(fires) f:
    for(u_x.length) i:
        let to_fire = f - gp(float(u_x[i]), float(u_y[i]))
        if magnitude(to_fire) < 75.0 and dir_of(to_fire) >= 0: man_dir.set(u_id[i], dir_of(to_fire))
if arg_of("look") != "":  // look:<x>,<y>: the camera on this tile
    let xy = tokenize(arg_of("look"), ",", " ")
    cam = gp(string_to_float(xy[0]) * 1000.0, string_to_float(xy[1]) * 1000.0)
print "start: {seconds_elapsed() - boot0} s (men baked in {men_bake_s} s, trees in {trees_bake_s} s; 0: read from bake_cache/)"

// ------------------------------------------------------------------ the loop

var phase = "arriving"  // arriving (fading in), play, leaving (fading out), letter, end
var phase_t = 0.0
var leave_edge = ""
var letter = []::string
var letter_loaded = false
var acc = 0.0
var paused = false
var frame_no = 0
var shot_taken = false

def set_phase(p:string):
    phase = p
    phase_t = 0.0

// The next place set up, behind the letter: the world, then the view's part (its ground, this season's crowns).
def load_next():
    let t0 = seconds_elapsed()
    trees_bake_s = 0.0
    route_arrive(leave_edge)
    view_enter(): pass()
    view_load_s = seconds_elapsed() - t0
    print "loaded {leg_id} in {view_load_s} s (the world {last_load_s} s, crowns baked {trees_bake_s} s), behind a letter of {gint(route, "letter_seconds", 20)} s"

while gl.frame():
    let dt = min(gl.delta_time(), 0.1)
    frame_no++
    phase_t += dt
    if gl.button("space") == 1: paused = not paused
    if phase == "play" or phase == "arriving" or phase == "leaving":
        if phase == "play":
            select_tick()
            order_tick()
        camera_tick()
        if not paused: acc = min(acc + dt, 0.5)
        while acc >= 0.05:
            p_id = copy(u_id)
            p_x = copy(u_x)
            p_y = copy(u_y)
            step()
            for(u_x.length) i:
                let px, py = prev_pos(i)
                if u_moving[i] == 1: man_walked.set(u_id[i], man_walked.get(u_id[i], 0.0) + sqrt(float(dist2(px, py, u_x[i], u_y[i]))))
            let edge = route_tick()
            tour_tick()
            clock_s += 0.05
            acc -= 0.05
            if edge != "" and phase == "play":
                leave_edge = edge
                set_phase("leaving")
                selected = []
        mood_tick()
    if phase == "arriving" and phase_t >= 1.5: set_phase("play")
    if phase == "leaving" and phase_t >= 1.5:
        route_leave(leave_edge)
        letter = gstrs(gobj(route, "letters"), gstr(exit_by(leave_edge), "letter", ""))
        letter_loaded = false
        set_phase("letter")
    if phase == "letter":
        if not letter_loaded and phase_t > 0.3:  // (the letter is on the screen first: the load stops the picture for its length)
            load_next()
            letter_loaded = true
        let hold = if script == "tour": 6.0 else: float(gint(route, "letter_seconds", 20))
        let skip = letter_loaded and phase_t > 2.0 and (gl.button("mouse1") == 1 or gl.button("space") == 1 or gl.button("return") == 1)
        if letter_loaded and (phase_t >= hold or skip):
            paused = false
            set_phase(if run_over(): "end" else: "arriving")
    if drawing():
        gl.clear(float4 { 0.035, 0.055, 0.04, 1.0 })
        gl.blend(1)
        if phase == "letter":
            draw_lines(letter, phase_t, int(float(gl.window_size().y) / 34.0))
        elif phase == "end":
            draw_lines([ "Home.", "{men_alive()} of {men.length} men came back." ], phase_t, int(float(gl.window_size().y) / 30.0))
        else:
            draw_world(acc / 0.05)
            if dragging and magnitude(mouse_px() - drag_from) > 6.0:
                let a = drag_from
                let b = mouse_px()
                ui_batch():
                    for([ [ a, float2 { b.x, a.y } ], [ float2 { b.x, a.y }, b ], [ b, float2 { a.x, b.y } ], [ float2 { a.x, b.y }, a ] ]) l: ui_line(l[0], l[1], 1.2, float4 { 0.95, 0.91, 0.79, 0.7 })
            veil(if phase == "arriving": 1.0 - phase_t / 1.5 elif phase == "leaving": phase_t / 1.5 else: 0.0)
        if debug_line:
            gl.set_shader("color")
            gl.set_font_name(FONT)
            gl.set_font_size(16)
            gl.color(float4 { 1.0, 1.0, 1.0, 0.8 }):
                gl.translate(float2 { 10.0, 8.0 }): gl.text("{leg_id}  {season_now()}  {int(hour_now())}h  {atmo_mood}  men {men_alive()}  {int(1.0 / max(dt, 0.001))} fps  {phase}")
    if shot != "" and not shot_taken and (clock_s >= shot_at or (phase == "end" and phase_t > 5.0)) and (arg_of("in") == "" or arg_of("in") == phase or arg_of("in") == leg_id):
        gl.screenshot(shot)
        shot_taken = true
        print "shot {shot} at {clock_s} s: {leg_id}, {phase}, tick {tick}"
        if script != "tour": break
    wall_s += dt
    if shots_dir != "" and wall_s >= shots_next:
        gl.screenshot("{shots_dir}/{100 + shots_n}.png")
        print "shot {100 + shots_n}: {leg_id} {phase} {clock_s} s"
        shots_n++
        shots_next += if arg_of("every") != "": string_to_float(arg_of("every")) else: 8.0
    if script == "tour" and phase == "end" and phase_t > 6.0: break
