// ------------------------------------------------------------------ Smyana: the game
// The window, the camera, what's drawn and how the men are told what to do, on Creel. The run itself (the route, one
// map per place, what carries across) is smyana/route.lobster; this shows it and plays the letter home between places.
// Run from src/ (../play.sh does):  lobster smyana.lobster -- [windowed] [shot:<png> at:<seconds>] [script:tour] [debug]
// No panels or bars (D-021): what there is to read is in the world. Left click or drag picks men, right click sends
// them (onto a young tree: fell it), the arrows or WASD move the camera, the wheel zooms, F finds the men, Space pauses.
// It opens on the menu: the men in the wood, alive, under the game's name; Start and the name fades away (#86).
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
import smyana.gunfire
import smyana.trees
import smyana.cliff
import smyana.camp
import smyana.music
import smyana.cursors

// ------------------------------------------------------------------ what it was started with

let args = command_line_arguments()
def arg_of(key:string) -> string:
    for(args) a: if starts_with(a, key + ":"): return substring(a, key.length + 1, -1)
    return ""
let shot = arg_of("shot")
let shot_at = if arg_of("at") != "": string_to_float(arg_of("at")) else: 4.0
let script = arg_of("script")  // "tour": the men walk the whole route by themselves (captures, and timing the loads)
let debug_line = has_s(args, "debug")
let show_cover = has_s(args, "cover")                                             // cover: a mark on each tile, the more solid the better it hides a man (#9), for a look
hour_force = if arg_of("hour") != "": string_to_float(arg_of("hour")) else: -1.0  // hour:16.5: this place at that hour, for a look
year_force = if arg_of("year") != "": string_to_int(arg_of("year")) else: -1      // year:1300: this place at that point of the year (0 summer, 1000 autumn, 2000 winter, 3000 spring), for a look
wood_force = arg_of("wood")                                                       // wood:conifer: this place with another wood's trees, for a look
season_force = arg_of("season")                                                   // season:autumn: this place in another season, for a look
weather_force = arg_of("weather")                                                 // weather:rain: this place in mist, rain or snow, for a look
let shots_dir = arg_of("shots")                                                   // a picture every few seconds into this folder (with script:tour)
var shots_n = 0
var shots_next = 3.0
var wall_s = 0.0
let music_arg = arg_of("music")  // music:off, or music:<a danger, a moment or a track> to hear it from the start (data/music.json)
let capture = shot != "" or script != "" or arg_of("shots") != ""

// ------------------------------------------------------------------ the camera (art px: a tile is 96 x 48)

var cam = float2_0  // art px at the middle of the window
var zoom = 1.5      // screen px an art px

// The zoom (#86) in steps of the window's own height, so a view is the same on any screen (a Retina display has twice
// the pixels) and the wheel always comes back to where it started. 1 is the window 325 art px high (a man about a
// tenth of it); each step is rounded to a quarter so the pixels of the art keep an even size. Dominic: "Default camera
// zoom seems too close, when i zoom out, i cant zoom back to the default": it starts a step further out than before.
let ZOOM_STEPS = [ 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.15, 1.3, 1.5 ]
let ZOOM_START = 4
var zoom_step = ZOOM_START
var zoom_fixed = 0.0  // the zoom: option's zoom, till the wheel turns (0: the step's)
def zoom_of(step:int) -> float:
    return max(0.5, floor(float(gl.window_size().y) / 325.0 * ZOOM_STEPS[step] * 4.0 + 0.5) / 4.0)
// How fast the camera moves: window heights a second, whatever the zoom (Dominic: "Camera movement too slow").
let CAM_SPEED = 1.6

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
    lift:float
var canopies = []::Canopy
// The broadleaves in view that are shedding (#11): where each one's foot is (art px), its kind, and how fast it sheds
// (0 .. 1). Their leaves are drawn coming down (draw_leaf_fall).
class Shedding:
    at:float2
    sp:string
    pick:int
    rate:float
    seed:int
var shedding = []::Shedding
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

// Which trees stand in this place (the map's "wood": beech or conifer), picked per cell.
// (deep: the high dark woods, where the trunks run up out of sight and only the understorey is a tree's whole height)
def old_kind(wood:string, pick:int) -> string, int:
    let sp = old_species(wood, pick)
    return sp, pick % (if sp == "pine": PINE_KINDS else: 3)

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
// Damp ground: water, a ford or a rock face within a tile (where the male fern grows, out of the wood too).
def near_wet(c:int) -> bool:
    let wet = [ str_index(tr_names, "water"), str_index(tr_names, "ford"), str_index(tr_names, "rock") ]
    for(3) dy:
        for(3) dx:
            let x = c % W + dx - 1
            let y = c / W + dy - 1
            if x >= 0 and y >= 0 and x < W and y < H:
                let t = terrain[y * W + x]
                if t == wet[0] or t == wet[1] or t == wet[2]: return true
    return false

