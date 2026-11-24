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
import smyana.heard
import smyana.gunfire
import smyana.trees
import smyana.cliff
import smyana.camp
import smyana.music
import smyana.ambience
import smyana.cursors

// ------------------------------------------------------------------ what it was started with

let args = command_line_arguments()
def arg_of(key:string) -> string:
    for(args) a: if starts_with(a, key + ":"): return substring(a, key.length + 1, -1)
    return ""
let shot = arg_of("shot")
let shot_at = if arg_of("at") != "": string_to_float(arg_of("at")) else: 4.0
let script = arg_of("script")  // "tour": the men walk the whole route by themselves (captures, and timing the loads); "play": the same, and they fight what they meet, logging the run (a fast playthrough, with fast:)
meal_log = script == "play"
heard_on = (find(args) a: a == "heard") >= 0
// fast:<n>: the sim runs n times as fast as the clock, the picture drawn as usual (a playthrough in minutes, Dominic
// 2026-11-12: "very fast playthroughs where we speed it up loads and shoot through everything really quickly")
let fast = if arg_of("fast") != "": max(1.0, string_to_float(arg_of("fast"))) else: 1.0
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
// The seconds the player has watched, a frame at a time (not the wall's clock: a playtest frozen between its steps,
// tools/playtest.sh, lost the men's words and the order's ring to the wait).
var seen_s = 0.0
var zoom = 1.5  // screen px an art px

// The zoom (#86) in steps of the window's own height, so a view is the same on any screen (a Retina display has twice
// the pixels) and the wheel always comes back to where it started. 1 is the window 325 art px high (a man about a
// tenth of it); each step is rounded to a quarter so the pixels of the art keep an even size. Dominic: "Default camera
// zoom seems too close, when i zoom out, i cant zoom back to the default": it starts a step further out than before.
// (two steps closer than before, and the + and - keys as well as the wheel: Dominic, 2026-11-24, on a Retina screen in
// the browser: "good if we can zoom in out a little ,the guys are abit small")
let ZOOM_STEPS = [ 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.15, 1.3, 1.5, 1.75, 2.0 ]
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
    // (the men only: the deer and a patrol are units too, and with five deer in the first place the menu's view and
    // the Tab key sat nine tiles east of the men)
    var sum = float2_0
    var n = 0
    for(u_x.length) i:
        if man_of(u_id[i]):
            sum += gp(float(u_x[i]), float(u_y[i]))
            n++
    return if n: sum / float(n) else: cam

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
            // (which kind by the place's rules for evergreens, D-108; a place can say it has no pines, "pines": 0)
            let sp = old_tree_at(c)
            let k = species_pick(c) % (if sp == "pine": PINE_KINDS else: 3)
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
            // (under broadleaves the grass gives out sooner: the year's leaves lie deep and smother it, Dominic
            // 2026-11-12: "you won't be able to walk without just going through leaves")
            let sunny = if broadleaved(wood): clamp(1.15 - float(shading) / 4.0, 0.03, 1.0) else: clamp(1.15 - float(shading) / 7.0, 0.08, 1.0)
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
            // dog roses (D-106): in the wood's mantle, where a tree or two gives half shade, and now and then out in
            // the meadow, a few together
            let hr = mixed(c + 270001)
            let roses = woods_field(c % W, c / W, 4.0, 6007) > 0.55
            if shading <= 5 and hr % 1000 < (if roses and shading >= 1: 140 elif roses: 35 else: 6):
                props.push(Prop { 5, 0, "rose{(hr / 1000) % ROSE_KINDS}", "", gp(float((c % W) * 1000 + (hr / 10000) % 1000), float((c / W) * 1000 + (hr / 10000000) % 1000)), c })
            if (h2 / 100) % 100 >= 90 and (h2 / 100) % 100 < 94:
                // (a sapling of the wood's own kinds, #98)
                let r = (h2 / 10000) % 10
                let sp = if wood == "oak": (if r < 6: "oak" else: "hornbeam") elif wood == "beech": (if r < 5: "beech" elif r < 8: "oak" else: "hornbeam") else: (if r < 4: "spruce" elif r < 7: "fir" else: "beech")
                props.push(Prop { 5, 0, "sapling_" + sp, "", centre, c })
            if (h2 / 100) % 100 < 6: props.push(Prop { 5, 0, "bush{h2 % BUSH_KINDS}", "", centre + iso(float((h2 / 13) % 600) - 300.0, float((h2 / 19) % 600) - 300.0), c })
            elif (h2 / 100) % 100 == 99:
                // (not where the ground steps up or down within two tiles: a trunk lay across a ledge's edge and
                // hung out over the drop. Dominic, playing, 2026-11-24: "fallen trees over the cliff?")
                var flat = true
                for(25) k:
                    let x = c % W + k % 5 - 2
                    let y = c / W + k / 5 - 2
                    if x >= 0 and y >= 0 and x < W and y < H and level[y * W + x] != level[c]: flat = false
                if flat: props.push(Prop { 6, 0, "log{h2 % LOG_KINDS}", "", centre, c })
    // the camp, where the place has one laid out ("camp": [name, x, y in milli-tiles] each: the tents, the woodpile,
    // the horses and the mules; the fireplace comes with the fire): nothing grows under it
    let camp = glist(su_map, "camp")
    if camp.length:
        let standing = map(camp) e: gp(as_float(e.a[1]), as_float(e.a[2]))
        props = filter(props) pr: pr.kind != 5 or not exists(standing) q: abs(pr.at.x - q.x) < 60.0 and abs(pr.at.y - q.y) < 34.0
        // (nor round the fire, where the men tread: "fire", x and y in milli-tiles)
        let hearth = glist(su_map, "fire")
        if hearth.length:
            let f = gp(as_float(hearth[0]), as_float(hearth[1]))
            props = filter(props) pr: pr.kind != 5 or abs(pr.at.x - f.x) > 46.0 or abs(pr.at.y - f.y) > 26.0
        // (a fourth "far": seen far off, as the ridge's patrol on the far road is, and not marked like the men: a dark
        // shape in the fog, not a figure kept bright, D-084)
        for(camp) e, i: props.push(Prop { 4, 0, as_str(e.a[0]), if e.a.length > 3: as_str(e.a[3]) else: "", standing[i],
                                          (as_int(e.a[2]) / 1000) * W + as_int(e.a[1]) / 1000 })

    // the Roman ruins (#17), where the place has them ("ruins": [name, x, y in milli-tiles] each): the undergrowth
    // grows up round them but not through a wall or a column; on the road (#97) it grows only where the stones are gone
    // or buried, and not in its drain
    let ruins = glist(su_map, "ruins")
    if ruins.length:
        let standing = map(ruins) e: gp(as_float(e.a[1]), as_float(e.a[2]))
        let cells = map(ruins) e: (as_int(e.a[2]) / 1000) * W + as_int(e.a[1]) / 1000
        props = filter(props) pr: pr.kind != 5 or not exists(ruins) e, i:
            let name = as_str(e.a[0])
            if starts_with(name, "road"):
                let n = clamp(string_to_int(substring(name, 4, name.length - 4)), 0, ROAD_PLAN.length - 1)
                let c = ROAD_PLAN[n]
                let d = ROAD_DRAIN[n]
                pr.cell == cells[i] and (c == 'w' or c == 'h') or pr.cell == cells[i] + W and (d == 'd' or d == 'c')
            else: abs(pr.at.x - standing[i].x) < 34.0 and abs(pr.at.y - standing[i].y) < 18.0
        for(ruins) e, i: props.push(Prop { 3, 0, as_str(e.a[0]), "", standing[i], cells[i] })
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
let LITTER_DEEP = 2.6   // tiles, under a broadleaf giant

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
            // (2026-11-12, Dominic, from a beech wood: "everywhere off the path will just be covered in really deep leaf
            // cover". A beech's leaves lie all year, deep: under a broadleaf giant they reach well past its crown, so
            // in a closed wood they meet and the floor is leaves, and only the open glades are turf)
            let reach = (if pr.kind == 0: (if leafy(pr.sp): LITTER_DEEP else: 1.0) else: 0.6) * (if leafy(pr.sp): 1.0 + 0.25 * carpet else: 1.0) * (0.8 + 0.4 * float(cell_hash(pr.cell) % 100) / 100.0)
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
                    let v = clamp((1.0 - d) * 2.2, 0.0, if leafy(pr.sp): 0.95 else: 0.85)
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
    // (the path stays worn: the leaves lie thin on it, kicked aside by feet)
    let trail_tt = str_index(tr_names, "trail")
    for(h) y: for(w) x:
        if terrain[(y / MASK_K) * W + x / MASK_K] == trail_tt: a[y * w + x] = min(a[y * w + x], 0.3)
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
let PATCH_LOOKS = [ "mushrooms", "nuts", "berries_blue", "berries_red", "herbs", "greens", "pears", "rosehips" ]
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
// Our men again, drawn faintly over everything (Dominic, 2026-11-13: "need to ensure we can always see our guys"):
// where a man is in sight his ghost lands on himself and changes nothing; behind a crown or a trunk it shows him
// through it. Each is his foot (art px, as drawn) and his frame.
var ghosts = []::float3
let GHOST = 0.55  // how strongly a hidden man shows through

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
            // (game a man can see: the crowns over it thin out, so it can be hunted)
            if game_of(u_id[i]) >= 0 and men_see(i): eyes.push(p - float2 { 0.0, 8.0 })
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
                if lf >= 0: ghosts.push(float3 { p.x, p.y, float(lf) })
                fire_light_man(lf, p, p.y - 0.39, false)
                eyes.push(p - float2 { 0.0, 6.0 })
                continue
            if m and not moving and m.warm < 30000 and (int(gl.time() * 14.0) + u_id[i]) % 3 == 0: p.x += if (int(gl.time() * 14.0) / 3 + u_id[i]) % 2 == 0: 1.0 else: -1.0
            if m:
                let chill = max(35 - air_warmth(), (40000 - m.warm) / 1000)
                if chill > 0: breaths.push(Breath { p - float2 { 0.0, 19.0 }, float(u_id[i] % 13) * 0.37, max(1.8, 4.2 - float(chill) * 0.06) })
            // (by the fire at dark, his shadow is the fire's, thrown behind him: not the sky's)
            if pk >= 0 and is_riding(u_id[i]):
                // (a patrolman on his horse: the horse's walk, docs/threats.md, riders)
                let hs = int(man_walked.get(u_id[i], 0.0) / beast_cycle("horse") * float(MEN_STEPS)) % MEN_STEPS
                add(frame_at.get(rider_shadow_name(pk, facing), -1), p.x, p.y, p.y - 0.5, float4_1, 1.0, 1)
                add(frame_at.get(rider_frame_name(pk, if moving: 1 + hs else: 0, facing), -1), p.x, p.y, p.y, patrol_sash(), 1.0, 4)
                feet.push(float3 { p.x, p.y, 3.0 })
                continue
            if not (fire_dark() > 0.4 and fire_reach_k(p) > 0.05): add(frame_at.get(man_shadow_name(look, facing), -1), p.x, p.y, p.y - 0.5, float4_1, 1.0, 1)
            let mf = frame_at.get(man_frame_name(look, if gun >= 0: gun elif moving: 1 + step else: 0, facing), -1)
            add(mf, p.x, p.y, p.y, if m: SASH else: patrol_sash(), 1.0, 4)
            if m and mf >= 0: ghosts.push(float3 { p.x, p.y, float(mf) })
            fire_light_man(mf, p, p.y + 0.01, true)
            feet.push(float3 { p.x, p.y, 2.2 })
            if u_carry[i] > 0: add(frame_at.get("load.wood", -1), p.x + 3.0, p.y - 27.0, p.y + 0.1, float4_1, 1.0, 2)
            eyes.push(p - float2 { 0.0, 16.0 })
    // (and the camps' fires: crowns thin over them too. Dominic, 2026-11-24: "i dont see a fire when asking them to
    // make it - oh might be hidnig behind some trees")
    for(sv_camps) cp: if not cp.hut: eyes.push(gp(float(cp.x), float(cp.y)) - float2 { 0.0, 10.0 })
    add_lift = 0.0

// How much of a giant's crown shows: it thins out over any man it would hide.
def crown_fade(foot:float2, sp:string) -> float:
    let c = foot - float2 { 0.0, crown_up(sp) * ART_UP }
    let r = crown_reach(sp) * 68.0
    var least = 1.0
    for(eyes) e:
        let d = magnitude(float2 { (e.x - c.x) / r, (e.y - c.y) / (r * (if leafy(sp): 0.8 else: 1.6)) })
        least = min(least, clamp((d - 1.05) / 0.55, 0.04, 1.0))
    return least

// How much of a tall fir's trunk shows: its crown is out of sight overhead, so nothing of it thinned over a man, and
// in the deep fir woods the trunks stood black across the men, the game and the track (the tenth first-time play,
// 2026-11-24). The trunk thins where a man stands behind it.
def trunk_fade(foot:float2) -> float:
    var least = 1.0
    for(eyes) e:
        if e.y < foot.y + 6.0 and e.y > foot.y - TALL_H * ART_UP * 1.6:
            least = min(least, clamp((abs(e.x - foot.x) - 14.0) / 18.0, 0.22, 1.0))
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
                // (its trunk and limbs thin out over a man too, as its crown does, but less: the tree stays a tree)
                add(snow_frame(pr.name, pr.cell), pr.at.x, pr.at.y, pr.at.y, dim, if pr.sp == "tall": trunk_fade(pr.at) else: max(0.3, crown_fade(pr.at, pr.sp)))
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
                // (the lane's cobbles lie on the ground, under every shadow and everything that stands)
                if starts_with(pr.name, "cobbles"):
                    add(frame_at.get(pr.name, -1), pr.at.x, pr.at.y, -40002.0, float4_1, 1.0, 2)
                // (a yard wall has none: a stretch's shadow runs out past its end and lay across the next stretch)
                elif pr.name.length < 4 or substring(pr.name, 0, 4) != "wall": add(frame_at.get(pr.name + ".shadow", -1), pr.at.x, pr.at.y, -39997.0, float4_1)
                // (the camp's horses and mules are marked like the men, so they keep their colour in the shade
                // instead of reading as grey ghosts)
                let beast = starts_with(pr.name, "horse") or starts_with(pr.name, "mule") or starts_with(pr.name, "rider")
                if not starts_with(pr.name, "cobbles"):
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
        let since = seen_s - mark_t
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
    ghosts = []
    breaths = []
    fire_lits = []
    // (a fire on a hut's hearth is inside it: not drawn)
    if not fires_look: fires = map(filter(fires_lit()) cp: not cp.hut) cp: gp(float(cp.x), float(cp.y))
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
    // (a fire still being laid: its ring of stones and its logs already, so the camp shows at once; the flames come when
    // it catches. Dominic, 2026-11-13: "telling them to make camp, i got no fire")
    if not fires_look:
        for(sv_camps) cp:
            if not cp.hut and not fire_burning(cp):
                let p = gp(float(cp.x), float(cp.y))
                add(frame_at.get("fireplace.shadow", -1), p.x, p.y, -39997.0, float4_1)
                add(frame_at.get("fireplace", -1), p.x, p.y, p.y, float4_1, 1.0, 2)
    // (the shepherds' huts at the side paths' ends, smyana/finds.lobster)
    for(huts) c:
        let p = gp(float((c % W) * TILE + TILE / 2), float((c / W) * TILE + TILE / 2))
        if p.x > view_lo.x - 120.0 and p.x < view_hi.x + 120.0 and p.y > view_lo.y - 40.0 and p.y < view_hi.y + 200.0:
            add(frame_at.get("hut.shadow", -1), p.x, p.y, -39997.0, float4_1)
            add(frame_at.get("hut", -1), p.x, p.y, p.y, float4_1, 1.0, 2)
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
                        if d.col.x >= 0.0:
                            // (a stand's item, drawn bigger than life so it is seen from a way off: docs/gathering.md)
                            gl.translate(float(floor(float2 { d.x, d.ay }))):
                                gl.scale(if d.col.x == 7.0: 1.4 else: 2.0): draw_patch(0.0, 0.0, int(d.col.x), int(d.col.y))
                        else: draw_patch(d.x, d.ay, int(d.col.x), int(d.col.y))
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
                for(ghosts) g: sprite_faded(int(g.z), g.x, g.y, SASH, GHOST)
                draw_leaf_fall()
                draw_chimney_smoke()
                gunfire_draw()
                draw_weather()
                if show_cover: draw_cover()
                fires_glow()
                gunfire_glow()
    sprite_snap = 1.0
    if atmo_on: atmo_end(cam_px, zoom, 1.5)

// The village's hearths (D-172): a thread of smoke from each house's chimney, so that somebody is at home. Where each
// chimney's top is comes from tools/camp_vox.py's house(): 0.4 of the half length along the house and a quarter of the
// half depth behind its ridge, 1.16 m over the roof there (metres from the middle of the floor; HOUSES there).
let CHIMNEYS = [ float3 { 1.36, 0.75, 6.6 }, float3 { 1.16, 0.7, 8.64 }, float3 { 1.44, 0.68, 6.41 } ]
let TILE_M = 4.85  // (metres a tile, as the camp's models are cut: 135.76 voxels a tile at 28 a metre)

def draw_chimney_smoke():
    let camp = glist(su_map, "camp")
    if not camp.length: return
    let t = gl.time()
    gl.set_shader("color")
    // (coming home, a hearth for each house whose man came back: with half the men lost, half the chimneys are cold.
    // D-197)
    var houses = 0
    for(camp) e: if as_str(e.a[0]).length == 6 and substring(as_str(e.a[0]), 0, 5) == "house": houses++
    let lit = if leg_id == "village_home" and men.length > 0: (houses * men_alive() + men.length - 1) / men.length else: houses
    var house_n = 0
    for(camp) e, i:
        let name = as_str(e.a[0])
        if name.length == 6 and substring(name, 0, 5) == "house":
            house_n++
            // (which are cold is spread through the village, not one end of it)
            if (house_n * 7) % houses >= lit: continue
            let n = string_to_int(substring(name, 5, 1))
            let c = CHIMNEYS[n % 3]
            // (house0..2 are turned half round, house3..5 a quarter: camp.lobster's CAMP_THING_TURNS)
            let q = if n < 3: float2 { -c.x, -c.y } else: float2 { -c.y, c.x }
            let top = gp(as_float(e.a[1]), as_float(e.a[2])) + iso(q.x / TILE_M * 1000.0, q.y / TILE_M * 1000.0) - float2 { 0.0, c.z / TILE_M * ART_UP }
            for(12) k:
                let u = (t * 0.09 + float(k) / 12.0 + float(i) * 0.37) % 1.0
                let lean = (0.25 + gust()) * 34.0 * u * u  // (the air takes it east as it rises, more the higher it is)
                gl.color(float4 { 0.9, 0.9, 0.91, 0.7 * (1.0 - u) * min(1.0, u * 8.0) }):
                    gl.translate(floor(top + float2 { sin(u * 300.0 + float(i) * 70.0) * 2.5 + lean, -u * 58.0 })):
                        gl.rect(float2 { 3.0 + u * 11.0, 3.0 + u * 7.0 })

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
    for(piles) pl:
        let p = gp(float(pl.x), float(pl.y))
        if p.x > view_lo.x and p.x < view_hi.x and p.y > view_lo.y and p.y < view_hi.y:
            draws.push(Drawable { p.y + 1.0, draws.length, -8, p.x, p.y, float4 { -1.0 - float(pl.kind), float(pl.food + pl.wares.length), 0.0, 0.0 }, 1.0, 3, 0.0, 0.0 })
    // (each stand as its items, each sorted on its own foot: a rose bush stands up among the men, ceps lie under them;
    // fewer of them the less is left)
    let finds = forage_finds()
    for(stands) st:
        if st.left > 0 and st.kind < finds.length:
            let look = find(PATCH_LOOKS) l: l == gstr(finds[st.kind], "look", "")
            let n = if look == 7: clamp((st.left + 3) / 4, 1, 3) else: clamp(st.left, 3, 16)
            for(n) j:
                // (spread over the stand's ground, each item a hash of its own for its bearing and its distance out)
                let a = float(cell_hash(st.cell * 31 + j * 7 + 5) % 628) / 100.0
                let r = (if look == 7: 0.6 else: 2.2) * sqrt(float(cell_hash(st.cell * 53 + j * 11 + 9) % 1000) / 1000.0) * 1000.0
                let p = gp(float((st.cell % W) * 1000 + 500) + cos(a) * r, float((st.cell / W) * 1000 + 500) + sin(a) * r)
                if p.x > view_lo.x - 40.0 and p.x < view_hi.x + 40.0 and p.y > view_lo.y and p.y < view_hi.y + 60.0:
                    draws.push(Drawable { p.y + 1.0, draws.length, -8, p.x, p.y, float4 { float(look), float(st.cell * 64 + j), float(st.left), 0.0 }, 1.0, 3, 0.0, 0.0 })

