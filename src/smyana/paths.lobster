// Side paths off the trail into the wood (docs/off-the-path.md; Dominic, 2026-11-13: "going off the beaten path there
// might be some other paths to the woods - again the bigger the path, more likely the patrols go there, or look
// there. They might decide to turn left and go down another path. So hiding down a path is less good").
// When a place's wood has grown (woods_grow), a few paths are cut from the trail into it: a cart track to a clearing,
// a shepherd's path, a deer track, each ending in a small clearing. A patrol on its road that comes by a path's mouth
// looks down it, and may turn down it and back, the more likely the bigger it is. The same place cuts the same paths.
import smyana.route

let PATH_TRACK = 2  // a cart track: two wide, worn, its edges cleared
let PATH_SHEEP = 1  // a shepherd's path: one wide, worn
let PATH_DEER = 0   // a deer track: a gap through the trees, no more

class SidePath:
    size:int
    cells:[int]  // from its mouth on the trail to its end

var side_paths = []::SidePath
let paths_looked = dictionary<int, int>(64)  // a patrol's first man * 64 + a path: it has come by that path's mouth

def path_hash(n:int) -> int:
    var v = (n * 2654435761 + 7919) & 0xFFFFFFFF
    v = ((v ^ (v >> 15)) * 0x2C1B3C6D) & 0xFFFFFFFF
    return (v ^ (v >> 12)) & 0xFFFFFF

// Cut `count` side paths in the place: called when its wood has grown (woods_grow).
def paths_cut(count:int, seed:int):
    side_paths = []
    paths_looked.clear()
    if count <= 0: return
    let trail = str_index(tr_names, "trail")
    let old = str_index(tr_names, "tree")
    let young = str_index(tr_names, "young_tree")
    let grass = str_index(tr_names, "grass")
    let rim = gint(su_map, "rim", 0)
    let edge = rim + 6
    def inside(x:int, y:int) -> bool: return x >= edge and y >= edge and x < W - edge and y < H - edge
    def woody(t:int) -> bool: return t == old or t == young or t == grass
    // (no path near a gate: the ground the men come in and go out by stays as the map draws it)
    def by_gate(x:int, y:int) -> bool:
        for(gate_rects) r: if abs(x - (r[0] + r[2]) / 2) + abs(y - (r[1] + r[3]) / 2) < 18: return true
        return false
    // (where a path may leave the trail: a trail tile well inside the place, away from the gates)
    let mouths = []::int
    for(terrain) t, c:
        if t == trail and inside(c % W, c / W):
            if not by_gate(c % W, c / W): mouths.push(c)
    if not mouths.length: return
    let taken = []::int
    def cut(c:int, worn:bool):
        if terrain[c] == old or terrain[c] == young or (worn and terrain[c] == grass): set_terrain(c, if worn: trail else: grass)
    let dirs = [ int2 { 1, 0 }, int2 { 1, 1 }, int2 { 0, 1 }, int2 { -1, 1 }, int2 { -1, 0 }, int2 { -1, -1 }, int2 { 0, -1 }, int2 { 1, -1 } ]
    var tries = 0
    while side_paths.length < count and tries < count * 40:
        tries++
        let m = mouths[path_hash(seed * 131 + tries) % mouths.length]
        let mx = m % W
        let my = m / W
        var crowded = false
        for(taken) t: if abs(t % W - mx) + abs(t / W - my) < 14: crowded = true
        if crowded: continue
        // (the way into the wood: the one of the eight with no trail ahead and the most trees)
        var best = -1
        var best_n = 0
        for(dirs) d, k:
            var n = 0
            var clear = true
            for(10) s:
                let x = mx + d.x * (s + 2)
                let y = my + d.y * (s + 2)
                if not inside(x, y):
                    clear = false
                    break
                let t = terrain[y * W + x]
                if t == trail or not woody(t) or level[y * W + x] != level[m]: clear = false
                if t == old or t == young: n++
            if clear and n > best_n + (path_hash(seed + tries * 8 + k) % 3):
                best = k
                best_n = n
        if best < 0 or best_n < 3: continue
        // (big paths are fewest: one track, then shepherd's paths and deer tracks)
        let size = if side_paths.length == 0: PATH_TRACK elif side_paths.length % 2 == 1: PATH_SHEEP else: PATH_DEER
        let len = [ 12, 18, 26 ][size] + path_hash(seed + tries * 3) % 8
        // the walk: on from the mouth, turning a little as it goes
        var hx = float(dirs[best].x)
        var hy = float(dirs[best].y)
        let hl = sqrt(hx * hx + hy * hy)
        hx /= hl
        hy /= hl
        var px = float(mx) + 0.5
        var py = float(my) + 0.5
        var a = 0.0
        let cells = [ m ]
        for(len * 2) s:
            if cells.length > len: break
            a += (float(path_hash(seed * 7 + tries * 97 + s) % 1000) / 1000.0 - 0.5) * 40.0 - a * 0.25
            let dx = hx * cos(a) - hy * sin(a)
            let dy = hx * sin(a) + hy * cos(a)
            px += dx * 0.7
            py += dy * 0.7
            let x = int(px)
            let y = int(py)
            if not inside(x, y) or by_gate(x, y): break
            let c = y * W + x
            if c == cells[cells.length - 1]: continue
            if not woody(terrain[c]) and terrain[c] != trail: break
            if level[c] != level[m]: break
            if terrain[c] == trail and cells.length > 3: break
            // (a step across a corner: the tile beside it too, so the path is one worn line, not stepping stones)
            let last = cells[cells.length - 1]
            if last % W != x and last / W != y: cells.push(last / W * W + x)
            cells.push(c)
        if cells.length < len / 2: continue
        taken.push(m)
        side_paths.push(SidePath { size, cells })
        print "path: {[ "deer track", "sheep path", "cart track" ][size]} from {mx},{my} to {cells[cells.length - 1] % W},{cells[cells.length - 1] / W}, {cells.length} tiles"
        // cut it: the path, its edges for a track, and a clearing at its end
        for(cells) c, n:
            if n > 0:
                cut(c, size != PATH_DEER)
                // (a track is two wide; a track's and a sheep path's sides are clear of trees, a deer track's not)
                if size == PATH_TRACK: cut(c + 1, true)
                if size != PATH_DEER:
                    for([ -1, 1, -W, W, 2, W + 1 ]) o:
                        if c + o >= 0 and c + o < W * H and abs((c + o) % W - c % W) <= 2: cut(c + o, false)
        let end = cells[cells.length - 1]
        let r = size + 1
        for(r * 2 + 1) j:
            for(r * 2 + 1) i:
                let x = end % W + i - r
                let y = end / W + j - r
                if inside(x, y) and (i - r) * (i - r) + (j - r) * (j - r) <= r * r + 1: cut(y * W + x, false)

