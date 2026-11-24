// ------------------------------------------------------------------ the music
// The score follows the game (D-036) by swapping whole tracks (D-042), never by blending them. Which track goes with
// what is data (data/music.json); the tracks are Ogg files in assets/audio/music, made by music/pieces/set_03_score.py.
//
//   calm     a track for the season and the hour plays once, then the forest is left alone for a while; when the
//            light or the season turns, or a fire is lit at night, it fades and the track for now begins.
//   danger   score_danger("bandits"): the calm track is cut and the danger's loop starts on its first sound.
//            score_safe(): the loop is cut, a single drum stroke rings over the cut, and after a silence the calm
//            music starts again from its beginning.
//   moments  score_moment("death"): one track played once (the homecoming, a man's death, the intro).
//
// Each track's length is known from data/music_tracks.json, so the turn-taking works the same with no sound device
// (a cloud session, a capture). The volume is Creel's music setting (settings.txt) over the score's own "db".

let SCORE_DIR = "../assets/audio/music"
var score_cfg = jobj()
var score_seconds = jobj()
var score_on = true
var score_id = 0         // the music playing (0: none, or no sound device)
var score_track = ""     // its name ("": silence)
var score_kind = ""      // "calm", "danger", "moment", "stroke" or ""
var score_left = 0.0     // seconds of it still to play (a loop: none)
var score_wait = 0.0     // seconds of silence still to keep before the next calm track
var score_fired = false  // the fire's song had the last turn at the fire
var score_strokes = 0
var score_for = ""  // the season and hour the calm track began in
var score_fire_was = false
var score_played = 0.0  // seconds the calm track has played
var score_hold = false  // the light is about to turn: no new calm track for the hour that is ending

def score_load():
    score_cfg = lib_data("music.json")
    score_seconds = gobj(lib_data("music_tracks.json"), "seconds")
    score_wait = as_float(at(score_cfg, "first_wait_s"))
    volume_load()

// (each track's own trim on top, data/music.json "trim": the tracks were made a few dB apart, measured 2026-11-24)
def score_volume() -> float:
    let trims = gobj(score_cfg, "trim")
    let trim = if score_track != "" and has(trims, score_track): as_float(at(trims, score_track)) else: 0.0
    return db_to_volume(as_float(at(score_cfg, "db")) + trim) * float(music_level) / 10.0

def score_stop(fade_s:float = 0.0):
    if score_id > 0:
        if fade_s > 0.0: music_fade_out(score_id, int(fade_s * 1000.0))
        else: music_halt(score_id)
    score_id = 0
    score_track = ""
    score_kind = ""
    score_left = 0.0

// One track, from its start, cutting whatever was playing. A loop goes on until it is stopped.
def score_play(track:string, kind:string, loop:bool, why:string):
    score_stop()
    if not score_on or track == "" or not has(score_seconds, track): return
    score_track = track
    score_kind = kind
    score_left = if loop: -1.0 else: as_float(at(score_seconds, track))
    score_id = play_music("{SCORE_DIR}/{track}.ogg", if loop: -1 else: 0)
    if score_id > 0: music_volume(score_id, score_volume())
    print "music: {track} ({why}){if score_id > 0: "" else: ", no sound device"}"

// The calm track for now. At night by a fire the men's own song takes turns with the season's.
def score_calm_for(season:string, mood:string, fire:bool) -> string:
    let by_fire = gstr(gobj(score_cfg, "fire_night"), "track", "")
    if fire and mood == "night" and by_fire != "" and not score_fired: return by_fire
    return gstr(gobj(gobj(score_cfg, "calm"), season), mood, "")

// Danger of that kind begins ("wary", "hiding", "beasts", "bandits", "ottomans", "chase"): its loop, at once.
def score_danger(kind:string):
    let track = gstr(gobj(score_cfg, "danger"), kind, "")
    if track != "" and track != score_track: score_play(track, "danger", true, "danger: {kind}")

// The danger is over: a drum stroke over the cut, then silence, then the calm music from its beginning.
def score_safe():
    if score_kind != "danger": return
    let strokes = gstrs(score_cfg, "end_strokes")
    if strokes.length:
        score_play(strokes[score_strokes % strokes.length], "stroke", false, "the danger is over")
        score_strokes++
    else:
        score_stop()
    score_wait = as_float(at(score_cfg, "after_danger_s"))

// A moment's track, once ("death", "intro", "leaving", "homecoming", "ending"; "menu" loops).
def score_moment(name:string):
    let track = gstr(gobj(score_cfg, "moments"), name, "")
    if track != "": score_play(track, "moment", (find(gstrs(score_cfg, "loops")): _ == track) >= 0, name)

// The men are leaving this place: the calm music fades (the next place may be another season).
def score_leave():
    if score_kind == "calm": score_stop(as_float(at(score_cfg, "leave_fade_s")))
    score_wait = as_float(at(score_cfg, "first_wait_s"))

// Every frame the world is on the screen. fire: a fire is lit here.
def score_tick(dt:float, season:string, mood:string, fire:bool):
    if score_id > 0: music_volume(score_id, score_volume())
    if score_left > 0.0:
        score_left -= dt
        if score_left <= 0.0:
            // (a track is over: the forest is left alone a while; after a stroke the wait is already set)
            if score_kind != "stroke": score_wait = as_float(at(score_cfg, "gap_s"))
            score_stop()
    // (the light has turned, the season has, or a fire is lit in the dark: the calm track gives way to the one for now,
    // D-145. Until 2026-11-22 a track always played through, and at two minutes a track and four a day the dusk's came
    // after dark and the fire's song an hour before dawn, two agent playtests found.)
    if score_kind == "calm":
        score_played += dt
        let want = score_calm_for(season, mood, fire)
        let turned = "{season} {mood}" != score_for or (fire and mood == "night" and not score_fire_was and not score_fired)
        if turned and want != "" and want != score_track and score_played >= as_float(at(score_cfg, "turn_min_s")):
            score_stop(as_float(at(score_cfg, "turn_fade_s")))
            score_wait = as_float(at(score_cfg, "turn_gap_s"))
        elif turned and want == score_track: score_for = "{season} {mood}"
    if score_track != "": return
    // (in the quiet between two tracks, the light turning or a fire lit in the dark brings the next one in at once)
    let gap = as_float(at(score_cfg, "turn_gap_s"))
    if score_for != "" and score_wait > gap and ("{season} {mood}" != score_for or (fire and mood == "night" and not score_fire_was and not score_fired)): score_wait = gap
    score_wait -= dt
    if score_wait > 0.0: return
    if score_hold and score_for == "{season} {mood}": return
    let track = score_calm_for(season, mood, fire)
    score_fired = track == gstr(gobj(score_cfg, "fire_night"), "track", "-")
    score_play(track, "calm", false, "{season} {mood}{if score_fired: ", by the fire" else: ""}")
    score_for = "{season} {mood}"
    score_fire_was = fire
    score_played = 0.0
    if score_track == "": score_wait = as_float(at(score_cfg, "gap_s"))  // (no track for this: ask again later)