// One patch, a few pixels of the art about its foot (x, y art px): pale mushroom caps, fallen nuts and husks, a
// fruiting tuft, flowering sprigs. Spread over a stretch of ground and pale against the litter, so it can be found.
def draw_patch(x:float, y:float, look:int, cell:int):
    gl.set_shader("color")
    def px(dx:float, dy:float, w:float, h:float, c:float4):
        gl.color(c): gl.translate(float2 { floor(x) + dx, floor(y) + dy }): gl.rect(float2 { w, h })
    let leaf = float4 { 0.22, 0.36, 0.17, 1.0 }
    let shade = float4 { 0.08, 0.06, 0.04, 0.6 }
    if look == -2:  // another band's cache: a low heap of flat stones, a sack's corner showing under them
        for(9) n:
            let o = float2 { float(n % 3) * 4.0 - 4.0 + float(n / 3 % 2), float(n / 3) * -2.0 }
            px(o.x - 2.0, o.y + 1.0, 5.0, 1.0, shade)
            px(o.x - 2.0, o.y - 2.0, 4.0, 3.0, [ float4 { 0.55, 0.53, 0.5, 1.0 }, float4 { 0.47, 0.45, 0.42, 1.0 }, float4 { 0.62, 0.6, 0.56, 1.0 } ][n % 3])
            px(o.x - 2.0, o.y - 2.0, 4.0, 1.0, float4 { 0.7, 0.68, 0.64, 1.0 })
        px(3.0, -1.0, 3.0, 2.0, float4 { 0.55, 0.45, 0.32, 1.0 })
        return
    if look == -3:  // wild bees' honey: the dark mouth of a hollow at an old tree's foot, pale comb in it, a few bees
        px(-4.0, -9.0, 7.0, 9.0, float4 { 0.12, 0.09, 0.07, 1.0 })
        px(-3.0, -7.0, 2.0, 5.0, float4 { 0.86, 0.66, 0.24, 1.0 })
        px(0.0, -6.0, 2.0, 4.0, float4 { 0.78, 0.56, 0.18, 1.0 })
        if season_now() != "winter":
            let t = gl.time()
            for(4) n:
                let a = t * (2.0 + float(n) * 0.7) + float(n) * 1.7
                px(floor(cos(a) * 7.0) - 1.0, floor(sin(a * 1.3) * 4.0) - 12.0, 1.0, 1.0, float4 { 0.18, 0.14, 0.06, 1.0 })
        return
    if look < 0:  // a pile of packs: tied sacks and a bundle, more of them the more there is (cell: how much)
        for(clamp(cell / 6 + 1, 1, 6)) n:
            let o = float2 { float(n % 3) * 5.0 - 5.0, float(n / 3) * -3.0 }
            px(o.x - 2.0, o.y + 1.0, 6.0, 1.0, shade)
            px(o.x - 2.0, o.y - 4.0, 5.0, 5.0, float4 { 0.55, 0.45, 0.32, 1.0 })
            px(o.x - 1.0, o.y - 5.0, 3.0, 1.0, float4 { 0.64, 0.54, 0.4, 1.0 })
            px(o.x, o.y - 6.0, 1.0, 1.0, float4 { 0.3, 0.2, 0.12, 1.0 })
            px(o.x - 2.0, o.y - 2.0, 5.0, 1.0, float4 { 0.42, 0.33, 0.22, 1.0 })
        return
    // (one item of a stand: a cell's worth of it, bigger than life so it is seen from a way off, docs/gathering.md)
    let h = cell
    def r(n:int, m:int) -> float: return float(cell_hash(h * 13 + n) % m)
    if look == 0:  // ceps: one to three together, stout pale stems under broad red-brown caps (Boletus edulis)
        for(1 + h % 3) n:
            let o = float2 { r(n, 15) - 7.0, r(n + 5, 7) - 3.0 }
            let w = 7.0 + r(n + 9, 4)
            px(o.x - w / 2.0 - 1.0, o.y + 1.0, w + 3.0, 2.0, shade)
            px(o.x - 2.0, o.y - 5.0, 4.0, 6.0, float4 { 0.9, 0.86, 0.74, 1.0 })
            px(o.x - 1.0, o.y - 4.0, 1.0, 4.0, float4 { 0.78, 0.72, 0.6, 1.0 })
            px(o.x - w / 2.0, o.y - 8.0, w, 3.0, float4 { 0.52, 0.3, 0.16, 1.0 })
            px(o.x - w / 2.0 + 1.0, o.y - 9.0, w - 2.0, 1.0, float4 { 0.62, 0.38, 0.2, 1.0 })
            px(o.x - w / 2.0 + 2.0, o.y - 9.0, 2.0, 1.0, float4 { 0.74, 0.5, 0.3, 1.0 })
            px(o.x - w / 2.0, o.y - 5.0, w, 1.0, float4 { 0.86, 0.8, 0.6, 1.0 })
    elif look == 1:  // beechnuts: split four-lobed husks and the dark three-sided nuts on the litter, a good fall of them
        for(7) n:
            let o = float2 { r(n, 23) - 11.0, r(n + 7, 11) - 5.0 }
            px(o.x - 1.0, o.y + 1.0, 4.0, 1.0, shade)
            if n % 2 == 0:
                px(o.x - 1.0, o.y - 1.0, 4.0, 2.0, float4 { 0.62, 0.46, 0.26, 1.0 })
                px(o.x, o.y - 2.0, 2.0, 1.0, float4 { 0.72, 0.56, 0.32, 1.0 })
            else:
                px(o.x, o.y - 1.0, 2.0, 2.0, float4 { 0.34, 0.2, 0.1, 1.0 })
                px(o.x, o.y - 1.0, 1.0, 1.0, float4 { 0.5, 0.32, 0.16, 1.0 })
    elif look == 2 or look == 3:  // a low fruiting tuft: leaves, blue-black bilberries or red berries thick on it
        let berry = if look == 2: float4 { 0.2, 0.22, 0.46, 1.0 } else: float4 { 0.86, 0.14, 0.1, 1.0 }
        let shine = if look == 2: float4 { 0.5, 0.54, 0.78, 1.0 } else: float4 { 1.0, 0.6, 0.5, 1.0 }
        px(-9.0, 1.0, 19.0, 2.0, shade)
        px(-9.0, -3.0, 19.0, 4.0, leaf)
        px(-6.0, -6.0, 13.0, 3.0, float4 { 0.28, 0.44, 0.2, 1.0 })
        px(-3.0, -8.0, 7.0, 2.0, leaf)
        for(9) n:
            let o = float2 { r(n, 17) - 8.0, r(n + 3, 8) - 7.0 }
            px(o.x, o.y, 2.0, 2.0, berry)
            px(o.x, o.y, 1.0, 1.0, shine)
    elif look == 4:  // mountain tea and herbs: upright woolly silver-green stems, pale yellow flower spikes
        for(5) n:
            let o = float2 { r(n, 17) - 8.0, r(n + 4, 7) - 3.0 }
            let tall = 9.0 + r(n + 8, 5)
            px(o.x - 1.0, o.y, 3.0, 1.0, shade)
            px(o.x, o.y - tall, 1.0, tall, float4 { 0.62, 0.68, 0.56, 1.0 })
            px(o.x - 2.0, o.y - 3.0, 2.0, 1.0, float4 { 0.7, 0.76, 0.64, 1.0 })
            px(o.x + 1.0, o.y - 5.0, 2.0, 1.0, float4 { 0.7, 0.76, 0.64, 1.0 })
            px(o.x - 1.0, o.y - tall - 4.0, 3.0, 5.0, float4 { 0.92, 0.86, 0.48, 1.0 })
            px(o.x, o.y - tall - 5.0, 1.0, 1.0, float4 { 0.96, 0.92, 0.6, 1.0 })
    elif look == 5:  // greens: low bright tufts, nettles or wild garlic
        px(-8.0, 1.0, 17.0, 1.0, shade)
        px(-8.0, -3.0, 17.0, 4.0, float4 { 0.36, 0.58, 0.2, 1.0 })
        px(-5.0, -6.0, 11.0, 3.0, float4 { 0.46, 0.7, 0.28, 1.0 })
        px(-2.0, -8.0, 5.0, 2.0, float4 { 0.56, 0.8, 0.34, 1.0 })
    elif look == 6:  // wild pears fallen in the grass: small, green flushed red, the ripest gone brown (Pyrus pyraster)
        for(6) n:
            let o = float2 { r(n, 21) - 10.0, r(n + 6, 9) - 4.0 }
            let c = [ float4 { 0.62, 0.7, 0.26, 1.0 }, float4 { 0.7, 0.62, 0.24, 1.0 }, float4 { 0.66, 0.4, 0.2, 1.0 }, float4 { 0.46, 0.32, 0.16, 1.0 } ][(h + n) % 4]
            px(o.x - 1.0, o.y + 1.0, 5.0, 1.0, shade)
            px(o.x - 1.0, o.y - 2.0, 5.0, 3.0, c)
            px(o.x, o.y - 3.0, 3.0, 1.0, c)
            px(o.x, o.y - 2.0, 1.0, 1.0, float4 { 0.78, 0.36, 0.2, 1.0 })
            px(o.x + 1.0, o.y - 4.0, 1.0, 1.0, float4 { 0.3, 0.2, 0.1, 1.0 })
    elif look == 7:  // a dog rose: arching dark stems, bare in winter, hung thick with red hips (Rosa canina)
        let wide = 22.0 + r(1, 10)
        px(-wide / 2.0, 1.0, wide, 3.0, shade)
        for(9) n:
            let a = (float(n) / 8.0 - 0.5) * 2.4
            let len = 22.0 + r(n + 2, 12)
            for(int(len)) k:
                let t = float(k) / len
                let sx = sin(a) * len * t * 0.8 + sin(t * 3.0) * float(n % 3 - 1)
                let sy = -cos(a * 0.6) * len * t + t * t * len * 0.35
                px(floor(sx), floor(sy), 1.0, 1.0, float4 { 0.3, 0.16, 0.12, 1.0 })
                if k % 4 == 3 and cell_hash(h + n * 17 + k) % 3 != 0:
                    px(floor(sx) - 1.0, floor(sy), 2.0, 3.0, float4 { 0.8, 0.12, 0.08, 1.0 })
                    px(floor(sx) - 1.0, floor(sy), 1.0, 1.0, float4 { 0.96, 0.42, 0.3, 1.0 })

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

let FONT = "../data/fonts/OldStandard/OldStandard-Regular.ttf"  // (the title's face, for the letters and the end's words too; Droid Sans till 2026-11-24)

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

// Above the click's words, from the letter's start: how long the walk to the next place is and when in the day the men
// come in ("Crossing into the beech valley threw away the afternoon ... I had about 40 seconds of daylight in the new
// place", the fifth first-time play, 2026-11-23: the hours were always spent, and nothing said so).
def walk_words(hours:int, arrive_hour:float) -> string:
    if hours <= 0: return ""
    let n = [ "An hour", "Two hours", "Three hours", "Four hours", "Five hours", "Six hours", "Seven hours", "Eight hours" ][min(hours, 8) - 1]
    let h = arrive_hour - floor(arrive_hour / 24.0) * 24.0
    let dusk = mood_hour("dusk")
    let when = if h < mood_hour("dawn") or h >= dusk + 1.5: "after dark" elif h >= dusk - 1.0: "as the light goes" elif h < 11.0: "in the morning" elif h < 14.0: "at midday" else: "in the afternoon"
    return "{n} on the road. They come in {when}."

def draw_walk_words(l:string, t:float):
    if l == "": return
    let ws = float(gl.window_size())
    gl.set_shader("color")
    gl.set_font_name(FONT)
    gl.set_font_size(int(ws.y / 44.0))
    let w = float(gl.text_size(l).x)
    gl.color(float4 { 0.93, 0.89, 0.78, clamp(t - 0.4, 0.0, 1.0) * 0.6 }):
        gl.translate(float2 { floor(ws.x / 2.0 - w / 2.0), floor(ws.y * 0.8) }): gl.text(l)

// Under the letter, once the next place is ready: that a click goes on.
def draw_go_on(t:float):
    let ws = float(gl.window_size())
    gl.set_shader("color")
    gl.set_font_name(FONT)
    gl.set_font_size(int(ws.y / 52.0))
    let l = "click to go on"
    let w = float(gl.text_size(l).x)
    gl.color(float4 { 0.93, 0.89, 0.78, clamp(t, 0.0, 1.0) * 0.45 }):
        gl.translate(float2 { floor(ws.x / 2.0 - w / 2.0), floor(ws.y * 0.86) }): gl.text(l)

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
    // (and what mends it, while he is not in a camp. Dominic, playing, 2026-11-24: "the guys say they're tired and
    // hungry . What do i do next?")
    let i = index_of(m.uid)
    if (m.fed < 40000 or m.rested < 40000 or m.warm < 40000) and i >= 0 and camp_of(i) < 0:
        gl.color(float4 { 0.85, 0.81, 0.7, 0.6 }):
            gl.translate(float2 { floor(ws.y * 0.03), floor(ws.y - float(size) * 0.95) }): gl.text("Make camp: a fire, a meal and sleep will mend it.")

// ------------------------------------------------------------------ the order signs (Dominic, 2026-11-13: "teaching
// them to press C is pretty bad. This is where we need a minimal level of UI somehow"; "The UI youve done i pretty bad.
// You went for minimal, but it just looks like placholder")
// With men chosen, a few small pictures drawn in the game's own hand just under their feet, no words: a fire (make
// camp, light it, or put it out), a pack (open the packs), an open hand (halt); and beside them a row of loaves, one
// for each day the bread will last. Nothing shows when no one is chosen. The keys still work. docs/gathering.md.

// The chosen men who are men (not game or a patrol someone clicked).
def chosen_men() -> [int]: return filter(selected) id: man_of(id) != nil and index_of(id) >= 0

// The signs for the chosen men now: what each does (0 camp, 1 open the packs, 2 halt), and the camp's state for the fire's
// picture (0 no camp, 1 a camp with its fire out, 2 the fire being laid, 3 the fire lit).
def signs() -> [int], int:
    let ids = chosen_men()
    if not ids.length: return [], 0
    var camp = 0
    for(ids) id:
        let k = camp_of(index_of(id))
        if k >= 0: camp = if sv_camps[k].lit and tick < sv_camps[k].lit_at: 2 elif sv_camps[k].lit: 3 else: 1
    // (the pack's sign always: it opens the packs now, and a sign that came and went without a word puzzled the
    // sixth first-time play, 2026-11-24)
    let what = [ 0, 1 ]
    what.push(2)
    return what, camp

// The bread the men have, in days for each man (all of them share it at a meal).
def bread_days() -> int:
    // (with what is in their own packs set down: the fourth agent playtest set the packs down and was told "That is
    // the last of the bread", 2026-11-23)
    var food = 0
    for(piles) pl: if pl.kind == 0: food += pl.food
    var n = 0
    for(men) m:
        if m.alive:
            food += m.food
            n++
    return if n: food / n else: 0

// The size of a pixel of the signs' art, in screen pixels (a sign is 16 of them square).
var sign_held = float3_0  // where the signs last sat (x, y; z: 1 once they have)
// (the packs: the pack's sign opens them, to see what the men carry; with them open a right click on an old tree
// sends the chosen men to hide their packs at its foot. Dominic, 2026-11-24: "opening the pack to see what you have",
// and hiding "should be done via interaction menu with the place you're hiding it, not dumping it randomly". D-180)
var pack_open = false
// (what a man has just called out, a stand of fruit, game, a hut: a small ring on it for a few seconds, at the screen's
// edge if it is out of view, so the call can be followed. Dominic, 2026-11-24: "feels too easy to just walk forward on
// the first map"; four first-time plays heard "Strawberries!" and never found them. D-189)
var find_mark = float2_0  // art px
var find_until = 0.0      // seen_s
var find_word = ""
var way_until = 0.0        // till when "The way on" and its ring show (seen_s)
var find_milli = float2_0  // where it is on the map (thousandths of a tile), for a click on the ring itself
var hide_ids = []::int     // the men on their way to hide their packs
var hide_at = int2_0       // where, in sim units
var hide_until = 0.0       // and till when they keep trying (seen_s)

def sign_px() -> float: return float(max(2, gl.window_size().y / 360))

// Where the signs sit on the screen, each a square (x, y, side) in a row centred under the chosen men's feet, kept on
// the screen; and where the loaves start.
def sign_boxes(n:int) -> [float3], float2:
    let k = sign_px()
    let side = 16.0 * k
    let gap = 5.0 * k
    let ws = float(gl.window_size())
    var men_foot = 0.0
    var sx = 0.0
    let ids = chosen_men()
    for(ids) id:
        let p = to_screen(gp(float(u_x[index_of(id)]), float(u_y[index_of(id)])))
        sx += p.x
        men_foot = max(men_foot, p.y)
    let loaves_w = 9.0 * k * float(clamp(bread_days(), 1, 8)) + gap
    let total = float(n) * side + float(max(0, n - 1)) * gap + gap * 2.0 + loaves_w
    var x0 = sx / float(max(1, ids.length)) - total / 2.0
    var y0 = men_foot + 10.0 * k
    // (with the men off the screen, or so near its edge that the signs would be pushed against it, the signs sit at
    // the foot of the screen in the middle. Dominic, 2026-11-24: "their controls also follow you, so end up at the
    // edge of the screen")
    if x0 < ws.y * 0.03 or x0 > ws.x - ws.y * 0.03 - total or y0 < ws.y * 0.08 or y0 > ws.y - side - ws.y * 0.04:
        x0 = ws.x / 2.0 - total / 2.0
        y0 = ws.y * 0.86
    // (they stay where they are while the mouse is on or near them: under walking men they slid away from the click,
    // which then landed on the ground as an order, twice in the sixth first-time play, 2026-11-24)
    let m = mouse_px()
    if sign_held.z > 0.0 and m.x > sign_held.x - side and m.x < sign_held.x + total + side and m.y > sign_held.y - side and m.y < sign_held.y + side * 2.0:
        x0 = sign_held.x
        y0 = sign_held.y
    sign_held = float3 { x0, y0, 1.0 }
    let boxes = map(n) j: float3 { floor(x0 + float(j) * (side + gap)), floor(y0), side }
    return boxes, float2 { floor(x0 + float(n) * (side + gap) + gap), floor(y0 + side - 7.0 * k) }

// The sign under the mouse, or -1.
def sign_under() -> int:
    let what = signs()
    if not what.length: return -1
    let m = mouse_px()
    let boxes = sign_boxes(what.length)
    for(boxes) b, j: if m.x >= b.x and m.x < b.x + b.z and m.y >= b.y and m.y < b.y + b.z: return what[j]
    return -1

// Asked to make a new camp with unwary zaptiye within 22 tiles: the men say no, once; asked again within half a minute
// they do it. (The tenth first-time play was told "We should make camp", lit the fire, was told of the zaptiye nine
// seconds later, and was shot at in its sleep, 2026-11-24.)
var camp_refused_at = -1000.0
var camp_refused_say = false
def camp_refused(ids:[int]) -> bool:
    if camps_made() or seen_s - camp_refused_at < 30.0 or script != "": return false
    for(patrols) pt:
        for(patrol_alive(pt)) pid:
            let j = index_of(pid)
            for(ids) id:
                let i = index_of(id)
                if i >= 0 and dist2(u_x[i], u_y[i], u_x[j], u_y[j]) < sq(22 * TILE):
                    camp_refused_at = seen_s
                    camp_refused_say = true
                    find_mark = gp(float(u_x[j]), float(u_y[j]))
                    find_milli = float2 { float(u_x[j]), float(u_y[j]) }
                    find_until = seen_s + 25.0
                    find_word = "Zaptiye"
                    return true
    return false

// A camp just ordered: the order's ring where its fire will be, so the place is seen even among trees.
def camp_marked():
    if not sv_camps.length: return
    let cp = sv_camps[sv_camps.length - 1]
    mark_at = gp(float(cp.x), float(cp.y))
    mark_t = seen_s

// A sign clicked: its order.
def sign_order(what:int):
    let ids = chosen_men()
    if not ids.length: return
    if what == 1:
        pack_open = not pack_open
        return
    pack_open = false
    march_off(ids)
    if what == 0:
        // (a new camp lets the men go, so its signs are out of the way; putting a fire out or lighting it again
        // keeps them chosen for the order that follows, the third agent playtest, 2026-11-22)
        if not camp_refused(ids) and camp_order(ids):
            selected = []
            camp_marked()
    elif what == 2: issue_cmd(0, CMD_STOP, ids, 0, 0, 0, 0)

