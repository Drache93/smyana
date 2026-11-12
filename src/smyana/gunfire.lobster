// ------------------------------------------------------------------ the rifles, seen and heard (#58)
// A shot as the men's flintlocks make it, after the sim has fired it (smyana/guns.lobster): the lock falls and the
// priming flashes in the pan with a fizz and a puff, a moment later (the hang, now and then a long hang-fire) the
// charge goes off: a flash at the muzzle, the bang and the place answering it (data/audio.json, made by
// sound/flintlock.py: close wood, valley, gorge or open ridge; a long way off, only the low far boom), and a cloud of
// white smoke that rolls out ahead, then hangs and drifts on the air and hides the man who fired. Then the long
// reload: the rifle stood upright, powder down the barrel, the rod rammed, each with its own small sound.
// Art px throughout (the world's own units: a tile is 96 x 48). View only: nothing here touches the sim.

let GUN_MUZZLE_UP = 19.0     // art px over his feet the barrel is when he aims
let GUN_MUZZLE_AHEAD = 18.0  // and how far ahead of him its muzzle is (shortened by the view's tilt, sideways)
let GUN_LOCK_UP = 18.0
let GUN_LOCK_AHEAD = 3.0
let GUN_FIRE_POSE_S = 0.3  // he shows the kick this long after the bang
let GUN_TILE_PX = 68.0     // art px a tile, roughly, for distances to the camera
let SMOKE_LIT = float4 { 0.93, 0.92, 0.88, 1.0 }
let SMOKE_MID = float4 { 0.79, 0.79, 0.77, 1.0 }
let SMOKE_SHADE = float4 { 0.56, 0.57, 0.58, 1.0 }

// (the smoke in the light's shade buffer, as Creel's atmo_shade_clear but its strength a uniform: gl.rect has no
// colour of its own a vertex)
let GUNFIRE_SHADERS = """
SHADER smoke_shade_clear
    VERTEX
        INPUTS apos:4 atc:2
        UNIFORMS mvp
        gl_Position = mvp * apos;
        itc = atc;
    PIXEL
        INPUTS itc:2
        UNIFORMS tex0 col
        float a = texture(tex0, itc).a * col.r;
        if (a < 0.02) discard;
        frag_color = vec4(0.0, 0.0, 0.0, a);
"""

class GunShot:
    uid:int
    feet:float2
    dir:float2  // toward what he fired at, on the screen, a unit
    t:float     // seconds since the lock fell
    hang:float  // when the charge goes off
    banged:bool = false

class GunPuff:
    pos:float2
    vel:float2  // art px a second, slowing
    t:float
    life:float
    r0:float  // art px, as it starts and as it ends
    r1:float
    rise:float  // art px a second
    thick:float

class GunFlash:
    pos:float2
    dir:float2
    t:float
    muzzle:bool

var gun_now = 0.0  // seconds of play (it stops when the game is paused)
var gun_shots = []::GunShot
var gun_puffs = []::GunPuff
var gun_flashes = []::GunFlash
let gun_banged = dictionary<int, float>(32)  // a man's last bang (gun_now) ...
let gun_reload = dictionary<int, float>(32)  // ... and how long his reload is, seconds
let gun_heard = dictionary<int, int>(32)     // the reload's sounds he has made
var gun_cam = float2_0                       // the middle of the view and half its width, art px (the listener)
var gun_half = 600.0

def gun_cfg_f(o:JV, k:string, f:float) -> float: return if has(o, k): as_float(at(o, k)) else: f

def gun_place() -> string: return gstr(gobj(guns_cfg, "places"), place_now(), "valley")

def gun_air() -> JV: return gobj(gobj(guns_cfg, "air"), gun_place())

def gun_between(r:[JV]) -> float: return as_float(r[0]) + rnd_float() * (as_float(r[1]) - as_float(r[0]))

// How far from the listener, in tiles, and where left or right (-1 .. 1).
def gun_hear(p:float2) -> float, float:
    return magnitude(p - gun_cam) / GUN_TILE_PX, clamp((p.x - gun_cam.x) / max(gun_half, 1.0), -1.0, 1.0)

