// ------------------------------------------------------------------ the forest's own sound (D-147)
// Dominic, 2026-11-22: "I think biggest gap is music and sounds". Until now the forest was silent: guns, wolves and a
// bear, and nothing else. Beds: loops made by sound/forest.py (the wind, small birds, crickets, rain, a stream, a
// fire), each faded up and down by what is on the screen, never cut. Calls: a cuckoo, a woodpecker, a jay, a raven,
// an owl, each now and then in its season and hour. data/audio.json "forest" sets how loud each is and how often.
//
// With no sound device the beds are still reckoned, so the playtest's log (smyana/heard.lobster) says what a player
// would hear.

class Bed:
    name:string
    label:string     // what the log calls it
    id:int = 0       // its track (0: not started; -1: no sound device)
    now:float = 0.0  // its volume now, 0..1
    want:float = 0.0
    heard:bool = false

let beds = [
    Bed { "wind", "the wind in the trees" },
    Bed { "birds", "birdsong" },
    Bed { "night", "crickets" },
    Bed { "rain", "rain on the leaves" },
    Bed { "stream", "the stream" },
    Bed { "fire", "the fire crackling" },
    // (the men's feet, D-148: no line in the log for them, they come and go with every order)
    Bed { "steps_leaf", "" },
    Bed { "steps_snow", "" },
    Bed { "wade", "men wading" }
]
let BED_WIND = 0
let BED_BIRDS = 1
let BED_NIGHT = 2
let BED_RAIN = 3
let BED_STREAM = 4
let BED_FIRE = 5
let BED_STEPS = 6
let BED_SNOW = 7
let BED_WADE = 8
var call_wait = 20.0  // seconds till the next call

def forest_cfg() -> JV: return gobj(lib_data("audio.json"), "forest")

// How loud a bed should be now (0..1), before its own level in the data.
def bed_want(k:int, v:float):
    beds[k].want = clamp(v, 0.0, 1.0)

// Every frame the world is on the screen: each bed eased toward what was asked of it.
def beds_tick(dt:float):
    let fc = forest_cfg()
    let fade = as_float(at(fc, "fade_s"))
    let levels = gobj(fc, "beds")
    let bus = db_to_volume(buses.get("Forest", 0.0)) * float(sound_level) / 10.0
    for(beds) b:
        // (the men's feet come and go four times as fast as the weather)
        b.now = move_toward(b.now, if sound_on: b.want else: 0.0, dt / max(if b.label == "" or b.name == "wade": fade / 4.0 else: fade, 0.1))
        if b.id == 0 and b.now > 0.0:
            b.id = play_music(audio_file("sfx/amb_{b.name}_1.wav"), -1)
            if b.id <= 0: b.id = -1
        if b.id > 0: music_volume(b.id, b.now * db_to_volume(as_float(at(levels, b.name))) * bus)
        // (the log: when it can first be heard, and when it has gone)
        if b.label == "": continue
        if not b.heard and b.now > 0.25:
            b.heard = true
            heard_line("heard", "{b.label}, coming up")
        elif b.heard and b.now < 0.05:
            b.heard = false
            heard_line("heard", "{b.label} fades away")

// The beds silent at once (leaving a place: the next may be another season).
def beds_hush():
    for(beds) b: b.want = 0.0

// A bird calls, now and then: which, by the season and the hour. dt in seconds; rnd01: a roll of the dice 0..1.
def calls_tick(dt:float, season:string, night:bool, raining:bool, roll:float):
    call_wait -= dt
    if call_wait > 0.0: return
    let fc = forest_cfg()
    let gaps = glist(fc, "call_s")
    call_wait = as_float(gaps[0]) + (as_float(gaps[1]) - as_float(gaps[0])) * roll
    if raining: return
    let name = if night: "owl" else: gstr(gobj(fc, "calls"), season, "")
    if name == "": return
    // (somewhere off to one side, far or nearer)
    hear(name, -8.0 * roll, roll * 2.0 - 1.0)