// One sign's picture on its square (x, y, side), k screen pixels to the art's pixel; lit when under the mouse.
def draw_sign(b:float3, k:float, what:int, camp:int, lit:bool):
    def px(x:float, y:float, w:float, h:float, c:float4):
        gl.color(c): gl.translate(float2 { b.x + x * k, b.y + y * k }): gl.rect(float2 { w * k, h * k })
    // (a dark round under it, so it reads over the brightest crowns; paler when the mouse is on it)
    let under = if lit: float4 { 0.26, 0.22, 0.16, 0.85 } else: float4 { 0.05, 0.04, 0.03, 0.6 }
    px(3.0, 0.0, 10.0, 16.0, under)
    px(1.0, 2.0, 14.0, 12.0, under)
    px(0.0, 4.0, 16.0, 8.0, under)
    px(2.0, 1.0, 12.0, 14.0, under)
    let wood = float4 { 0.45, 0.3, 0.17, 1.0 }
    let wood_lit = float4 { 0.62, 0.44, 0.26, 1.0 }
    let cut = float4 { 0.82, 0.68, 0.46, 1.0 }
    if what == 0:  // a fire: two crossed logs, flames on them (none while it is laid, embers and smoke when it is lit)
        px(3.0, 11.0, 10.0, 2.0, wood)
        px(3.0, 11.0, 10.0, 1.0, wood_lit)
        px(2.0, 11.0, 1.0, 2.0, cut)
        px(13.0, 11.0, 1.0, 2.0, cut)
        px(5.0, 9.0, 2.0, 2.0, wood)
        px(7.0, 10.0, 2.0, 2.0, wood_lit)
        px(9.0, 9.0, 2.0, 2.0, wood)
        if camp == 3:  // lit: put it out, a glow of embers and a grey thread of smoke
            px(5.0, 10.0, 6.0, 1.0, float4 { 0.9, 0.36, 0.1, 1.0 })
            px(7.0, 9.0, 2.0, 1.0, float4 { 1.0, 0.6, 0.2, 1.0 })
            for([ [ 8.0, 7.0 ], [ 7.0, 6.0 ], [ 7.0, 5.0 ], [ 8.0, 4.0 ], [ 9.0, 3.0 ], [ 9.0, 2.0 ] ]) s, n:
                px(s[0], s[1], 2.0, 1.0, float4 { 0.72, 0.7, 0.66, 0.9 - float(n) * 0.12 })
        elif camp != 2:
            px(5.0, 6.0, 6.0, 4.0, float4 { 0.86, 0.28, 0.08, 1.0 })
            px(6.0, 3.0, 4.0, 3.0, float4 { 0.86, 0.28, 0.08, 1.0 })
            px(7.0, 1.0, 2.0, 2.0, float4 { 0.86, 0.28, 0.08, 1.0 })
            px(6.0, 6.0, 4.0, 4.0, float4 { 0.98, 0.58, 0.14, 1.0 })
            px(7.0, 4.0, 2.0, 2.0, float4 { 0.98, 0.58, 0.14, 1.0 })
            px(7.0, 7.0, 2.0, 3.0, float4 { 1.0, 0.88, 0.44, 1.0 })
    elif what == 1:  // a pack set down: a tied sack, its strap, a bedroll rolled on top
        let sack = float4 { 0.6, 0.5, 0.34, 1.0 }
        px(4.0, 6.0, 8.0, 8.0, sack)
        px(3.0, 8.0, 10.0, 5.0, sack)
        px(5.0, 5.0, 6.0, 1.0, float4 { 0.7, 0.6, 0.42, 1.0 })
        px(4.0, 13.0, 8.0, 1.0, float4 { 0.42, 0.34, 0.22, 1.0 })
        px(10.0, 7.0, 1.0, 6.0, float4 { 0.36, 0.24, 0.14, 1.0 })
        px(4.0, 2.0, 8.0, 3.0, float4 { 0.5, 0.18, 0.14, 1.0 })
        px(4.0, 2.0, 8.0, 1.0, float4 { 0.64, 0.26, 0.2, 1.0 })
        px(3.0, 3.0, 1.0, 1.0, float4 { 0.36, 0.12, 0.1, 1.0 })
        px(12.0, 3.0, 1.0, 1.0, float4 { 0.36, 0.12, 0.1, 1.0 })
    else:  // halt: an open hand held up, its palm to you
        let skin = float4 { 0.84, 0.66, 0.5, 1.0 }
        let shade = float4 { 0.66, 0.48, 0.36, 1.0 }
        for(4) f:
            let tall = [ 5.0, 6.0, 6.0, 5.0 ][f]
            px(4.0 + float(f) * 2.0, 8.0 - tall + (if f == 0 or f == 3: 1.0 else: 0.0), 2.0, tall, skin)
            px(5.0 + float(f) * 2.0, 8.0 - tall + (if f == 0 or f == 3: 1.0 else: 0.0), 1.0, tall, shade)
        px(4.0, 8.0, 8.0, 5.0, skin)
        px(2.0, 7.0, 2.0, 2.0, skin)
        px(3.0, 9.0, 2.0, 2.0, skin)
        px(5.0, 13.0, 6.0, 2.0, skin)
        px(5.0, 11.0, 5.0, 1.0, shade)
        px(6.0, 15.0, 4.0, 1.0, float4 { 0.42, 0.3, 0.2, 1.0 })

// A loaf at (x, y) screen px, k to the art's pixel: a round country loaf with its crust scored; a grey crust when it
// is the last crumbs.
def draw_loaf(x:float, y:float, k:float, gone:bool):
    def px(dx:float, dy:float, w:float, h:float, c:float4):
        gl.color(c): gl.translate(float2 { x + dx * k, y + dy * k }): gl.rect(float2 { w * k, h * k })
    let dark = if gone: float4 { 0.2, 0.19, 0.17, 0.8 } else: float4 { 0.26, 0.14, 0.06, 1.0 }
    let crust = if gone: float4 { 0.42, 0.4, 0.37, 0.8 } else: float4 { 0.72, 0.46, 0.2, 1.0 }
    let top = if gone: float4 { 0.5, 0.48, 0.45, 0.8 } else: float4 { 0.86, 0.62, 0.3, 1.0 }
    let low = if gone: float4 { 0.34, 0.32, 0.3, 0.8 } else: float4 { 0.56, 0.32, 0.12, 1.0 }
    // (a dome: narrow at the top, its full width low down, flat on the board)
    px(2.0, -1.0, 4.0, 1.0, dark)
    px(1.0, 0.0, 6.0, 1.0, dark)
    px(0.0, 1.0, 8.0, 4.0, dark)
    px(1.0, 5.0, 6.0, 1.0, dark)
    px(2.0, 0.0, 4.0, 1.0, crust)
    px(1.0, 1.0, 6.0, 3.0, crust)
    px(1.0, 4.0, 6.0, 1.0, low)
    // (its scoring, pale across the top)
    px(2.0, 1.0, 1.0, 1.0, top)
    px(3.0, 2.0, 1.0, 1.0, top)
    px(4.0, 1.0, 1.0, 1.0, top)
    px(5.0, 2.0, 1.0, 1.0, top)

def draw_signs():
    let what, camp = signs()
    if not what.length: return
    let under = sign_under()
    gl.set_shader("color")
    let k = sign_px()
    let boxes, loaves = sign_boxes(what.length)
    for(boxes) b, j: draw_sign(b, k, what[j], camp, what[j] == under)
    // (a word under the one the mouse is on: two agent playtests, 2026-11-22, never learned what the pack and the hand
    // do; D-144)
    for(boxes) b, j:
        if what[j] == under:
            let word = if under == 1: (if pack_open: "Close the packs" else: "Open the packs") elif under == 2: "Halt" elif camp == 3: "Put the fire out" elif camp == 2: "Laying the fire" elif camp == 1: "Light the fire" else: "Make camp"
            gl.set_font_name("../data/fonts/OldStandard/OldStandard-Regular.ttf")
            gl.set_font_size(int(float(gl.window_size().y) / 46.0))
            let at = float2 { b.x, b.y + b.z + 3.0 * k }
            for([ 1.0, 0.0 ]) shade:
                gl.color(if shade > 0.0: float4 { 0.0, 0.0, 0.0, 0.75 } else: float4 { 0.97, 0.93, 0.82, 1.0 }):
                    gl.translate(at + float2 { shade, shade }): gl.text(word)
    // (the bread: a loaf for each day it will last, the last of them grey when it is gone)
    let days = bread_days()
    if days <= 0: draw_loaf(loaves.x, loaves.y, k, true)
    else:
        for(min(days, 8)) n: draw_loaf(loaves.x + float(n) * 9.0 * k, loaves.y, k, false)
    // (and a word under the loaves too when the mouse is on them: a playtester asked what they count, 2026-11-23)
    let m = mouse_px()
    let wide = 9.0 * k * float(clamp(days, 1, 8))
    let side = boxes[0].z
    if m.x >= loaves.x - 2.0 * k and m.x <= loaves.x + wide and m.y >= boxes[0].y and m.y <= boxes[0].y + side:
        let word = if days <= 0: "No food left" elif days == 1: "Food for a day" else: "Food for {days} days"
        gl.set_font_name("../data/fonts/OldStandard/OldStandard-Regular.ttf")
        gl.set_font_size(int(float(gl.window_size().y) / 46.0))
        let at = float2 { min(loaves.x, float(gl.window_size().x) - float(gl.text_size(word).x) - 6.0), boxes[0].y + side + 3.0 * k }
        for([ 1.0, 0.0 ]) shade:
            gl.color(if shade > 0.0: float4 { 0.0, 0.0, 0.0, 0.75 } else: float4 { 0.97, 0.93, 0.82, 1.0 }):
                gl.translate(at + float2 { shade, shade }): gl.text(word)

// ------------------------------------------------------------------ on the march (Dominic, 2026-11-13: "long march they
// should walk in a column not wide")
// Sent far, the men go in a column two abreast: the one nearest where they are going sets off first and each of the
// others a moment after the man before him, each to his own place in the column at the end of the walk. Sent a short
// way, they move as a group (Creel's formation).
let MARCH_TILES = 14    // further than this is a march
let MARCH_GAP_S = 0.45  // seconds between one man setting off and the next
let MARCH_STEP = 1100   // milli-tiles between one pair and the next in the column

class Marcher:
    id:int
    x:int
    y:int
    at:int  // the tick he sets off

var marchers = []::Marcher
// The march's end: when its head is nearly there, the whole column is given one move together, so they stand round it
// in Creel's formation instead of each pressing for his own spot (twenty men pressing for twenty spots in a gate's
// narrow end never got there, a playthrough found).
class MarchEnd:
    ids:[int]
    head:int
    x:int
    y:int
    at:int  // the tick it was ordered

var march_ends = []::MarchEnd

var gathered_said = 0
var far_howl_again = 0.0  // when the second far howl of the first night comes (watched seconds; 0: none due)
var near_asked = false    // an order was moved to the nearest ground the men can reach
var hunt_said_n = 0
var camp_shot_at = -1000.0   // when a camp was last shot into and the men told (seen_s)
var hunt_asked_at = -1000.0  // when the men were last sent after game (seen_s)
var hunt_alarm = false
var hunt_away_at = -1.0    // when "They are away" is to be said, by seen_s (-1: not)
var ending_played = false  // the ending's music has been begun
var rose_asked = false     // a right click has just sent the men to a dog rose that is no stand

def march(ids:[int], x:int, y:int):
    let here = filter(ids) id: index_of(id) >= 0
    march_off(here)
    if not here.length: return
    var cx = 0
    var cy = 0
    for(here) id:
        cx += u_x[index_of(id)] / here.length
        cy += u_y[index_of(id)] / here.length
    let far = sqrt(float(dist2(cx, cy, x, y)))
    if far < float(MARCH_TILES * TILE) or here.length < 3:
        send_men(here, x, y)
        return
    // (the way they go, and across it)
    let ux = float(x - cx) / far
    let uy = float(y - cy) / far
    let order = copy(here)
    insertion_sort(order) a, b: dist2(u_x[index_of(a)], u_y[index_of(a)], x, y) < dist2(u_x[index_of(b)], u_y[index_of(b)], x, y)
    march_ends.push(MarchEnd { order, order[0], x, y, tick })
    for(order) id, n:
        let back = float(n / 2 * MARCH_STEP)
        let side = if n % 2 == 0: -350.0 else: 350.0
        let tx = clamp(x - int(ux * back) + int(-uy * side), TILE, (W - 1) * TILE)
        let ty = clamp(y - int(uy * back) + int(ux * side), TILE, (H - 1) * TILE)
        marchers.push(Marcher { id, tx, ty, tick + int(float(n) * MARCH_GAP_S * float(TICK_HZ)) })

// Every sim tick: a man whose turn it is sets off.
def march_tick():
    if march_ends.length:
        march_ends = filter(march_ends) e:
            let h = index_of(e.head)
            if h < 0 or dist2(u_x[h], u_y[h], e.x, e.y) <= sq(4 * TILE) or (u_moving[h] == 0 and tick > e.at + 2 * TICK_HZ):
                let left = filter(e.ids) id: index_of(id) >= 0
                marchers = filter(marchers) mr: (find(left) id: id == mr.id) < 0
                if left.length: send_men(left, e.x, e.y)
                false
            else: true
    if not marchers.length: return
    marchers = filter(marchers) mr:
        if tick < mr.at: true
        else:
            if index_of(mr.id) >= 0: send_men([ mr.id ], mr.x, mr.y)
            false

// Told something else: he is no longer on the march.
def march_off(ids:[int]):
    marchers = filter(marchers) mr: (find(ids) id: id == mr.id) < 0
    for(march_ends) e: e.ids = filter(e.ids) id: (find(ids) i: i == id) < 0
    march_ends = filter(march_ends) e: e.ids.length > 0 and (find(e.ids) id: id == e.head) >= 0

// ------------------------------------------------------------------ what the mouse is on (Dominic, 2026-11-13: "i cant
// click on trees to see what they have or right click them")
// Under the mouse (Dominic, 2026-11-13: "The over over trees to see if we can cut is just lots of text instead of
// visual"): no words, but a man's name when the mouse is on him; everything else is said by the cursor, a picture of
// what a right-click on it would have the chosen men do (smyana/cursors.lobster).

// Whether a bridge here is down (felling is for mending one, and nothing else).
def bridge_down() -> bool: return (find(br_up) up: up == 0) >= 0

// The old tree whose foot the mouse is on (a place to hide the packs), or -1. Its own tile only, within a third of a
// tile of its middle: with the tiles beside it counted too, most right clicks in a wood were on "a tree", and the
// ninth first-time play hid its packs three times by accident with the packs open, 2026-11-24.
def hide_tree_under(mm:float2) -> int:
    let x = int(mm.x / 1000.0)
    let y = int(mm.y / 1000.0)
    if x < 0 or y < 0 or x >= W or y >= H or terrain[y * W + x] != str_index(tr_names, "tree"): return -1
    let d = float2 { mm.x - float(x) * 1000.0 - 500.0, mm.y - float(y) * 1000.0 - 500.0 }
    return if magnitude(d) < 380.0: y * W + x else: -1

// The cursor for what is under the mouse, with men chosen, in the order a right click takes them.
def hover_cursor() -> int:
    let u = unit_at_screen(mouse_px())
    if u >= 0: return if man_of(u_id[u]): CURSOR_POINT elif beast_kind(u_id[u]) == "horse": CURSOR_GO else: CURSOR_SHOOT
    let mm = mouse_milli()
    let mc = clamp(int(mm.y / 1000.0), 0, H - 1) * W + clamp(int(mm.x / 1000.0), 0, W - 1)
    if carcass_near(int(mm.x), int(mm.y)) >= 0: return CURSOR_KNIFE
    // (a pointer only for what is still there to do: Dominic, playing, 2026-11-24: "after ive taken things from it, i
    // can still right click it". Not the scholar's pointer on ruins already learned from, nor the camp's on a hut the
    // men are camped in)
    if at_ruin(mc) and not drain_learned(): return CURSOR_STUDY
    let hut = hut_near(int(mm.x), int(mm.y), 1)
    if hut >= 0 and not (exists(sv_camps) cp: cp.hut and dist2(cp.x, cp.y, (huts[hut] % W) * TILE, (huts[hut] / W) * TILE) < sq(4 * TILE)): return CURSOR_CAMP
    if pile_near(int(mm.x), int(mm.y)) >= 0: return CURSOR_TAKE
    if pack_open and hide_tree_under(mm) >= 0: return CURSOR_TAKE
    if patch_under(mm) >= 0: return CURSOR_GATHER
    let yt = young_tree_at(mm)
    if yt >= 0 and terrain[yt] == str_index(tr_names, "rubble"): return CURSOR_DIG
    if yt >= 0 and bridge_down(): return CURSOR_FELL
    return CURSOR_GO

// The men speak (Dominic, 2026-11-13: "i love your men saying \"i cant feel my hands\""): a short line over a man's
// head for a few seconds, said once when the moment comes, never as a lesson. The first is a man calling out a stand
// of what the wood gives as he comes near it ("Pears, there."), so it is found by the men, not by the mouse.
class Speech:
    id:int
    text:string
    until:float

var speech = []::Speech

def man_says(uid:int, text:string):
    if text != "" and not (exists(speech) sp: sp.id == uid and sp.text == text):
        let who = man_of(uid)
        heard_line("said", "{if who: who.name else: "a man"}: \"{text}\"")
    speech = filter(speech) sp: sp.id != uid
    speech.push(Speech { uid, text, seen_s + 5.0 })

def draw_speech():
    let k, uid = stand_seen()
    if k >= 0:
        man_says(uid, gstr(forage_finds()[stands[k].kind], "call", ""))
        find_mark = gp(float((stands[k].cell % W) * 1000 + 500), float((stands[k].cell / W) * 1000 + 500))
        find_milli = float2 { float((stands[k].cell % W) * 1000 + 500), float((stands[k].cell / W) * 1000 + 500) }
        find_until = seen_s + 16.0
        find_word = "Right click to gather"
    let now = seen_s
    speech = filter(speech) sp: sp.until > now and sp.text != "" and index_of(sp.id) >= 0
    if not speech.length: return
    let ws = float(gl.window_size())
    let size = int(ws.y / 36.0)  // (was a 46th: two agent playtests missed the one line said, 2026-11-22)
    gl.set_shader("color")
    gl.set_font_name("../data/fonts/OldStandard/OldStandard-Regular.ttf")
    gl.set_font_size(size)
    let placed = []::float3
    for(speech) sp:
        let i = index_of(sp.id)
        let a = clamp((sp.until - now) / 0.6, 0.0, 1.0)
        let tw = float(gl.text_size(sp.text))
        let p0 = float(floor(to_screen(gp(float(u_x[i]), float(u_y[i])) - float2 { 0.0, 46.0 }) - float2 { tw.x / 2.0, tw.y }))
        // (kept on the screen: a man at its edge had his words cut to one letter, the sixth first-time play)
        var p = float2 { clamp(p0.x, 4.0, max(4.0, ws.x - tw.x - 4.0)), clamp(p0.y, 4.0, ws.y - tw.y - 4.0) }
        // (and clear of a line already up: two men's words lay across each other on arriving in the fir woods, the
        // tenth first-time play)
        for(placed) q:
            if abs(p.y - q.y) < tw.y * 1.15 and p.x < q.x + q.z and q.x < p.x + tw.x: p = float2 { p.x, q.y + tw.y * 1.25 }
        placed.push(float3 { p.x, p.y, tw.x })
        for([ 1.0, 0.0 ]) shade:
            gl.color(if shade > 0.0: float4 { 0.0, 0.0, 0.0, 0.7 * a } else: float4 { 0.97, 0.93, 0.82, a }):
                gl.translate(p + float2 { shade, shade }): gl.text(sp.text)

// A man's name by the pointer when it is on him.
def draw_hover():
    let u = unit_at_screen(mouse_px())
    // (with the packs open, on an old tree's foot: what a right click there does)
    let hide_here = u < 0 and pack_open and hide_tree_under(mouse_milli()) >= 0
    if u < 0 and not hide_here: return
    let m = if hide_here: nil else: man_of(u_id[u])
    if not m and not hide_here: return
    let label = if m: m.name else: "Hide the packs here"
    let ws = float(gl.window_size())
    let size = int(ws.y / 38.0)
    let p = mouse_px() + float2 { 20.0, 16.0 }
    gl.set_shader("color")
    gl.set_font_name("../data/fonts/OldStandard/OldStandard-Regular.ttf")
    gl.set_font_size(size)
    for([ 1.0, 0.0 ]) shade:
        let o = float2 { shade, shade }
        gl.color(if shade > 0.0: float4 { 0.0, 0.0, 0.0, 0.75 } else: float4 { 0.97, 0.93, 0.82, 1.0 }):
            gl.translate(floor(p + o)): gl.text(label)

// ------------------------------------------------------------------ the menu (#86)
// Dominic: "Game start is slow, we want very minimal loader. The game menu should show the village (once ready - just
// the men in forest for now is fine) alive in real time -> when you "start", the menu should just fade away". So the
// loader is the game's name on the dark, and the menu is the same name over the wood, the men in it going about the
// camp, with two words under it. Start, and the words fade off the game that is already running.

