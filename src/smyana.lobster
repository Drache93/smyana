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

// ------------------------------------------------------------------ what it was started with

let args = command_line_arguments()
def arg_of(key:string) -> string:
    for(args) a: if starts_with(a, key + ":"): return substring(a, key.length + 1, -1)
    return ""
let shot = arg_of("shot")
let shot_at = if arg_of("at") != "": string_to_float(arg_of("at")) else: 4.0
let script = arg_of("script")  // "tour": the men walk the whole route by themselves (captures, and timing the loads)
let debug_line = has_s(args, "debug")
season_force = arg_of("season")  // season:autumn: this place in another season, for a look
let shots_dir = arg_of("shots")  // a picture every few seconds into this folder (with script:tour)
var shots_n = 0
var shots_next = 3.0
var wall_s = 0.0
let capture = shot != "" or script != "" or arg_of("shots") != ""

// ------------------------------------------------------------------ the camera (art px: a tile is 96 x 48)

var cam = float2_0  // art px at the middle of the window
var zoom = 1.5      // screen px an art px

def to_screen(p:float2) -> float2: return (p - cam) * zoom + float(gl.window_size()) / 2.0
def from_screen(p:float2) -> float2: return (p - float(gl.window_size()) / 2.0) / zoom + cam
def mouse_milli() -> float2: return iso_inv(from_screen(mouse_px()))

// Where the men are, taken together (art px).
def men_centre() -> float2:
    var sum = float2_0
    for(u_x.length) i: sum += iso(float(u_x[i]), float(u_y[i]))
    return if u_x.length: sum / float(u_x.length) else: cam

// ------------------------------------------------------------------ what the view remembers of a place

class Prop:
    kind:int  // 0 an old tree, 1 a young tree, 2 a stump, 3 a rock outcrop, 4 loose slabs, 5 undergrowth (its leaves by season), 6 a fallen log
    pick:int  // which of its shapes
    name:string  // its picture (an old tree's trunk; a young beech's without its season)
    sp:string  // an old tree's kind: beech, pine, spruce
    at:float2  // its foot, art px
    cell:int

var props = []::Prop
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
    if wood == "deep": sp = if r < 6: "tall" elif r < 7: "beech" else: "hornbeam"
    if wood == "conifer": sp = if r < 5: "spruce" elif r < 7: "pine" else: "beech"
    return sp, pick % (if sp == "pine": PINE_KINDS else: 3)

def leafy(sp:string) -> bool: return sp == "beech" or sp == "oak" or sp == "hornbeam"