// Whether a man is on a side path (or its clearing), and which.
def path_of(c:int) -> int:
    for(side_paths) sp, k: if (find(sp.cells) pc: abs(pc % W - c % W) <= sp.size / 2 + 1 and abs(pc / W - c / W) <= sp.size / 2 + 1) >= 0: return k
    return -1

// The points a patrol walks to go down path k and back to its mouth (milli-tiles, x and y).
def path_walk(k:int) -> [int]:
    let cells = side_paths[k].cells
    let out = []::int
    var n = 3
    while n < cells.length:
        out.push((cells[n] % W) * TILE + TILE / 2)
        out.push((cells[n] / W) * TILE + TILE / 2)
        n += 4
    let end = cells[cells.length - 1]
    out.push((end % W) * TILE + TILE / 2)
    out.push((end / W) * TILE + TILE / 2)
    // (and back)
    var back = out.length / 2 - 2
    while back >= 0:
        out.push(out[back * 2])
        out.push(out[back * 2 + 1])
        back--
    out.push((cells[0] % W) * TILE + TILE / 2)
    out.push((cells[0] / W) * TILE + TILE / 2)
    return out

// A patrol's leader at (x, y): the path whose mouth he has just come by, that he has not come by before, or -1.
def path_mouth_by(first:int, x:int, y:int) -> int:
    for(side_paths) sp, k:
        let m = sp.cells[0]
        let mx = (m % W) * TILE + TILE / 2
        let my = (m / W) * TILE + TILE / 2
        if (x - mx) * (x - mx) + (y - my) * (y - my) <= sq3() and not paths_looked.get(first * 64 + k, 0):
            paths_looked.set(first * 64 + k, 1)
            return k
    return -1

def sq3() -> int: return 3 * TILE * 3 * TILE

// A patrol on its road (threats.lobster's patrol_think) comes by a path's mouth: it looks down it, and a man seen on
// it brings them to look; or it may turn down it, and back. Whether it did either.
def patrol_by_path(first:int, x:int, y:int, sight:int) -> int, [int]:
    let k = path_mouth_by(first, x, y)
    if k < 0: return -1, []
    let sp = side_paths[k]
    for(men) m:
        if m.alive:
            let i = index_of(m.uid)
            if i >= 0 and path_of(cell_of(u_x[i], u_y[i])) == k and dist2(u_x[i], u_y[i], x, y) <= sq(sight * 2): return i, []
    let go = gint(gobj(lib_data("woods.json"), "patrol_down_path"), [ "deer", "sheep", "track" ][sp.size], 0)
    if path_hash(first * 31 + k * 7 + tick) % 100 < go: return -1, path_walk(k)
    return -1, []