let MENU_ITEMS = if has_s(args, "web"): [ "Start" ] else: [ "Start", "Quit" ]  // (a browser tab has nothing to quit to)
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
    send_men([ u_id[i] ], x, y)

// The camera while the menu is up: over the men, drifting slowly as if someone stood watching.
def menu_camera(dt:float):
    let t = gl.time()
    // (four tiles back up the lane from the men, so that the village's houses stand in the picture behind them: what
    // they are leaving. Not kept in from the rim, which is where the village is. D-167)
    let to = men_centre() + iso(-4000.0, 0.0) + float2 { sin(t * 4.0) * 40.0, cos(t * 3.0) * 14.0 }
    cam += (to - cam) * min(1.0, dt * 0.6)

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
    if gl.button("mouse1") == 1 and not dragging:
        let sg = sign_under()
        if sg >= 0:
            sign_order(sg)
            return
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
            if i >= 0 and seen_s - last_click < 0.5: selected = filter(u_id) id: man_of(id) != nil  // (a second click: every man)
            elif i >= 0: selected = [ u_id[i] ]
            // (a click on empty ground keeps the men chosen, Escape lets them go: a click that missed a sign, or
            // one on the mark that finds the men, left the fifth agent playtest with nobody chosen, 2026-11-23)
            last_click = seen_s
    // (Escape closes the packs first, then lets the men go)
    if gl.button("escape") == 1:
        if pack_open: pack_open = false
        else: selected = []

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
    for(3) n:
        let x = int(mm.x / 1000.0) + n
        let y = int(mm.y / 1000.0) + n
        if x >= 0 and y >= 0 and x < W and y < H and stand_at(y * W + x) >= 0: return y * W + x
    return -1

// The music turns with the threats (docs/threats.md): wary, then the hunting threat's own loop; when it is over, the
// end stroke and quiet, or the lament if a man fell in it (#64).
var danger_was = ""
var danger_told = ""   // the danger the men last spoke of
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
    if far < 24.0: hear(what, -far * 0.6, pan)

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
        if far < 12.0: hear("howl", -2.0 - far * 0.4, pan)
        else: hear("far_howl", -2.0 - (far - 12.0) * 0.25, pan * 0.6)

def order_tick():
    // C: make camp where the chosen men stand, or put its fire out, or light it again (docs/survival.md, #68)
    if gl.button("c") == 1 and selected.length:
        march_off(selected)
        if not camp_refused(selected) and camp_order(filter(selected) id: man_of(id) != nil): camp_marked()
        selected = []
    // X: open the packs, or close them (it put them down where the men stood before D-180)
    if gl.button("x") == 1 and selected.length: pack_open = not pack_open
    // (the right button is SDL's third, "mouse3", as Creel's own controls have it; on the Lobster this was first built
    // with it came as "mouse2", which is now the middle one, and a right click gave no order at all, Dominic
    // 2026-11-12: "I can select everyone, but I don't seem to... move anyone". Either gives the order.)
    if gl.button("mouse3") != 1 and gl.button("mouse2") != 1: return
    let ids = filter(selected) id: index_of(id) >= 0
    if not ids.length: return
    march_off(ids)
    hut_goal = -1  // (a new order: not on their way to a hut any more)
    hide_ids = []
    var mm = mouse_milli()
    // (a right click on the ring round something called out, while that thing is off the edge of the view, is a
    // right click on the thing: the ring says "Right click to take" and it is what a player clicks)
    if seen_s < find_until and find_word.length > 5 and find_word.substring(0, 5) == "Right":
        let ws = float(gl.window_size())
        let d = to_screen(find_mark) - ws / 2.0
        let pad = ws.y * 0.06
        let k = min((ws.x / 2.0 - pad) / max(abs(d.x), 1.0), (ws.y / 2.0 - pad) / max(abs(d.y), 1.0))
        let ring_at = ws / 2.0 + d * k
        if k < 1.0 and magnitude(mouse_px() - float2 { ring_at.x, min(ring_at.y, ws.y * 0.8) }) < ws.y * 0.06:
            mm = find_milli
            // (the ring on game is a hunt, as a click on the deer is: the tenth first-time play clicked it, the men
            // walked up to the herd, and it ran)
            if find_word == "Right click to hunt":
                var deer = -1
                for(u_id) id, i:
                    if game_of(id) >= 0 and (deer < 0 or dist2(u_x[i], u_y[i], int(mm.x), int(mm.y)) < dist2(u_x[deer], u_y[deer], int(mm.x), int(mm.y))): deer = i
                if deer >= 0:
                    hunt_order(ids, u_id[deer])
                    hunt_asked_at = seen_s
                    mark_at = gp(float(u_x[deer]), float(u_y[deer]))
                    mark_t = seen_s
                    return
    // (and a right click on "The way on" at the picture's edge is an order to the gate itself, the whole way: the
    // eleventh first-time play clicked the ring fifteen times to cross a place, each click a quarter of a screen)
    if seen_s < way_until and mm == mouse_milli():
        let ws = float(gl.window_size())
        let exits = gobj(leg_now(), "exits")
        for(gate_names) name, g:
            if has(exits, name):
                let r = gate_rects[g]
                let gm = float2 { float(r[0] + r[2] + 1) * 500.0, float(r[1] + r[3] + 1) * 500.0 }
                let d = to_screen(gp(gm.x, gm.y)) - ws / 2.0
                let pad = ws.y * 0.07
                let k = min((ws.x / 2.0 - pad) / max(abs(d.x), 1.0), (ws.y / 2.0 - pad) / max(abs(d.y), 1.0))
                if k < 1.0 and magnitude(mouse_px() - (ws / 2.0 + d * k)) < ws.y * 0.06: mm = gm
    // (the packs open and an old tree under the mouse: hide the packs at its foot)
    let was_open = pack_open
    pack_open = false
    let hide_tree = if was_open: hide_tree_under(mm) else: -1
    if hide_tree >= 0:
        let g = camp_ground_near(hide_tree, -1)
        hide_ids = ids
        hide_at = int2 { (g % W) * TILE + TILE / 2, (g / W) * TILE + TILE / 2 }
        hide_until = seen_s + 90.0
        march(ids, hide_at.x, hide_at.y)
        mark_at = gp(float(hide_at.x), float(hide_at.y))
        mark_t = seen_s
        return
    let foe = unit_at_screen(mouse_px())
    if foe >= 0 and not man_of(u_id[foe]):
        hunt_order(ids, u_id[foe])
        if game_of(u_id[foe]) >= 0: hunt_asked_at = seen_s
        mark_t = seen_s
        mark_at = gp(float(u_x[foe]), float(u_y[foe]))
        return
    // (the ruins under the mouse, off the road: study the Romans' drain beside it, #70)
    let mc0 = clamp(int(mm.y / 1000.0), 0, H - 1) * W + clamp(int(mm.x / 1000.0), 0, W - 1)
    if at_ruin(mc0) and study_order(ids):
        mark_at = gp(mm.x, mm.y)
        mark_t = seen_s
        return
    // (a carcass under the mouse: butcher it into their packs)
    let carcass = carcass_near(int(mm.x), int(mm.y))
    if carcass >= 0 and butcher_order(ids, carcass):
        mark_at = gp(float(carcasses[carcass].x), float(carcasses[carcass].y))
        mark_t = seen_s
        return
    // (a shepherds' hut under the mouse: make camp in it, smyana/finds.lobster)
    let hut = hut_near(int(mm.x), int(mm.y), 1)
    if hut >= 0 and not (exists(sv_camps) cp: cp.hut and dist2(cp.x, cp.y, (huts[hut] % W) * TILE, (huts[hut] / W) * TILE) < sq(4 * TILE)) and hut_order(ids, hut):
        mark_at = gp(mm.x, mm.y)
        mark_t = seen_s
        return
    // (a pile of packs under the mouse: pick it up)
    let pile = pile_near(int(mm.x), int(mm.y))
    if pile >= 0:
        packs_fetch(ids, pile)
        mark_at = gp(float(piles[pile].x), float(piles[pile].y))
        mark_t = seen_s
        return
    // (a patch of what the wood gives under the mouse: gather it)
    let pc = patch_under(mm)
    if pc >= 0 and forage_order(ids, pc):
        // (the rest go with the pickers when the stand is a way off, and wait a few tiles short of it: the band
        // stays one band, the third agent playtest's did not, 2026-11-22)
        let rest = filter(ids) id: not foraging(id)
        let px = (pc % W) * TILE + TILE / 2
        let py = (pc / W) * TILE + TILE / 2
        if rest.length:
            let r0 = index_of(rest[0])
            let far = sqrt(float(dist2(u_x[r0], u_y[r0], px, py)))
            if far > float(8 * TILE):
                let k = (far - float(4 * TILE)) / far
                march(rest, u_x[r0] + int(float(px - u_x[r0]) * k), u_y[r0] + int(float(py - u_y[r0]) * k))
        mark_at = gp(float((pc % W) * 1000 + 500), float((pc / W) * 1000 + 500))
        mark_t = seen_s
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
    elif tree >= 0 and (terrain[tree] == str_index(tr_names, "rubble") or bridge_down()):
        // (fallen rock dug away; a young tree felled only for the timber to mend a bridge, Dominic 2026-11-13: "Im
        // not sure yet actually how or why we would cut trees")
        issue_cmd(0, CMD_GATHER, ids, tree, 0, 0, 0)
        mark_at = gp(float((tree % W) * 1000 + 500), float((tree / W) * 1000 + 500))
    else:
        // (a click on ground the men cannot walk to, a ledge's top or a rock, sends them to the nearest ground they
        // can: at the village edge a first-time player was told "No way through there" five times, 2026-11-23, for
        // rock ledges that did not read as walls. D-166)
        let i0 = index_of(ids[0])
        let reach = reach_side(0, u_kind[i0], cell_of(u_x[i0], u_y[i0]))
        let x, y = reachable_near(reach, clamp(int(mm.x), 0, W * TILE - 1), clamp(int(mm.y), 0, H * TILE - 1))
        march(ids, x, y)
        // (told when it is far from where the mouse was: men who stopped at a cliff's foot without a word looked
        // like men who had stopped obeying, the seventh first-time play, 2026-11-24)
        if dist2(x, y, int(mm.x), int(mm.y)) > sq(3 * TILE): near_asked = true
        // (a dog rose that is only a bush: two first-time players went straight to its red hips, right-clicked nine
        // times and were told nothing, 2026-11-22 and 23. Now a man says why there is nothing to pick: guide_tick.)
        rose_asked = (find(props) pr: pr.kind == 5 and pr.name.length >= 4 and substring(pr.name, 0, 4) == "rose" and abs(pr.cell % W - x / TILE) <= 1 and abs(pr.cell / W - y / TILE) <= 1) >= 0
        mark_at = gp(float(x), float(y))
    mark_t = seen_s

// The camera stays over the place, far enough in from its edge that the view never runs off the map (the place has a
// rim of forest that deep: the map's "rim").
def cam_keep():
    // (on the flat: picking the ground under the camera and putting the camera back on it moved it every frame on a
    // cliff, where the picture under it is the cliff's face, not ground, and the view shook going over one, Dominic
    // 2026-11-12. Now it is only ever moved back in when it is past the rim)
    let rim = float(gint(su_map, "rim", 0)) * 1000.0
    let t = iso_inv(cam)
    let c = float2 { clamp(t.x, rim, float(W * 1000) - rim), clamp(t.y, rim, float(H * 1000) - rim) }
    if c != t: cam += iso(c.x, c.y) - iso(t.x, t.y)

var cam_follow = true  // the view goes with the men till the player moves it
var cam_mark = 0.0

def camera_tick(with_men:bool):
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
        // (not while a box is being dragged: one that ended at the screen's edge slid the view a screen away)
        if not (dragging and magnitude(m - drag_from) > 6.0):
            if m.x <= 3.0: d.x -= 1.0
            if m.y <= 3.0: d.y -= 1.0
            if m.x >= ws.x - 4.0: d.x += 1.0
            if m.y >= ws.y - 4.0: d.y += 1.0
    cam += d * sp
    // The view goes with the men (D-176): while they walk on an order and the player has not moved the view since, it
    // eases after them as they near its edge, so they stay in the middle part of it. Moving the view by hand lets go
    // of them till the next order or Tab. ("The view does not follow the men ... every order needed Tab or the arrow
    // keys first", the sixth and seventh first-time plays, 2026-11-24.)
    if d != float2_0: cam_follow = false
    elif mark_t != cam_mark or gl.button("tab") == 1: cam_follow = true
    cam_mark = mark_t
    if cam_follow and with_men and not dragging:
        let s = to_screen(men_centre())
        let lo = ws * float2 { 0.32, 0.3 }
        let hi = ws * float2 { 0.68, 0.62 }
        let off = float2 { (if s.x < lo.x: s.x - lo.x elif s.x > hi.x: s.x - hi.x else: 0.0), (if s.y < lo.y: s.y - lo.y elif s.y > hi.y: s.y - hi.y else: 0.0) }
        cam += off / zoom * min(1.0, gl.delta_time() * 2.0)
    // the wheel: a step in or out, about the point under the mouse
    let wheel = gl.mousewheel_delta() + (if gl.button("=") == 1 or gl.button("keypad +") == 1: 1 else: 0) - (if gl.button("-") == 1 or gl.button("keypad -") == 1: 1 else: 0)
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

var play_foe = -1    // (script:play) the id the men are firing at
var play_foe_uh = 0  // when they were told to (a foe they can't get at in three hours is left be)
let play_let_be = []::int
var play_log_leg = ""
var play_fights = 0
var play_frames = 0
var play_slow = 0  // frames over 1/50 s
var play_camped = false
var play_leg_uh = 0
var play_stuck = false
var play_next_status = 0.0

def play_status() -> string:
    var fed = 0
    var warm = 0
    var rested = 0
    var asleep_n = 0
    let alive = filter(men) m: m.alive
    for(alive) m:
        fed += m.fed / 1000
        warm += m.warm / 1000
        rested += m.rested / 1000
        if is_asleep(m.uid): asleep_n++
    let n = max(1, alive.length)
    return "men {alive.length} (asleep {asleep_n}), fed {fed / n} warm {warm / n} rested {rested / n}, food {sum(map(alive) m: m.food)}"

// script:play: the men fire at the nearest beast or patrolman within eight tiles of any of them, all together, and
// walk on when it is down or gone. What happens is printed as it happens, for a playthrough's log.
def play_fight(ids:[int]) -> bool:
    if play_foe >= 0 and index_of(play_foe) >= 0:
        if clock_uh - play_foe_uh < 3 * 1000000: return true
        print "play: {leg_id} foe {play_foe} out of reach, left be at {int(clock_s)} s"
        play_let_be.push(play_foe)
    elif play_foe >= 0: print "play: {leg_id} foe {play_foe} down or gone at {int(clock_s)} s, men {men_alive()}"
    if play_foe >= 0:
        play_foe = -1
        tour_sent = ""  // (walk on)
    var best = -1
    var best_d = 8 * TILE * 8 * TILE
    for(u_x.length) j:
        if u_owner[j] == 1 and t_hp[u_kind[j]] < 100000 and not is_horse(u_id[j]) and game_of(u_id[j]) < 0 and (find(play_let_be) f: f == u_id[j]) < 0:
            for(ids) id:
                let i = index_of(id)
                let d = dist2(u_x[i], u_y[i], u_x[j], u_y[j])
                if d < best_d:
                    best_d = d
                    best = j
    if best < 0: return false
    play_foe = u_id[best]
    play_foe_uh = clock_uh
    play_fights++
    march_off(ids)
    print "play: {leg_id} fire at {play_foe} ({if is_wolf(play_foe): "wolf" elif bear_of(play_foe) >= 0: "bear" else: "patrol"}) at {int(clock_s)} s, men {men_alive()}"
    guns_order(ids, play_foe)
    return true

// script:play gets food as a careful player would: with less than three days' food a man, it shoots game the men can
// see (the nearest four men fire), butchers what falls, and gathers patches near the trail; six hours a place at most.
var play_hunt = -1  // the game it is after
var play_hunt_uh = 0
var play_busy_uh = 0  // butchering or gathering since
var play_busy = ""
var play_hunts = 0
var play_food_uh = 0  // time spent hunting and gathering in this place
var play_food_leg = ""
var play_food_was = 0
let play_scouted = dictionary<int, int>(16)  // side paths the bot has sent scouts down in this place
var play_scout_leg = ""
var play_scouts = []::int  // (the men down a path now)
var play_stalked = false   // (and they have crept on toward what they found)
var play_scout_x = 0       // (where they are going)
var play_scout_y = 0
// Whether this leg is on the way out (route.json's legs: <place>_out; the ridge is the turn).
def outbound() -> bool: return leg_id.length > 4 and substring(leg_id, leg_id.length - 4, 4) == "_out"

var play_fetch_leg = ""
var play_fetched = []::Pile                // (the piles it has gone for in this place)
var play_held = ""                         // (the leg they stopped in for the evening)                    // (the leg its caches were fetched in)
let play_tried = dictionary<int, int>(64)  // patches already sent to in this place (one that can't be reached is left)
var play_tried_leg = ""

def play_food(ids:[int]) -> bool:
    if play_food_leg != leg_id:
        play_food_leg = leg_id
        play_food_uh = 0
        play_hunt = -1
    let going = play_food_order(ids)
    if going:
        march_off(ids)
        play_food_uh += clamp(clock_uh - play_food_was, 0, 100000)  // (not the night between: it isn't called at night)
    play_food_was = clock_uh
    return going

// pathonly: the test player never leaves the track for food (no hunting, gathering or fetching): what a player gets
// who only walks on. Dominic, 2026-11-24: "if players can finish the game by just following the path. And the game
// doesnt suggest anything other than that - then yes we need to rethink a bit right?"
let path_only = has_s(args, "pathonly")