def build_props():
    props = []
    props_version = map_version
    let wood = gstr(su_map, "wood", "beech")
    let old = str_index(tr_names, "tree")
    let young = str_index(tr_names, "young_tree")
    let stump = str_index(tr_names, "stump")
    let rock = str_index(tr_names, "rock")
    let grass = str_index(tr_names, "grass")
    for(terrain) t, c:
        let h = cell_hash(c)
        let centre = iso(float((c % W) * 1000 + 500), float((c / W) * 1000 + 500))
        // (not dead centre: a wood isn't planted in rows)
        let off = iso(float((c % W) * 1000 + 500 + (h % 400) - 200), float((c / W) * 1000 + 500 + ((h / 400) % 400) - 200))
        if t == old:
            let sp, k = old_kind(wood, h / 7)
            props.push(Prop { 0, k, "{sp}{k}", sp, off, c })
        elif t == young:
            let fir = wood != "beech" and (h / 7) % 4 != 0
            props.push(Prop { 1, h / 7, if fir: "yspruce{(h / 7) % YOUNG_KINDS}" else: "young{(h / 7) % YOUNG_KINDS}", if fir: "spruce" else: "beech", centre, c })
        elif t == stump: props.push(Prop { 2, 0, "stump", "", centre, c })
        elif t == rock: props.push(Prop { 3, 0, "rock{(h / 7) % ROCK_KINDS}", "", off, c })
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
            if (h2 / 100) % 100 >= 90 and (h2 / 100) % 100 < 94: props.push(Prop { 5, 0, "sapling", "", centre, c })
            if (h2 / 100) % 100 < 6: props.push(Prop { 5, 0, "bush{h2 % BUSH_KINDS}", "", centre + iso(float((h2 / 13) % 600) - 300.0, float((h2 / 19) % 600) - 300.0), c })
            elif (h2 / 100) % 100 == 99: props.push(Prop { 6, 0, "log{h2 % LOG_KINDS}", "", centre, c })

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
            let reach = (if pr.kind == 0: (if leafy(pr.sp): LITTER_REACH else: 1.0) else: 0.6) * (if season_now() == "autumn" and leafy(pr.sp): 1.9 else: 1.0) * (0.8 + 0.4 * float(cell_hash(pr.cell) % 100) / 100.0)
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
            let patch = float(cell_hash((y / 3) * w + x / 3 + 5003) % 100) / 100.0
            a[y * w + x] = max(a[y * w + x], 0.42 + 0.3 * patch)
    prop_tex = gl.create_texture(map(h) y: map(w) x: float4 { a[y * w + x], 0.0, 0.0, 0.0 }, texture_format_clamp | texture_format_nomipmap)
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
    ground_atlas_tex = gl.load_texture("../data/ground/atlas" + (if gstr(su_map, "wood", "beech") != "beech": "_conifer" else: "") + (if season_now() == "autumn": "_autumn" else: "") + ".png", texture_format_clamp | texture_format_nomipmap | texture_format_nearest_mag | texture_format_nearest_min)
    build_masks()
    build_wear()
    bake_season(season_now(), between)
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

def mood_tick():
    var m = mood_now()
    // (a season's own light where there is one: "day.autumn")
    let own = m + "." + season_now()
    for(gobj(atmo_data, "moods").keys) name: if name == own: m = own
    if m != atmo_mood and m != "":
        let why = atmo_set(atmo_data, m)
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

var draws = []::Drawable
var view_lo = float2_0
var view_hi = float2_0

def add(f:int, x:float, y:float, sort_y:float, col:float4, fade:float = 1.0):
    if f < 0: return
    let fr = frames[f]
    let x0 = x - float(fr.ox) * fr.k
    let y0 = y - float(fr.oy) * fr.k
    if x0 < view_hi.x and y0 < view_hi.y and x0 + float(fr.w) * fr.k > view_lo.x and y0 + float(fr.h) * fr.k > view_lo.y:
        draws.push(Drawable { sort_y, draws.length, f, x, y, col, fade })

def prev_pos(i:int) -> int, int:
    let found, at = binary_search(p_id, u_id[i])
    return if found: p_x[at] else: u_x[i], if found: p_y[at] else: u_y[i]

