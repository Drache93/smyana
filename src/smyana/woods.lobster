// The woods grown when a place is loaded (docs/woods.md, D-100; Dominic, 2026-11-12: "a few trees popped here and
// there and a few plants popped here and there just doesn't give that feeling. It should feel dense and rich and
// alive."). The map draws where the wood is with its trees; here the wood is grown out from them as a wood grows:
// thick in clumps and thinner between, with a gap here and there, a mantle of young trees at its edge toward the open,
// a group of trees now and then out in the meadow, and the rim beyond play wooded. The trail, the gates, the camp,
// the ruins, the bridges and the cliffs' edges are left clear. The same place grows the same wood every time.
var woods_grown = 0  // (how many trees the last place grew: for a look, and the run check)

def woods_hash(n:int) -> int:
    var v = (n * 2654435761 + 40503) & 0xFFFFFFFF
    v = ((v ^ (v >> 15)) * 0x2C1B3C6D) & 0xFFFFFFFF
    return (v ^ (v >> 12)) & 0xFFFFFF

def woods_roll(n:int) -> float: return float(woods_hash(n)) / 16777216.0

// A smooth field over the tiles, 0..1, `size` tiles to a swell: where the wood is thick and where thinner.
def woods_field(x:int, y:int, size:float, seed:int) -> float:
    let fx = float(x) / size
    let fy = float(y) / size
    let ix = int(floor(fx))
    let iy = int(floor(fy))
    let u = fx - float(ix)
    let v = fy - float(iy)
    let su = u * u * (3.0 - 2.0 * u)
    let sv = v * v * (3.0 - 2.0 * v)
    def at(i:int, j:int) -> float: return woods_roll(i * 7919 + j * 104729 + seed * 31)
    return (at(ix, iy) * (1.0 - su) + at(ix + 1, iy) * su) * (1.0 - sv) + (at(ix, iy + 1) * (1.0 - su) + at(ix + 1, iy + 1) * su) * sv