def play_food_order(ids:[int]) -> bool:
    if path_only: return false
    let alive = filter(men) m: m.alive
    let food = sum(map(alive) m: m.food)
    let room = sum(map(alive) m: pack_room(m))
    if play_busy != "":
        if butchers.length and clock_uh - play_busy_uh < 2 * 1000000: return true
        // (a stand can be forty tiles off: the walk there and the gathering)
        if foragers.length and clock_uh - play_busy_uh < 5 * 1000000: return true
        // (a cache or the honey can be far down a path: six hours to walk there, a playthrough found two hours too few)
        if fetchers.length and clock_uh - play_busy_uh < 6 * 1000000: return true
        // (scouts who see game on the way that has not run: they stop and shoot, as a player would the moment it
        // shows; a playthrough found them walking on to the path's end, and every herd gone before a shot)
        if play_scouts.length and not is_night():
            let out = filter(play_scouts) id: index_of(id) >= 0
            var quarry = -1
            var quarry_d = sq(9 * TILE)
            for(game) g:
                let j = index_of(g.id)
                if j >= 0 and g.state != G_DEAD and g.state != G_FLEE and men_see(j):
                    for(out) id:
                        let d = dist2(u_x[index_of(id)], u_y[index_of(id)], u_x[j], u_y[j])
                        if d < quarry_d:
                            quarry_d = d
                            quarry = j
            if quarry >= 0:
                play_hunt = u_id[quarry]
                play_hunt_uh = clock_uh
                play_hunts++
                print "play: {leg_id} scouts shoot at a {game[game_of(play_hunt)].kind} at {int(sqrt(float(quarry_d))) / TILE} tiles, {int(clock_s)} s"
                hunt_order(out, play_hunt)
                play_scouts = []
                play_stalked = false
                play_busy = ""
                return true
        // (scouts on their way down a path: till one is there, or four hours; then what they see is hunted)
        if play_scouts.length and clock_uh - play_busy_uh < 4 * 1000000 and not (exists(play_scouts) id: index_of(id) >= 0 and dist2(u_x[index_of(id)], u_y[index_of(id)], play_scout_x, play_scout_y) < sq(3 * TILE)): return true
        // (there, and nothing in sight: they stalk on to seven tiles from the nearest of it, once, slowly)
        if play_scouts.length and not play_stalked:
            let s0 = index_of(play_scouts[0])
            var best = -1
            var best_d = sq(16 * TILE)
            for(game) g:
                let j = index_of(g.id)
                if j >= 0 and s0 >= 0 and g.state != G_DEAD and g.state != G_FLEE and dist2(u_x[j], u_y[j], u_x[s0], u_y[s0]) < best_d:
                    best_d = dist2(u_x[j], u_y[j], u_x[s0], u_y[s0])
                    best = j
            // (they go for it as a player who sees it on the screen does: the order walks them to a rifle's range)
            if best >= 0:
                play_hunt = u_id[best]
                play_hunt_uh = clock_uh
                play_hunts++
                print "play: {leg_id} scouts go for a {game[game_of(play_hunt)].kind} at {int(sqrt(float(best_d))) / TILE} tiles, {int(clock_s)} s"
                hunt_order(filter(play_scouts) id: index_of(id) >= 0, play_hunt)
                play_scouts = []
                play_busy = ""
                return true
        play_scouts = []
        play_stalked = false
        print "play: {leg_id} {play_busy} done at {int(clock_s)} s, {play_status()}"
        play_busy = ""
        tour_sent = ""
    // (something shot: butcher it)
    let ck = find(carcasses) cc: cc.meat > 0
    if ck >= 0 and room > 0:
        if butcher_order(ids, ck):
            play_busy = "butchering a {carcasses[ck].kind}"
            play_busy_uh = clock_uh
            return true
    // (on the way home: their caches here, first, docs/design.md: "Pick up the caches left on the way out"; and what
    // lies at the paths' ends, a cache someone else left, wild honey, as a player who went down the paths would)
    if play_fetch_leg != leg_id:
        play_fetch_leg = leg_id
        play_fetched = []
    if not outbound() and room > 0:
        // (twice at most: a fight on the way can take them off it; and one they can walk to: a pack fallen on a
        // ledge below the road was walked at for days, a playthrough found)
        let i0 = index_of(ids[0])
        let reach = if piles.length: men_reach(i0) else: []
        let pk = find(piles) p: p.food > 0 and (filter(play_fetched) q: q == p).length < 2 and reach[cell_of(p.x, p.y)] == 1
        if pk >= 0:
            play_fetched.push(piles[pk])
            packs_fetch(ids, pk)
            play_busy = "fetching {[ "the cache", "someone\'s cache", "the honey" ][piles[pk].kind]} ({piles[pk].food} portions)"
            play_busy_uh = clock_uh
            print "play: {leg_id} {play_busy} at {int(clock_s)} s"
            return true
    // (no more than six daylight hours a place on it, then they walk on; the packs filled to leave caches for the
    // winter)
    // (2026-11-22: a careful player keeps the packs near full all the way, and with under three days' bread stays
    // a second day's light in a place to hunt, sooner than walk on to starve)
    if food >= alive.length * 9 or play_food_uh >= (if food < alive.length * 3: 12 else: 6) * 1000000: return false
    if play_hunt >= 0 and game_of(play_hunt) >= 0 and index_of(play_hunt) >= 0 and game[game_of(play_hunt)].state != G_DEAD:
        if clock_uh - play_hunt_uh < 2 * 1000000: return true
        print "play: {leg_id} lost the {game[game_of(play_hunt)].kind} at {int(clock_s)} s"
        play_hunt = -1
        tour_sent = ""
    play_hunt = -1
    var best = -1
    var best_d = 16 * TILE * 16 * TILE
    for(game) g:
        let j = index_of(g.id)
        if j >= 0 and g.state != G_DEAD and g.state != G_FLEE and men_see(j):
            for(ids) id:
                let i = index_of(id)
                let d = dist2(u_x[i], u_y[i], u_x[j], u_y[j])
                if d < best_d:
                    best_d = d
                    best = j
    if best >= 0:
        let near = copy(ids)
        insertion_sort(near) a, b: dist2(u_x[index_of(a)], u_y[index_of(a)], u_x[best], u_y[best]) < dist2(u_x[index_of(b)], u_y[index_of(b)], u_x[best], u_y[best])
        let shooters = near.slice(0, min(6, near.length))
        play_hunt = u_id[best]
        play_hunt_uh = clock_uh
        play_hunts++
        print "play: {leg_id} hunt a {game[game_of(play_hunt)].kind} at {int(sqrt(float(best_d))) / TILE} tiles, {int(clock_s)} s"
        hunt_order(shooters, play_hunt)
        return true
    // (none in sight: four men go quietly down a side path whose mouth shows signs of game, as a player reads them,
    // and the rest wait; not with wolves on their heels, docs/off-the-path.md)
    if play_scout_leg != leg_id:
        play_scout_leg = leg_id
        play_scouted.clear()
    let wolves_near = exists(packs) p: p.state == W_FOLLOW and pack_alive(p).length > 0
    if not wolves_near and not is_night() and hour_now() < 15.0:
        for(side_paths) sp, k:
            let end = sp.cells[sp.cells.length - 1]
            let ex = (end % W) * TILE + TILE / 2
            let ey = (end / W) * TILE + TILE / 2
            let signs = find(game) g: g.state != G_DEAD and index_of(g.id) >= 0 and dist2(u_x[index_of(g.id)], u_y[index_of(g.id)], ex, ey) < sq(8 * TILE)
            if signs >= 0 and not play_scouted.get(k, 0):
                play_scouted.set(k, 1)
                let stop = sp.cells[max(0, sp.cells.length - 13)]  // (twelve tiles short of its end: a deer there notices a man at nine)
                play_scout_x = (stop % W) * TILE + TILE / 2
                play_scout_y = (stop / W) * TILE + TILE / 2
                let mouth = sp.cells[0]
                let near = copy(ids)
                insertion_sort(near) a, b: dist2(u_x[index_of(a)], u_y[index_of(a)], (mouth % W) * TILE, (mouth / W) * TILE) < dist2(u_x[index_of(b)], u_y[index_of(b)], (mouth % W) * TILE, (mouth / W) * TILE)
                play_scouts = near.slice(0, min(6, near.length))
                let rest = near.slice(play_scouts.length, near.length - play_scouts.length)
                if rest.length: issue_cmd(0, CMD_STOP, rest, 0, 0, 0, 0)
                send_men(play_scouts, play_scout_x, play_scout_y)  // (not a march: play_food takes them off any)
                play_busy = "scouting down the {[ "deer track", "sheep path", "cart track" ][sp.size]} after {game[signs].kind}"
                play_busy_uh = clock_uh
                print "play: {leg_id} {play_busy} at {int(clock_s)} s"
                return true
    // (a patch near the men: gather it)
    if room > 0:
        let cx = sum(map(ids) id: u_x[index_of(id)]) / ids.length
        let cy = sum(map(ids) id: u_y[index_of(id)]) / ids.length
        let c = cell_of(cx, cy)
        var pc = -1
        // (the nearest stand within forty tiles not tried yet: the wood off the trail is where most of it is)
        var pd = sq(40)
        for(stands) st:
            let d = sq(st.cell % W - c % W) + sq(st.cell / W - c / W)
            if st.left > 0 and d < pd and play_tried.get(st.cell, 0) == 0:
                pc = st.cell
                pd = d
        if play_tried_leg != leg_id:
            play_tried.clear()
            play_tried_leg = leg_id
        if pc >= 0: play_tried.set(pc, 1)
        if pc >= 0 and forage_order(ids, pc):
            play_busy = "gathering"
            play_busy_uh = clock_uh
            return true
    return false

var tour_still = 0  // the tick the men were last seen moving (script:tour, script:play)

// The cells man i can walk to from where he stands (threats' reach_from, on the men's own lanes).
def men_reach(i:int) -> [int]:
    let ln = lane_base[0] + t_mclass[u_kind[i]]
    let c = cell_of(u_x[i], u_y[i])
    let seen = map(W * H): 0
    seen[c] = 1
    let todo = [ c ]
    while todo.length:
        let n = todo.pop()
        for([ 1, -1, W, -W ]) d:
            let v = n + d
            if v >= 0 and v < W * H and abs(v % W - n % W) <= 1 and seen[v] == 0 and walks[ln][v] == 1:
                seen[v] = 1
                todo.push(v)
    return seen

// Whether the men's middle is more than a short walk (twenty-five tiles) from the gate they leave by.
def gate_far(ids:[int]) -> bool:
    let exits = gobj(leg_now(), "exits")
    if not exits.keys.length: return true
    let r = gate_rects[gate_index(exits.keys[0])]
    let cx = sum(map(ids) id: u_x[index_of(id)]) / ids.length / TILE
    let cy = sum(map(ids) id: u_y[index_of(id)]) / ids.length / TILE
    return sq(cx - (r[0] + r[2]) / 2) + sq(cy - (r[1] + r[3]) / 2) > sq(25)

def tour_tick():
    if (script != "tour" and script != "play") or run_over() or play_stuck: return
    // (alive and still on the map: a man killed this tick is gone from it before his record says so)
    let ids = filter(map(filter(men) m: m.alive) m: m.uid) id: index_of(id) >= 0
    if not ids.length: return
    if not gates_armed: return
    if script == "play":
        if play_log_leg != leg_id:
            play_log_leg = leg_id
            play_leg_uh = clock_uh
            play_camped = false  // (a camp made as they went out of the last place is not one here: a playthrough found them a night unfed)
            print "play: into {leg_id} at {int(clock_s)} s ({season_now()}), men {men_alive()}"
        // (five days in one place and not out of it: stuck; say where everyone is and stop. Three was too few once the bot hunted and cached through two days in the fir woods, 2026-11-13)
        if clock_uh - play_leg_uh > 120 * 1000000:
            print "play: STUCK in {leg_id} for five days, the bridges {br_up}"
            for(ids) id:
                let i = index_of(id)
                print "play:   man {id} at tile {u_x[i] / TILE},{u_y[i] / TILE}, going to {u_tx[i] / TILE},{u_ty[i] / TILE}, moving {u_moving[i]}, stuck {u_stuck[i]}, speed {u_speed[i]} pace {u_pace[i]} block {u_block[i]} group {u_group[i]} foe {u_foe[i]} task {u_task[i]} hp {u_hp[i]}"
            for(u_x.length) j:
                if not man_of(u_id[j]): print "play:   other {u_id[j]} {beast_kind(u_id[j])} side {u_owner[j]} at tile {u_x[j] / TILE},{u_y[j] / TILE}"
            play_stuck = true
            return
        if play_fight(ids): return
        // (a day spent after food ends in a camp like any other: a playthrough found last night's camp still counted
        // as made, and the men a second night with no fire or meal, dead with bread in their packs)
        if not is_night() and hour_now() < 19.0 and play_camped:
            play_camped = false
            tour_sent = ""
            print "play: {leg_id} morning, {play_status()}"
        if not is_night() and hour_now() < 19.0 and play_food(ids): return
        // (at night they make camp and light a fire, as a player would, and walk on at first light)
        if is_night() or hour_now() >= 19.0:  // (a careful player makes camp at dusk, before the dark)
            if not play_camped:
                play_camped = true
                march_off(ids)
                // (not in a camp whose fire is lit already, as at a hut they reached before dusk: the order given
                // again puts a fire out, and a playthrough found a night in a hut with none)
                // (the men not yet in it come in to it: a playthrough found one man asleep in the hut and fifteen out
                // in the snow three nights running, unfed with bread in their packs)
                let inside = find(ids) id: camp_of(index_of(id)) >= 0 and sv_camps[camp_of(index_of(id))].lit
                if inside < 0: camp_order(ids)
                else:
                    // (only from near by: men a long walk from that fire make their own where they are, sooner than
                    // walk the night through to it; the gorge going home cost eleven men that way)
                    let cp = sv_camps[camp_of(index_of(ids[inside]))]
                    let out = filter(ids) id: camp_of(index_of(id)) < 0
                    let far = filter(out) id: dist2(u_x[index_of(id)], u_y[index_of(id)], cp.x, cp.y) > sq(10 * TILE)
                    if far.length: camp_order(out)
                    else:
                        for(out) id, n: send_men([ id ], cp.x + (n % 5 - 2) * TILE / 2, cp.y + TILE + (n / 5) * TILE / 2)
                print "play: {leg_id} camp at {int(hour_now())}h, {play_status()}"
            return
        // (late in the day they stop where they are and wait for the evening, rather than walk on into the next place in
        // the dark and miss the meal and the sleep: a playthrough found them walking every night)
        // (not when the gate is near: they walk on into the next place and camp there, rather than lose the evening)
        if hour_now() >= 16.0 and not play_camped and (play_held == leg_id or gate_far(ids)):
            if play_held != leg_id:
                play_held = leg_id
                march_off(ids)
                // (on the cold way home, a shepherds' hut within reach: the night in it, its fire unseen)
                let cx = sum(map(ids) id: u_x[index_of(id)]) / ids.length
                let cy = sum(map(ids) id: u_y[index_of(id)]) / ids.length
                let hut = if outbound(): -1 else: hut_near(cx, cy, 30)
                if hut >= 0:
                    hut_order(ids, hut)
                    print "play: {leg_id} to the shepherds\' hut for the night at {int(clock_s)} s"
                else: issue_cmd(0, CMD_STOP, ids, 0, 0, 0, 0)
            return
        play_held = ""
        if play_camped:
            play_camped = false
            tour_sent = ""
            print "play: {leg_id} morning, walk on, {play_status()}"
        if clock_s >= play_next_status:
            play_next_status = clock_s + 300.0
            print "play: {leg_id} at {int(clock_s)} s, {int(hour_now())}h, {play_status()}"
    // (script:tour) one man fells the first young tree he finds, once, on the way out, to see felling work; the
    // playthrough doesn't: felling is only for mending a bridge now (2026-11-13)
    if script == "tour" and not tour_cut and leg_id == gstr(route, "start", ""):
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
    // (all of them stood still a while and not gone yet: some stopped short of the gate; send them again, together)
    let still = (find(ids) id: u_moving[index_of(id)] == 1) < 0 and not marchers.length
    if not still: tour_still = tick
    let again = tour_sent == leg_id and tick - tour_still > 15 * TICK_HZ
    if again: tour_still = tick
    if again and not waiting:
        let exits = gobj(leg_now(), "exits")
        if exits.keys.length:
            let r = gate_rects[gate_index(exits.keys[0])]
            // (each man still short of the gate to a spot of his own in it: sent together to its middle, a few
            // jammed at its mouth for days, a playthrough found)
            for(ids) id, n:
                let i = index_of(id)
                if not in_rect(r, u_x[i] / TILE, u_y[i] / TILE):
                    send_men([ id ], (r[0] + n % (r[2] - r[0] + 1)) * TILE + TILE / 2, (r[1] + n / (r[2] - r[0] + 1) % (r[3] - r[1] + 1)) * TILE + TILE / 2)
    // (setting off from a place on the way out that they come back through in the winter: what is more than seven
    // days' food a man is left there as a cache, by the men who carry most; four, until 2026-11-22: the pass, the ridge
    // and the pass again are six days with little to find, and they went up with three)
    if script == "play" and tour_sent != leg_id and not waiting and outbound() and has(gobj(route, "legs"), place_now() + "_home"):
        let alive = filter(men) m: m.alive
        var surplus = sum(map(alive) m: m.food) - alive.length * 7
        if surplus > 4:
            let rich = copy(ids)
            def food_of(id:int) -> int:
                let m = man_of(id)
                return if m: m.food else: 0
            insertion_sort(rich) a, b: food_of(a) > food_of(b)
            let droppers = []::int
            for(rich) id:
                if surplus > 0:
                    droppers.push(id)
                    surplus -= food_of(id) - 1
            march_off(droppers)
            if packs_drop(droppers): print "play: {leg_id} cache left at {int(clock_s)} s by {droppers.length} men, {play_status()}"
    if tour_sent != leg_id and not waiting:
        tour_sent = leg_id
        tour_still = tick
        let exits = gobj(leg_now(), "exits")
        if exits.keys.length:
            let r = gate_rects[gate_index(exits.keys[0])]
            march(ids, (r[0] + r[2] + 1) * TILE / 2, (r[1] + r[3] + 1) * TILE / 2)
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
// (how long each took, for the start's line: where a slow start goes)
var boot_parts = ""
var boot_t = seconds_elapsed()
def boot_part(name:string):
    boot_parts += " {name} {int((seconds_elapsed() - boot_t) * 1000.0)} ms,"
    boot_t = seconds_elapsed()
boot_part("window")
bake_men(): waiting_frame()
boot_part("men")
bake_beast("wolf"): waiting_frame()
bake_beast("bear"): waiting_frame()
bake_beast("horse"): waiting_frame()
for([ "roe", "roe_winter", "boar", "chamois", "chamois_winter" ]) b: bake_beast(b): waiting_frame()
bake_riders(): waiting_frame()
boot_part("beasts")
bake_trees(): waiting_frame()
boot_part("trees")
bake_camp(): waiting_frame()
boot_part("camp")
// prebake: every season's leaves and snow baked too (tools/prebake.sh), then the game stops: the baked/ folder is then
// whole, to be committed, and no start bakes anything
let prebake = has_s(args, "prebake")
if prebake:
    for([ 0, 700, 1350, 1750, 2650, 3500 ]) begins: bake_season(stage_of(begins)): waiting_frame()
    print "prebake: done in {seconds_elapsed() - boot0} s"
let boot_bakes = seconds_elapsed() - boot0
sounds_load()
boot_part("sounds")
guns_load()
threats_load()
with_mark = arg_of("range") != ""
with_patrol = arg_of("fight") != ""
with_wolves = arg_of("wolves") != ""
with_bear = arg_of("bear") != ""
needs_kept = has_s(args, "fresh")  // fresh: the men never get hungry, cold or tired (for a look)
boot_part("data")
run_seed = if arg_of("seed") != "": string_to_int(arg_of("seed")) else: 0  // seed:7: another run's chance meetings (docs/threats.md, riders)
run_begin()
boot_part("the first place")
if arg_of("leg") != "": enter_leg(arg_of("leg"), if arg_of("by") != "": arg_of("by") else: "west")  // by:east: walked in by that gate
if arg_of("hours") != "": clock_uh += string_to_int(arg_of("hours")) * 1000000                      // hours:<n>: the clock that much later (an evening arrival, for a playthrough from there)
// range:<x>,<y>: the men in a loose line on that tile, a mark five tiles east of them, and told to fire at it, for a
// look and a listen at the rifles (#58)
if arg_of("range") != "":
    let xy = map(tokenize(arg_of("range"), ",", " ")) v: string_to_int(v)
    for(u_x.length) i:
        u_x[i] = xy[0] * TILE + 500 - (i % 2) * 700
        u_y[i] = (xy[1] - 4) * TILE + 500 + (i / 2) * 800
    let mark = guns_mark((xy[0] + 5) * TILE + 500, xy[1] * TILE + 500)
    for(u_id) id, i: send_men([ id ], u_x[i], u_y[i])
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
    for(u_id) id, i: send_men([ id ], u_x[i], u_y[i])
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
if has_s(args, "broken"):  // broken: every bridge down, as the men find the gorge's (for a look, or a playthrough from there)
    for(br_id.length) k:
        br_up[k] = 0
        set_deck(br_cells[k], false)
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
        for(u_id) id, i: send_men([ id ], u_x[i], u_y[i])
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
// goods: every man carries one of the goods for home as the place opens (for a look at the open pack)
if has_s(args, "goods"): for(men) m, n: if m.alive and n % 5 != 4: m.wares = [ n % 4 ]
// droppacks: the men put their packs down where they stand as the place opens and walk on a little (#67, for a look)
if has_s(args, "droppacks"):
    let ids = filter(u_id) id: man_of(id) != nil
    for(men) m: if m.alive: m.wares = [ WARE_HERBS, WARE_HIDES ]
    packs_drop(ids)
    cam = gp(float(piles[0].x), float(piles[0].y))
    for(ids) id, n: send_men([ id ], piles[0].x + 3000 + (n % 4) * 700, piles[0].y + (n / 4) * 700 - 1500)
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
                send_men([ u_id[i] ], u_x[i], u_y[i])
                man_dir.set(u_id[i], 1)
boot_part("the rest")
print "start: {seconds_elapsed() - boot0} s ({boot_parts}) (the bakes {boot_bakes} s: men baked in {men_bake_s} s, trees in {trees_bake_s} s, 0: read from baked/; the first place {last_load_s} s, its view {view_load_s} s)"

// ------------------------------------------------------------------ the loop

// menu (the game running under its name: the start), arriving (fading in), play, leaving (fading out), letter, end.
// A picture or the tour starts playing at once (menu: the menu, for a look).
var phase = if capture and not has_s(args, "menu"): "arriving" else: "menu"
if phase != "menu": menu_alpha = 0.0
var phase_t = 0.0
var leave_edge = ""
var letter = []::string
var letter_loaded = false
var walk_line = ""  // under the letter: the hours of the walk and when the men come in
var acc = 0.0
var paused = false
var frame_no = 0
var shot_taken = false

// What the agent player is told it would hear and see, a line at a time (smyana/heard.lobster): the music as it begins
// and ends, the screen's turns (the menu, the letter between places, the end), and every half minute where the men are.
var heard_track = ""
var heard_phase = ""
var heard_next = 0.0
var heard_sec = -1
var heard_cursor = -1