// A man has fired (the sim's shot): his lock falls now. feet: his feet; to: what he fired at, both art px.
def gunfire_shot(uid:int, feet:float2, to:float2):
    let d = to - feet
    let dir = if magnitude(d) > 0.01: normalize(d) else: float2 { 1.0, 0.0 }
    let hf = gobj(guns_cfg, "hang_fire")
    let long = rnd(max(1, gint(hf, "one_in", 12))) == 0
    let hang = gun_between(glist(if long: hf else: guns_cfg, if long: "s" else: "hang_s"))
    gun_shots.push(GunShot { uid, feet, dir, 0.0, hang })
    let lock = feet + float2 { dir.x * GUN_LOCK_AHEAD, -GUN_LOCK_UP }
    gun_flashes.push(GunFlash { lock, dir, 0.0, false })
    let far, pan = gun_hear(lock)
    if far < gun_cfg_f(guns_cfg, "far_tiles", 16.0) * 0.6: play_sound_at("pan", -3.0 - far * 0.8, pan)
    // the priming's own little puff, out of the pan, rising
    for(2): gun_puffs.push(GunPuff { lock + float2 { rnd_range(-1.0, 1.0), 0.0 }, float2 { dir.x * 6.0, -4.0 }, -0.03, rnd_range(4.0, 7.0), 1.5, rnd_range(4.0, 6.0), 3.0, 0.7 })

// The charge goes off.
def gun_bang(s:GunShot):
    s.banged = true
    gun_banged.set(s.uid, gun_now)
    gun_heard.set(s.uid, 0)
    let i = index_of(s.uid)
    gun_reload.set(s.uid, if i >= 0: float(u_cooldown[i]) / float(TICK_HZ) + s.hang else: 20.0)
    let muzzle = s.feet + s.dir * GUN_MUZZLE_AHEAD - float2 { 0.0, GUN_MUZZLE_UP }
    gun_flashes.push(GunFlash { muzzle, s.dir, 0.0, true })
    let far, pan = gun_hear(muzzle)
    let near = far < gun_cfg_f(guns_cfg, "far_tiles", 16.0)
    play_sound_at("{if near: "boom" else: "far"}_{gun_place()}", if near: -far * 0.5 else: -4.0 - (far - 16.0) * 0.3, pan)
    // the smoke: driven out ahead of the muzzle in a long plume, slowing fast, then a cloud that swells and hangs
    let life = gun_cfg_f(gun_air(), "smoke_s", 18.0)
    for(12):
        let speed = rnd_range(15.0, 175.0)
        let v = s.dir * speed + float2 { rnd_range(-10.0, 10.0), rnd_range(-8.0, 4.0) }
        gun_puffs.push(GunPuff { muzzle, v, -rnd_float() * 0.05, life * rnd_range(0.5, 1.0), rnd_range(1.5, 3.5), rnd_range(7.0, 16.0), rnd_range(0.6, 2.2), rnd_range(0.8, 1.0) })
    for(4):  // (some rolls back round the man himself)
        gun_puffs.push(GunPuff { muzzle - float2 { s.dir.x * 8.0, 0.0 }, float2 { rnd_range(-8.0, 8.0), rnd_range(-4.0, 2.0) }, -0.05, life * rnd_range(0.5, 0.85), 3.0, rnd_range(8.0, 12.0), rnd_range(1.0, 2.5), 0.9 })

// Every frame the game runs: time on, bangs when they're due, the reload's sounds, the smoke on the air.
// cam: the middle of the view, half_w: half its width, art px.
def gunfire_tick(dt:float, cam:float2, half_w:float):
    gun_cam = cam
    gun_half = half_w
    gun_now += dt
    for(gun_shots) s:
        s.t += dt
        if not s.banged and s.t >= s.hang: gun_bang(s)
    gun_shots = filter(gun_shots) s: s.t < s.hang + GUN_FIRE_POSE_S
    for(gun_flashes) f: f.t += dt
    gun_flashes = filter(gun_flashes) f: f.t < 0.2
    // the reload's sounds, at their shares of each man's reload, heard only near
    let plan = glist(guns_cfg, "reload")
    for(gun_banged.get_keys()) uid:
        let since = gun_now - gun_banged.get(uid, 0.0)
        let len = gun_reload.get(uid, 20.0)
        var n = gun_heard.get(uid, 0)
        let i = index_of(uid)
        while n < plan.length and since >= as_float(plan[n].a[0]) * len:
            if i >= 0 and u_hp[i] > 0:
                let far, pan = gun_hear(on_ground(float2 { float(u_x[i]), float(u_y[i]) }))
                if far < 9.0: play_sound_at(as_str(plan[n].a[1]), -far * 1.2, pan)
            n++
        gun_heard.set(uid, n)
    // the smoke: slowing, rising a little, carried by the air (from the west, a little up the screen)
    let drift = gun_cfg_f(gun_air(), "drift", 0.2) * GUN_TILE_PX
    let wind = float2 { 1.0, -0.25 } * drift
    for(gun_puffs) p:
        p.t += dt
        if p.t > 0.0:
            p.pos += p.vel * dt
            p.vel *= pow(0.02, dt)  // (most of its push gone in a second)
            p.pos += (wind * min(1.0, p.t / 3.0) + float2 { 0.0, -p.rise }) * dt
    gun_puffs = filter(gun_puffs) p: p.t < p.life

