// What a player would have heard and read, written to the log with the run's clock on it, for the agent that plays as
// a first-time player and cannot hear (D-139, tools/playtest.sh; the game is started with `heard`). "heard:" lines are
// sounds and the music, "said:" a man's words over his head, "clock:" where and when the men are, every half minute.

import game.audio

var heard_on = false
var heard_s = 0.0  // the run's clock in seconds, kept by smyana.lobster

def heard_stamp() -> string:
    let s = int(heard_s)
    return "{s / 60}:{if s % 60 < 10: "0" else: ""}{s % 60}"

// A sound played at `db` and `pan` (Creel's play_sound_at), and a line for it: how loud, and from which side.
// The same sound many times in a breath (a volley of seventeen guns, the third agent playtest: "probably a wall of
// noise") is thinned: the first three within `CROWD_S` play, each of the rest only if it is a tenth of a second after
// the last that did, and quieter. D-148.
let CROWD_S = 0.35
let crowd_at = dictionary<string, float>(64)  // a sound's name: when one of it last played
let crowd_n = dictionary<string, int>(64)     // and how many have in this breath
def hear(name:string, db:float, pan:float):
    let now = gl.time()
    let last = crowd_at.get(name, -10.0)
    var n = if now - last > CROWD_S: 0 else: crowd_n.get(name, 0)
    if n >= 3 and now - last < 0.1: return
    crowd_at.set(name, now)
    crowd_n.set(name, n + 1)
    let quiet = if n >= 3: -4.0 else: 0.0
    if heard_on:
        let loud = if db > -4.0: "close" elif db > -10.0: "not far off" else: "far off"
        let side = if pan < -0.25: ", to the left" elif pan > 0.25: ", to the right" else: ""
        print "heard: {heard_stamp()} {name}, {loud}{side}"
    play_sound_at(name, db + quiet, pan)

def heard_line(kind:string, text:string):
    if heard_on: print "{kind}: {heard_stamp()} {text}"