let SASH = float4 { 0.66, 0.19, 0.16, 1.0 }  // the sash's red (the men's 'team' colour)
let ART_UP = 58.8                              // art px a tile of height
var eyes = []::float2                          // where the men are on the picture: crowns over them fade

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
            let p = iso(x, y)
            add(frame_at.get(man_shadow_name(m.look, facing), -1), p.x, p.y, p.y - 0.5, float4_1)
            add(frame_at.get(man_frame_name(m.look, if moving: 1 + step else: 0, facing), -1), p.x, p.y, p.y, SASH)
            if u_carry[i] > 0: add(frame_at.get("load.wood", -1), p.x + 3.0, p.y - 27.0, p.y + 0.1, float4_1)
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
    let season = season_now()
    let bare = season == "winter"
    for(props) pr:
        if pr.at.x > view_lo.x - 250.0 and pr.at.x < view_hi.x + 250.0 and pr.at.y > view_lo.y - 100.0 and pr.at.y < view_hi.y + 620.0:
            if pr.kind == 0:
                add(frame_at.get(pr.name + ".shadow", -1), pr.at.x, pr.at.y, -40000.0, float4_1)
                add(frame_at.get(pr.name, -1), pr.at.x, pr.at.y, pr.at.y, float4_1)
                let crown = if pr.sp == "tall": "spruce{pr.pick}.crown.ever" else: pr.name + ".crown." + (if leafy(pr.sp): season else: "ever")
                if pr.sp == "tall":
                    // its crown is out of sight overhead: only its shade reaches the ground
                    add(frame_at.get(crown + ".shadow", -1), pr.at.x, pr.at.y, -39999.0, float4_1)
                elif not leafy(pr.sp) or not bare:
                    add(frame_at.get(crown + ".shadow", -1), pr.at.x, pr.at.y, -39999.0, float4_1)
                    add(frame_at.get(crown, -1), pr.at.x, pr.at.y, pr.at.y + 0.2, float4_1, crown_fade(pr.at, pr.sp))
            elif pr.kind == 1:
                if pr.sp == "spruce":
                    add(frame_at.get(pr.name + ".shadow", -1), pr.at.x, pr.at.y, -39998.0, float4_1)
                    add(frame_at.get(pr.name, -1), pr.at.x, pr.at.y, pr.at.y, float4_1)
                else:
                    // (a young beech: its wood, and over it this season's leaves)
                    add(frame_at.get(pr.name + ".bare.shadow", -1), pr.at.x, pr.at.y, -39998.0, float4_1)
                    add(frame_at.get(pr.name + ".bare", -1), pr.at.x, pr.at.y, pr.at.y, float4_1)
                    if not bare:
                        add(frame_at.get(pr.name + "." + season + ".shadow", -1), pr.at.x, pr.at.y, -39998.0, float4_1)
                        add(frame_at.get(pr.name + "." + season, -1), pr.at.x, pr.at.y, pr.at.y + 0.1, float4_1)
            elif pr.kind == 2:
                add(frame_at.get("stump", -1), pr.at.x, pr.at.y, pr.at.y, float4_1)
            elif pr.kind == 5:
                if not bare:
                    add(frame_at.get(pr.name + "." + season + ".shadow", -1), pr.at.x, pr.at.y, -39996.0, float4_1)
                    add(frame_at.get(pr.name + "." + season, -1), pr.at.x, pr.at.y, pr.at.y, float4_1)
            else:
                add(frame_at.get(pr.name + ".shadow", -1), pr.at.x, pr.at.y, -39997.0, float4_1)
                add(frame_at.get(pr.name, -1), pr.at.x, pr.at.y, pr.at.y, float4_1)

// An ellipse on the ground (2:1) round p.
def draw_ring(p:float2, r:float, col:float4):
    let n = 24
    for(n) k:
        let a0 = 360.0 * float(k) / float(n)
        let a1 = 360.0 * float(k + 1) / float(n)
        ui_line(p + float2 { cos(a0) * r, sin(a0) * r * 0.5 }, p + float2 { cos(a1) * r, sin(a1) * r * 0.5 }, 1.2, col)

var mark_at = float2_0  // where the last order pointed (art px), and when
var mark_t = -10.0

def draw_rings(alpha:float):
    ui_batch():
        for(selected) id:
            let i = index_of(id)
            if i >= 0:
                let px, py = prev_pos(i)
                draw_ring(iso(float(px) + float(u_x[i] - px) * alpha, float(py) + float(u_y[i] - py) * alpha), 9.0, float4 { 0.95, 0.91, 0.79, 0.85 })
        let since = gl.time() - mark_t
        if since < 0.7: draw_ring(mark_at, 6.0 + since * 14.0, float4 { 0.95, 0.91, 0.79, 0.8 * (1.0 - since / 0.7) })