def woods_grow():
    let cfg = lib_data("woods.json")
    let own = gobj(gobj(cfg, "places"), place_now())
    def num(k:string, d:float) -> float: return if has(own, k): as_float(at(own, k)) elif has(cfg, k): as_float(at(cfg, k)) else: d
    woods_grown = 0
    if num("off", 0.0) > 0.0: return
    let old = str_index(tr_names, "tree")
    let young = str_index(tr_names, "young_tree")
    let grass = str_index(tr_names, "grass")
    let trail = str_index(tr_names, "trail")
    let ford = str_index(tr_names, "ford")
    // what's left clear
    let keep = map(W * H): false
    def clear_round(x0:int, y0:int, x1:int, y1:int, r:int):
        for(y1 - y0 + 1 + r * 2) j:
            for(x1 - x0 + 1 + r * 2) i:
                let x = x0 - r + i
                let y = y0 - r + j
                if x >= 0 and y >= 0 and x < W and y < H: keep[y * W + x] = true
    let kt = int(num("keep_trail", 1.0))
    let ks = int(num("keep_set", 4.0))
    for(terrain) t, c:
        if t == trail or t == ford: clear_round(c % W, c / W, c % W, c / W, kt)
        // (a cliff's edge, top or foot, and a ramp: no tree on the step)
        let x = c % W
        let y = c / W
        for([ int2 { 1, 0 }, int2 { 0, 1 } ]) d:
            if x + d.x < W and y + d.y < H and level[c] != level[(y + d.y) * W + x + d.x]:
                keep[c] = true
                keep[(y + d.y) * W + x + d.x] = true
    // (a patrol's road through the place: it is a road, walked)
    let road = glist(gobj(leg_now(), "patrol"), "road")
    for(road.length / 2 - 1) k:
        let x0 = as_int(road[k * 2])
        let y0 = as_int(road[k * 2 + 1])
        let x1 = as_int(road[k * 2 + 2])
        let y1 = as_int(road[k * 2 + 3])
        let n = max(abs(x1 - x0), abs(y1 - y0))
        for(n + 1) s:
            let x = x0 + (x1 - x0) * s / max(1, n)
            let y = y0 + (y1 - y0) * s / max(1, n)
            clear_round(x, y, x, y, kt)
    for(gate_rects) r: clear_round(r[0], r[1], r[2], r[3], int(num("keep_gate", 3.0)))
    for(glist(su_map, "starts")) s: clear_round(as_int(s.a[0]), as_int(s.a[1]), as_int(s.a[0]), as_int(s.a[1]), ks)
    for([ "camp", "ruins" ]) key:
        for(glist(su_map, key)) e:
            let x = as_int(e.a[1]) / 1000
            let y = as_int(e.a[2]) / 1000
            clear_round(x, y, x, y, ks)
    for(glist(su_map, "bridges")) b: clear_round(as_int(b.a[0]), as_int(b.a[1]), as_int(b.a[2]), as_int(b.a[3]), ks)
    // how wooded the map draws the ground round each tile (a sum over a square of tiles, read from a running total)
    let reach = int(num("reach", 3.0))
    let sums = map((W + 1) * (H + 1)): 0
    for(H) y:
        var row = 0
        for(W) x:
            let t = terrain[y * W + x]
            if t == old or t == young: row++
            sums[(y + 1) * (W + 1) + x + 1] = sums[y * (W + 1) + x + 1] + row
    def drawn(x:int, y:int) -> float:
        let x0 = max(0, x - reach)
        let y0 = max(0, y - reach)
        let x1 = min(W, x + reach + 1)
        let y1 = min(H, y + reach + 1)
        let n = sums[y1 * (W + 1) + x1] - sums[y0 * (W + 1) + x1] - sums[y1 * (W + 1) + x0] + sums[y0 * (W + 1) + x0]
        return float(n) / float(max(1, (x1 - x0) * (y1 - y0)))
    let rim = gint(su_map, "rim", 0)
    let wood_at = num("wood_at", 0.06)
    let closed_at = num("closed_at", 0.16)
    let share = map(W * H) c: drawn(c % W, c / W)
    def in_rim(c:int) -> bool:
        let x = c % W
        let y = c / W
        return x < rim or y < rim or x >= W - rim or y >= H - rim
    let wooded = map(W * H) c: in_rim(c) or share[c] >= wood_at
    // (the wood's edge: within edge_tiles of open grass)
    let et = int(num("edge_tiles", 2.0))
    def at_edge(c:int) -> bool:
        let x = c % W
        let y = c / W
        for(et * 2 + 1) j:
            for(et * 2 + 1) i:
                let u = x + i - et
                let v = y + j - et
                if u >= 0 and v >= 0 and u < W and v < H and not wooded[v * W + u] and terrain[v * W + u] == grass: return true
        return false
    let size = num("clump_tiles", 7.0)
    let clump = num("clump", 0.75)
    let seed = gint(su_map, "grass_seed", 9001)
    let grown = []::int
    def grow(c:int, k:int):
        set_terrain(c, k)
        grown.push(c)
    for(terrain) t, c:
        if t != grass or keep[c]: continue
        let x = c % W
        let y = c / W
        let n = woods_field(x, y, size, seed)
        var p_old = 0.0
        var p_young = 0.0
        if in_rim(c):
            p_old = num("rim", 0.7) * (0.6 + 0.8 * n)
        elif wooded[c]:
            if at_edge(c):
                p_old = num("edge_old", 0.12)
                p_young = num("edge_young", 0.3)
            else:
                let deep = woods_smooth(wood_at, closed_at, share[c])
                p_old = num("closed", 0.5) * (0.45 + 0.55 * deep) * (1.0 - clump + 2.0 * clump * n)
                p_young = num("young", 0.1)
        let r = woods_roll(c * 3 + seed)
        if r < p_old: grow(c, old)
        elif r < p_old + p_young: grow(c, young)
    // out in the meadows: a group of a few trees now and then, close together
    let groups = num("groups", 0.006)
    let gsize = int(num("group_size", 4.0))
    for(terrain) t, c:
        if t == grass and not keep[c] and not wooded[c] and woods_roll(c * 5 + seed + 1) < groups:
            for(gsize) k:
                let h = woods_hash(c * 11 + k)
                let x = c % W + h % 5 - 2
                let y = c / W + (h / 5) % 5 - 2
                if x >= 0 and y >= 0 and x < W and y < H:
                    let g = y * W + x
                    if terrain[g] == grass and not keep[g]: grow(g, if k == 0 or (h / 25) % 3 != 0: old else: young)
    // no pocket of open ground the wood has closed round: what was open stays reachable from the gates (the trees
    // grown round a pocket are taken out again, ring by ring, until it opens onto the rest)
    let was_grown = map(W * H): false
    for(grown) c: was_grown[c] = true
    for(12):
        let reached = map(W * H): false
        var todo = []::int
        for(gate_rects) r:
            for(r[3] - r[1] + 1) j:
                for(r[2] - r[0] + 1) i:
                    let c = (r[1] + j) * W + r[0] + i
                    if c >= 0 and c < W * H and walks[0][c] == 1 and not reached[c]:
                        reached[c] = true
                        todo.push(c)
        while todo.length:
            let c = todo.pop()
            for([ -1, 1, -W, W ]) d:
                let n = c + d
                if n >= 0 and n < W * H and abs(n % W - c % W) <= 1 and walks[0][n] == 1 and not reached[n]:
                    reached[n] = true
                    todo.push(n)
        var opened = 0
        for(W * H) c:
            if walks[0][c] == 1 and not reached[c] and not in_rim(c):
                for([ -1, 1, -W, W ]) d:
                    let n = c + d
                    if n >= 0 and n < W * H and abs(n % W - c % W) <= 1 and was_grown[n]:
                        set_terrain(n, grass)
                        was_grown[n] = false
                        opened++
        if opened == 0: break
    woods_grown = 0
    for(was_grown) g: if g: woods_grown++

def woods_smooth(a:float, b:float, x:float) -> float:
    let t = clamp((x - a) / max(b - a, 0.0001), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)
