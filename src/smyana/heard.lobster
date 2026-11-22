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
def hear(name:string, db:float, pan:float):
    if heard_on:
        let loud = if db > -4.0: "close" elif db > -10.0: "not far off" else: "far off"
        let side = if pan < -0.25: ", to the left" elif pan > 0.25: ", to the right" else: ""
        print "heard: {heard_stamp()} {name}, {loud}{side}"
    play_sound_at(name, db, pan)

def heard_line(kind:string, text:string):
    if heard_on: print "{kind}: {heard_stamp()} {text}"