def heard_tick():
    if not heard_on: return
    heard_s = clock_s
    // (a line a second of the run's clock, so the harness can run the game for so many seconds of it however fast or
    // slowly the machine draws)
    if int(clock_s) > heard_sec:
        heard_sec = int(clock_s)
        print "tick: {heard_sec}"
    if score_track != heard_track:
        heard_track = score_track
        heard_line("heard", if score_track != "": "music begins: {score_track} ({score_kind})" else: "the music ends, and the wood is left quiet")
    if cursor_now != heard_cursor and phase == "play":
        heard_cursor = cursor_now
        let pictures = [ "an arrow", "an arrow with a ring (a right click sends the men here)", "an axe (fell it)", "a basket (a right click gathers this)", "a hand (pick these up)", "a knife (butcher it)", "a sight (shoot it)", "a flame (camp here)", "a book (study this)", "a spade (dig it away)" ]
        if cursor_now >= 0: heard_line("clock", "the picture at the pointer is now: " + pictures[cursor_now])
    if phase != heard_phase:
        heard_phase = phase
        heard_line("clock", "the screen now: {phase}")
    if clock_s >= heard_next:
        heard_next = clock_s + 30.0
        heard_line("clock", "{gstr(leg_now(), "name", "")}, {season_now()}, {int(hour_now())}h, {men_alive()} men")

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

// ------------------------------------------------------------------ what a first-time player is told (D-144)
// Two agent playtests, 2026-11-22: no goal, a pause with no sign, orders that fail without a word, the men lost off the
// screen, hunger unseen. Dominic: "guiding player through first 5-10mins probably needed". Kept small: the men say it
// (data/survival.json "says"), one faint line at the foot of the screen until the first order is given, the word
// Paused, and a mark at the screen's edge toward the men when none of them is in view.
let said = []::string
var hint_stage = 0  // 0 choose them, 1 send them, 2 the Tab key (nine seconds), 3 done
var hint_t = 0.0
// A line at the foot of the screen for a few seconds, once each, when the moment for it comes: what the men's words
// do not say, which sign or key does it (Dominic, 2026-11-24: "What do i do next? is our final push planning little
// tutorial at the start?"). D-181.
var tip = ""
var tip_until = 0.0
var open_n = 0
var order_seen = -10.0
var order_ids = []::int
var order_from = float2_0
var order_tick_no = 0

// A line of the men's by its key. Said again, it is worded another way where the data has other wordings for it
// ("<key>_more"): the tenth first-time play heard six lines twice or more, word for word (2026-11-24).
let say_times = dictionary<string, int>(32)   // a key: how many times its line has been said
let say_key = dictionary<string, string>(64)  // a wording: its key
def say_cfg(k:string) -> string:
    let more = gstrs(sv_cfg("says"), k + "_more")
    let n = say_times.get(k, 0)
    let text = if n == 0 or not more.length: gstr(sv_cfg("says"), k, "") else: more[(n - 1) % more.length]
    say_key.set(text, k)
    return text

// One of the men says it: the first of `ids` who is there, else any man.
def one_says(key:string, text:string, n:int):
    if text == "" or (find(said): _ == key) >= 0: return
    said.push(key)
    let sk = say_key.get(text, "")
    if sk != "": say_times.set(sk, say_times.get(sk, 0) + 1)
    let there = filter(men) m: m.alive and index_of(m.uid) >= 0
    // (one of the five nearest the middle of the view, so the words are where the player is looking: the third agent
    // playtest found them at the screen's corner, over a man at the edge of the band)
    def off(m:Man) -> float:
        let i = index_of(m.uid)
        return magnitude(gp(float(u_x[i]), float(u_y[i])) - cam)
    insertion_sort(there) a, b: off(a) < off(b)
    if there.length: man_says(there[n % min(5, there.length)].uid, text)

def men_in_view() -> bool:
    let ws = float(gl.window_size())
    for(u_x.length) i:
        if man_of(u_id[i]):
            let s = to_screen(gp(float(u_x[i]), float(u_y[i])))
            if s.x > 0.0 and s.y > 0.0 and s.x < ws.x and s.y < ws.y: return true
    return false

// Where the men's mark sits on the screen's edge, toward them.
def men_mark() -> float2:
    let ws = float(gl.window_size())
    var sum = float2_0
    var n = 0
    for(u_x.length) i:
        if man_of(u_id[i]):
            sum += to_screen(gp(float(u_x[i]), float(u_y[i])))
            n++
    if not n: return ws / 2.0
    let d = sum / float(n) - ws / 2.0
    let pad = ws.y * 0.06
    let k = min((ws.x / 2.0 - pad) / max(abs(d.x), 1.0), (ws.y / 2.0 - pad) / max(abs(d.y), 1.0))
    return ws / 2.0 + d * min(k, 1.0)

// The way on (D-173): where this place's gate out is, in the picture or at its edge toward it. The sixth first-time
// play (2026-11-24) spent twenty minutes of its twenty-eight lost in the beech valley: "After the first line nobody ever
// says. There is no map, compass, path or signpost". East on the map is down and to the right on the screen, and it
// had walked to the right. So: a man says where the track goes as they come into a place, and again when they have
// been well off it for a minute and a half of daylight, and for twenty seconds a pale ring shows the way.
var still_since = 0.0  // since when no man has been walking (seen_s)
var season_said = ""
var rain_heard = false  // the rain is hard enough to hush the birds
var amb_ack_s = -100.0  // when a man last grunted at an order
var off_trail_s = 0.0
var off_trail_at = 0.0

def way_on() -> float2, bool:
    let exits = gobj(leg_now(), "exits")
    for(gate_names) name, g:
        if has(exits, name):
            let r = gate_rects[g]
            return to_screen(gp(float(r[0] + r[2] + 1) * 500.0, float(r[1] + r[3] + 1) * 500.0)), true
    return float2_0, false

// How far the middle of the men is from the nearest tile of trail, in tiles (99 where the place has none).
def tiles_off_trail() -> float:
    let trail = str_index(tr_names, "trail")
    var sum = float2_0
    var n = 0
    for(u_x.length) i:
        if man_of(u_id[i]):
            sum += float2 { float(u_x[i]), float(u_y[i]) }
            n++
    if not n: return 0.0
    let c = sum / float(n) / 1000.0
    var best = 99.0 * 99.0
    for(H) y: for(W) x:
        if terrain[y * W + x] == trail:
            let d = float2 { float(x) + 0.5, float(y) + 0.5 } - c
            best = min(best, d.x * d.x + d.y * d.y)
    return sqrt(best)

def way_tick():
    if leg_id != gstr(route, "start", "") and phase_t > 3.0 and (find(said): _ == "way {leg_id}") < 0:
        one_says("way {leg_id}", say_cfg("way_on"), 2)
        way_until = seen_s + 20.0
        off_trail_s = 0.0
    // (and again each morning, and whenever Tab finds the men: the eighth first-time play had the ring on arriving in
    // the dark and never again, and was lost for three minutes after going round a patrol, 2026-11-24)
    if gl.button("tab") == 1: way_until = max(way_until, seen_s + 12.0)
    // (and all day out of camp: the tenth first-time play lost the track for three and a half minutes in the fir
    // woods with the ring gone, the fifth play in a row to lose it. Two words at the screen's edge, Dominic's to
    // overrule.)
    if not is_night() and not camps_made() and not paused and leg_id != "": way_until = max(way_until, seen_s + 2.0)
    // (and whenever the men have stood still a few seconds by day, out of camp: a player who has stopped is a player
    // working out where to go. Four first-time plays in a row lost the way once the ring had gone.)
    var walking = false
    for(u_id) id, i: if man_of(id) and u_moving[i] == 1: walking = true
    if walking or is_night() or camps_made() or paused: still_since = seen_s
    elif seen_s - still_since > 6.0: way_until = max(way_until, seen_s + 2.0)
    if seen_s - off_trail_at < 1.0: return
    let dt = min(seen_s - off_trail_at, 2.0)
    off_trail_at = seen_s
    if paused or is_night() or camps_made(): return
    let off = tiles_off_trail()
    if off < 6.0: off_trail_s = min(off_trail_s, 0.0)
    elif off > 10.0 and off < 90.0: off_trail_s += dt
    if off_trail_s > 90.0:
        off_trail_s = -240.0  // (not again for four minutes more: going off the track is what the wood is for)
        said.remove_obj("lost track")
        one_says("lost track", say_cfg("lost_track"), 3)
        way_until = seen_s + 20.0

// The men sent to hide their packs put them down together at the tree's foot once most of them are there.
def hide_tick():
    if not hide_ids.length: return
    let ids = filter(hide_ids) id: man_of(id) != nil and index_of(id) >= 0
    let there = filter(ids) id: dist2(u_x[index_of(id)], u_y[index_of(id)], hide_at.x, hide_at.y) <= sq(4 * TILE)
    if ids.length and there.length * 3 < ids.length * 2 and seen_s < hide_until: return
    hide_ids = []
    if not there.length: return
    if packs_drop(there):
        piles[piles.length - 1].x = hide_at.x
        piles[piles.length - 1].y = hide_at.y
        said.remove_obj("packs hidden")
        one_says("packs hidden", say_cfg("packs_hidden"), 1)
    else:
        said.remove_obj("packs empty")
        one_says("packs empty", say_cfg("packs_empty"), 1)

def tip_once(key:string, text:string):
    if (find(said): _ == key) >= 0 or seen_s < tip_until or hint_stage < 3: return
    said.push(key)
    tip = text
    tip_until = seen_s + 12.0

// Whether game the player can see has taken fright (not a herd over the hill: "They are away" was said three times of
// animals the eighth first-time play never saw).
def game_alarmed_seen() -> bool:
    let ws = float(gl.window_size())
    for(game) g:
        let i = index_of(g.id)
        if i >= 0 and (g.state == G_ALERT or g.state == G_FLEE):
            let s = to_screen(gp(float(u_x[i]), float(u_y[i])))
            if s.x > 0.0 and s.y > 0.0 and s.x < ws.x and s.y < ws.y: return true
    return false

def guide_tick():
    if phase != "play" or script != "": return
    // the first ten minutes, a step at a time: what the pointer is for; that the view comes closer; when the men tire
    // or the light goes, how a camp is made; once the fire is lit, what it does; and in the morning, the way on
    if clock_s > 40.0: tip_once("tip pointer", "The pointer changes over what the men can use. Right click it.")
    if clock_s > 100.0: tip_once("tip zoom", "The wheel, or + and -, brings the view closer.")
    var worn = 0
    var living = 0
    for(men) m:
        if m.alive:
            living++
            if m.rested < 40000 or m.fed < 40000: worn++
    if not camps_made() and (worn * 3 > living or (hour_now() >= 17.5 and not is_night())):
        one_says("worn", say_cfg("worn"), 2)
        tip_once("tip camp", "Choose the men and click the fire under them to make camp. They eat and sleep by it.")
    if (exists(sv_camps) cp: fire_burning(cp)):
        one_says("camp first", say_cfg("camp_first"), 1)
        tip_once("tip night", "The night passes quickly once every man sleeps. A fire can be seen from far off.")
    way_tick()
    // the season turned: one of them says so (the sixth first-time play took the autumn trees for the new place's look)
    if season_said == "": season_said = season_now()
    elif season_said != season_now() and phase_t > 4.0:
        season_said = season_now()
        said.remove_obj("season")
        one_says("season", say_cfg("season_" + season_said), 4)
    let day = (gint(route, "start_hour", 7) * 1000000 + clock_uh) / 24000000
    if day >= 1 and hour_now() >= 6.0 and hour_now() < 9.0 and not is_night() and (find(said): _ == "way day {day}") < 0:
        said.push("way day {day}")
        way_until = max(way_until, seen_s + 30.0)
    // a hut within a morning's stroll of the men, not yet spoken of: one of them points it out
    if not is_night():
        for(huts) hc, hk:
            let key = "hut {leg_id} {hk}"
            if (find(said): _ == key) < 0:
                var near = false
                for(u_id) id, i: if man_of(id) and dist2(u_x[i], u_y[i], (hc % W) * TILE, (hc / W) * TILE) < sq(14 * TILE): near = true
                if near:
                    one_says(key, say_cfg("hut_seen"), 1)
                    find_mark = gp(float((hc % W) * 1000 + 500), float((hc / W) * 1000 + 500))
                    find_milli = float2 { float((hc % W) * 1000 + 500), float((hc / W) * 1000 + 500) }
                    find_until = seen_s + 16.0
                    find_word = "A hut"
        // (and a cache under its stones, or wild bees in a hollow trunk)
        for(piles) pl:
            let key = "pile {leg_id} {pl.x} {pl.y}"
            if pl.kind != 0 and (find(said): _ == key) < 0:
                var near = false
                for(u_id) id, i: if man_of(id) and dist2(u_x[i], u_y[i], pl.x, pl.y) < sq(12 * TILE): near = true
                if near:
                    one_says(key, say_cfg(if pl.kind == PILE_HONEY: "honey_seen" else: "cache_seen"), 2)
                    find_mark = gp(float(pl.x), float(pl.y))
                    find_milli = float2 { float(pl.x), float(pl.y) }
                    find_until = seen_s + 16.0
                    find_word = "Right click to take"
    // the opening: where the road goes, and what the year is for
    let opening = gstrs(sv_cfg("says"), "opening")
    if open_n < opening.length and phase_t > 2.0 + float(open_n * gint(sv_cfg("says"), "opening_s", 7)) and leg_id == gstr(route, "start", ""):
        one_says("opening {open_n}", opening[open_n], open_n * 7)
        if open_n == 0: way_until = seen_s + 30.0  // (east is down and to the right: the ring says so)
        open_n++
    // a later morning still in the first place: which way, again (the third and fourth agent playtests spent three
    // days at the village edge, 2026-11-22 and 23)
    if day >= 1 and hour_now() >= 6.0 and hour_now() < 9.0 and leg_id == gstr(route, "start", "") and not is_night() and (find(said): _ == "morning {day}") < 0:
        one_says("morning {day}", say_cfg("morning"), day)
        way_until = seen_s + 30.0
    // each morning out of camp, and on coming into a place by day: what the nearest ground off the track holds, and a
    // ring on it. (Dominic, 2026-11-24: "if players can finish the game by just following the path. And the game
    // doesnt suggest anything other than that - then yes we need to rethink a bit". The tenth first-time play left the
    // road for everything called out in the first place, and then walked twelve minutes through the beech valley
    // with nothing called: the stands and the deer were past where the men see from the track.)
    if hour_now() >= 6.0 and hour_now() < 15.0 and not is_night() and not camps_made() and phase_t > 14.0 and (find(said): _ == "look {leg_id} {day}") < 0 and (day >= 1 or leg_id != gstr(route, "start", "")):
        var mx = 0
        var my = 0
        var n = 0
        for(u_id) id, i:
            if man_of(id):
                mx += u_x[i] / 20
                my += u_y[i] / 20
                n++
        if n > 0:
            mx = mx * 20 / n
            my = my * 20 / n
            var best = sq(45 * TILE)
            var bx = 0
            var by = 0
            var what = ""
            for(stands) st:
                let sx = (st.cell % W) * TILE + TILE / 2
                let sy = (st.cell / W) * TILE + TILE / 2
                if st.left > 0 and not st.called and dist2(sx, sy, mx, my) < best and dist2(sx, sy, mx, my) > sq(9 * TILE):
                    best = dist2(sx, sy, mx, my)
                    bx = sx
                    by = sy
                    what = "look_stand"
            for(game) g:
                let gi = index_of(g.id)
                if gi >= 0 and g.state != G_DEAD and dist2(u_x[gi], u_y[gi], mx, my) < best and dist2(u_x[gi], u_y[gi], mx, my) > sq(9 * TILE):
                    best = dist2(u_x[gi], u_y[gi], mx, my)
                    bx = u_x[gi]
                    by = u_y[gi]
                    what = "look_game"
            // (what is nine tiles off or nearer is in front of them already, and is called out as they come on it)
            if what != "":
                one_says("look {leg_id} {day}", say_cfg(what), 4)
                find_mark = gp(float(bx), float(by))
                find_milli = float2 { float(bx), float(by) }
                find_until = seen_s + 30.0
                find_word = "Right click to go and look"
            else: said.push("look {leg_id} {day}")
    // the first night by a fire: wolves heard a long way off, and the man on watch says so. Nothing comes of it; it is
    // the first word of what the deeper woods hold (three first-time plays met nothing at all in twenty minutes)
    if day == 0 and is_night() and fires.length > 0 and (hour_now() >= 22.5 or hour_now() < 3.0) and (find(said): _ == "first howl") < 0:
        hear("far_howl", -10.0, 0.6)
        far_howl_again = seen_s + 10.0
        one_says("first howl", say_cfg("first_howl"), 1)
    if far_howl_again > 0.0 and seen_s >= far_howl_again:
        far_howl_again = 0.0
        hear("far_howl", -13.0, 0.3)
    // gathered: what it came to, said once the pickers are done
    if food_gathered < gathered_said: gathered_said = food_gathered
    if food_gathered > gathered_said and not foragers.length:
        gathered_said = food_gathered
        one_says("gathered {food_gathered}", say_cfg("gathered"), 2)
    if camp_refused_say:
        camp_refused_say = false
        said.remove_obj("camp near")
        one_says("camp near", say_cfg("camp_near"), 0)
    // dark, and no camp: the men will not walk on blind
    if first_say:
        first_say = false
        one_says("patrol ahead", say_cfg("patrol_ahead"), 1)
        // (and where: two first-time plays went round a patrol they never saw, and could not tell how wide to go)
        let c = men_centre()
        var best = 1.0e12
        for(patrols) pt:
            for(patrol_alive(pt)) pid:
                let at = gp(float(u_x[index_of(pid)]), float(u_y[index_of(pid)]))
                if magnitude(at - c) < best:
                    best = magnitude(at - c)
                    find_mark = at
                    find_milli = float2 { float(u_x[index_of(pid)]), float(u_y[index_of(pid)]) }
                    find_until = seen_s + 25.0
                    find_word = "Zaptiye"
    // (the first game the men can see: one of them says what it is and how it is come at)
    if (find(said): _ == "first game") < 0 and not is_night():
        let ws = float(gl.window_size())
        for(game) g:
            let i = index_of(g.id)
            if g.state != G_DEAD and i >= 0 and (find(said): _ == "first game") < 0 and men_see(i):
                // (and the player can: the words wait till the game is well inside the picture)
                let s = to_screen(gp(float(u_x[i]), float(u_y[i])))
                if s.x > ws.x * 0.08 and s.y > ws.y * 0.1 and s.x < ws.x * 0.92 and s.y < ws.y * 0.9:
                    one_says("first game", say_cfg("first_game"), 2)
                    find_mark = gp(float(u_x[i]), float(u_y[i]))
                    find_milli = float2 { float(u_x[i]), float(u_y[i]) }
                    find_until = seen_s + 10.0
                    find_word = "Right click to hunt"
    if is_night() and not camps_made() and hour_now() >= 21.5: one_says("dark {day}", say_cfg("dark"), 3)
    // (coming home: the village's smoke over the trees, said once, so the lane and the end do not come from nowhere;
    // "Arrival is abrupt", the eleventh first-time play. Claude's stand-in for Dominic's words.)
    if leg_id == "village_home" and (find(said): _ == "home seen") < 0:
        var sum_x = 0
        var men_n = 0
        for(u_x.length) i:
            if man_of(u_id[i]):
                sum_x += u_x[i]
                men_n++
        if men_n > 0 and sum_x / men_n < 30 * TILE: one_says("home seen", say_cfg("home_seen"), 4)
    // the hunt's end, said: one down (and what to do with it), or the game away ("Deer gone, no result shown ... I
    // never learnt whether we hit", the seventh first-time play)
    if game_shot < hunt_said_n: hunt_said_n = game_shot
    if game_shot > hunt_said_n:
        hunt_said_n = game_shot
        hunt_alarm = false
        hunt_away_at = -1.0
        // (and of this chase nothing more is said: "They are away" after "One down" read as the kill undone)
        hunt_asked_at = -1000.0
        said.remove_obj("game down")
        one_says("game down", say_cfg("game_down"), 2)
    // (only of game the men were sent after in the last minute: the ninth first-time play was told "They are away" ten
    // times, of herds it had not seen and while the men slept)
    elif game_alarmed_seen() and seen_s - hunt_asked_at < 60.0: hunt_alarm = true
    elif hunt_alarm:
        hunt_alarm = false
        hunt_away_at = seen_s + 6.0
    // (said six seconds after the game settles, and not at all if one falls in them: the tenth first-time play was
    // told "They are away" and then saw a deer drop to a shot already in the air)
    elif hunt_away_at > 0.0 and seen_s >= hunt_away_at:
        hunt_away_at = -1.0
        said.remove_obj("game away")
        one_says("game away", say_cfg("game_away"), 3)
    // the wary music's reason, said: wolves following, or a patrol that has noticed something (the eighth first-time
    // play heard the wary track through a whole night in the fir woods and never knew what the danger was)
    if danger_was == "wary" and danger_told != "wary":
        let wolves = (find(packs) pk: pk.state == W_FOLLOW and pack_alive(pk).length > 0) >= 0
        said.remove_obj("wary")
        one_says("wary", say_cfg(if wolves: "followed" else: "patrol_wary"), 2)
        if wolves:
            for(packs) pk:
                let alive = pack_alive(pk)
                if pk.state == W_FOLLOW and alive.length > 0:
                    find_mark = gp(float(u_x[index_of(alive[0])]), float(u_y[index_of(alive[0])]))
                    find_milli = float2 { float(u_x[index_of(alive[0])]), float(u_y[index_of(alive[0])]) }
                    find_until = seen_s + 14.0
                    find_word = "Wolves"
    danger_told = danger_was
    hide_tick()
    if near_asked:
        near_asked = false
        said.remove_obj("as near")
        one_says("as near", say_cfg("as_near"), 1)
    if rose_asked:
        rose_asked = false
        one_says("rose {day}", say_cfg(if season_now() == "summer": "rose_unripe" else: "rose_bare"), 4)
    // dusk, the first evenings, with no camp made
    if day < 3 and hour_now() >= 17.5 and hour_now() < 20.0 and not camps_made(): one_says("dusk {day}", say_cfg("dusk"), 3)
    // the bread gone; a man hungry; a man starving
    if bread_days() == 1 and clock_s > 30.0: one_says("bread low {day / 2}", say_cfg("bread_low"), 4)
    if bread_days() <= 0 and clock_s > 30.0: one_says("last bread {day / 3}", say_cfg("last_bread"), 5)
    for(men) m:
        if m.alive and index_of(m.uid) >= 0 and not is_asleep(m.uid):
            // (only with the bread gone: a man is hungry every evening before the meal, and the third agent playtest
            // was told of empty bellies beside four loaves, 2026-11-22)
            if bread_days() <= 0 and m.fed < 15000: one_says("starving {day}", say_cfg("starving"), 1)
            elif bread_days() <= 0 and m.fed < 40000:
                one_says("hungry {day}", say_cfg("hungry"), 2)
                tip_once("tip hunger", "Hungry men walk slower and weaken. Game and what grows off the path will feed them.")
    // an order that can't be followed: three seconds on, nobody has moved and they are nowhere near it
    if mark_t != order_seen:
        order_seen = mark_t
        order_ids = filter(selected) id: man_of(id) != nil and index_of(id) >= 0
        order_tick_no = tick
        order_from = float2_0
        for(order_ids) id: order_from += float2 { float(u_x[index_of(id)]), float(u_y[index_of(id)]) } / float(order_ids.length)
        if hint_stage == 1:
            hint_stage = 2
            hint_t = 0.0
    elif order_ids.length and tick > order_tick_no + 3 * TICK_HZ:
        let ids = filter(order_ids) id: index_of(id) >= 0
        var now = float2_0
        var moving = false
        for(ids) id:
            now += float2 { float(u_x[index_of(id)]), float(u_y[index_of(id)]) } / float(ids.length)
            if u_moving[index_of(id)] == 1: moving = true
        // (for the playtest's log: what state men who did not move for an order are in; thirteen stood deaf to five
        // orders until Halt, 2026-11-22, and why is not known)
        if heard_on and ids.length and not moving and magnitude(now - order_from) < 1000.0 and magnitude(mark_at - gp(now.x, now.y)) > 90.0:
            for(ids) id:
                let i = index_of(id)
                print "deaf: man {id} at {u_x[i] / TILE},{u_y[i] / TILE} to {u_tx[i] / TILE},{u_ty[i] / TILE} stuck {u_stuck[i]} block {u_block[i]} group {u_group[i]} task {u_task[i]} foe {u_foe[i]} asleep {is_asleep(id)} camp {camp_of(i)} marchers {marchers.length}"
        if ids.length and not moving and magnitude(now - order_from) < 1000.0 and magnitude(mark_at - gp(now.x, now.y)) > 90.0 and not camps_made():
            said.remove_obj("no way")
            one_says("no way", say_cfg("no_way"), 0)
        order_ids = []
    if hint_stage == 0 and chosen_men().length > 1: hint_stage = 1
    // Tab, or a click on the men's mark: the view goes to them
    if gl.button("tab") == 1: cam = men_centre()
    if not men_in_view() and gl.button("mouse1") == 1 and magnitude(mouse_px() - men_mark()) < float(gl.window_size().y) * 0.05: cam = men_centre()