// The pose a man is drawn in for his rifle (men_view.lobster's POSE_*), or -1 for his own (standing or walking); and
// where he faces then (the screen direction toward his target), if he's turned to it.
def gun_pose(uid:int, moving:bool, aiming:bool) -> int:
    for(gun_shots) s:
        if s.uid == uid: return if s.banged: POSE_FIRE else: POSE_AIM
    let banged = gun_banged.get(uid, -1000.0)
    let since = gun_now - banged
    let len = gun_reload.get(uid, 0.0)
    if since < len and not moving:
        let k = since / max(len, 0.1)
        if k < 0.06: return POSE_FIRE  // (the gun comes down)
        if k > 0.94 and aiming: return POSE_AIM
        let ram = glist(guns_cfg, "ram")
        if k >= as_float(ram[0]) and k <= as_float(ram[1]): return if int(since * 2.6) % 2 == 0: POSE_RAM_UP else: POSE_RAM_DOWN
        return POSE_RAM_DOWN
    if aiming and not moving: return POSE_AIM
    return -1

// The flashes and the smoke, drawn into the world over the men (so the smoke hides them).
def gunfire_draw():
    gl.set_shader("color")
    for(gun_flashes) f:
        let k = f.t / (if f.muzzle: 0.09 else: 0.07)
        if k < 1.0:
            if f.muzzle:
                // a tongue of flame out along the barrel, white at the root
                for(4) n:
                    let along = float(n) * 2.2 * (1.0 + k)
                    let r = (3.4 - float(n) * 0.7) * (1.0 - k * 0.4)
                    let c = if n == 0: float4 { 1.0, 0.97, 0.85, 1.0 - k } else: float4 { 1.0, 0.72 - float(n) * 0.1, 0.3, (1.0 - k) * 0.9 }
                    gl.color(c):
                        gl.translate(float(floor(f.pos + f.dir * along))): gl.circle(max(0.8, r), 8)
            else:
                gl.color(float4 { 1.0, 0.9, 0.6, 1.0 - k }):
                    gl.translate(float(floor(f.pos))): gl.circle(2.2 * (1.0 + k), 8)
    if not gun_puffs.length: return
    gl.set_shader("textured")
    // (in three bands, as Creel draws dust: every puff in shade, then lit up and to the left of it, then a smaller
    // highlight, so the puffs merge into one cloud lit from above)
    for(3) band:
        let c = [ SMOKE_SHADE, SMOKE_MID, SMOKE_LIT ][band]
        gun_puffs_drawn(band) a: float4 { c.x, c.y, c.z, a * 0.75 }
    gl.set_shader("color")

// The smoke in the light's shade buffer (between atmo_shade_standing and atmo_begin): it wipes the mark that keeps a
// man readable in the shade where it covers him, so the light doesn't lift him out of it.
def gunfire_shade():
    if not gun_puffs.length: return
    gl.set_shader("smoke_shade_clear")
    gun_puffs_drawn(0) a: float4 { min(1.0, a * 2.0), 0.0, 0.0, 1.0 }
    gl.set_shader("color")

// Each puff of smoke drawn, in band 0 (all of it), 1 or 2 (its lit parts), in the colour col(its thickness) gives.
def gun_puffs_drawn(band:int, col):
    for(gun_puffs) p:
        if p.t >= 0.0:
            let k = p.t / p.life
            let r = (p.r0 + (p.r1 - p.r0) * sqrt(min(1.0, p.t / (p.life * 0.45)))) * [ 1.0, 0.82, 0.5 ][band]
            let ri = max(1, int(r + 0.5))
            let at = float(floor(p.pos - float2_1 * r * [ 0.0, 0.28, 0.5 ][band]))
            // thick at first, then thinning out over the second half of its life
            let a = p.thick * (if k < 0.35: 1.0 else: 1.0 - (k - 0.35) / 0.65) * (0.75 + 0.25 * float(band) / 2.0)
            gl.set_primitive_texture(0, puff_tex(ri))
            gl.color(col(a)):
                gl.translate(at - float2_1 * float(ri)): gl.rect(float2_1 * float(ri * 2 + 1))

// The flashes' light on what's round them (Creel's atmosphere: the "flash" glow).
def gunfire_glow():
    if not atmo_on: return
    let src = atmo_source("flash")
    for(gun_flashes) f:
        if f.muzzle: atmo_glow(src, f.pos / 1.5, float3 { 1.0, 0.75, 0.4 }, 1.0 - f.t / 0.2, 0.0)

// A new place: nothing of the last one's shots carries over.
def gunfire_clear():
    gun_shots = []
    gun_puffs = []
    gun_flashes = []
    gun_banged.clear()
    gun_reload.clear()
    gun_heard.clear()
