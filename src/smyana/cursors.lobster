// ------------------------------------------------------------------ the mouse's cursors
// Smyana's own cursors (#86, Dominic: "We need custom cursors"), drawn by the OS so they never lag the mouse: the
// pictures are in data/cursors/ (tools/make_cursors.py), each with a twice-as-big one for a high DPI display. The
// pointer, the pointer with an order's ring when chosen men would walk where it points, and an axe over a young tree
// they would fell. With no cursors (an OS that won't make them): the system's own.
import gl

let CURSOR_POINT = 0
let CURSOR_GO = 1
let CURSOR_FELL = 2
let CURSOR_NAMES = [ "point", "go", "fell" ]
let CURSOR_HOT = [ int2 { 1, 1 }, int2 { 1, 1 }, int2 { 3, 4 } ]  // (the arrow's tip, the axe's edge: tools/make_cursors.py)

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