def shaded_text(t:string, at:float2, a:float):
    for([ 1.0, 0.0 ]) shade:
        gl.color(if shade > 0.0: float4 { 0.0, 0.0, 0.0, 0.7 * a } else: float4 { 0.97, 0.93, 0.82, a }):
            gl.translate(floor(at + float2 { shade, shade })): gl.text(t)

// How long the end's words take to come up (draw_lines' own pace).
def end_read_s() -> float: return 0.6 + float(tally_lines().length) * 1.4 + 1.2

// The morning after the men come home (D-197): what the village makes of what they brought, a line at a time at the
// foot of the picture, over the village in clear morning light, on a band of shade so the words read over grass and
// leaves alike. When the last has been read the picture darkens and the game's name stands over it: the end (the
// eleventh first-time play sat at the last line with no sign the game was over).
let AFTER_EACH = 7.0

// How long into the morning after its last words have been read.
def after_fin(t:float) -> float: return t - 3.0 - float(after_lines().length) * AFTER_EACH - 3.0

def draw_after(t:float):
    let texts = after_lines()
    if t < 0.0 or not texts.length: return
    let n = min(int(t / AFTER_EACH), texts.length - 1)
    let u = t - float(n) * AFTER_EACH
    let fin = after_fin(t + 3.0)
    let a = if n == texts.length - 1: clamp(min(u / 1.2, 1.0 - fin / 2.0), 0.0, 1.0) else: clamp(min(u / 1.2, (AFTER_EACH - u) / 1.2), 0.0, 1.0)
    let ws = float(gl.window_size())
    gl.set_shader("color")
    gl.set_font_name(FONT)
    gl.set_font_size(int(ws.y / 28.0))
    let w = float(gl.text_size(texts[n]))
    let at = float2 { floor(ws.x / 2.0 - w.x / 2.0), floor(ws.y * 0.8) }
    for(6) k:
        let grow = float(k) * w.y * 0.16
        gl.color(float4 { 0.02, 0.02, 0.015, 0.11 * a }): gl.translate(float2 { 0.0, at.y - w.y * 0.35 - grow }): gl.rect(float2 { ws.x, w.y * 1.7 + grow * 2.0 })
    shaded_text(texts[n], at, a)
    if fin > 0.0:
        let fa = clamp(fin / 3.0, 0.0, 1.0)
        veil(fa * 0.55)
        draw_title(fa, 0.0)
        if fin > 5.0 and not has_s(args, "web"):
            gl.set_shader("color")
            gl.set_font_name(FONT)
            gl.set_font_size(int(ws.y / 36.0))
            let leave = "Click to leave"
            shaded_text(leave, float2 { floor(ws.x / 2.0 - float(gl.text_size(leave).x) / 2.0), floor(ws.y * 0.9) }, clamp((fin - 5.0) / 2.0, 0.0, 0.8))

// The packs, open (D-186. Dominic, 2026-11-24: "we need to design a pack looking UI, not a plane box"): a torba, the
// woven wool shoulder bag of the Rhodopes, drawn in the signs' own hand with its flap thrown back and its strap over
// the top, striped red and black at mouth and foot. What the men carry between them lies on its cloth, a small
// picture and a few words for each kind: the bread, the goods for home, and what they have learned.
// One picture of what is in a pack, on a square 10 art px wide at (x, y), k screen px to the art px:
// 0 a loaf, 1 a bundle of herbs, 2 a cake of wax, 3 a rolled hide, 4 wool, 5 the Romans' drain (an arch of stone).
def draw_pack_thing(what:int, x:float, y:float, k:float):
    def px(dx:float, dy:float, w:float, h:float, c:float4):
        gl.color(c): gl.translate(float2 { x + dx * k, y + dy * k }): gl.rect(float2 { w * k, h * k })
    let dark = float4 { 0.16, 0.11, 0.07, 1.0 }
    if what == 0: draw_loaf(x + k, y + 2.0 * k, k, false)
    elif what == 1:
        // (stalks tied at the middle, leaves above, a pale flower or two)
        let stalk = float4 { 0.36, 0.42, 0.2, 1.0 }
        let leaf = float4 { 0.5, 0.58, 0.28, 1.0 }
        px(4.0, 3.0, 2.0, 5.0, stalk)
        px(2.0, 0.0, 6.0, 3.0, leaf)
        px(1.0, 1.0, 8.0, 1.0, leaf)
        px(3.0, 0.0, 1.0, 1.0, float4 { 0.9, 0.86, 0.5, 1.0 })
        px(6.0, 1.0, 1.0, 1.0, float4 { 0.9, 0.86, 0.5, 1.0 })
        px(3.0, 4.0, 4.0, 1.0, float4 { 0.72, 0.6, 0.4, 1.0 })
        px(3.0, 7.0, 1.0, 1.0, stalk)
        px(6.0, 7.0, 1.0, 1.0, stalk)
    elif what == 2:
        // (a round cake of wax, pale yellow, its rim darker)
        px(2.0, 2.0, 6.0, 5.0, float4 { 0.62, 0.48, 0.16, 1.0 })
        px(1.0, 3.0, 8.0, 3.0, float4 { 0.62, 0.48, 0.16, 1.0 })
        px(2.0, 2.0, 6.0, 3.0, float4 { 0.9, 0.76, 0.34, 1.0 })
        px(3.0, 2.0, 3.0, 1.0, float4 { 0.98, 0.9, 0.56, 1.0 })
    elif what == 3:
        // (a hide rolled and tied, the fur's edge pale at one end)
        px(1.0, 2.0, 8.0, 5.0, float4 { 0.42, 0.27, 0.15, 1.0 })
        px(1.0, 2.0, 8.0, 1.0, float4 { 0.56, 0.38, 0.22, 1.0 })
        px(8.0, 2.0, 1.0, 5.0, float4 { 0.8, 0.7, 0.54, 1.0 })
        px(3.0, 2.0, 1.0, 5.0, dark)
        px(6.0, 2.0, 1.0, 5.0, dark)
    elif what == 4:
        // (a fleece: pale, lumpy)
        let wool = float4 { 0.9, 0.87, 0.78, 1.0 }
        px(2.0, 1.0, 3.0, 2.0, wool)
        px(5.0, 2.0, 3.0, 2.0, wool)
        px(1.0, 3.0, 8.0, 3.0, wool)
        px(2.0, 6.0, 6.0, 1.0, float4 { 0.68, 0.64, 0.56, 1.0 })
        px(4.0, 4.0, 1.0, 1.0, float4 { 0.68, 0.64, 0.56, 1.0 })
    else:
        // (an arch of dressed stone over dark water)
        let stone = float4 { 0.66, 0.64, 0.6, 1.0 }
        px(1.0, 1.0, 8.0, 6.0, stone)
        px(3.0, 3.0, 4.0, 4.0, dark)
        px(4.0, 2.0, 2.0, 1.0, dark)
        px(3.0, 6.0, 4.0, 1.0, float4 { 0.3, 0.42, 0.5, 1.0 })
        px(1.0, 3.0, 2.0, 1.0, float4 { 0.5, 0.48, 0.45, 1.0 })
        px(7.0, 5.0, 2.0, 1.0, float4 { 0.5, 0.48, 0.45, 1.0 })

// What is in the packs: for each row its picture and its words.
def pack_rows() -> [int], [string]:
    var food = 0
    let count = map(WARES) _: 0
    var knowers = 0
    for(men) m:
        if m.alive:
            food += m.food
            for(m.wares) w: count[w]++
            if knows_drain(m): knowers++
    let days = bread_days()
    let pics = [ 0 ]
    let words = [ if food <= 0: "No bread left" elif days < 1: "Bread for less than a day" elif days == 1: "Bread for a day" else: "Bread for {days} days" ]
    let kinds = glist(gobj(survival_cfg, "wares"), "kinds")
    // (every kind of goods has its place in the bag, empty or not: what there is to bring home is the answer to
    // "what am I collecting"; an empty place is drawn faint, its picture -(kind) - 1)
    for(count) n, w:
        if w < kinds.length:
            pics.push(if n > 0: w + 1 else: -w - 2)
            words.push(if n == 0: gstr(kinds[w], "short_none", "") elif n == 1: gstr(kinds[w], "short_one", "") else: replace_string(gstr(kinds[w], "short", "%"), "%", string(n)))
    if knowers:
        pics.push(5)
        words.push(if knowers == 1: "One man knows the Roman drain" else: "{knowers} men know the Roman drain")
    return pics, words

def draw_packs():
    if not pack_open or phase != "play" or script != "": return
    if not chosen_men().length:
        pack_open = false
        return
    let ws = float(gl.window_size())
    let pics, words = pack_rows()
    let k = floor(sign_px() * 1.5)
    gl.set_font_name("../data/fonts/OldStandard/OldStandard-Regular.ttf")
    let size = int(k * 7.5)
    gl.set_font_size(size)
    var wide = 0.0
    for(words) t: wide = max(wide, float(gl.text_size(t).x))
    let row = 14.0
    let bw = max(96.0, ceiling(wide / k) + 34.0)  // the bag's width and height, art px
    let bh = 30.0 + row * float(pics.length)
    let at = float2 { floor(ws.y * 0.05), floor(ws.y * 0.2) }
    def px(x:float, y:float, w:float, h:float, c:float4):
        gl.color(c): gl.translate(float2 { at.x + x * k, at.y + y * k }): gl.rect(float2 { w * k, h * k })
    gl.set_shader("color")
    let edge = float4 { 0.1, 0.07, 0.05, 0.9 }
    let cloth = float4 { 0.46, 0.36, 0.25, 1.0 }
    let cloth_lit = float4 { 0.55, 0.44, 0.31, 1.0 }
    let weave = float4 { 0.3, 0.22, 0.15, 0.35 }
    let red = float4 { 0.62, 0.17, 0.13, 1.0 }
    let black = float4 { 0.13, 0.1, 0.09, 1.0 }
    let cream = float4 { 0.88, 0.82, 0.68, 1.0 }
    let strap = float4 { 0.36, 0.26, 0.17, 1.0 }
    // the strap, up from the two corners and over
    px(7.0, -19.0, 6.0, 20.0, edge)
    px(bw - 13.0, -19.0, 6.0, 20.0, edge)
    px(7.0, -21.0, bw - 14.0, 6.0, edge)
    px(8.0, -18.0, 4.0, 19.0, strap)
    px(bw - 12.0, -18.0, 4.0, 19.0, strap)
    px(8.0, -20.0, bw - 16.0, 4.0, strap)
    px(8.0, -20.0, bw - 16.0, 1.0, cloth_lit)
    // the flap, thrown back above the mouth: its paler inside, a stripe along its edge
    px(3.0, -11.0, bw - 6.0, 12.0, edge)
    px(4.0, -10.0, bw - 8.0, 10.0, cloth_lit)
    px(4.0, -10.0, bw - 8.0, 2.0, red)
    px(4.0, -8.0, bw - 8.0, 1.0, black)
    // the bag: its corners taken off, the weave across it
    px(1.0, -1.0, bw - 2.0, bh + 2.0, edge)
    px(-1.0, 1.0, bw + 2.0, bh - 2.0, edge)
    px(1.0, 0.0, bw - 2.0, bh, cloth)
    px(0.0, 1.0, bw, bh - 2.0, cloth)
    for(int(bh / 2.0) - 1) n: px(1.0, float(n) * 2.0 + 2.0, bw - 2.0, 1.0, weave)
    // the stripes at its mouth and its foot: red, black, cream, as the bags are woven
    for([ 3.0, bh - 11.0 ]) y:
        px(0.0, y, bw, 3.0, red)
        px(0.0, y + 3.0, bw, 1.0, black)
        px(0.0, y + 4.0, bw, 1.0, cream)
        px(0.0, y + 5.0, bw, 1.0, black)
        px(0.0, y + 6.0, bw, 2.0, red)
        for(int(bw / 6.0)) n: px(float(n) * 6.0 + 2.0, y + 4.0, 2.0, 1.0, red)
    // tassels at the foot's corners
    for([ 3.0, bw - 6.0 ]) x:
        px(x - 1.0, bh, 5.0, 7.0, edge)
        px(x, bh, 3.0, 2.0, black)
        px(x, bh + 2.0, 3.0, 4.0, red)
    // a cloth laid in it, and the things on the cloth
    px(7.0, 13.0, bw - 14.0, row * float(pics.length) + 3.0, float4 { 0.2, 0.14, 0.1, 0.55 })
    px(6.0, 12.0, bw - 12.0, row * float(pics.length) + 3.0, float4 { 0.84, 0.79, 0.66, 1.0 })
    px(6.0, 12.0, bw - 12.0, 1.0, float4 { 0.94, 0.9, 0.8, 1.0 })
    for(pics) what, n:
        let y = 15.0 + row * float(n)
        if n > 0: px(9.0, y - 2.0, bw - 18.0, 1.0, float4 { 0.6, 0.54, 0.42, 0.6 })
        draw_pack_thing(if what < 0: -what - 1 else: what, at.x + 10.0 * k, at.y + (y + 1.0) * k, k)
        if what < 0: px(9.0, y, 12.0, 10.0, float4 { 0.84, 0.79, 0.66, 0.72 })
        gl.color(float4 { 0.17, 0.12, 0.08, if what < 0: 0.45 else: 1.0 }):
            gl.translate(float2 { at.x + 24.0 * k, at.y + (y + 5.0) * k - float(size) * 0.62 }): gl.text(words[n])
    // (and under the bag, how the packs are hidden)
    gl.set_font_size(int(ws.y / 44.0))
    shaded_text("Right click an old tree to hide the packs at its foot.", float2 { at.x, at.y + (bh + 11.0) * k }, 0.8)

def draw_guide(dt:float):
    if phase != "play" or script != "" or shot != "": return
    let ws = float(gl.window_size())
    gl.set_shader("color")
    gl.set_font_name("../data/fonts/OldStandard/OldStandard-Regular.ttf")
    if paused:
        veil(0.3)
        gl.set_shader("color")
        gl.set_font_size(int(ws.y / 22.0))
        let w = float(gl.text_size("Paused").x)
        shaded_text("Paused", float2 { ws.x / 2.0 - w / 2.0, ws.y * 0.4 }, 0.95)
    if hint_stage == 2 and hint_t > 9.0: hint_stage = 3
    if hint_stage < 3 and menu_alpha <= 0.0:
        hint_t += dt
        gl.set_font_size(int(ws.y / 40.0))
        let l = if hint_stage == 0: "Drag across the men to choose them" elif hint_stage == 1: "Right click to send them" else: "Tab brings the view back to the men"
        let w = float(gl.text_size(l).x)
        shaded_text(l, float2 { ws.x / 2.0 - w / 2.0, ws.y * 0.9 }, clamp(hint_t - 1.0, 0.0, 1.0) * 0.8)
    if hint_stage >= 3 and seen_s < tip_until:
        gl.set_font_size(int(ws.y / 40.0))
        let w = float(gl.text_size(tip).x)
        shaded_text(tip, float2 { ws.x / 2.0 - w / 2.0, ws.y * 0.9 }, clamp(min(seen_s - (tip_until - 12.0), tip_until - seen_s), 0.0, 1.0) * 0.85)
    if seen_s < way_until:
        // (the way on: a pale ring at the gate out, or at the screen's edge toward it, and two words)
        let g, has_gate = way_on()
        if has_gate:
            let d = g - ws / 2.0
            let pad = ws.y * 0.07
            let k = min((ws.x / 2.0 - pad) / max(abs(d.x), 1.0), (ws.y / 2.0 - pad) / max(abs(d.y), 1.0))
            let p = ws / 2.0 + d * min(k, 1.0)
            let a = clamp(way_until - seen_s, 0.0, 1.0)
            let r = ws.y * 0.02
            for(12) j:
                let a0 = 30.0 * float(j)
                gl.color(float4 { 0.95, 0.91, 0.79, 0.85 * a }):
                    gl.line(p + float2 { cos(a0), sin(a0) } * r, p + float2 { cos(a0 + 30.0), sin(a0 + 30.0) } * r, 2.0)
            gl.set_font_size(int(ws.y / 46.0))
            let w = float(gl.text_size("The way on").x)
            shaded_text("The way on", float2 { clamp(p.x - w / 2.0, 4.0, ws.x - w - 4.0), p.y + (if p.y > ws.y * 0.8: -r * 3.0 else: r * 1.4) }, a)
            gl.set_shader("color")
    if seen_s < find_until:
        // (what was called out: a smaller ring on it, warm in colour, its word under it)
        let g = to_screen(find_mark)
        let d = g - ws / 2.0
        let pad = ws.y * 0.06
        let k = min((ws.x / 2.0 - pad) / max(abs(d.x), 1.0), (ws.y / 2.0 - pad) / max(abs(d.y), 1.0))
        // (not down among the foot's line of words)
        let p1 = ws / 2.0 + d * min(k, 1.0)
        let p = float2 { p1.x, min(p1.y, ws.y * 0.8) }
        let a = clamp(find_until - seen_s, 0.0, 1.0)
        let r = ws.y * 0.014 * (1.0 + 0.12 * sin(seen_s * 220.0))
        for(12) j:
            let a0 = 30.0 * float(j)
            gl.color(float4 { 0.98, 0.82, 0.5, 0.9 * a }):
                gl.line(p + float2 { cos(a0), sin(a0) } * r, p + float2 { cos(a0 + 30.0), sin(a0 + 30.0) } * r, 2.0)
        gl.set_font_size(int(ws.y / 50.0))
        let w = float(gl.text_size(find_word).x)
        shaded_text(find_word, float2 { clamp(p.x - w / 2.0, 4.0, ws.x - w - 4.0), p.y + (if p.y > ws.y * 0.8: -r * 3.4 else: r * 1.6) }, a * 0.9)
        gl.set_shader("color")
    if not men_in_view():
        // (a small pale ring with a dot, where the signs' hand would be: the men are that way; a click on it goes there)
        let p = men_mark()
        let near = magnitude(mouse_px() - p) < ws.y * 0.05
        let r = ws.y * 0.016
        for(12) k:
            let a0 = 30.0 * float(k)
            let a1 = a0 + 30.0
            gl.color(float4 { 0.95, 0.91, 0.79, if near: 1.0 else: 0.75 }):
                gl.line(p + float2 { cos(a0), sin(a0) } * r, p + float2 { cos(a1), sin(a1) } * r, 2.0)
        gl.color(float4 { 0.95, 0.91, 0.79, 0.9 }): gl.translate(floor(p - float2 { 2.0, 2.0 })): gl.rect(float2 { 4.0, 4.0 })
        if near:
            gl.set_font_size(int(ws.y / 46.0))
            let w = float(gl.text_size("The men").x)
            shaded_text("The men", float2 { clamp(p.x - w / 2.0, 4.0, ws.x - w - 4.0), p.y + (if p.y > ws.y * 0.8: -r * 3.2 else: r * 1.4) }, 1.0)