def draw_world(alpha:float):
    atlas_pack()
    if map_version != props_version:
        build_props()
        build_masks()
        build_litter()
    if tick - wear_tick >= 40:
        build_wear()
        wear_tick = tick
    let ws = float(gl.window_size())
    let cam_px = float2 { floor(cam.x * zoom), floor(cam.y * zoom) } / zoom
    sprite_snap = zoom
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
                view_lo = from_screen(float2_0) - float2_1
                view_hi = from_screen(ws) + float2_1
                draws = []
                collect_men(alpha)
                collect_props()
                draws.push(Drawable { -30000.0, draws.length, -4, 0.0, 0.0, float4_1, 1.0 })  // the rings: on the ground, over the shadows
                qsort_in_place(draws) a, b: a.y < b.y or (a.y == b.y and a.seq < b.seq)
                b_sheet = -1
                for(draws) d:
                    if d.f == -4:
                        flush_sprites()
                        draw_rings(alpha)
                        b_sheet = -1
                    elif d.fade < 1.0: sprite_faded(d.f, d.x, d.ay, d.col, d.fade)
                    else: sprite(d.f, d.x, d.ay, d.col)
                flush_sprites()
    sprite_snap = 1.0
    if atmo_on: atmo_end(cam_px, zoom, 1.5)

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
        let s = to_screen(iso(float(u_x[i]), float(u_y[i])) - float2 { 0.0, 14.0 })
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
                let s = to_screen(iso(float(u_x[i]), float(u_y[i])))
                if s.x >= lo.x and s.x <= hi.x and s.y >= lo.y - 10.0 and s.y <= hi.y + 20.0 * zoom: selected.push(u_id[i])
        else:
            let i = unit_at_screen(m)
            if i >= 0 and gl.time() - last_click < 0.4: selected = copy(u_id)  // (a second click: every man)
            elif i >= 0: selected = [ u_id[i] ]
            else: selected = []
            last_click = gl.time()
    if gl.button("escape") == 1: selected = []

// The young tree the mouse is on: its cell, or the one its picture stands on (a tree is drawn up from its foot).
def young_tree_at(mm:float2) -> int:
    let young = str_index(tr_names, "young_tree")
    for(3) n:
        let x = int(mm.x / 1000.0) + n
        let y = int(mm.y / 1000.0) + n
        if x >= 0 and y >= 0 and x < W and y < H and terrain[y * W + x] == young: return y * W + x
    return -1

def order_tick():
    if gl.button("mouse2") != 1: return
    let ids = filter(selected) id: index_of(id) >= 0
    if not ids.length: return
    let mm = mouse_milli()
    let tree = young_tree_at(mm)
    if tree >= 0:
        issue_cmd(0, CMD_GATHER, ids, tree, 0, 0, 0)
        mark_at = iso(float((tree % W) * 1000 + 500), float((tree / W) * 1000 + 500))
    else:
        let x = clamp(int(mm.x), 0, W * TILE - 1)
        let y = clamp(int(mm.y), 0, H * TILE - 1)
        issue_cmd(0, CMD_MOVE, ids, x, y, 0, 0)
        mark_at = iso(float(x), float(y))
    mark_t = gl.time()

// The camera stays over the place, far enough in from its edge that the view never runs off the map (the place has a
// rim of forest that deep: the map's "rim").
def cam_keep():
    let rim = float(gint(su_map, "rim", 0)) * 1000.0
    let t = iso_inv(cam)
    cam = iso(clamp(t.x, rim, float(W * 1000) - rim), clamp(t.y, rim, float(H * 1000) - rim))

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
fatal(gl.load_materials(ATMO_SHADERS, true))
pace_background = not capture
pace(PACE_MATCH)
lib_load("../data")
route_load()
atmo_data = lib_data("atmosphere.json")
for(atmo_problems(atmo_data)) why: print why
zoom = max(1.0, floor(float(gl.window_size().y) / 450.0 * 4.0) / 4.0)

// A frame of words while something long is made (the first start bakes the men and the trees).
var waiting_lines = [ "Smyana" ]
var waiting_t0 = seconds_elapsed()
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
run_begin()
if arg_of("leg") != "": enter_leg(arg_of("leg"), "west")  // leg:<id>: start at this leg of the route, for a look
view_enter(): waiting_frame()
if arg_of("look") != "":  // look:<x>,<y>: the camera on this tile
    let xy = tokenize(arg_of("look"), ",", " ")
    cam = iso(string_to_float(xy[0]) * 1000.0, string_to_float(xy[1]) * 1000.0)
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
