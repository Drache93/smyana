// ------------------------------------------------------------------ the mouse's cursors
// Smyana's own cursors (#86, Dominic: "We need custom cursors"), drawn by the OS so they never lag the mouse: the
// pictures are in data/cursors/ (tools/make_cursors.py), each with a twice-as-big one for a high DPI display. The
// pointer, the pointer with an order's ring when chosen men would walk where it points, and a picture of what a
// right-click does over anything else they can use (Dominic, 2026-11-13: no words under the mouse, "lots of text
// instead of visual"): an axe over a young tree where a bridge is down, a basket over a find, a hand over a pile, a
// knife over a carcass, a sight over game or a foe, a flame over a hut, a book over the ruins, a spade over fallen
// rock. With no cursors (an OS that won't make them): the system's own.
import gl

let CURSOR_POINT = 0
let CURSOR_GO = 1
let CURSOR_FELL = 2
let CURSOR_GATHER = 3
let CURSOR_TAKE = 4
let CURSOR_KNIFE = 5
let CURSOR_SHOOT = 6
let CURSOR_CAMP = 7
let CURSOR_STUDY = 8
let CURSOR_DIG = 9
let CURSOR_NAMES = [ "point", "go", "fell", "gather", "take", "knife", "shoot", "camp", "study", "dig" ]
// (the arrow's tip, the axe's edge, the sight's middle: tools/make_cursors.py)
let CURSOR_HOT = [ int2 { 1, 1 }, int2 { 1, 1 }, int2 { 3, 4 }, int2 { 1, 1 }, int2 { 1, 1 }, int2 { 1, 1 }, int2 { 6, 5 }, int2 { 1, 1 }, int2 { 1, 1 }, int2 { 1, 1 } ]

var cursors = []::resource<cursor>?
var cursor_now = -1

def cursors_load(dir:string):
    cursors = map(CURSOR_NAMES) n, i: gl.cursor_image("{dir}/{n}.png", "{dir}/{n}@2x.png", CURSOR_HOT[i])
    cursor_now = -1

// This one over the window (only told to the OS when it changes).
def cursor_show(kind:int):
    if kind == cursor_now or kind >= cursors.length: return
    cursor_now = kind
    let c = cursors[kind]
    if c: gl.cursor_set(c)
    else: gl.cursor_set_default()
