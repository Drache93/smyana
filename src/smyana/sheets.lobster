// ------------------------------------------------------------------ baked art, kept between runs
// The men and the trees are drawn into pictures when the game first starts (a bake), which takes a while. A Sheet is
// one such picture with its frames; it's saved in bake_cache/ (a PNG and a list of its frames) and read back the next
// time, as long as its key (what it was made from) is the same.

class SheetFrame:
    name:string
    x:int
    y:int
    w:int
    h:int
    ox:int
    oy:int

class Sheet:
    file:string  // bake_cache/<file>.png and .txt
    key:string
    w:int
    rows:[[float4]] = []
    frames:[SheetFrame] = []
    sx:int = 0  // the shelf being filled
    sy:int = 0
    sh:int = 0

let BAKE_DIR = "../bake_cache"

var bake_light = ""  // the light the art is baked under (the sun's height): part of every sheet's key

def sheet_new(file:string, key:string, w:int) -> Sheet: return Sheet { file, "{key} {bake_light} elev {vx_ELEV}", w }

// Room for a frame w x h on the sheet: its corner.
def sheet_place(s:Sheet, w:int, h:int) -> int2:
    assert w + 2 <= s.w
    if s.sx + w + 2 > s.w:
        s.sy += s.sh
        s.sx = 0
        s.sh = 0
    let at = int2 { s.sx + 1, s.sy + 1 }
    s.sx += w + 2
    s.sh = max(s.sh, h + 2)
    while s.rows.length < s.sy + s.sh: s.rows.push(map(s.w): float4_0)
    return at

// A frame from a cell of pixels (cw wide), the part of it in box (x0, y0, x1, y1), its anchor at `anchor` in the cell.
def sheet_add_cell(s:Sheet, name:string, cell:[float4], cw:int, box:int4, anchor:int2):
    let w = max(box.z - box.x + 1, 1)
    let h = max(box.w - box.y + 1, 1)
    let at = sheet_place(s, w, h)
    if box.z >= box.x:
        for(h) y:
            let row = s.rows[at.y + y]
            for(w) x: row[at.x + x] = cell[(box.y + y) * cw + box.x + x]
    s.frames.push(SheetFrame { name, at.x, at.y, w, h, anchor.x - box.x, anchor.y - box.y })

// A frame from RGBA bytes (rows top down), w x h, its anchor at `origin` on it.
def sheet_add_bytes(s:Sheet, name:string, bytes:string, w:int, h:int, origin:float2):
    let at = sheet_place(s, w, h)
    for(h) y:
        let row = s.rows[at.y + y]
        for(w) x:
            let o = (y * w + x) * 4
            row[at.x + x] = float4 { float(bytes[o]), float(bytes[o + 1]), float(bytes[o + 2]), float(bytes[o + 3]) } / 255.0
    s.frames.push(SheetFrame { name, at.x, at.y, w, h, int(origin.x), int(origin.y) })

// The sheet as a texture, its frames added to Creel's (game/pack.lobster) under their names, each `k` art px a
// texture px; saved for next time when `save`.
def sheet_finish(s:Sheet, k:float, save:bool):
    while s.rows.length < 4: s.rows.push(map(s.w): float4_0)
    let tex = gl.create_texture(s.rows, pack_formats)
    if save:
        if gl.save_texture(tex, "{BAKE_DIR}/{s.file}.png", false):
            var t = s.key + "\n"
            for(s.frames) f: t += "{f.name} {f.x} {f.y} {f.w} {f.h} {f.ox} {f.oy}\n"
            write_file("{BAKE_DIR}/{s.file}.txt", t)
        else: print "(bake_cache/ isn\'t there or can\'t be written: the art will be baked again next time)"
    sheet_frames(s, tex, float2 { float(s.w), float(s.rows.length) }, k)
    s.rows = []

def sheet_frames(s:Sheet, tex:resource<texture>, dims:float2, k:float):
    add_sheet(tex, dims)
    let sheet = sheet_tex.length - 1
    for(s.frames) f:
        frame_at.set(f.name, frames.length)
        frames.push(Frame { sheet, f.x, f.y, f.w, f.h, f.ox, f.oy, k })

// The sheet as it was saved, if its key is still the same: true when it was read.
def sheet_load(s:Sheet, k:float) -> bool:
    let t = read_file("{BAKE_DIR}/{s.file}.txt")
    if not t: return false
    let rows = tokenize(t, "\n", "")
    if not rows.length or rows[0] != s.key: return false
    let tex = gl.load_texture("{BAKE_DIR}/{s.file}.png", pack_formats)
    if not tex: return false
    for(rows) l, n:
        if n > 0:
            let p = tokenize(l, " ", "")
            if p.length == 7:
                s.frames.push(SheetFrame { p[0], string_to_int(p[1]), string_to_int(p[2]), string_to_int(p[3]), string_to_int(p[4]), string_to_int(p[5]), string_to_int(p[6]) })
    sheet_frames(s, tex, float(gl.texture_size(tex)), k)
    return true