// ------------------------------------------------------------------ the forest's sound, from what is on the screen
// (smyana/ambience.lobster, D-147)
var amb_water = 0.0  // how near water is to the middle of the view, 0..1 (looked for twice a second)
var amb_look = 0.0
var amb_fires = 0
var amb_piles = 0
var amb_mark = -10.0
var work_wait = 0.0  // seconds till the next sound of hands gathering or a knife cutting

def ambience_tick(dt:float):
    let fc = forest_cfg()
    let season = season_now()
    let kind, hard = weather_now()
    let night = is_night()
    let h = hour_now()
    // (with a gap between starting and stopping: at one line the birds and the rain swapped every few seconds as a
    // shower came on, the sixth first-time play, 2026-11-24)
    rain_heard = kind == "rain" and hard > (if rain_heard: 100 else: 220)
    let raining = rain_heard
    // the wind: a little always, more as it blows, more over snow and bare boughs
    bed_want(BED_WIND, 0.3 + float(wind_now()) / 1000.0 * 0.7 + (if season == "winter": 0.2 else: 0.0))
    // small birds: by day, a chorus at first light, quiet by dusk; most in spring, few in winter, none in hard rain
    let by_season = if season == "spring": 1.0 elif season == "summer": 0.8 elif season == "autumn": 0.4 else: 0.12
    let by_hour = if night: 0.0 elif h < 8.0: 1.0 elif h < 17.0: 0.7 elif h < 20.0: 0.45 else: 0.15
    bed_want(BED_BIRDS, by_season * by_hour * (if raining: 0.15 elif kind == "snow": 0.3 else: 1.0))
    // crickets: warm nights and evenings
    let warm = if season == "summer": 1.0 elif season == "autumn" and year_here() % 4000 < 1500: 0.5 else: 0.0
    bed_want(BED_NIGHT, if raining: 0.0 elif night: warm elif h >= 19.0: warm * 0.6 else: 0.0)
    // (rain is heard from where it can be seen: a spell's first drops are too few to draw, and two agent playtests
    // had a minute of rain's sound over a dry picture)
    bed_want(BED_RAIN, if kind == "rain": clamp(float(hard - 120) / 600.0, 0.0, 1.0) else: 0.0)
    // the stream: water or a ford near the middle of the view (frozen quiet in deep winter)
    amb_look -= dt
    if amb_look <= 0.0:
        amb_look = 0.5
        let reach = gint(fc, "stream_tiles", 12)
        let t = iso_inv(cam) / 1000.0
        let water = str_index(tr_names, "water")
        let ford = str_index(tr_names, "ford")
        var best = 1000.0
        for(reach * 2 + 1) dy:
            for(reach * 2 + 1) dx:
                let x = int(t.x) + dx - reach
                let y = int(t.y) + dy - reach
                if x >= 0 and y >= 0 and x < W and y < H and (terrain[y * W + x] == water or terrain[y * W + x] == ford):
                    best = min(best, magnitude(float2 { float(x) + 0.5 - t.x, float(y) + 0.5 - t.y }))
        amb_water = clamp(1.0 - (best - 2.0) / float(reach - 2), 0.0, 1.0)
    bed_want(BED_STREAM, amb_water * (if season == "winter" and snow_lying() > 600: 0.35 else: 1.0))
    // the fire: a lit one near the middle of the view
    var fire = 0.0
    for(fires) fp: fire = max(fire, clamp(1.0 - magnitude(iso_inv(cam - fp)) / 1000.0 / float(gint(fc, "fire_tiles", 10)), 0.0, 1.0))
    bed_want(BED_FIRE, fire)
    // the men (D-148): their feet, as loud as how many walk in view; their work, where one is at it in view
    let ws = float(gl.window_size())
    var walking = 0
    var wading = 0
    var gathering = false
    var cutting = false
    let ford = str_index(tr_names, "ford")
    for(u_x.length) i:
        if man_of(u_id[i]):
            let sp = to_screen(gp(float(u_x[i]), float(u_y[i])))
            if sp.x > 0.0 and sp.y > 0.0 and sp.x < ws.x and sp.y < ws.y:
                if u_moving[i] == 1 and not paused:
                    if terrain[cell_of(u_x[i], u_y[i])] == ford: wading++
                    else: walking++
                elif foraging(u_id[i]): gathering = true
                elif butchering(u_id[i]): cutting = true
    let tread = min(1.0, sqrt(float(walking) / float(max(1, gint(fc, "steps_men", 8)))))
    let snow = snow_lying() > 300
    bed_want(BED_STEPS, if snow: 0.0 else: tread)
    bed_want(BED_SNOW, if snow: tread else: 0.0)
    bed_want(BED_WADE, min(1.0, sqrt(float(wading) / 4.0)))
    if not paused and phase == "play":
        // (hands at work are heard every second or two, not every frame: the fifth agent playtest's log had 66
        // gather sounds in six seconds, 2026-11-23)
        work_wait -= dt
        if work_wait <= 0.0 and (gathering or cutting):
            hear(if cutting: "knife" else: "gather", -2.0, 0.0)
            work_wait = 1.2 + float(cell_hash(frame_no * 3 + 5) % 100) / 100.0
        // (a fire catching, a pile of packs set down, an order given: each once as it happens)
        if fires.length > amb_fires: hear("fire_light", 0.0, 0.0)
        if piles.length > amb_piles: hear("pack_down", 0.0, 0.0)
        // (not at every order: "I heard it about sixty times", the sixth first-time play, 2026-11-24)
        if mark_t != amb_mark and chosen_men().length > 0 and seen_s - amb_ack_s > 8.0:
            hear("ack", 0.0, 0.0)
            amb_ack_s = seen_s
    amb_fires = fires.length
    amb_piles = piles.length
    amb_mark = mark_t
    beds_tick(dt)
    if not paused: calls_tick(dt, season, night or h >= 19.5 or h < 5.5, raining, float(cell_hash(frame_no * 7 + 13) % 1000) / 1000.0)

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
    if prebake: break
    let dt = min(gl.delta_time(), 0.1)
    frame_no++
    seen_s += dt
    phase_t += dt
    if zoom_fixed <= 0.0: zoom = zoom_of(zoom_step)  // (the window may have changed size)
    if phase == "menu":
        menu_mill(dt)
        menu_camera(dt)
        let go = (menu_hover == 0 and gl.button("mouse1") == 1) or gl.button("return") == 1 or gl.button("space") == 1
        if menu_hover == 1 and gl.button("mouse1") == 1: break
        if go and phase_t > 0.5:
            // (the men stop where they are: the run is theirs now)
            for(u_id) id, i: send_men([ id ], u_x[i], u_y[i])
            set_phase("play")
    elif gl.button("space") == 1: paused = not paused
    if phase == "menu" or phase == "play" or phase == "arriving" or phase == "leaving" or phase == "home" or phase == "after":
        if phase == "play":
            guide_tick()
            select_tick()
            order_tick()
        // (not at the homecoming or after it: the view goes up the lane by itself, past where the rim keeps it)
        if phase != "menu" and phase != "home" and phase != "after": camera_tick(phase == "play" and script != "tour")
        // (once every man sleeps the whole world runs faster till one wakes or the day comes, D-150: a first-time
        // player sat through two minutes of dark at each camp with nothing to do, 2026-11-22. The first try ran only
        // the clock faster, and the test bot's men starved: the game and the wood's food come back by the tick.)
        let rush = if phase == "play" and script == "" and is_night() and all_asleep(): float(gint(gobj(route, "night"), "asleep_speed", 100)) / 100.0 else: 1.0
        if not paused: acc = min(acc + dt * fast * rush, 0.5 * fast * rush)
        while acc >= 0.05:
            p_id = copy(u_id)
            p_x = copy(u_x)
            p_y = copy(u_y)
            march_tick()
            step()
            let fired = guns_after_step()
            for(fired) id:
                let i = index_of(id)
                let j = if i >= 0: index_of(u_foe[i]) else: -1
                if i >= 0: gunfire_shot(id, gp(float(u_x[i]), float(u_y[i])), if j >= 0: gp(float(u_x[j]), float(u_y[j])) else: gp(float(u_x[i] + 1000), float(u_y[i])))
            // (the patrols hear the shots and think; where each ball landed, and Creel's own misses, a shot whose
            // target had moved off the spot)
            threats_after_step(fired)
            // (a camp shot into: the men are up at the first shot (survival_heard_shot); one of them says so, a
            // ring goes on whoever fired, the men are chosen and they fire back. The tenth first-time play's camp
            // was shot at for a minute and nobody stirred, 2026-11-24)
            if script == "" and phase == "play" and camps_made() and seen_s - camp_shot_at > 45.0:
                for(fired) id:
                    let i = index_of(id)
                    if i >= 0 and not man_of(id) and man_of(u_foe[i]) and seen_s - camp_shot_at > 45.0:
                        camp_shot_at = seen_s
                        said.remove_obj("camp shot")
                        one_says("camp shot", say_cfg("camp_shot"), 0)
                        find_mark = gp(float(u_x[i]), float(u_y[i]))
                        find_milli = float2 { float(u_x[i]), float(u_y[i]) }
                        find_until = seen_s + 20.0
                        find_word = "Zaptiye"
                        selected = filter(u_id) mid: man_of(mid) != nil
                        guns_order(selected, id)
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
            // (every man dead: the run ends where they fell, 2026-11-12: a playthrough found it running on forever)
            if phase == "play" and men_alive() == 0:
                set_phase("end")
                break
            if edge != "" and phase == "play":
                leave_edge = edge
                set_phase("leaving")
                score_leave()
                selected = []
        gunfire_tick(if paused: 0.0 else: dt, cam, float(gl.window_size().x) * 0.5 / zoom)
        mood_tick()
        // (the menu has its own track, a loop, which fades as the game is started: until 2026-11-23 it was never
        // played and the summer day's tune began over the title, the fourth agent playtest found)
        let menu_track = gstr(gobj(score_cfg, "moments"), "menu", "-")
        if phase == "menu" and music_arg == "":
            if score_track == "": score_moment("menu")
        elif phase != "leaving":
            if score_track == menu_track and music_arg == "":
                score_stop(2.0)
                score_wait = as_float(at(score_cfg, "first_wait_s"))
            // (no calm track is begun in the last minute and a half before the light turns: it would be cut)
            var turn_h = 99.0
            for([ "dawn", "day", "dusk", "night" ]) name:
                let ahead = mood_hour(name) - hour_now()
                turn_h = min(turn_h, if ahead > 0.0: ahead else: ahead + 24.0)
            score_hold = turn_h * float(ticks_per_hour()) / float(TICK_HZ) / (if is_night(): float(gint(gobj(route, "night"), "speed", 100)) / 100.0 else: 1.0) < 45.0
            // (home, and the morning after: when the homecoming's music is over the ending's follows, once, and then
            // nothing: no track of the forest's begins over the village)
            if phase == "home" or phase == "after":
                if score_track == "" and not ending_played:
                    ending_played = true
                    score_moment("ending")
                score_wait = 9999.0
            score_tick(dt, season_now(), mood_now(), fires.length > 0)
        danger_tick()
        if phase == "leaving": beds_hush()
        if phase != "menu" or menu_alpha > 0.0: ambience_tick(dt)
        heard_tick()
        if not paused: howl_tick(dt)
        if debug_line: score_keys()
        ground_season_tick()
    if phase == "home":
        cam += (men_centre() - cam) * min(1.0, dt * 0.9)
        if phase_t >= 14.0: set_phase("end")
    // (the end's words read, or clicked past: the morning after, D-197)
    if phase == "end" and script == "" and men_alive() > 0 and (phase_t > end_read_s() + 5.0 or (phase_t > 3.0 and (gl.button("mouse1") == 1 or gl.button("space") == 1 or gl.button("return") == 1))):
        hour_force = 8.5
        weather_force = "clear"
        // (by the morning the men are indoors: stood on the lane with their rifles still on their shoulders they made
        // the morning a still of the evening, the eleventh first-time play. Behind the dark between the two.)
        for(u_id) id, i:
            if man_of(id):
                u_x[i] = (W - 4) * TILE
                u_y[i] = 4 * TILE + (i % 8) * TILE
                send_men([ id ], u_x[i], u_y[i])
        set_phase("after")
    if phase == "after":
        cam += (gp(9000.0, 51500.0) - cam) * min(1.0, dt * 0.1)
        // (the game's name is up: a click or a key and the game closes)
        if after_fin(phase_t) > 5.0 and not has_s(args, "web") and (gl.button("mouse1") == 1 or gl.button("space") == 1 or gl.button("return") == 1 or gl.button("escape") == 1): break
    if phase == "arriving" and phase_t >= 1.5:
        set_phase("play")
        // (the men come into a new place still chosen, once the player has learned to choose them: the eighth and ninth
        // first-time plays called dragging the box again at every arrival busywork)
        if hint_stage >= 2 and script == "": selected = filter(u_id) id: man_of(id) != nil
    if phase == "leaving" and phase_t >= 1.5:
        let last = gbool(gobj(gobj(route, "legs"), gstr(exit_by(leave_edge), "to", "")), "end", false)
        route_leave(leave_edge)
        if last:
            // (the last walk, down the lane into the village: no letter and nothing to load. The village edge stays
            // as it is behind the end's words, D-168)
            score_moment("homecoming")
            if script != "": set_phase("end")
            else:
                // (the men walk on up the lane between the yard walls, the view going with them, before the end's
                // words: D-197)
                set_phase("home")
                selected = []
                var n = 0
                for(u_id) id:
                    if man_of(id):
                        send_men([ id ], (3 + n % 9) * TILE + 300 + (n * 137) % 400, (50 + (n / 9) % 2) * TILE + 300 + (n * 251) % 400)
                        n++
        else:
            letter = gstrs(gobj(route, "letters"), gstr(exit_by(leave_edge), "letter", ""))
            letter_loaded = false
            walk_line = walk_words(gint(exit_by(leave_edge), "hours", 0), hour_now() + float(gint(exit_by(leave_edge), "hours", 0)))
            set_phase("letter")
    if phase == "letter":
        if not letter_loaded and phase_t > 0.3:  // (the letter is on the screen first: the load stops the picture for its length)
            load_next()
            letter_loaded = true
        // (no letter on the last walk, down the lane into the village: straight on to the end)
        // (Dominic, 2026-11-13: "how come loading next map is slower than game start?": the place loads in about a
        // second; it was the letter that held the screen, twenty seconds. Now it is up as long as it takes to read,
        // and a click or a key goes on as soon as the place is ready)
        let reading = 2.5 + float(letter.length) * 1.4 + float(sum(map(letter) l: l.length)) / 30.0
        let hold = if not letter.length: 0.5 elif script == "tour": 6.0 elif arg_of("letter") != "": string_to_float(arg_of("letter")) elif script == "play": 1.0 else: min(reading, float(gint(route, "letter_seconds", 20)))
        let skip = letter_loaded and phase_t > 0.6 and (gl.button("mouse1") == 1 or gl.button("space") == 1 or gl.button("return") == 1)
        if letter_loaded and (phase_t >= hold or skip):
            paused = false
            set_phase(if run_over(): "end" else: "arriving")
            if run_over(): score_moment("homecoming")
    // the cursor: an axe over a young tree the chosen men would fell, the pointer with an order's ring where they would
    // walk, else the pointer
    let ws = float(gl.window_size())
    let mp = mouse_px()
    let in_window = mp.x >= 0.0 and mp.y >= 0.0 and mp.x < ws.x and mp.y < ws.y
    cursor_show(if phase != "play" or not selected.length or not in_window: CURSOR_POINT else: hover_cursor())
    if drawing():
        gl.clear(float4 { 0.035, 0.055, 0.04, 1.0 })
        gl.blend(1)
        if phase == "letter":
            draw_lines(letter, phase_t, int(float(gl.window_size().y) / 34.0))
            draw_walk_words(walk_line, phase_t)
            if letter_loaded and phase_t > 1.5: draw_go_on(phase_t - 1.5)
        elif phase == "end":
            // (home: the words over the village edge, the view going slowly up the lane to the houses, D-168. With
            // nobody left the words stand on the dark, where the last man fell.)
            if men_alive() > 0 and gstr(su_map, "id", "") == "village_edge":
                cam += (gp(8500.0, 50500.0) - cam) * min(1.0, dt * 0.2)
                draw_world(acc / 0.05)
                veil(1.0 - clamp(phase_t / 3.0, 0.0, 1.0) * 0.5)
            draw_lines(tally_lines(), phase_t, int(float(gl.window_size().y) / 30.0))
        elif phase == "after":
            draw_world(acc / 0.05)
            veil(1.0 - clamp(phase_t / 3.0, 0.0, 1.0))
            draw_after(phase_t - 3.0)
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
        if phase == "play":
            if arg_of("chosen") == "all" and shot != "":  // (for a picture: chosen, and in view)
                selected = filter(u_id) id: man_of(id) != nil
                var sum = float2_0
                for(selected) id: sum += gp(float(u_x[index_of(id)]), float(u_y[index_of(id)]))
                if selected.length: cam = sum / float(selected.length)
            draw_one_man()
            draw_signs()
            draw_speech()
            if not dragging and sign_under() < 0: draw_hover()
            draw_guide(dt)
            draw_packs()
        if debug_line:
            gl.set_shader("color")
            gl.set_font_name(FONT)
            gl.set_font_size(16)
            gl.color(float4 { 1.0, 1.0, 1.0, 0.8 }):
                gl.translate(float2 { 10.0, 8.0 }): gl.text("{leg_id}  {season_now()} {year_here()}  {int(hour_now())}h  {atmo_mood}  men {men_alive()}  {int(1.0 / max(dt, 0.001))} fps  {phase}")
    if shot != "" and not shot_taken and (clock_s >= shot_at or (phase == "end" and phase_t > (if script == "play": 1.8 else: 5.0))) and (arg_of("in") == "" or (arg_of("in") == phase and (phase != "letter" or phase_t >= 5.0)) or arg_of("in") == leg_id):
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
    if script == "play":
        play_frames++
        if dt > 0.02: play_slow++
    if play_stuck: break
    if script == "play" and phase == "end" and phase_t > 2.0:
        print "play: the end at {int(clock_s)} s of game time, men {men_alive()}, {play_fights} fights, {play_frames} frames, {play_slow} slower than 50 fps"
        print "play: food: {play_hunts} hunts, {game_shot} game shot, {meat_taken} portions of meat, {food_gathered} gathered"
        for(tally_lines()) l: print "play: tally: {l}"
        break
    if script == "tour" and phase == "end" and phase_t > 6.0: break