def mixed(n:int) -> int:
    var v = (n + 0x9E3779B9) & 0xFFFFFFFF
    v = ((v ^ (v >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
    v = ((v ^ (v >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
    return v ^ (v >> 16)

let TUFTS_A_TILE = 36
let LITTER_THIN = 0.38  // the leaves' weight where turf shows through them a pixel in two
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
    if arg_of("props") == "0": return  // props:0: the bare ground and its cliffs, for a look at them
    props = []
    let debris_t = str_index(tr_names, "rubble")
    props_version = map_version
    let wood = place_wood()
    let pines = gint(su_map, "pines", 1) != 0
    let crags = gint(su_map, "crags", 1) != 0
    let trail_t = str_index(tr_names, "trail")
    let water_t = str_index(tr_names, "water")
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
            let sp0, k = old_kind(wood, species_pick(c))
            // (a place can say it has no pines among its beeches, "pines": 0: the mock-up's clearing has none)
            let sp = if (sp0 == "pine" or sp0 == "bpine") and not pines: "beech" else: sp0
            props.push(Prop { 0, k, "{sp}{k}", sp, off, c })
        elif t == young:
            let fir = not broadleaved(wood) and ((h / 7) % 4 != 0 or gint(su_map, "spruce", 0) == 1)
            props.push(Prop { 1, h / 7, if fir: "yspruce{(h / 7) % YOUNG_KINDS}" else: "young{(h / 7) % YOUNG_KINDS}", if fir: "spruce" else: "beech", centre, c })
        elif t == stump:
            // (and what was left when it was sawn up lies beside it: its top and boughs, a round of its trunk)
            props.push(Prop { 2, 0, "stump", "", centre, c })
            props.push(Prop { 6, 0, "brash{(h / 7) % BRASH_KINDS}", "", centre + iso(float((h / 5) % 300) + 150.0, float((h / 11) % 300) - 150.0), c })
        elif t == rock:
            props.push(Prop { 3, 0, "rock{(h / 7) % ROCK_KINDS}", "", off, c })
        elif t == debris_t:
            // a landslide's debris (#20): a heap of earth and broken rock on each tile, a broken trunk here and there
            props.push(Prop { 3, 0, "rubble{(h / 7) % RUBBLE_KINDS}", "", off + iso(float((h / 5) % 500) - 250.0, float((h / 23) % 500) - 250.0), c })
            if (h / 3) % 5 == 0: props.push(Prop { 6, 0, "log{h % LOG_KINDS}", "", off + iso(float(h % 500) - 250.0, float((h / 9) % 500) - 250.0), c })
        // a cliff's foot (#20): crags stand against the face behind this tile (to its north, or to its west), more
        // of them where the face turns a corner, and loose rock lies between them
        // (a place can leave them out, "crags": 0: the ridge's far walls, seen in fog, where lit crags read as snow)
        if t != debris_t and t != rock:
            let cx = c % W
            for([ -W, -1 ]) d, side:
                let n = c + d
                if n >= 0 and (side == 0 or cx > 0) and level[n] - level[c] >= 2 and crags:
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
            let h2 = cell_hash(c + 40507)
            // (bracken: a patch of it covers the tile, in drifts out in the light)
            if bracken_at(c): props.push(Prop { 5, 0, "fern{h2 % FERN_KINDS}", "", centre + iso(float((h2 / 11) % 300) - 150.0, float((h2 / 17) % 300) - 150.0), c })
            // (male ferns: in groups of a few, only in the shade and the damp, under the wood, by water, at a rock's foot)
            let damp = near_wet(c)
            if (shade_at(c) >= 9 or damp) and woods_field(c % W, c / W, 3.0, 5113) > (if damp: 0.45 else: 0.6):
                for(1 + h2 % 3) k:
                    let hk = mixed(c * 7 + k + 31)
                    props.push(Prop { 5, 0, "malefern{(hk / 5) % MALE_FERN_KINDS}", "", centre + iso(float((hk / 11) % 800) - 400.0, float((hk / 13) % 800) - 400.0), c })
            // (soft grass: pale tufts standing out of the leaves in drifts a few tiles across, thick at a drift's
            // middle and thinning to single tufts at its edge; a low herb here and there among them)
            var shading = 0
            for(5) dy: for(5) dx:
                let nx = c % W + dx - 2
                let ny = c / W + dy - 2
                if nx >= 0 and ny >= 0 and nx < W and ny < H and terrain[ny * W + nx] == old: shading++
            let sunny = clamp(1.15 - float(shading) / 7.0, 0.08, 1.0)
            var edge_grass = 0.0
            for([ -1, 1, -W, W ]) d:
                let n = c + d
                if n >= 0 and n < W * H and abs(n % W - c % W) <= 1 and (terrain[n] == trail_t or terrain[n] == water_t): edge_grass = 0.55
            for(TUFTS_A_TILE) k:
                // (three well-mixed numbers a tuft: where in the tile, and its chance)
                let h3 = mixed(c * TUFTS_A_TILE + k)
                let at = float2 { float((c % W) * 1000 + h3 % 1000), float((c / W) * 1000 + (h3 / 1000) % 1000) }
                // (grass wants light: thick in a clearing, thin under a close wood)
                // (and it masses along a trail's sides and a stream's bank, as in the mock-up)
                let thick = max(drift_at(at.x / 1000.0, at.y / 1000.0, grass_seed), edge_grass) * sunny
                if thick * 100.0 > float((h3 / 1000000) % 100): props.push(Prop { 5, 0, "tuft{(h3 / 7) % TUFT_KINDS}", "", gp(at.x, at.y), c })
                elif k < 2 and thick > 0.5 and (h3 / 3) % 10 < 2: props.push(Prop { 5, 0, "herb{(h3 / 5) % HERB_KINDS}", "", gp(at.x, at.y), c })
            // what lies about (the floor is not swept): dead branches, more of them near trees, and a mossy stone now
            // and then
            let hl = mixed(c + 131071)
            if hl % 100 < 14 + shading * 5:
                props.push(Prop { 6, 0, "branch{(hl / 100) % BRANCH_KINDS}", "", gp(float((c % W) * 1000 + (hl / 1000) % 1000), float((c / W) * 1000 + (hl / 1000000) % 1000)), c })
            if (hl / 7) % 100 < 5:
                props.push(Prop { 6, 0, "stone{(hl / 100) % STONE_KINDS}", "", gp(float((c % W) * 1000 + (hl / 3000) % 1000), float((c / W) * 1000 + (hl / 700000) % 1000)), c })
            // brambles (#8): at a wood's edge, where a tree or two gives half shade, in thickets of a few tiles
            let thicket = mixed((c / W / 3) * W + (c % W) / 3 + 5501) % 10 < 3
            let hb = mixed(c + 88001)
            if shading >= 1 and shading <= 4 and hb % 100 < (if thicket: 45 else: 3):
                props.push(Prop { 5, 0, "bramble{(hb / 100) % BRAMBLE_KINDS}", "", gp(float((c % W) * 1000 + (hb / 1000) % 1000), float((c / W) * 1000 + (hb / 1000000) % 1000)), c })
            if (h2 / 100) % 100 >= 90 and (h2 / 100) % 100 < 94:
                // (a sapling of the wood's own kinds, #98)
                let r = (h2 / 10000) % 10
                let sp = if wood == "oak": (if r < 6: "oak" else: "hornbeam") elif wood == "beech": (if r < 5: "beech" elif r < 8: "oak" else: "hornbeam") else: (if r < 4: "spruce" elif r < 7: "fir" else: "beech")
                props.push(Prop { 5, 0, "sapling_" + sp, "", centre, c })
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
        // (a fourth "far": seen far off, as the ridge's patrol on the far road is, and not marked like the men: a dark
        // shape in the fog, not a figure kept bright, D-084)
        for(camp) e, i: props.push(Prop { 4, 0, as_str(e.a[0]), if e.a.length > 3: as_str(e.a[3]) else: "", stands[i],
                                          (as_int(e.a[2]) / 1000) * W + as_int(e.a[1]) / 1000 })

    // the Roman ruins (#17), where the place has them ("ruins": [name, x, y in milli-tiles] each): the undergrowth
    // grows up round them but not through a wall or a column; on the road (#97) it grows only where the stones are gone
    // or buried, and not in its drain
    let ruins = glist(su_map, "ruins")
    if ruins.length:
        let stands = map(ruins) e: gp(as_float(e.a[1]), as_float(e.a[2]))
        let cells = map(ruins) e: (as_int(e.a[2]) / 1000) * W + as_int(e.a[1]) / 1000
        props = filter(props) pr: pr.kind != 5 or not exists(ruins) e, i:
            let name = as_str(e.a[0])
            if starts_with(name, "road"):
                let n = clamp(string_to_int(substring(name, 4, name.length - 4)), 0, ROAD_PLAN.length - 1)
                let c = ROAD_PLAN[n]
                let d = ROAD_DRAIN[n]
                pr.cell == cells[i] and (c == 'w' or c == 'h') or pr.cell == cells[i] + W and (d == 'd' or d == 'c')
            else: abs(pr.at.x - stands[i].x) < 34.0 and abs(pr.at.y - stands[i].y) < 18.0
        for(ruins) e, i: props.push(Prop { 3, 0, as_str(e.a[0]), "", stands[i], cells[i] })
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

// How much of the year's leaves lie as a carpet over a broadleaf wood's floor, 0 .. 1: they come down through the
// autumn (the season clock's leaves_down) and the snow covers them.
def leaf_carpet() -> float:
    if year_still(): return if season_now() == "autumn": 1.0 else: 0.0
    return float(leaves_down()) / 1000.0 * (1.0 - float(snow_lying()) / 1000.0)

var carpet_step = -1  // (the carpet the litter was last painted for, in eighths)

def build_litter():
    let carpet = leaf_carpet()
    carpet_step = int(carpet * 8.0 + 0.5)
    let w = W * MASK_K
    let h = H * MASK_K
    let a = map(w * h): 0.0
    let r = int(LITTER_REACH * 3.2 * float(MASK_K)) + 1
    for(props) pr:
        if pr.kind == 0 or pr.kind == 2:
            let reach = (if pr.kind == 0: (if leafy(pr.sp): LITTER_REACH else: 1.0) else: 0.6) * (if leafy(pr.sp): 1.0 + 0.25 * carpet else: 1.0) * (0.8 + 0.4 * float(cell_hash(pr.cell) % 100) / 100.0)
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
    let turf_seed = gint(su_map, "grass_seed", 9001)
    if carpet > 0.0 and broadleaved(place_wood()):
        for(h) y: for(w) x:
            // (2026-11-11: the leaves lie over all of it, only a worn spot of turf here and there: the mock-up's grass
            // stands out of the leaves in tufts, it isn't a green floor between drifts of them)
            let patch = float(cell_hash((y / 3) * w + x / 3 + 5003) % 100) / 100.0
            // (later the same day, from the review: "one material". Where the grass stands in drifts the leaves lie
            // thin and the turf shows through them a pixel at a time, in soft patches a few tiles across; and the
            // leaves' weight drifts slowly elsewhere, so the floor is not one tone)
            let thin = drift_at((float(x) + 0.5) / float(MASK_K), (float(y) + 0.5) / float(MASK_K), turf_seed)
            let slow = drift_at((float(x) + 0.5) / float(MASK_K) * 0.6, (float(y) + 0.5) / float(MASK_K) * 0.6, turf_seed + 311)
            let leaves = if patch < 0.05 and open_ground(x, y): 0.36 else: 0.62 + 0.2 * patch
            // (as the leaves come down through the autumn the carpet thickens from what lies under each tree)
            let full = max(a[y * w + x] * (1.0 - 0.35 * thin), leaves - (leaves - LITTER_THIN) * max(thin, slow * 0.45))
            a[y * w + x] = a[y * w + x] + (full - a[y * w + x]) * carpet
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

// The ground by the season (#11): its textures are a set per season (the summer's, which spring shares, autumn's
// with the year's leaves, winter's with the first snow), and as the season clock moves the next set turns in over
// the one before it a texel at a time (Creel's ground_atlas_next and ground_atlas_mix): the leaves gather through the
// autumn, the snow comes over them, and it goes in spring. Which sets, and how far: from the clock's leaves_down
// and snow_lying.
var ground_base = ""
var ground_next = ""
var ground_mix_step = -1

def ground_turn() -> string, string, float:
    if year_still():
        let name = if season_now() == "autumn": "_autumn" elif season_now() == "winter": "_winter" else: ""
        return name, name, 0.0
    let snow = float(snow_lying()) / 1000.0
    if snow > 0.0: return (if year_here() % 4000 < 2250: "_autumn" else: ""), "_winter", snow
    return "", "_autumn", float(leaves_down()) / 1000.0

def ground_season_tick():
    let base, next, t = ground_turn()
    def atlas(name:string) -> resource<texture>?:
        return gl.load_texture("../data/ground/atlas" + (if not broadleaved(place_wood()): "_conifer" else: "") + name + ".png", texture_format_clamp | texture_format_nomipmap | texture_format_nearest_mag | texture_format_nearest_min)
    if base != ground_base or next != ground_next:
        ground_atlas_tex = atlas(base)
        ground_atlas_next = if next != base: atlas(next) else: nil
        ground_base = base
        ground_next = next
        ground_mix_step = -1
    let step = int(t * 48.0 + 0.5)
    if step != ground_mix_step:
        ground_mix_step = step
        ground_atlas_mix = float(step) / 48.0
        // (no drawn line where the fallen leaves and needles end: they thin out onto the grass; under snow less so)
        ground_litter_fringe = 0.3 - 0.2 * (if next == "_winter": ground_atlas_mix elif base == "_winter": 1.0 else: 0.0)
        // (and snow lies on the cliffs' ledges, lips and scree as it lies on the ground)
        relief_snow = if next == "_winter": ground_atlas_mix elif base == "_winter": 1.0 else: 0.0
        ground_stale = true
    // (and the carpet of leaves on a beech wood's floor thickens with it, painted again an eighth at a time)
    if carpet_step >= 0 and int(leaf_carpet() * 8.0 + 0.5) != carpet_step: build_litter()

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
    gunfire_clear()
    if run_over(): return
    // the ground's own textures: a beech wood's leaf litter and grass, or a conifer wood's needles and moss
    ground_base = ""
    ground_season_tick()
    // (a stream is narrower than its tiles and runs a little below its banks, as in the mock-ups)
    // (the water: a narrow stream between banks that slope, pale under the sky as the mock-up's is)
    ground_bank_px = gfloat(su_map, "bank_px", 0.0)
    ground_water_edge = gfloat(su_map, "water_edge", 0.5)
    ground_shore_soft = gfloat(su_map, "shore_soft", 0.5)
    // (a clear mid blue with white dabs of ripples all along it, as the mock-up's stream; Dominic, 2026-11-11: "And the
    // water", of what is not rich enough yet)
    ground_water_shallow = float3 { 0.56, 0.74, 0.90 }
    ground_water_deep = float3 { 0.33, 0.52, 0.80 }
    ground_water_ripples = gfloat(su_map, "ripples", 0.6)
    build_masks()
    build_stream(gfloat(su_map, "stream", 0.25))
    // (a mountain's cliffs are sheer and jog square: no corner of high ground is cut down to a slope)
    relief_sharp = true
    // (and no rim is ruled straight along the tiles: the ground by a drop rises and falls, Dominic's "hard edges")
    relief_rough = (if arg_of("rough") != "": string_to_float(arg_of("rough")) else: gfloat(su_map, "rough", 0.9))
    // (proper cliffs, Creel #25: each drop a curve through the unwalkable tile below it, with ledges, a rolled rim and scree)
    relief_cliffs = if arg_of("cliffs") != "": string_to_float(arg_of("cliffs")) else: gfloat(su_map, "cliffs", 0.0)
    if relief_cliffs > 0.0: relief_rough = 0.0
    // (a high drop hides more of the ground behind it: the ridge's near edge hides four tiles of the valley, D-084)
    relief_occlude = gint(su_map, "occlude", 2)
    // (the fog in a valley, D-084: its top and how deep it is to its thickest, in levels; the mood says how thick)
    let low = glist(su_map, "low_fog")
    atmo_low_fog_at(if low.length == 2: as_float(low[0]) else: 0.0, if low.length == 2: as_float(low[1]) else: 1.0)
    build_relief()
    trail_wear()
    build_trail()
    for(leg_stages()) st: bake_season(st, between)
    build_props()
    build_litter()
    cam = men_centre()

// ------------------------------------------------------------------ the light, by the hour

var atmo_data = jobj()

// The hour a mood starts, this time of year (#13: the days shorten into winter): atmosphere.json's "hours" are high
// summer's, "hours_winter" midwinter's, and between them the hour moves with the season clock.
def mood_hour(name:string) -> float:
    let at = gfloat(gobj(atmo_data, "hours"), name, 0.0)
    return at + (gfloat(gobj(atmo_data, "hours_winter"), name, at) - at) * float(winter_depth()) / 1000.0

def mood_now() -> string:
    let hours = gobj(atmo_data, "hours")
    let h = hour_now()
    var best = ""
    var best_at = -1.0
    var last = ""
    var last_at = -1.0
    for(hours.keys) name:
        if not starts_with(name, "_"):
            let at = mood_hour(name)
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
    let d = light_along(VM_SUN)  // where the light goes
    // (on the screen, the way the shadows fall: the light's way along the ground, as the trees' baker lays them; the
    // light's own way, with its fall from the sky in it, pointed elsewhere, and the men's shadows went another way from
    // the trees', Dominic 2026-11-12)
    let fall = normalize(float2 { dot(float3 { d.x, 0.0, d.z }, view.x), -dot(float3 { d.x, 0.0, d.z }, view.y) })
    // the men's shadows the same way (their baker's ground is x right, y away, seen at the camera's elevation: its
    // depth shrunk by the sine of it, not the half of the old 30 degrees)
    let toward = normalize(float2 { -fall.x, fall.y / sin(vx_ELEV) })
    vx_SUN = normalize(float3 { toward.x, toward.y, tan(elev) })
    atmo_sun_dir = normalize(float2 { -fall.x, fall.y })  // (towards the sun, y up)
    // crisp art (Dominic: "evryhting crisp and sharp" in the mock-ups): little jitter in the voxels' light, and a leaf's
    // light in four hard bands
    vg_dither = gfloat(sun, "dither", 1.0)
    vg_leaf_tones = gfloat(sun, "leaf_tones", 5.0)
    // (a model's own shadow, exact to a voxel: a crown shades its boughs and trunk; and how deep that shade is)
    vg_sun_shadow = gint(sun, "self_shadow", 1) != 0
    vg_shade = gfloat(sun, "self_shade", 0.4)
    bake_light = "sun {elev} {vg_dither} {vg_leaf_tones} {vg_sun_shadow} {vg_shade} fall {int(fall.x * 1000.0)} {int(fall.y * 1000.0)}"
    // (Dominic, 2026-11-11: "concerned the men look a little pixelated". At a zoom between whole numbers every art px
    // drawn the same size, crisp, not two screen px and then three; look option even:0 shows it without)
    sprite_even = arg_of("even") != "0"
    canopy_spread = gfloat(sun, "canopy", 0.0)
    canopy_reach = int(gfloat(sun, "canopy_reach", 3.0))
    canopy_trees = gfloat(sun, "canopy_trees", 14.0)
    canopy_dim = gfloat(sun, "canopy_dim", 0.0)
    canopy_flecks = int(gfloat(sun, "flecks", 0.0))

// A tree's picture with snow on its boughs (#15) once enough snow lies for it, each tree from its own day (and losing
// it on its own day in the thaw); the plain picture till then, and where there is no snowy one.
def snow_frame(name:string, cell:int) -> int:
    if snow_lying() > 250 + cell_hash(cell * 3 + 1) % 500:
        let f = frame_at.get(name + ".snow", -1)
        if f >= 0: return f
    return frame_at.get(name, -1)

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
    for(hours.keys) name:
        if not starts_with(name, "_"):
            let at = mood_hour(name)
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

// A mood's own light in a season where there is one ("day.autumn").
def mood_in_season(m:string, season:string) -> string:
    let own = m + "." + season
    let has = exists(gobj(atmo_data, "moods").keys) name: name == own
    return if has: own else: m

// The two seasons the light stands between, and how far from the first to the second (#14): at a season's height the
// light is that season's own, and between two heights it turns from the one to the other, slowly round the heights.
def light_seasons() -> string, string, float:
    if year_still(): return season_now(), season_now(), 0.0
    let y = year_here() % 4000
    let t = float(y % 1000) / 1000.0
    return SEASONS[y / 1000], SEASONS[(y / 1000 + 1) % 4], t * t * (3.0 - 2.0 * t)

var mood_key = ""

def mood_tick():
    let now, next, t = mood_turn()
    if now == "": return
    let s0, s1, st = light_seasons()
    let step = int(t * 48.0)  // (the turn in small steps: the light set again only when it has moved)
    let sstep = int(st * 32.0)
    let wkind, whard = weather_now()
    let wstep = whard * 24 / 1000
    let key = "{now} {next} {step} {s0} {s1} {sstep} {wkind} {wstep}"
    if key == mood_key: return
    mood_key = key
    // (the hour's turn in the season before, then in the season coming, and the light between the two)
    let why = atmo_set_between(atmo_data, mood_in_season(now, s0), mood_in_season(next, s0), float(step) / 48.0)
    if why != "": print why
    if sstep > 0 and atmo_on:
        let n0 = atmo_nums
        let c0 = atmo_cols
        let o0 = atmo_opt
        let p0 = atmo_opt_cols
        let why1 = atmo_set_between(atmo_data, mood_in_season(now, s1), mood_in_season(next, s1), float(step) / 48.0)
        if why1 != "": print why1
        let k = float(sstep) / 32.0
        atmo_nums = map(atmo_nums) v, i: lerp(n0[i], v, k)
        atmo_cols = map(atmo_cols) v, i: lerp(c0[i], v, k)
        atmo_opt = map(atmo_opt) v, i: lerp(o0[i], v, k)
        atmo_opt_cols = map(atmo_opt_cols) v, i: lerp(p0[i], v, k)
    weather_light(wkind, float(wstep) / 24.0)
    // (and the place's own air, the map's "light", the same way: the high ridge looks out over a valley full of air, D-084)
    light_add(gobj(su_map, "light"), 1.0)
    // (the painter's softening over the whole picture, whatever the hour: atmosphere.json's "paint", or paint:<0..1>
    // for a look at it; Dominic, 2026-11-12: "Try making this a bit more watercolour")
    if atmo_on:
        let pi = find(ATMO_OPT) n: n == "paint"
        if pi >= 0: atmo_opt[pi] = if arg_of("paint") != "": string_to_float(arg_of("paint")) else: gfloat(atmo_data, "paint", 0.0)

// What the weather does to the light (#15: "weather changes the mood"): atmosphere.json's "weather" gives, for mist,
// rain and snow, how much each of a mood's numbers moves at the weather's full strength (added to whatever the hour
// and the season have set), and a haze colour the mood's own turns toward.
def weather_light(kind:string, k:float):
    light_add(gobj(gobj(atmo_data, "weather"), kind), k)

def light_add(w:JV, k:float):
    if k <= 0.0 or not atmo_on or w.kind != J_OBJ: return
    atmo_nums = map(atmo_nums) v, i: clamp(v + gfloat(w, ATMO_NUMS[i], 0.0) * k, ATMO_MIN[i], ATMO_MAX[i])
    atmo_opt = map(atmo_opt) v, i: clamp(v + gfloat(w, ATMO_OPT[i], 0.0) * k, 0.0, ATMO_OPT_MAX[i])
    let haze = gstr(w, "haze_colour", "")
    if haze != "":
        let hi = find(ATMO_COLS) n: n == "haze_colour"
        atmo_cols = map(atmo_cols) v, i: (if i == hi: lerp(v, atmo_hex(haze), k * gfloat(w, "haze_colour_mix", 0.6)) else: v)

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
    lean:float  // art px its top leans to the right just now (a crown in the wind, #15)
    lift:float  // art px its ground is raised (it is sorted by its place on the base plane, as Creel sorts: a hill's near edge hides what's behind it)

var draws = []::Drawable
var fires = []::float2  // the camp's fires, art px: where each one's foot is (draw_fire)
var fires_look = false  // (the camp option's fire, for a look: kept, not the camps')
// The fire's light on what stands round it (Dominic, 2026-11-12: "should be over the men, creating shadow and light on
// them"): each man near a lit fire is lit on his side toward it, and casts a shadow on the ground away from it.
class FireLit:
    f:int        // his frame
    p:float2     // his foot, art px
    to:float2    // toward the fire on the picture (unit)
    away:float2  // away from it on the ground (unit, the map's milli)
    tiles:float  // how far from it on the ground
    k:float      // how much of its light reaches him
    up:bool      // standing (his shadow falls away from it); lying, none
    upto:float   // art px above its foot the light reaches (a tree's trunk, not its crown)
var fire_lits = []::FireLit
let FIRE_LIGHT_TILES = 5.5  // how far the fire's light reaches a man
class Breath:
    p:float2     // his head, art px
    phase:float  // his own breathing, seconds
    every:float  // a breath every so many seconds: the colder the more often it shows
var breaths = []::Breath
let PATCH_LOOKS = [ "mushrooms", "nuts", "berries_blue", "berries_red", "herbs", "greens", "pears" ]
var patch_cells = []::int  // the patches of what the wood gives (smyana/forage.lobster), looked for again now and then
var patch_tick = -1000
var view_lo = float2_0
var view_hi = float2_0

// (art px each of the hills' near edges is raised: its highest tile's level; found again when the hills are rebuilt)
var occ_lifts = []::float
var occ_of = []::Occluder

def occluder_lift(k:int) -> float:
    if occ_of.length != occluders.length or (occ_of.length and occ_of[0] != occluders[0]):
        occ_of = occluders
        occ_lifts = map(occluders) o:
            var top = 0
            for(o.cells) c: top = max(top, level[c])
            float(top) * LEVEL_PX * 1.5
    return occ_lifts[k]

// (art px the ground under what's being added is raised: set it before adding a thing on raised ground)
var add_lift = 0.0

def add(f:int, x:float, y:float, sort_y:float, col:float4, fade:float = 1.0, kind:int = -1, lean:float = 0.0):
    if f < 0: return
    let fr = frames[f]
    let x0 = x - float(fr.ox) * fr.k
    let y0 = y - float(fr.oy) * fr.k
    if x0 < view_hi.x and y0 < view_hi.y and x0 + float(fr.w) * fr.k > view_lo.x and y0 + float(fr.h) * fr.k > view_lo.y:
        let flat = sort_y < -39000.0
        draws.push(Drawable { if flat: sort_y else: sort_y + add_lift, draws.length, f, x, y, col, fade, if kind >= 0: kind elif flat: 1 else: 0, lean,
                              add_lift })

def prev_pos(i:int) -> int, int:
    let found, at = binary_search(p_id, u_id[i])
    return if found: p_x[at] else: u_x[i], if found: p_y[at] else: u_y[i]

// Where things touch the ground (#86, Dominic: "Darkest point should be where anything touches the ground"): a small
// dark oval at the foot of every trunk, young tree, stump and man, drawn on the ground under them. Each: x, y (art px)
// and its half width. In shade, or deep under the canopy where the shade is all one, it is darker still, so a tree
// still stands on the ground there.
var feet = []::float3
let FOOT_DARK = float4 { 0.035, 0.03, 0.022, 0.0 }

// Half a trunk's width at the ground, in its sheet's pixels (measured on the baked trunks: an oak's is broad, a
// hornbeam's slim; a spruce's inside its low boughs).
def trunk_half(sp:string) -> float:
    return if sp == "oak": 16.0 elif sp == "hornbeam": 9.0 elif sp == "beech": 11.5 elif sp == "tall": 11.0 elif sp == "bpine": 12.0 elif sp == "fir": 11.0 else: 10.0

def foot_at(f:int, x:float, y:float, half:float):
    if f >= 0 and x > view_lo.x - 20.0 and x < view_hi.x + 20.0 and y > view_lo.y - 10.0 and y < view_hi.y + 10.0:
        feet.push(float3 { x, y, half * frames[f].k })

// The feet, all at once: two ovals as flat as the ground is seen, a pixel row at a time (crisp, as the art): a faint one
// a little wider than the trunk and a darker one its own width, so it is darkest right at the foot.
def draw_feet():
    let flat = iso_k / 0.048  // (the ground's ovals: sin of the camera's angle)
    def oval(c:float2, half:float, a:float):
        let rows = max(1, int(half * flat + 0.5))
        for(rows * 2) j:
            let dy = (float(j - rows) + 0.5) / float(rows)
            let w = floor(half * sqrt(max(0.0, 1.0 - dy * dy)) + 0.5)
            if w >= 1.0: ui_fill(float2 { c.x - w, c.y + float(j - rows) }, float2 { w * 2.0, 1.0 }, float4 { FOOT_DARK.x, FOOT_DARK.y, FOOT_DARK.z, a })
    ui_batch():
        for(feet) f:
            let c = float2 { floor(f.x + 0.5), floor(f.y + 0.5) }
            let half = max(1.5, f.z)
            oval(c, half * 1.9 + 1.0, 0.25)
            oval(c, half * 1.15 + 0.5, 0.5)

let SASH = float4 { 0.66, 0.19, 0.16, 1.0 }  // the sash's red (the men's 'team' colour)
let ART_UP = 58.8                            // art px a tile of height
var eyes = []::float2                        // where the men are on the picture: crowns over them fade

// The patrol's sash (data/threats.json), where the men wear red.
def patrol_sash() -> float4:
    let c = glist(patrol_cfg(), "sash")
    return if c.length == 3: float4 { as_float(c[0]), as_float(c[1]), as_float(c[2]), 1.0 } else: SASH

def collect_men(alpha:float):
    eyes = []
    let n_looks = gstrs(men_data, "looks").length
    // (the fallen, lying where they were hit, facing the one who shot them)
    for(fallen) f:
        let p = gp(float(f.x), float(f.y))
        let d = dir_of(iso(float(f.by_x - f.x), float(f.by_y - f.y)))
        let facing = (max(0, d) + 2) % 8
        add_lift = lift_at(float(f.x), float(f.y)) * 1.5
        if f.beast != "":
            add(frame_at.get(beast_frame_name(f.beast, BEAST_DOWN, facing), -1), p.x, p.y, p.y - 0.4, float4_1, 1.0, 4)
            continue
        add(frame_at.get(man_frame_name(f.look, POSE_DOWN, facing), -1), p.x, p.y, p.y - 0.4, if f.patrol: patrol_sash() else: SASH, 1.0, 4)
    for(u_x.length) i:
        let m = man_of(u_id[i])
        let pk = patrol_look(u_id[i])
        let beast = beast_kind(u_id[i])
        if beast != "":
            // (a wolf or the bear: walking, or standing, facing the way it goes or what it goes for; the bear up on
            // its hind legs when it rears)
            let px, py = prev_pos(i)
            let x = float(px) + float(u_x[i] - px) * alpha
            let y = float(py) + float(u_y[i] - py) * alpha
            let moving, walking_d = unit_walk(i, man_dir.get(u_id[i], 2), px, py)
            man_dir.set(u_id[i], walking_d)
            let step = int(man_walked.get(u_id[i], 0.0) / beast_cycle(beast) * float(MEN_STEPS)) % MEN_STEPS
            let facing = (walking_d + 2) % 8
            let p = gp(x, y)
            add_lift = lift_at(x, y) * 1.5
            let pose = if bear_rearing(u_id[i]): BEAST_UP elif moving: 1 + step else: 0
            add(frame_at.get(beast_shadow_name(beast, facing), -1), p.x, p.y, p.y - 0.5, float4_1, 1.0, 1)
            add(frame_at.get(beast_frame_name(beast, pose, facing), -1), p.x, p.y, p.y, float4_1, 1.0, 4)
            feet.push(float3 { p.x, p.y, 2.6 })
            continue
        if not m and pk < 0 and u_owner[i] == 1:  // (the mark, on the range)
            let p = gp(float(u_x[i]), float(u_y[i]))
            draws.push(Drawable { p.y, draws.length, -7, p.x, p.y, float4_1, 1.0, 3, 0.0, 0.0 })
        if m or pk >= 0:
            let look = if m: m.look else: n_looks + pk
            let px, py = prev_pos(i)
            let x = float(px) + float(u_x[i] - px) * alpha
            let y = float(py) + float(u_y[i] - py) * alpha
            let moving, walking_d = unit_walk(i, man_dir.get(u_id[i], 2), px, py)
            var d = walking_d
            if not moving and u_task[i] == GATHER and u_target[i] >= 0:
                let nd = dir_of(iso(float((u_target[i] % W) * 1000 + 500) - x, float((u_target[i] / W) * 1000 + 500) - y))
                if nd >= 0: d = nd
            // (standing in a camp, he faces its fire)
            if m and not moving:
                let k = camp_of(i)
                if k >= 0:
                    let fx, fy = camp_xy(k)
                    let fd = dir_of(iso(float(fx) - x, float(fy) - y))
                    if fd >= 0: d = fd
            // (his rifle: aimed at what he was told to fire at, fired, or being loaded again)
            let foe = if u_foe[i] != 0: index_of(u_foe[i]) else: -1
            let gun = gun_pose(u_id[i], moving, foe >= 0)
            if gun >= 0 and foe >= 0:
                let fd = dir_of(iso(float(u_x[foe]) - x, float(u_y[foe]) - y))
                if fd >= 0 and (gun == POSE_AIM or gun == POSE_FIRE): d = fd
            man_dir.set(u_id[i], d)
            let step = int(man_walked.get(u_id[i], 0.0) / man_cycle() * float(MEN_STEPS)) % MEN_STEPS
            let facing = (d + 2) % 8
            var p = gp(x, y)
            add_lift = lift_at(x, y) * 1.5
            // (his needs, read off him (docs/survival.md, #73): asleep he lies with his feet to the fire, cold he
            // shivers when he stands, and his breath shows in the cold, the colder the more often)
            if m and is_asleep(m.uid):
                var fire = gp(x + 1000.0, y)
                for(fires) f: if magnitude(f - p) < magnitude(fire - p): fire = f
                let fd = dir_of(fire - p)
                let lf = frame_at.get(man_frame_name(look, POSE_DOWN, (max(0, fd) + 2) % 8), -1)
                add(lf, p.x, p.y, p.y - 0.4, SASH, 1.0, 4)
                fire_light_man(lf, p, p.y - 0.39, false)
                eyes.push(p - float2 { 0.0, 6.0 })
                continue
            if m and not moving and m.warm < 30000 and (int(gl.time() * 14.0) + u_id[i]) % 3 == 0: p.x += if (int(gl.time() * 14.0) / 3 + u_id[i]) % 2 == 0: 1.0 else: -1.0
            if m:
                let chill = max(35 - air_warmth(), (40000 - m.warm) / 1000)
                if chill > 0: breaths.push(Breath { p - float2 { 0.0, 19.0 }, float(u_id[i] % 13) * 0.37, max(1.8, 4.2 - float(chill) * 0.06) })
            // (by the fire at dark, his shadow is the fire's, thrown behind him: not the sky's)
            if not (fire_dark() > 0.4 and fire_reach_k(p) > 0.05): add(frame_at.get(man_shadow_name(look, facing), -1), p.x, p.y, p.y - 0.5, float4_1, 1.0, 1)
            let mf = frame_at.get(man_frame_name(look, if gun >= 0: gun elif moving: 1 + step else: 0, facing), -1)
            add(mf, p.x, p.y, p.y, if m: SASH else: patrol_sash(), 1.0, 4)
            fire_light_man(mf, p, p.y + 0.01, true)
            feet.push(float3 { p.x, p.y, 2.2 })
            if u_carry[i] > 0: add(frame_at.get("load.wood", -1), p.x + 3.0, p.y - 27.0, p.y + 0.1, float4_1, 1.0, 2)
            eyes.push(p - float2 { 0.0, 16.0 })
    add_lift = 0.0

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
    canopies = []
    flecks = []
    shedding = []
    let day = hour_now() > 6.5 and hour_now() < 19.0
    for(props) pr, pidx:
        if pr.at.x > view_lo.x - 700.0 and pr.at.x < view_hi.x + 250.0 and pr.at.y > view_lo.y - 300.0 and pr.at.y < view_hi.y + 620.0:
            // (each tree and each clump of the undergrowth wears its own stage of the year: no two turn on one day)
            let season = leaf_stage_at(pr.cell + (if pr.kind == 5: pidx else: 0))
            let bare = season == "winter"
            add_lift = if has_heights != 0: float(level[pr.cell]) * LEVEL_PX * 1.5 else: 0.0
            if pr.kind == 0:
                // (deep in a wood a tree stands under its neighbours' crowns: drawn darker, as the floor round it is)
                let dim = float4 { 1.0, 1.0, 1.0, 1.0 - canopy_dim * (if pidx < canopy.length: canopy[pidx] else: 0.0) }
                add(frame_at.get(pr.name + ".shadow", -1), pr.at.x, pr.at.y, -40000.0, float4_1)
                add(snow_frame(pr.name, pr.cell), pr.at.x, pr.at.y, pr.at.y, dim)
                foot_at(frame_at.get(pr.name, -1), pr.at.x, pr.at.y, trunk_half(pr.sp))
                let crown = if pr.sp == "tall": "spruce{pr.pick}.crown.ever" else: pr.name + ".crown." + (if leafy(pr.sp): season else: "ever")
                if pr.sp == "tall":
                    // its crown is out of sight overhead: only its shade reaches the ground
                    add(frame_at.get(crown + ".shadow", -1), pr.at.x, pr.at.y, -39999.0, float4_1)
                elif not leafy(pr.sp) or not bare:
                    // (in autumn its leaves come down, fastest as the crown thins)
                    if leafy(pr.sp) and (season == "autumn" or season == "late"): shedding.push(Shedding { pr.at, pr.sp, pr.pick, if season == "late": 1.0 else: 0.5, cell_hash(pr.cell) })
                    add(frame_at.get(crown + ".shadow", -1), pr.at.x, pr.at.y, -39999.0, float4_1)
                    add(snow_frame(crown, pr.cell), pr.at.x, pr.at.y, pr.at.y + 0.2, dim, crown_fade(pr.at, pr.sp), -1, crown_lean(pr.cell))
                if (pr.sp == "tall" or not leafy(pr.sp) or not bare) and pidx < canopy.length and canopy[pidx] > 0.0:
                    let f = frame_at.get(crown + ".shadow", -1)
                    if f >= 0: canopies.push(Canopy { f, pr.at.x, pr.at.y, 1.0 + (canopy_spread - 1.0) * canopy[pidx], add_lift })
                    if day and canopy[pidx] > 0.5 and (pr.sp == "tall" or not bare):
                        for(canopy_flecks) k:
                            let h = cell_hash(pr.cell * 13 + k + 17)
                            flecks.push(float3 { pr.at.x + float(h % 160) - 80.0, pr.at.y + float((h / 160) % 90) - 45.0, float(h % 997) })
            elif pr.kind == 1:
                if pr.sp == "spruce":
                    add(frame_at.get(pr.name + ".shadow", -1), pr.at.x, pr.at.y, -39998.0, float4_1)
                    add(snow_frame(pr.name, pr.cell), pr.at.x, pr.at.y, pr.at.y, float4_1, 1.0, 2)
                    foot_at(frame_at.get(pr.name, -1), pr.at.x, pr.at.y, 6.0)
                else:
                    // (a young beech: its wood, and over it this season's leaves)
                    foot_at(frame_at.get(pr.name + ".bare", -1), pr.at.x, pr.at.y, 6.0)
                    add(frame_at.get(pr.name + ".bare.shadow", -1), pr.at.x, pr.at.y, -39998.0, float4_1)
                    add(snow_frame(pr.name + ".bare", pr.cell), pr.at.x, pr.at.y, pr.at.y, float4_1, 1.0, 2)
                    if not bare:
                        add(frame_at.get(pr.name + "." + season + ".shadow", -1), pr.at.x, pr.at.y, -39998.0, float4_1)
                        add(frame_at.get(pr.name + "." + season, -1), pr.at.x, pr.at.y, pr.at.y + 0.1, float4_1, 1.0, 2)
            elif pr.kind == 2:
                add(frame_at.get("stump", -1), pr.at.x, pr.at.y, pr.at.y, float4_1, 1.0, 2)
                foot_at(frame_at.get("stump", -1), pr.at.x, pr.at.y, 6.5)
            elif pr.kind == 5:
                // (winter: the bushes and herbs are gone (they have no winter frame), two tufts in three are under the
                // snow, and what's left stands dead)
                // (a conifer's sapling is evergreen: one picture all year)
                if pr.name == "sapling_spruce" or pr.name == "sapling_fir":
                    add(frame_at.get(pr.name + ".shadow", -1), pr.at.x, pr.at.y, -39996.0, float4_1)
                    add(frame_at.get(pr.name, -1), pr.at.x, pr.at.y, pr.at.y, float4_1, 1.0, 2)
                elif not bare or pr.name[0] != 't' or pidx % 3 == 0:
                    // (grass casts no shade of its own: a dot of shade under every tuft made the ground spotty)
                    if pr.name[0] != 't': add(frame_at.get(pr.name + "." + season + ".shadow", -1), pr.at.x, pr.at.y, -39996.0, float4_1)
                    add(frame_at.get(pr.name + "." + season, -1), pr.at.x, pr.at.y, pr.at.y, float4_1, 1.0, 2)
            else:
                add(frame_at.get(pr.name + ".shadow", -1), pr.at.x, pr.at.y, -39997.0, float4_1)
                // (the camp's horses and mules are marked like the men, so they keep their colour in the shade
                // instead of reading as grey ghosts)
                let beast = starts_with(pr.name, "horse") or starts_with(pr.name, "mule") or starts_with(pr.name, "rider")
                add(frame_at.get(pr.name, -1), pr.at.x, pr.at.y, pr.at.y, float4_1, 1.0,
                    if pr.kind == 3: 0 elif beast and pr.sp != "far": 4 else: 2)

    add_lift = 0.0
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
    feet = []
    breaths = []
    fire_lits = []
    if not fires_look: fires = map(fires_lit()) cp: gp(float(cp.x), float(cp.y))
    collect_men(alpha)
    collect_props()
    collect_patches()
    draws.push(Drawable { -39990.0, draws.length, -6, 0.0, 0.0, float4_1, 1.0, 3, 0.0, 0.0 })  // the feet: on the ground, over its shadows
    draws.push(Drawable { -30000.0, draws.length, -4, 0.0, 0.0, float4_1, 1.0, 3, 0.0, 0.0 })  // the rings: on the ground, over the shadows
    // (what stands near a fire, the trunks, tents and beasts: lit on its side toward it, up to a man's height or two)
    if fires.length and atmo_on:
        let n0 = draws.length
        for(n0) n:
            let d = draws[n]
            if d.f >= 0 and (d.kind == 0 or d.kind == 2) and d.fade >= 1.0 and d.lean == 0.0:
                var near = false
                for(fires) fp: if magnitude(iso_inv(float2 { d.x, d.ay } - fp)) > 300.0: near = true
                if near:
                    add_lift = d.lift
                    fire_light_man(d.f, float2 { d.x, d.ay }, d.y - d.lift + 0.01, false, 70.0)
        add_lift = 0.0
    if fires.length and atmo_on: draws.push(Drawable { -39996.0, draws.length, -11, 0.0, 0.0, float4_1, 1.0, 3, 0.0, 0.0 })  // the fire's light on the ground
    if fire_lits.length: draws.push(Drawable { -39995.0, draws.length, -10, 0.0, 0.0, float4_1, 1.0, 3, 0.0, 0.0 })          // the fire's shadows
    for(fires) p, i:
        // (the fireplace: its ring of stones, its logs and the tripod with the cauldron; the flames are the game's own)
        add(frame_at.get("fireplace.shadow", -1), p.x, p.y, -39997.0, float4_1)
        add(frame_at.get("fireplace", -1), p.x, p.y, p.y, float4_1, 1.0, 2)
        draws.push(Drawable { p.y + 0.05, draws.length, -5, float(i), 0.0, float4_1, 1.0, 3, 0.0, 0.0 })
    // (a hill's near edge, drawn again over what stands down behind it: the ridge hides the valley's trees' feet)
    for(occluders) o, k: draws.push(Drawable { o.sort_y, draws.length, -2, float(k), 0.0, float4_1, 1.0, 3, 0.0, occluder_lift(k) })
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
                        // (level by level, from the lowest: the shadows and the canopy of what stands at a level, then the
                        // near edges of the hills above it, lit, so the shade of a valley's trees isn't laid over the
                        // ridge in front of them; there's one level on a map with no hills)
                        let levels = if has_heights != 0: MAX_LEVEL + 1 else: 1
                        let step = LEVEL_PX * 1.5
                        for(levels) lv:
                            def here(lift:float) -> bool: return has_heights == 0 or int(lift / step + 0.5) == lv
                            b_sheet = -1
                            sprite_shader = "atmo_shade_cast"
                            for(draws) d: if d.kind == 1 and here(d.lift): sprite(d.f, d.x, d.ay, d.col)
                            flush_sprites()
                            b_sheet = -1
                            sprite_shader = "atmo_shade_canopy"
                            // (the canopy overhead: a crown's shade spread round itself, as far as the wood is closed: drawn again
                            // at a ring of offsets rather than scaled up, so its pixels stay the art's size and its edge stays fine)
                            for(canopies) cp:
                                if here(cp.lift):
                                    let fr = frames[cp.f]
                                    let rx = float(fr.w) * fr.k * (cp.s - 1.0) * 0.5
                                    let ry = float(fr.h) * fr.k * (cp.s - 1.0) * 0.5
                                    sprite(cp.f, cp.x, cp.y, float4_1)
                                    if rx > 0.5:
                                        for(8) a:
                                            let ang = float(a) * 45.0 + 22.5
                                            sprite(cp.f, cp.x + cos(ang) * rx, cp.y + sin(ang) * ry, float4_1)
                            flush_sprites()
                            if has_heights != 0:
                                gl.set_shader("color")
                                gl.color(float4 { 0.0, 0.0, 0.0, 1.0 }):
                                    for(occluders) o, k: if int(occluder_lift(k) / step + 0.5) == lv + 1: gl.render_mesh(o.tops)
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
        // back to front: what stands up wipes the shade off itself; a man or a horse takes the shade
        // of the ground at his feet from his feet to his head (Dominic, 2026-11-11, of the trees' shadows on the
        // camp's horses: "feels like it flat from camera perspective"), and a man is marked so the light can keep
        // him readable; a tree in front wipes that too
        atmo_shade_standing()
        gl.translate(ws / 2.0):
            gl.scale(zoom):
                gl.translate(-cam_px):
                    var now = -1
                    b_sheet = -1
                    for(draws) d:
                        if d.f == -2:
                            // (a hill's near edge takes back the ground's own shade over whatever stood down behind it)
                            flush_sprites()
                            b_sheet = -1
                            now = -1
                            let o = occluders[int(d.x)]
                            gl.blend(blend_none)
                            gl.set_shader("smyana_shade_restore")
                            let ag = atmo_ground
                            if ag:
                                gl.set_mesh_texture(o.tops, 0, 0, ag)
                                gl.render_mesh(o.tops)
                        elif d.f >= 0 and (d.kind == 0 or d.kind == 4):
                            let k = if d.kind == 0: 0 else: 1
                            if k != now:
                                flush_sprites()
                                b_sheet = -1
                                now = k
                                sprite_shader = if now == 0: "atmo_shade_clear" else: "atmo_shade_stand"
                                gl.blend(if now == 0: blend_alpha else: blend_none)
                            // (the ground just behind his feet, toward the sun: his own shadow falls the other way)
                            sprite(d.f, d.x, d.ay, if d.kind == 0: float4 { d.fade, 0.0, 0.0, 1.0 } else: atmo_stand_colour((float2 { d.x, d.ay - 3.0 } - cam_px) * zoom + ws / 2.0))
                    flush_sprites()
                    gl.blend(blend_alpha)
                    sprite_shader = "sprite"
                    gunfire_shade()
        gl.blend(blend_alpha)
    // the low fog's heights (Creel's atmo_low_begin): the ground's, then what stands on it, back to front, each pixel as
    // high as its foot and how far above it, with the hills' near edges again over what stands down behind them
    if atmo_low_fogging():
        atmo_low_begin(cam_px, zoom)
        gl.blend(blend_none)
        gl.set_shader("atmo_low_stand")
        gl.set_uniform("level_screen", LEVEL_PX * 1.5 * zoom)
        gl.translate(ws / 2.0):
            gl.scale(zoom):
                gl.translate(-cam_px):
                    draw_ground_heights()
                    b_sheet = -1
                    sprite_shader = "atmo_low_stand"
                    for(draws) d:
                        if d.f == -2:
                            flush_sprites()
                            b_sheet = -1
                            draw_occluder_heights(occluders[int(d.x)])
                        elif d.f >= 0 and d.kind != 1:
                            sprite(d.f, d.x, d.ay, atmo_low_colour((float2 { d.x, d.ay } - cam_px) * zoom + ws / 2.0, d.lift / (LEVEL_PX * 1.5)))
                    flush_sprites()
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
                    if d.f == -2:
                        flush_sprites()
                        draw_occluder(occluders[int(d.x)], zoom / ART_K)
                        b_sheet = -1
                    elif d.f == -4:
                        flush_sprites()
                        draw_rings(alpha)
                        b_sheet = -1
                    elif d.f == -5:
                        flush_sprites()
                        draw_fire(int(d.x))
                        b_sheet = -1
                    elif d.f == -6:
                        flush_sprites()
                        draw_feet()
                        b_sheet = -1
                    elif d.f == -7:
                        flush_sprites()
                        draw_mark(d.x, d.ay)
                        b_sheet = -1
                    elif d.f == -8:
                        flush_sprites()
                        draw_patch(d.x, d.ay, int(d.col.x), int(d.col.y))
                        b_sheet = -1
                    elif d.f == -9:
                        flush_sprites()
                        draw_fire_lit(int(d.x))
                        b_sheet = -1
                    elif d.f == -11:
                        flush_sprites()
                        draw_fire_pools()
                        b_sheet = -1
                    elif d.f == -10:
                        flush_sprites()
                        draw_fire_shadows()
                        b_sheet = -1
                    elif shading and d.kind == 1: pass()
                    elif d.fade < 1.0: sprite_faded(d.f, d.x, d.ay, d.col, d.fade)
                    elif d.lean != 0.0: sprite_leaning(d.f, d.x, d.ay, d.col, d.lean)
                    else: sprite(d.f, d.x, d.ay, d.col)
                flush_sprites()
                draw_leaf_fall()
                gunfire_draw()
                draw_weather()
                if show_cover: draw_cover()
                fires_glow()
                gunfire_glow()
    sprite_snap = 1.0
    if atmo_on: atmo_end(cam_px, zoom, 1.5)

// The leaves coming down (#11: "leaves fall and pile up"): from each shedding crown in view a few leaves at a time, a
// pixel or two of the tree's own autumn colour each, swinging as they fall from the crown to the ground at its foot.
// Drawn into the world, so the light falls on them as on everything else.
let LEAVES_A_TREE = 5

def draw_leaf_fall():
    if not shedding.length: return
    let t = gl.time()
    let blow = gust() * 60.0  // (how far the wind carries a leaf on its way down, art px)
    gl.set_shader("color")
    for(shedding) sh:
        let cols = autumn_leaf(sh.sp, sh.pick)
        let top = crown_up(sh.sp) * ART_UP
        let reach = crown_reach(sh.sp) * 60.0
        for(int(float(LEAVES_A_TREE) * sh.rate + 0.5)) k:
            let h = mixed(sh.seed * 31 + k)
            let period = 3.5 + float(h % 300) / 100.0
            let turn = t / period + float((h / 300) % 1000) / 1000.0
            let u = turn - floor(turn)
            // (each fall is its own: where in the crown it lets go changes with every turn)
            let h2 = mixed(h + int(floor(turn)) * 7919)
            let x0 = float(h2 % 2001) / 1000.0 - 1.0
            let from_up = top * (0.55 + 0.5 * float((h2 / 2001) % 1000) / 1000.0)
            let x = sh.at.x + x0 * reach + sin((u * 2.2 + float(h % 97) / 97.0) * 360.0) * 5.0 + u * (7.0 + blow)
            let y = sh.at.y - from_up * (1.0 - u) + x0 * x0 * 6.0 - float((h2 / 7) % 14)
            let c = cols[h % cols.length]
            gl.color(float4 { c.x, c.y, c.z, min(1.0, min(u * 8.0, (1.0 - u) * 5.0)) }):
                gl.translate(float2 { floor(x), floor(y) }): gl.rect(if (h / 11 + int(u * 6.0)) % 2 == 0: float2 { 2.0, 1.0 } else: float2 { 1.0, 2.0 })

// For a look at the cover (#9; the game shows no meter): a dark bar on every open tile in view, lit along as much of
// its length as the tile hides a man.
def draw_cover():
    let grass = str_index(tr_names, "grass")
    let trail = str_index(tr_names, "trail")
    gl.set_shader("color")
    for(terrain) t, c:
        if t == grass or t == trail:
            let at = gp(float((c % W) * 1000 + 500), float((c / W) * 1000 + 500))
            if at.x > view_lo.x and at.x < view_hi.x and at.y > view_lo.y and at.y < view_hi.y:
                let v = floor(float(cover_at(c)) / 10.0 + 0.5)  // (a bar of ten: how much of it is lit)
                let p = float2 { floor(at.x) - 6.0, floor(at.y) - 2.0 }
                gl.color(float4 { 0.05, 0.05, 0.08, 0.75 }): gl.translate(p): gl.rect(float2 { 12.0, 4.0 })
                if v > 0.0: gl.color(float4 { 0.4, 1.0, 1.0, 1.0 }): gl.translate(p + float2_1): gl.rect(float2 { v, 2.0 })

// Wind in the canopy (#15): a crown leans with the gusts, its foot still and its top carried over by up to a few
// pixels of the art in a storm, each tree in its own time. In steps of half a pixel, so a crown moves a row at a time
// and stays crisp.
let CROWN_LEAN = 4.5

def crown_lean(cell:int) -> float:
    let t = gl.time()
    let own = float(cell_hash(cell + 911) % 360)
    let swing = 0.55 + 0.3 * sin(t * 70.0 + own) + 0.15 * sin(t * 173.0 + own * 2.0)
    return floor(float(wind_now()) / 1000.0 * CROWN_LEAN * swing * 2.0 + 0.5) / 2.0

// A frame with its top leaning `lean` art px to the right of where it stands (its bottom row stays put).
def sprite_leaning(f:int, x:float, y:float, col:float4, lean:float):
    let fr = frames[f]
    let x0 = floor(x * sprite_snap) / sprite_snap - float(fr.ox) * fr.k
    let y0 = floor(y * sprite_snap) / sprite_snap - float(fr.oy) * fr.k
    sprite_xf(f, [ fr.k, 0.0, -lean / float(fr.h), fr.k, x0 + lean, y0 ], col)

// The wind as the eye sees it (0 .. 1): the sim's wind (wind_now), coming in gusts.
def gust() -> float:
    let t = gl.time()
    return float(wind_now()) / 1000.0 * (0.7 + 0.2 * sin(t * 47.0) + 0.1 * sin(t * 131.0 + 40.0))

// Rain and snow coming down (#15), drawn into the world a pixel of the art at a time, so the light of the hour falls
// on them and they stay as crisp as everything else. The air is cut into squares fixed to the ground; each holds a few
// drops or flakes that fall through it over and over, each from its own place and at its own time, so nothing moves
// with the camera. Rain is short slanted strokes, leaning with the wind, and a fleck where each lands; snow is single
// pixels (a few are two wide) swinging as they sink and carried along by the wind.
let WEATHER_CELL = 44.0

def draw_weather():
    let kind, hard = weather_now()
    if hard <= 0 or (kind != "rain" and kind != "snow"): return
    let k = float(hard) / 1000.0
    let t = gl.time()
    let wind = gust()
    let rain = kind == "rain"
    let each = int(k * (if rain: 9.0 else: 22.0) + 0.5)  // (a spell comes on a drop at a time)
    let fall = if rain: 150.0 else: 90.0
    let lean = if rain: 0.12 + wind * 0.5 else: 0.25 + wind * 1.6  // (sideways for each pixel down)
    let c0 = floor((view_lo - float2 { fall * lean + 8.0, 0.0 }) / WEATHER_CELL)
    let c1 = floor((view_hi + float2 { 8.0, fall }) / WEATHER_CELL)
    gl.set_shader("color")
    for(int(c1.y - c0.y) + 1) gy: for(int(c1.x - c0.x) + 1) gx:
        let cx = int(c0.x) + gx
        let cy = int(c0.y) + gy
        for(each) n:
            let h = mixed(cx * 7349 + cy * 9151 + n * 613)
            let period = if rain: 0.55 + float(h % 30) / 100.0 else: 4.5 + float(h % 250) / 100.0
            let turn = t / period + float((h / 250) % 1000) / 1000.0
            let u = turn - floor(turn)
            let h2 = mixed(h + int(floor(turn)) * 7919)
            let x0 = (float(cx) + float(h2 % 1000) / 1000.0) * WEATHER_CELL
            let y1 = (float(cy) + float((h2 / 1000) % 1000) / 1000.0) * WEATHER_CELL  // (where it lands)
            if rain:
                if u < 0.86:
                    let v = u / 0.86
                    let y = y1 - fall * (1.0 - v)
                    let x = x0 - fall * (1.0 - v) * lean
                    let long = 8 + h % 6
                    gl.color(float4 { 0.8, 0.86, 0.94, 0.42 + 0.2 * k }):
                        for(long / 2 + 1) q:  // (two pixels of height at a time, stepping aside as the stroke leans)
                            gl.translate(float2 { floor(x - float(q) * 2.0 * lean), floor(y) - float(q) * 2.0 }): gl.rect(float2 { 1.0, 2.0 })
                else:
                    let v = (u - 0.86) / 0.14
                    gl.color(float4 { 0.82, 0.88, 0.95, 0.4 * (1.0 - v) }):
                        gl.translate(float2 { floor(x0) - 1.0 - floor(v * 2.0), floor(y1) }): gl.rect(float2 { 3.0 + floor(v * 2.0) * 2.0, 1.0 })
            else:
                let y = y1 - fall * (1.0 - u)
                let x = x0 - fall * (1.0 - u) * lean + sin((u * 1.7 + float(h % 89) / 89.0) * 360.0) * 4.0
                let big = h % 3 == 0
                gl.color(float4 { 0.96, 0.97, 1.0, (if big: 0.95 else: 0.85) * min(1.0, min(u * 6.0, (1.0 - u) * 6.0)) }):
                    gl.translate(float2 { floor(x), floor(y) }): gl.rect(if big: float2 { 2.0, 2.0 } else: float2_1)

// The camp's fires (for now only for a look: the camp option lights one among the men at dusk): the fireplace's model,
// flames drawn unlit, a glow each in the light (atmosphere.json's "glows": "building_fire"), and a thread of smoke.

// A man's breath in the cold air (docs/survival.md): a little pale cloud at his mouth now and then, rising and gone.
// Drawn over the lit world, in the art's pixels, a cool grey that shows on a dark coat and on the night.
def draw_breaths():
    if not breaths.length: return
    gl.set_shader("color")
    let t = gl.time()
    for(breaths) b:
        let u = ((t + b.phase) % b.every) / 1.6
        if u < 1.0:
            let a = 0.7 * (1.0 - u) * min(1.0, u * 5.0)
            let w = floor(3.0 + u * 4.0)
            let at = to_screen(float2 { floor(b.p.x + 2.0 + u * 4.0), floor(b.p.y - u * 5.0) })
            gl.color(float4 { 0.78, 0.8, 0.86, a }):
                gl.translate(floor(at)): gl.rect(float2 { w, max(1.0, w - 2.0) } * zoom)
                gl.translate(floor(at + float2 { zoom, -zoom })): gl.rect(float2 { max(1.0, w - 2.0), 1.0 } * zoom)
                gl.translate(floor(at + float2 { zoom, (w - 2.0) * zoom })): gl.rect(float2 { max(1.0, w - 2.0), 1.0 } * zoom)

// The patches the wood gives (docs/survival.md, #66): drawn on the ground among everything else, so the light and the
// season's dark fall on them too.
def collect_patches():
    if tick - patch_tick >= 40 or tick < patch_tick:
        patch_cells = forage_patches()
        patch_tick = tick
    for(piles) pl:
        let p = gp(float(pl.x), float(pl.y))
        if p.x > view_lo.x and p.x < view_hi.x and p.y > view_lo.y and p.y < view_hi.y:
            draws.push(Drawable { p.y + 1.0, draws.length, -8, p.x, p.y, float4 { -1.0, float(pl.food + pl.goods), 0.0, 0.0 }, 1.0, 3, 0.0, 0.0 })
    let finds = forage_finds()
    for(patch_cells) c:
        let k = patch_at(c)
        if k >= 0:
            let p = gp(float((c % W) * 1000 + 500), float((c / W) * 1000 + 500))
            if p.x > view_lo.x and p.x < view_hi.x and p.y > view_lo.y and p.y < view_hi.y:
                let look = find(PATCH_LOOKS) l: l == gstr(finds[k], "look", "")
                draws.push(Drawable { p.y + 6.0, draws.length, -8, p.x, p.y, float4 { float(look), float(c), 0.0, 0.0 }, 1.0, 3, 0.0, 0.0 })

// One patch, a few pixels of the art about its foot (x, y art px): pale mushroom caps, fallen nuts and husks, a
// fruiting tuft, flowering sprigs. Spread over a stretch of ground and pale against the litter, so it can be found.
def draw_patch(x:float, y:float, look:int, cell:int):
    gl.set_shader("color")
    def px(dx:float, dy:float, w:float, h:float, c:float4):
        gl.color(c): gl.translate(float2 { floor(x) + dx, floor(y) + dy }): gl.rect(float2 { w, h })
    def spot(n:int) -> float2: return float2 { float(cell_hash(cell * 7 + n) % 29) - 14.0, float(cell_hash(cell * 13 + n) % 13) - 6.0 }
    let leaf = float4 { 0.22, 0.36, 0.17, 1.0 }
    let shade = float4 { 0.08, 0.06, 0.04, 0.6 }
    if look < 0:  // a pile of packs: tied sacks and a bundle, more of them the more there is (cell: how much)
        for(clamp(cell / 6 + 1, 1, 6)) n:
            let o = float2 { float(n % 3) * 5.0 - 5.0, float(n / 3) * -3.0 }
            px(o.x - 2.0, o.y + 1.0, 6.0, 1.0, shade)
            px(o.x - 2.0, o.y - 4.0, 5.0, 5.0, float4 { 0.55, 0.45, 0.32, 1.0 })
            px(o.x - 1.0, o.y - 5.0, 3.0, 1.0, float4 { 0.64, 0.54, 0.4, 1.0 })
            px(o.x, o.y - 6.0, 1.0, 1.0, float4 { 0.3, 0.2, 0.12, 1.0 })
            px(o.x - 2.0, o.y - 2.0, 5.0, 1.0, float4 { 0.42, 0.33, 0.22, 1.0 })
        return
    if look == 0:  // mushrooms: pale stems under cream and brown caps, in a ring
        for(7) n:
            let o = spot(n)
            px(o.x - 1.0, o.y, 4.0, 1.0, shade)
            px(o.x, o.y - 2.0, 2.0, 2.0, float4 { 0.94, 0.91, 0.82, 1.0 })
            px(o.x - 1.0, o.y - 4.0, 4.0, 2.0, if n % 3 == 0: float4 { 0.62, 0.4, 0.22, 1.0 } else: float4 { 0.9, 0.84, 0.68, 1.0 })
            px(o.x, o.y - 5.0, 2.0, 1.0, float4 { 0.7, 0.5, 0.3, 1.0 })
    elif look == 1:  // nuts: split pale husks and dark nuts scattered on the litter
        for(12) n:
            let o = spot(n)
            px(o.x, o.y + 1.0, 3.0, 1.0, shade)
            px(o.x, o.y - 1.0, 3.0, 2.0, float4 { 0.86, 0.76, 0.55, 1.0 })
            px(o.x + 1.0, o.y - 1.0, 1.0, 1.0, float4 { 0.3, 0.18, 0.09, 1.0 })
    elif look == 2 or look == 3:  // a fruiting tuft: low leaves, dark blue or red berries
        let berry = if look == 2: float4 { 0.24, 0.26, 0.56, 1.0 } else: float4 { 0.85, 0.14, 0.1, 1.0 }
        for(3) t:
            let o = spot(t + 20)
            px(o.x - 5.0, o.y + 1.0, 11.0, 1.0, shade)
            px(o.x - 5.0, o.y - 2.0, 11.0, 3.0, leaf)
            px(o.x - 3.0, o.y - 4.0, 7.0, 2.0, leaf)
            for(5) n: px(o.x + float(cell_hash(cell + n + t * 9) % 10) - 5.0, o.y + float(cell_hash(cell * 3 + n + t) % 4) - 4.0, 1.0, 1.0, berry)
    elif look == 4:  // herbs: green sprigs with white flower heads
        for(9) n:
            let o = spot(n)
            px(o.x, o.y - 4.0, 1.0, 4.0, float4 { 0.36, 0.52, 0.24, 1.0 })
            px(o.x - 1.0, o.y - 6.0, 3.0, 2.0, float4 { 0.95, 0.93, 0.84, 1.0 })
    elif look == 5:  // greens: low bright tufts
        for(4) n:
            let o = spot(n)
            px(o.x - 4.0, o.y - 2.0, 9.0, 2.0, float4 { 0.4, 0.62, 0.22, 1.0 })
            px(o.x - 2.0, o.y - 4.0, 5.0, 2.0, float4 { 0.5, 0.72, 0.3, 1.0 })
    elif look == 6:  // pears: small yellow fruit fallen under the tree
        for(6) n:
            let o = spot(n)
            px(o.x, o.y - 2.0, 3.0, 2.0, float4 { 0.84, 0.76, 0.28, 1.0 })
            px(o.x + 1.0, o.y - 3.0, 1.0, 1.0, float4 { 0.36, 0.24, 0.12, 1.0 })

// The mark on the range: a pale board with a dark ring, nailed to a post (art px, its foot at x, y).
def draw_mark(x:float, y:float):
    gl.set_shader("color")
    let f = float(floor(float2 { x, y }))
    for([ [ -1.0, -15.0, 2.0, 15.0 ], [ -5.0, -24.0, 10.0, 10.0 ], [ -3.0, -22.0, 6.0, 6.0 ], [ -1.0, -20.0, 2.0, 2.0 ] ]) r, k:
        let c = [ float4 { 0.3, 0.22, 0.15, 1.0 }, float4 { 0.84, 0.8, 0.7, 1.0 }, float4 { 0.22, 0.18, 0.14, 1.0 }, float4 { 0.84, 0.8, 0.7, 1.0 } ][k]
        gl.color(c):
            gl.translate(f + float2 { r[0], r[1] }): gl.rect(float2 { r[2], r[3] })

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

// How dark it is for the fire's light (0 by day .. 1 at night), from the mood's glow.
def fire_dark() -> float: return clamp((atmo_num("glow") - 1.1) / 1.1, 0.0, 1.0)

// How much of the nearest fire's light reaches p (art px): 1 at it, 0 at FIRE_LIGHT_TILES.
def fire_reach_k(p:float2) -> float:
    var best = 0.0
    for(fires) fp: best = max(best, clamp(1.0 - magnitude(iso_inv(p - fp)) / 1000.0 / FIRE_LIGHT_TILES, 0.0, 1.0))
    return best

// A man at p (art px) drawn with frame f, sorted at sort_y: lit by the nearest fire if he is in its reach.
def fire_light_man(f:int, p:float2, sort_y:float, up:bool, upto:float = 1000.0):
    if not atmo_on or f < 0 or not fires.length: return
    var best = 0.0
    var at = float2_0
    var g = float2_0
    for(fires) fp:
        let w = iso_inv(p - fp)
        let k = clamp(1.0 - magnitude(w) / 1000.0 / FIRE_LIGHT_TILES, 0.0, 1.0)
        if k > best:
            best = k
            at = fp
            g = w
    if best <= 0.0: return
    let night = 0.2 + 0.5 * fire_dark()                             // (by day the sun drowns it; at night it's all there is)
    let to = at - float2 { 0.0, 6.0 } - (p - float2 { 0.0, 12.0 })  // (flame to chest)
    let tiles = magnitude(g) / 1000.0
    fire_lits.push(FireLit { f, p, if magnitude(to) > 0.01: normalize(to) else: float2 { 0.0, 1.0 },
                             if tiles > 0.01: normalize(g) else: float2 { 1.0, 1.0 } / sqrt(2.0), tiles, pow(best, 1.4) * night, up, upto })
    draws.push(Drawable { sort_y + add_lift, draws.length, -9, float(fire_lits.length - 1), 0.0, float4_1, 1.0, 3, 0.0, add_lift })

// A frame placed as sprite() places it, each corner's colour its place in the frame (0..1 across, 0..1 down).
def fire_quad(f:int, x:float, y:float):
    let fr = frames[f]
    let at = sprite_sheet(fr)
    let x0 = floor(x * sprite_snap) / sprite_snap - float(fr.ox) * fr.k
    let y0 = floor(y * sprite_snap) / sprite_snap - float(fr.oy) * fr.k
    let s = sheet_dims[b_sheet]
    let n = b_pos.length
    for([ float2 { 0.0, 0.0 }, float2 { 1.0, 0.0 }, float2 { 1.0, 1.0 }, float2 { 0.0, 1.0 } ]) c:
        b_pos.push(float3 { x0 + c.x * float(fr.w) * fr.k, y0 + c.y * float(fr.h) * fr.k, 0.0 })
        b_tc.push((at + c * float2 { float(fr.w), float(fr.h) }) / s)
        b_col.push(float4 { c.x, c.y, 0.0, 1.0 })
    for([ n, n + 2, n + 1, n, n + 3, n + 2 ]) k: b_idx.push(k)

// The fire's light on a man: his frame again, added over him, warm on the side toward the fire, brightest on the edge
// facing it, and on his front when the fire is before him; his back is left dark when it's behind him.
def draw_fire_lit(n:int):
    let fl = fire_lits[n]
    let fr = frames[fl.f]
    gl.blend(blend_add)
    sprite_shader = "smyana_fire_lit"
    gl.set_shader(sprite_shader)
    gl.set_uniform("to", fl.to)
    gl.set_uniform("k", fl.k)
    gl.set_uniform("mid", float(fr.ox) / float(max(1, fr.w)))
    gl.set_uniform("team", float3 { SASH.x, SASH.y, SASH.z })
    gl.set_uniform("up", if fl.up or fl.upto < 1000.0: 1.0 else: 0.0)
    // (texels of the frame from its top down to where the light stops, and to its foot)
    gl.set_uniform("upto", float2 { (float(fr.oy) - fl.upto / fr.k) / float(max(1, fr.h)), float(fr.oy) / float(max(1, fr.h)) })
    fire_quad(fl.f, fl.p.x, fl.p.y)
    flush_sprites()
    sprite_shader = "sprite"
    gl.blend(blend_alpha)

// The fire's light on the ground round it, out to FIRE_LIGHT_TILES: brightest at the stones, falling off as the
// square of the way out, flickering with the flames. Drawn under what stands, so a man's shadow from it (and the man
// himself) is laid over it, as light on the ground should be.
def draw_fire_pools():
    let night = 0.15 + 0.45 * fire_dark()
    let t = gl.time()
    let rings = 7
    let sides = 40
    var pos = []::float3
    var col = []::float4
    var idx = []::int
    for(fires) fp, i:
        let flick = 0.9 + 0.06 * sin((t * 9.0 + float(i) * 3.1) * 57.29578) + 0.04 * sin((t * 23.0 + float(i)) * 57.29578)
        let c0 = pos.length
        pos.push(float3 { fp.x, fp.y - 1.0, 0.0 })
        col.push(float4 { 0.8, 0.38, 0.12, 1.0 } * (night * flick))
        for(rings) r:
            let u = float(r + 1) / float(rings)
            let k = pow(1.0 - u, 1.6)
            for(sides) a:
                let ang = float(a) * 360.0 / float(sides)
                let w = iso(cos(ang), sin(ang)) * (u * FIRE_LIGHT_TILES * 1000.0 * flick)
                pos.push(float3 { fp.x + w.x, fp.y - 1.0 + w.y, 0.0 })
                col.push(float4 { 0.8 * k, 0.38 * k, 0.12 * k, 1.0 } * (night * flick))
        for(sides) a:
            let b = (a + 1) % sides
            idx.push(c0)
            idx.push(c0 + 1 + a)
            idx.push(c0 + 1 + b)
            for(rings - 1) r:
                let i0 = c0 + 1 + r * sides
                let i1 = i0 + sides
                for([ i0 + a, i1 + a, i1 + b, i0 + a, i1 + b, i0 + b ]) q: idx.push(q)
    gl.blend(blend_add)
    gl.set_shader("color_attr")
    gl.draw_mesh("PC", pos, col, []::float3, []::float2, []::float2, idx)
    gl.blend(blend_alpha)

// Each standing man's shadow from the fire, on the ground away from it: his frame laid down from his feet, longer the
// further he stands from the low flames, fading with the light.
def draw_fire_shadows():
    sprite_shader = "smyana_fire_shadow"
    for(fire_lits) fl:
        if fl.up:
            let fr = frames[fl.f]
            let along = iso(fl.away.x, fl.away.y) * 1000.0    // (a tile along the ground, away from the fire, art px)
            let side = iso(-fl.away.y, fl.away.x) * 1000.0    // (a tile across it)
            let len = clamp(0.5 + fl.tiles * 0.45, 0.6, 2.4)  // (tiles his shadow reaches at its head)
            let wide = fr.k / 40.0                            // (tiles across a texel of him)
            let h = float(max(1, fr.oy))
            let a = side.x * wide
            let b = side.y * wide
            let c = -along.x * len / h
            let d = -along.y * len / h
            sprite_xf(fl.f, [ a, b, c, d, fl.p.x - float(fr.ox) * a - float(fr.oy) * c, fl.p.y - float(fr.ox) * b - float(fr.oy) * d ],
                      float4 { 0.0, 0.0, 0.0, min(1.0, fl.k * 3.0) })
    flush_sprites()
    sprite_shader = "sprite"

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

// The one panel left (docs/survival.md, #73): with one man chosen, his name and, under it, how he is in a few plain
// words. Nothing for a group.
def draw_one_man():
    if selected.length != 1: return
    let m = man_of(selected[0])
    if not m: return
    let ws = float(gl.window_size())
    let size = int(ws.y / 40.0)
    gl.set_shader("color")
    gl.set_font_name("../data/fonts/OldStandard/OldStandard-Regular.ttf")
    gl.set_font_size(size)
    gl.color(float4 { 0.93, 0.89, 0.78, 0.9 }):
        gl.translate(float2 { floor(ws.y * 0.03), floor(ws.y - float(size) * 3.4) }): gl.text(m.name)
    gl.set_font_size(int(float(size) * 0.72))
    gl.color(float4 { 0.85, 0.81, 0.7, 0.75 }):
        gl.translate(float2 { floor(ws.y * 0.03), floor(ws.y - float(size) * 1.9) }): gl.text(man_state(m))

// ------------------------------------------------------------------ the menu (#86)
// Dominic: "Game start is slow, we want very minimal loader. The game menu should show the village (once ready - just
// the men in forest for now is fine) alive in real time -> when you "start", the menu should just fade away". So the
// loader is the game's name on the dark, and the menu is the same name over the wood, the men in it going about the
// camp, with two words under it. Start, and the words fade off the game that is already running.

let MENU_ITEMS = [ "Start", "Quit" ]
// Old Standard (SIL Open Font License, data/fonts/OldStandard/OFL.txt): a book face of the 19th century, made for
// Cyrillic as well as Latin, for the name as the game's pictures write it, Смяна.
let TITLE_FONT = "../data/fonts/OldStandard/OldStandard-Bold.ttf"
let MENU_FONT = "../data/fonts/OldStandard/OldStandard-Regular.ttf"
var menu_alpha = 1.0  // the menu's words: 1 shown, fading to 0 once started
var menu_hover = -1
var menu_mill_t = 0.0

// The game's name, high in the middle (the loader's and the menu's, in the same place), and under it the menu's words
// at `items` (0: none). Returns the word under the mouse, or -1.
def draw_title(a:float, items:float) -> int:
    if a <= 0.0: return -1
    let ws = float(gl.window_size())
    let ink = float4 { 0.95, 0.91, 0.79, a }
    let dark = float4 { 0.02, 0.02, 0.015, a * 0.55 }
    gl.set_shader("color")
    // (a dark edge round the letters, so they read over the light grass and the dark wood alike)
    def centred(t:string, y:float, size:int, col:float4) -> float2, float2:
        gl.set_font_size(size)
        let w = float(gl.text_size(t))
        let at = float2 { floor(ws.x / 2.0 - w.x / 2.0), floor(y) }
        let off = max(1.0, floor(float(size) / 40.0))
        gl.color(float4 { dark.x, dark.y, dark.z, dark.w * col.w / max(a, 0.001) }):
            for([ float2 { -off, 0.0 }, float2 { off, 0.0 }, float2 { 0.0, -off }, float2 { off, off * 2.0 } ]) o: gl.translate(at + o): gl.text(t)
        gl.color(col): gl.translate(at): gl.text(t)
        return at, w
    gl.set_font_name(TITLE_FONT)
    centred("Смяна", ws.y * 0.12, int(ws.y / 6.5), ink)
    gl.set_font_name(MENU_FONT)
    var hover = -1
    if items > 0.0:
        let m = mouse_px()
        let size = int(ws.y / 26.0)
        for(MENU_ITEMS) t, i:
            let y = ws.y * 0.66 + float(i) * float(size) * 2.0
            gl.set_font_size(size)
            let w = float(gl.text_size(t))
            let lo = float2 { ws.x / 2.0 - w.x / 2.0 - 12.0, y - 6.0 }
            let over = m.x >= lo.x and m.x <= lo.x + w.x + 24.0 and m.y >= lo.y and m.y <= lo.y + w.y + 12.0
            if over: hover = i
            centred(t, y, size, float4 { ink.x, ink.y, ink.z, items * (if over: 1.0 else: 0.8) })
    return hover

// The men go about the camp while the menu is up: now and then one of them takes a few steps about the others.
def menu_mill(dt:float):
    menu_mill_t -= dt
    if menu_mill_t > 0.0 or not u_x.length: return
    menu_mill_t = 0.8 + float(rnd(100)) / 60.0
    var c = int2_0
    for(u_x.length) i: c += int2 { u_x[i], u_y[i] }
    c = c / u_x.length
    let i = rnd(u_x.length)
    let x = clamp(c.x + rnd(5000) - 2500, 500, W * TILE - 500)
    let y = clamp(c.y + rnd(5000) - 2500, 500, H * TILE - 500)
    issue_cmd(0, CMD_MOVE, [ u_id[i] ], x, y, 0, 0)

// The camera while the menu is up: over the men, drifting slowly as if someone stood watching.
def menu_camera(dt:float):
    let t = gl.time()
    let to = men_centre() + float2 { sin(t * 4.0) * 40.0, cos(t * 3.0) * 14.0 }
    cam += (to - cam) * min(1.0, dt * 0.6)
    cam_keep()

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

// The patch the mouse is on, or the one just below it (a patch is drawn a little up from its foot), or -1.
def patch_under(mm:float2) -> int:
    for(2) n:
        let x = int(mm.x / 1000.0) + n
        let y = int(mm.y / 1000.0) + n
        if x >= 0 and y >= 0 and x < W and y < H and patch_at(y * W + x) >= 0: return y * W + x
    return -1

// The music turns with the threats (docs/threats.md): wary, then the hunting threat's own loop; when it is over, the
// end stroke and quiet, or the lament if a man fell in it (#64).
var danger_was = ""
var danger_killed = 0  // men_killed when it began
def danger_tick():
    if music_arg != "": return
    let d = threats_danger()
    if d == danger_was: return
    if danger_was == "": danger_killed = men_killed
    if d != "": score_danger(d)
    elif men_killed > danger_killed: score_moment("death")
    else: score_safe()
    danger_was = d

// The wolves are heard more than seen (docs/threats.md): while a pack follows, one of them howls now and then, and
// the others join in; far off it is the wood's echo more than the wolf. A bite snarls, a ball yelps.
let howl_next = dictionary<int, float>(8)  // a pack's first wolf -> seconds till it howls

def wolf_cry(what:string, x:int, y:int):
    let far, pan = gun_hear(gp(float(x), float(y)))
    if far < 24.0: play_sound_at(what, -far * 0.6, pan)

def howl_tick(dt:float):
    for(packs) p:
        let alive = pack_alive(p)
        if not alive.length or p.state == W_FLED: continue
        let t = howl_next.get(p.ids[0], gun_between(glist(wolf_cfg(), "howl_s")) * 0.25) - dt
        if t > 0.0 or p.state != W_FOLLOW:
            howl_next.set(p.ids[0], max(t, 1.0))
            continue
        howl_next.set(p.ids[0], gun_between(glist(wolf_cfg(), "howl_s")))
        let i = index_of(alive[0])
        let far, pan = gun_hear(gp(float(u_x[i]), float(u_y[i])))
        if far < 12.0: play_sound_at("howl", -2.0 - far * 0.4, pan)
        else: play_sound_at("far_howl", -2.0 - (far - 12.0) * 0.25, pan * 0.6)

def order_tick():
    // C: make camp where the chosen men stand, or put its fire out, or light it again (docs/survival.md, #68)
    if gl.button("c") == 1 and selected.length:
        camp_order(filter(selected) id: man_of(id) != nil)
        selected = []
    // X: the chosen men drop their packs where they stand, to move light; at an old tree's foot it is a cache (#67, #69)
    if gl.button("x") == 1 and selected.length: packs_drop(filter(selected) id: man_of(id) != nil)
    if gl.button("mouse2") != 1: return
    let ids = filter(selected) id: index_of(id) >= 0
    if not ids.length: return
    let mm = mouse_milli()
    let foe = unit_at_screen(mouse_px())
    if foe >= 0 and not man_of(u_id[foe]):
        guns_order(ids, u_id[foe])
        mark_t = gl.time()
        mark_at = gp(float(u_x[foe]), float(u_y[foe]))
        return
    // (the ruins under the mouse, off the road: study the Romans' drain beside it, #70)
    let mc0 = clamp(int(mm.y / 1000.0), 0, H - 1) * W + clamp(int(mm.x / 1000.0), 0, W - 1)
    if at_ruin(mc0) and study_order(ids):
        mark_at = gp(mm.x, mm.y)
        mark_t = gl.time()
        return
    // (a pile of packs under the mouse: pick it up)
    let pile = pile_near(int(mm.x), int(mm.y))
    if pile >= 0:
        packs_fetch(ids, pile)
        mark_at = gp(float(piles[pile].x), float(piles[pile].y))
        mark_t = gl.time()
        return
    // (a patch of what the wood gives under the mouse: gather it)
    let pc = patch_under(mm)
    if pc >= 0 and forage_order(ids, pc):
        mark_at = gp(float((pc % W) * 1000 + 500), float((pc / W) * 1000 + 500))
        mark_t = gl.time()
        return
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
    let sp = CAM_SPEED * ws.y * gl.delta_time() / zoom
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
    // the wheel: a step in or out, about the point under the mouse
    let wheel = gl.mousewheel_delta()
    if wheel != 0:
        let under = from_screen(m)
        zoom_step = clamp(zoom_step + (if wheel > 0: 1 else: -1), 0, ZOOM_STEPS.length - 1)
        zoom_fixed = 0.0
        zoom = zoom_of(zoom_step)
        if inside: cam = under - (m - ws / 2.0) / zoom
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
// (a hill's near edge in the shade buffer, over what stood behind it: the ground's own shade there, kept by Creel's
// atmo_shade_standing, read back pixel for pixel)
fatal(gl.load_materials("""
SHADER smyana_shade_restore
    VERTEX
        INPUTS apos:4
        UNIFORMS mvp
        gl_Position = mvp * apos;
    PIXEL
        UNIFORMS tex0
        frag_color = texelFetch(tex0, ivec2(gl_FragCoord.xy), 0);
""", true))
fatal(gl.load_materials(GUNFIRE_SHADERS, true))
// (the fire's light on a man, added over him, and his shadow from it: draw_fire_lit, draw_fire_shadows)
fatal(gl.load_materials("""
SHADER smyana_fire_lit
    VERTEX
        INPUTS apos:4 atc:2 acolor:4
        UNIFORMS mvp
        gl_Position = mvp * apos;
        itc = atc;
        icolor = acolor;
    PIXEL
        INPUTS itc:2 icolor:4
        UNIFORMS tex0
        UNIFORM vec2 to
        UNIFORM float k
        UNIFORM float mid
        UNIFORM float up
        UNIFORM vec2 upto
        UNIFORM vec3 team
        ivec2 sz = textureSize(tex0, 0);
        ivec2 a = ivec2(floor(itc * vec2(sz)));
        vec4 t = texelFetch(tex0, a, 0);
        if (t.a < 0.5) discard;
        vec3 rgb = t.rgb;
        if (min(t.r, t.b) - t.g > 0.22 && abs(t.r - t.b) < 0.3) rgb = team * max(t.r, t.b) * 1.08;
        // (his edge toward the fire: here he is, a texel or two toward it he isn't)
        ivec2 o = ivec2(round(to * 1.4));
        float rim = (1.0 - texelFetch(tex0, a + o, 0).a) * 0.7 + (1.0 - texelFetch(tex0, a + o * 2, 0).a) * 0.3;
        // (his side toward it, across him; all his front when it's before him, little of his back when it's behind)
        float lat = clamp(0.5 + (icolor.r - mid) * to.x * 2.5, 0.0, 1.0);
        float front = clamp(to.y, 0.0, 1.0);
        float fill = mix(lat * 0.7, 1.0, front) * mix(0.25, 1.0, front * 0.5 + 0.5 * abs(to.x));
        fill *= 0.65 + 0.35 * icolor.g;  // (his legs nearer the flames than his head)
        if (up < 0.5) { fill = 0.4; rim *= 0.25; }  // (lying: lit all over, softly)
        // (a tree: its trunk lit up to where the light stops, fading, and its crown above left dark)
        float reach = smoothstep(upto.x - 0.06, upto.x + 0.06, icolor.g);
        fill *= reach;
        rim *= reach;
        vec3 warm = vec3(1.0, 0.55, 0.22);
        frag_color = vec4((rgb * 1.6 + vec3(0.05)) * warm * k * (fill * 1.1 + rim * 1.4), 0.0);
SHADER smyana_fire_shadow
    VERTEX
        INPUTS apos:4 atc:2 acolor:4
        UNIFORMS mvp
        gl_Position = mvp * apos;
        itc = atc;
        icolor = acolor;
    PIXEL
        INPUTS itc:2 icolor:4
        UNIFORMS tex0
        ivec2 sz = textureSize(tex0, 0);
        float a = texelFetch(tex0, ivec2(floor(itc * vec2(sz))), 0).a;
        if (a < 0.5) discard;
        frag_color = vec4(0.02, 0.01, 0.02, clamp(icolor.a * 2.8021978 * 0.55, 0.0, 0.7));
""", true))
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
if arg_of("zoom") != "": zoom_fixed = string_to_float(arg_of("zoom"))  // zoom:2.75: the camera this close, for a look beside a mock-up
zoom = if zoom_fixed > 0.0: zoom_fixed else: zoom_of(zoom_step)
cursors_load("../data/cursors")

// The loader (#86: "very minimal"): the game's name on the dark while the art is read (or, the first time, baked), where
// the menu will show it.
def waiting_frame():
    if not gl.frame(): return
    gl.clear(float4 { 0.03, 0.03, 0.025, 1.0 })
    gl.blend(1)
    draw_title(1.0, 0.0)

waiting_frame()
waiting_frame()
let boot0 = seconds_elapsed()
bake_men(): waiting_frame()
bake_beast("wolf"): waiting_frame()
bake_beast("bear"): waiting_frame()
bake_trees(): waiting_frame()
bake_camp(): waiting_frame()
sounds_load()
guns_load()
threats_load()
with_mark = arg_of("range") != ""
with_patrol = arg_of("fight") != ""
with_wolves = arg_of("wolves") != ""
with_bear = arg_of("bear") != ""
needs_kept = has_s(args, "fresh")  // fresh: the men never get hungry, cold or tired (for a look)
run_begin()
if arg_of("leg") != "": enter_leg(arg_of("leg"), "west")
// range:<x>,<y>: the men in a loose line on that tile, a mark five tiles east of them, and told to fire at it, for a
// look and a listen at the rifles (#58)
if arg_of("range") != "":
    let xy = map(tokenize(arg_of("range"), ",", " ")) v: string_to_int(v)
    for(u_x.length) i:
        u_x[i] = xy[0] * TILE + 500 - (i % 2) * 700
        u_y[i] = (xy[1] - 4) * TILE + 500 + (i / 2) * 800
    let mark = guns_mark((xy[0] + 5) * TILE + 500, xy[1] * TILE + 500)
    for(u_id) id, i: issue_cmd(0, CMD_MOVE, [ id ], u_x[i], u_y[i], 0, 0)
    guns_order(copy(u_id), mark)
    p_id = []  // leg:<id>: start at this leg of the route, for a look
// fight:<x>,<y>[,<n>]: the men in a loose block on that tile, and a patrol of n (7) on a road that comes down past them
// from the north-east, ten tiles off at the nearest; with ambush the men open fire when the first of it is within
// seven tiles (docs/threats.md, #62)
let ambush = has_s(args, "ambush")
var ambushed = false
if arg_of("fight") != "":
    let xy = map(tokenize(arg_of("fight"), ",", " ")) v: string_to_int(v)
    for(u_x.length) i:
        u_x[i] = xy[0] * TILE + 500 - (i % 4) * 900
        u_y[i] = xy[1] * TILE + 500 + (i / 4) * 900 - 2000
    for(u_id) id, i: issue_cmd(0, CMD_MOVE, [ id ], u_x[i], u_y[i], 0, 0)
    let road = [ xy[0] + 24, xy[1] - 14, xy[0] + 6, xy[1], xy[0], xy[1] + 26 ]
    patrol_spawn(map(road) v: v * TILE + TILE / 2, if xy.length > 2: xy[2] else: 7)
    p_id = []
// wolves:<x>,<y>[,<n>[,bold]]: a pack of n (5) set down on that tile, following the men; bold: winter's, which go for
// a man on his own at night (docs/threats.md, #60)
if arg_of("wolves") != "":
    let ws = tokenize(arg_of("wolves"), ",", " ")
    let xy = map(ws) v: string_to_int(v)
    pack_spawn(xy[0] * TILE + 500, xy[1] * TILE + 500, if ws.length > 2: xy[2] else: 5, ws.length > 3 and ws[3] == "bold")
    p_id = []
// bear:<x>,<y>: the bear set down on that tile, wandering (docs/threats.md, #61)
if arg_of("bear") != "":
    let xy = map(tokenize(arg_of("bear"), ",", " ")) v: string_to_int(v)
    bear_spawn(xy[0] * TILE + 500, xy[1] * TILE + 500)
    p_id = []
// fallen: beside each man, one lying as if fallen, turned each of the eight ways, the patrol's among them (for a look)
if has_s(args, "fallen"):
    let n_looks = gstrs(men_data, "looks").length
    for(men) m, k:
        let i = index_of(m.uid)
        if i >= 0:
            let a = float(k) * 0.785
            fallen.push(Fallen { 0, u_x[i] + 1500, u_y[i], if k % 3 == 2: n_looks + k % 4 else: m.look, k % 3 == 2, u_x[i] + 1500 + int(cos(a * 57.3) * 3000.0), u_y[i] + int(sin(a * 57.3) * 3000.0) })
def ambush_tick():
    if not ambush or ambushed or not patrols.length: return
    for(patrol_alive(patrols[0])) pid:
        let pi = index_of(pid)
        for(men) m:
            let mi = if m.alive: index_of(m.uid) else: -1
            if not ambushed and mi >= 0 and dist2(u_x[pi], u_y[pi], u_x[mi], u_y[mi]) < 7 * TILE * 7 * TILE:
                ambushed = true
                guns_order(map(filter(men) n: n.alive) n: n.uid, pid)
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
        // (each man is sent to where he stands: a stop leaves the group's march standing, and they walk on)
        for(u_id) id, i: issue_cmd(0, CMD_MOVE, [ id ], u_x[i], u_y[i], 0, 0)
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
    fires_look = true
view_enter(): waiting_frame()
// (round a camp's fire the men face it)
for(fires) f:
    for(u_x.length) i:
        let to_fire = f - gp(float(u_x[i]), float(u_y[i]))
        if magnitude(to_fire) < 75.0 and dir_of(to_fire) >= 0: man_dir.set(u_id[i], dir_of(to_fire))
// makecamp: the men make camp where they stand as the place opens, two of them with wood for the fire (#68, for a look)
if has_s(args, "makecamp"):
    let wood = str_index(resource_names, "wood") + 1
    for(min(2, u_x.length)) n:
        u_carry[n] = r_carry
        u_carry_kind[n] = wood
    camp_order(filter(u_id) id: man_of(id) != nil)
    let fx, fy = camp_xy(0)
    cam = gp(float(fx), float(fy))
// droppacks: the men put their packs down where they stand as the place opens and walk on a little (#67, for a look)
if has_s(args, "droppacks"):
    let ids = filter(u_id) id: man_of(id) != nil
    for(men) m: if m.alive: m.goods = 2
    packs_drop(ids)
    cam = gp(float(piles[0].x), float(piles[0].y))
    for(ids) id, n: issue_cmd(0, CMD_MOVE, [ id ], piles[0].x + 3000 + (n % 4) * 700, piles[0].y + (n / 4) * 700 - 1500, 0, 0)
// study: the men go to study the Roman drain as the place opens (#70, for a look at the ruins)
if has_s(args, "study"): study_order(filter(u_id) id: man_of(id) != nil)
if arg_of("look") != "":  // look:<x>,<y>: the camera on this tile
    let xy = tokenize(arg_of("look"), ",", " ")
    cam = gp(string_to_float(xy[0]) * 1000.0, string_to_float(xy[1]) * 1000.0)
    // file:<x>,<y>: the men in single file along the trail through that tile, as the ridge's mock-up has them, for a look
    if arg_of("file") != "":
        let fxy = map(tokenize(arg_of("file"), ",", " ")) v: string_to_int(v)
        let trail = str_index(tr_names, "trail")
        let on = []::int
        for(29) dy: for(29) dx:
            let x = fxy[0] + dx - 14
            let y = fxy[1] + dy - 14
            if x >= 0 and y >= 0 and x < W and y < H and terrain[y * W + x] == trail and level[y * W + x] == level[fxy[1] * W + fxy[0]]: on.push(y * W + x)
        // (across the screen, left to right: by x - y)
        insertion_sort(on) a, b: a % W - a / W < b % W - b / W
        let mid = on.length / 2
        for(u_x.length) i:
            let k = clamp(mid + (i - u_x.length / 2), 0, on.length - 1)
            if on.length:
                u_x[i] = (on[k] % W) * TILE + 500
                u_y[i] = (on[k] / W) * TILE + 500
                issue_cmd(0, CMD_MOVE, [ u_id[i] ], u_x[i], u_y[i], 0, 0)
                man_dir.set(u_id[i], 1)
print "start: {seconds_elapsed() - boot0} s (men baked in {men_bake_s} s, trees in {trees_bake_s} s; 0: read from bake_cache/)"

// ------------------------------------------------------------------ the loop

// menu (the game running under its name: the start), arriving (fading in), play, leaving (fading out), letter, end.
// A picture or the tour starts playing at once (menu: the menu, for a look).
var phase = if capture and not has_s(args, "menu"): "arriving" else: "menu"
if phase != "menu": menu_alpha = 0.0
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

score_load()
score_on = music_arg != "off"
if music_arg != "" and music_arg != "off":
    // (music:bandits, music:homecoming, music:05_autumn_night)
    score_danger(music_arg)
    if score_track == "": score_moment(music_arg)
    if score_track == "": score_play(music_arg, "moment", false, "asked for")

// With debug, the number keys try the music's swaps: 1 to 6 a danger begins, 0 it is over.
def score_keys():
    for([ "wary", "hiding", "beasts", "bandits", "ottomans", "chase" ]) kind, k:
        if gl.button("{k + 1}") == 1: score_danger(kind)
    if gl.button("0") == 1: score_safe()

while gl.frame():
    let dt = min(gl.delta_time(), 0.1)
    frame_no++
    phase_t += dt
    if zoom_fixed <= 0.0: zoom = zoom_of(zoom_step)  // (the window may have changed size)
    if phase == "menu":
        menu_mill(dt)
        menu_camera(dt)
        let go = (menu_hover == 0 and gl.button("mouse1") == 1) or gl.button("return") == 1 or gl.button("space") == 1
        if menu_hover == 1 and gl.button("mouse1") == 1: break
        if go and phase_t > 0.5:
            // (the men stop where they are: the run is theirs now)
            for(u_id) id, i: issue_cmd(0, CMD_MOVE, [ id ], u_x[i], u_y[i], 0, 0)
            set_phase("play")
    elif gl.button("space") == 1: paused = not paused
    if phase == "menu" or phase == "play" or phase == "arriving" or phase == "leaving":
        if phase == "play":
            select_tick()
            order_tick()
        if phase != "menu": camera_tick()
        if not paused: acc = min(acc + dt, 0.5)
        while acc >= 0.05:
            p_id = copy(u_id)
            p_x = copy(u_x)
            p_y = copy(u_y)
            step()
            let fired = guns_after_step()
            for(fired) id:
                let i = index_of(id)
                let j = if i >= 0: index_of(u_foe[i]) else: -1
                if i >= 0: gunfire_shot(id, gp(float(u_x[i]), float(u_y[i])), if j >= 0: gp(float(u_x[j]), float(u_y[j])) else: gp(float(u_x[i] + 1000), float(u_y[i])))
            // (the patrols hear the shots and think; where each ball landed, and Creel's own misses, a shot whose
            // target had moved off the spot)
            threats_after_step(fired)
            ambush_tick()
            let snow = snow_lying() > 300
            for(threats_landed()) l:
                if is_wolf(l.by): wolf_cry("snarl", l.x, l.y)
                elif bear_of(l.by) >= 0: wolf_cry("bear_swipe", l.x, l.y)
                else:
                    gunfire_strike(gp(float(l.x), float(l.y)), l.hit, snow, l.by * 31 + l.to + tick)
                    if l.hit and is_wolf(l.to): wolf_cry("yelp", l.x, l.y)
            for(threats_cries()) c: wolf_cry(c.what, c.x, c.y)
            for(events) e: if e.kind == EV_MISS: gunfire_strike(gp(float(e.x), float(e.y)), false, snow, e.a + tick)
            for(u_x.length) i:
                let px, py = prev_pos(i)
                if u_moving[i] == 1: man_walked.set(u_id[i], man_walked.get(u_id[i], 0.0) + sqrt(float(dist2(px, py, u_x[i], u_y[i]))))
            // (under the menu the men only move: the run's clock and its gates wait for Start)
            let edge = if phase == "menu": "" else: route_tick()
            if phase != "menu": tour_tick()
            clock_s += 0.05
            acc -= 0.05
            if edge != "" and phase == "play":
                leave_edge = edge
                set_phase("leaving")
                score_leave()
                selected = []
        gunfire_tick(if paused: 0.0 else: dt, cam, float(gl.window_size().x) * 0.5 / zoom)
        mood_tick()
        if phase != "leaving": score_tick(dt, season_now(), mood_now(), fires.length > 0)
        danger_tick()
        if not paused: howl_tick(dt)
        if debug_line: score_keys()
        ground_season_tick()
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
        // (no letter on the last walk, down the lane into the village: straight on to the end)
        let hold = if not letter.length: 0.5 elif script == "tour": 6.0 else: float(gint(route, "letter_seconds", 20))
        let skip = letter_loaded and phase_t > 2.0 and (gl.button("mouse1") == 1 or gl.button("space") == 1 or gl.button("return") == 1)
        if letter_loaded and (phase_t >= hold or skip):
            paused = false
            set_phase(if run_over(): "end" else: "arriving")
            if run_over(): score_moment("homecoming")
    // the cursor: an axe over a young tree the chosen men would fell, the pointer with an order's ring where they would
    // walk, else the pointer
    let ws = float(gl.window_size())
    let mp = mouse_px()
    let in_window = mp.x >= 0.0 and mp.y >= 0.0 and mp.x < ws.x and mp.y < ws.y
    cursor_show(if phase != "play" or not selected.length or not in_window: CURSOR_POINT elif young_tree_at(mouse_milli()) >= 0: CURSOR_FELL else: CURSOR_GO)
    if drawing():
        gl.clear(float4 { 0.035, 0.055, 0.04, 1.0 })
        gl.blend(1)
        if phase == "letter":
            draw_lines(letter, phase_t, int(float(gl.window_size().y) / 34.0))
        elif phase == "end":
            draw_lines(tally_lines(), phase_t, int(float(gl.window_size().y) / 30.0))
        else:
            draw_world(acc / 0.05)
            draw_breaths()
            if dragging and magnitude(mouse_px() - drag_from) > 6.0:
                let a = drag_from
                let b = mouse_px()
                ui_batch():
                    for([ [ a, float2 { b.x, a.y } ], [ float2 { b.x, a.y }, b ], [ b, float2 { a.x, b.y } ], [ float2 { a.x, b.y }, a ] ]) l: ui_line(l[0], l[1], 1.2, float4 { 0.95, 0.91, 0.79, 0.7 })
            veil(if phase == "arriving" or phase == "menu": 1.0 - phase_t / 1.5 elif phase == "leaving": phase_t / 1.5 else: 0.0)
            if phase != "menu": menu_alpha = max(0.0, menu_alpha - dt / 1.2)
            menu_hover = draw_title(menu_alpha, if phase == "menu": clamp((phase_t - 1.0) / 1.0, 0.0, 1.0) else: menu_alpha)
        if phase == "play": draw_one_man()
        if debug_line:
            gl.set_shader("color")
            gl.set_font_name(FONT)
            gl.set_font_size(16)
            gl.color(float4 { 1.0, 1.0, 1.0, 0.8 }):
                gl.translate(float2 { 10.0, 8.0 }): gl.text("{leg_id}  {season_now()} {year_here()}  {int(hour_now())}h  {atmo_mood}  men {men_alive()}  {int(1.0 / max(dt, 0.001))} fps  {phase}")
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
