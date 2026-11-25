#!/usr/bin/env python3
"""Makes the camp's voxel models (art/camp/vox/): the two tents, the fireplace, the woodpile, the riding horses and the
pack mules, from the autumn camp mock-up (archive/images/2026-11-10/62, left; Dominic's request of 2026-11-10: "the
tents, fireplace, and our horses"). A voxel is one pixel of the game's art, as the men's and the trees' are (VOX_K in
src/smyana/trees.lobster), so a man is 49 voxels and a metre 28. Sizes are the mock-up's, measured in men (a
little bigger than real Rhodope ponies and tents). Each model stands on z = 0 round x = y = 0; the animals face +x. The colours are the palette's own: the game
lights them (src/smyana/camp.lobster). Run from the repo's root: python3 tools/camp_vox.py   (numpy)"""
import math, os, random, struct, sys
import numpy as np

M = 28.0  # voxels a metre (a man of 1.75 m is 49 voxels)
OUT = "art/camp/vox"

# ---- the palette -----------------------------------------------------------------------------------------------
NAMES = ["CANVAS", "CANVAS2", "CANVAS3", "INSIDE", "POLE", "POLE2", "ROPE",
         "RED", "BLACK", "WHITE", "OCHRE", "BROWN", "BLUE", "GREEN",
         "STONE", "STONE2", "STONE3", "ASH", "ASH2", "CHAR", "EMBER", "COPPER", "COPPER2", "IRON", "WOOD", "WOOD2",
         "BAY", "BAY2", "HAIR", "GREY", "GREY2", "CHESTNUT", "CHESTNUT2", "DUN", "DUN2", "MUZZLE", "HOOF", "EYE",
         "LEATHER", "LEATHER2", "FELT", "SACK", "SACK2", "BLANKET", "BRASS", "WICKER", "WICKER2", "BLANKET2", "GREY3", "LOG", "LOG2", "CUT",
         "COAT", "COAT2", "FEZ", "SKIN", "SASH"]
COLOURS = [0xd6ccb4, 0xbcb198, 0x9c9078, 0x2a231d, 0x6e4e32, 0x4e3624, 0xb2a282,
           0xa33328, 0x2a2522, 0xe0d6be, 0xc08a3a, 0x6b4a30, 0x2c3a52, 0x4c5a36,
           0x8d877e, 0x6f6a62, 0xa8a296, 0x5c5852, 0x8a857c, 0x1f1b18, 0xb4481c, 0xb0683a, 0x7a4428, 0x3c3e41, 0x8a6440, 0x6a4a2e,
           0x6a3e24, 0x55301c, 0x1e1916, 0xc8c3b8, 0xa29e95, 0x8c4c26, 0x6e3a1c, 0x8a7458, 0x6c5a44, 0xb5a48c, 0x2a2420, 0x120e0c,
           0x6b4a2e, 0x4a3220, 0x5e4a38, 0xb59a74, 0x957c5c, 0xa8302a, 0xc49a48, 0x9a7a48, 0x7a5e34, 0x2c3444, 0x8a857e, 0xa0825c, 0x8a6c4a, 0xd8c49a,
           0x3454a8, 0x28407e, 0xc22a20, 0xc79a78, 0xd9b03c]
for _i, _n in enumerate(NAMES): globals()[_n] = _i + 1

# ---- a grid to draw in -----------------------------------------------------------------------------------------
class Model:
    def __init__(self, x, y, z):  # half sizes in metres along x and y, height z
        self.o = np.array([int(x * M) + 2, int(y * M) + 2, 0])
        self.v = np.zeros((self.o[0] * 2, self.o[1] * 2, int(z * M) + 2), np.uint8)
        self.g = None

    def grid(self, lo, hi):
        """the voxel centres (in metres) inside lo..hi, and the slice they are"""
        a = np.maximum(np.floor(np.array(lo) * M).astype(int) + self.o, 0)
        b = np.minimum(np.ceil(np.array(hi) * M).astype(int) + self.o + 1, self.v.shape)
        if (b <= a).any(): return None, None
        g = np.stack(np.meshgrid(*[(np.arange(a[i], b[i]) - self.o[i] + 0.5) / M for i in range(3)], indexing="ij"), -1)
        return g, (slice(a[0], b[0]), slice(a[1], b[1]), slice(a[2], b[2]))

    def put(self, lo, hi, inside, idx, over=True):
        g, s = self.grid(lo, hi)
        if g is None: return
        m = inside(g)
        sub = self.v[s]
        if callable(idx): idx = idx(g)
        if not over: m = m & (sub == 0)
        if np.isscalar(idx): sub[m] = idx
        else: sub[m] = np.asarray(idx)[m]

    def capsule(self, a, b, ra, rb, idx, over=True):
        a, b = np.array(a, float), np.array(b, float)
        r = max(ra, rb) + 1.0 / M
        ab = b - a
        def inside(g):
            t = np.clip(((g - a) @ ab) / max(ab @ ab, 1e-9), 0, 1)
            d = np.linalg.norm(g - a - t[..., None] * ab, axis=-1)
            return d <= ra + (rb - ra) * t + 0.35 / M
        self.put(np.minimum(a, b) - r, np.maximum(a, b) + r, inside, idx, over)

    def blob(self, c, r, idx, over=True, turn=0.0):  # an ellipsoid, radii r, turned about z
        c, r = np.array(c, float), np.array(r, float)
        ca, sa = math.cos(math.radians(turn)), math.sin(math.radians(turn))
        def inside(g):
            d = g - c
            u = d[..., 0] * ca + d[..., 1] * sa
            v = -d[..., 0] * sa + d[..., 1] * ca
            return (u / r[0]) ** 2 + (v / r[1]) ** 2 + (d[..., 2] / r[2]) ** 2 <= 1.0
        R = max(r[0], r[1])
        self.put(c - [R, R, r[2]], c + [R, R, r[2]], inside, idx, over)

    def box(self, lo, hi, idx, over=True):
        self.put(lo, hi, lambda g: np.ones(g.shape[:3], bool), idx, over)

    def voxels(self):
        out = {}
        for x, y, z in zip(*np.nonzero(self.v)):
            out[(int(x - self.o[0]), int(y - self.o[1]), int(z))] = int(self.v[x, y, z])
        return out


def rope(m, a, b, idx=ROPE):  # a line a voxel thick
    a, b = np.array(a, float), np.array(b, float)
    n = int(np.linalg.norm(b - a) * M * 2) + 1
    for t in np.linspace(0, 1, n):
        p = np.floor((a + (b - a) * t) * M).astype(int) + m.o
        if all(0 <= p[i] < m.v.shape[i] for i in range(3)): m.v[tuple(p)] = idx


def peg(m, at):
    m.capsule((at[0], at[1], 0.0), (at[0], at[1], 0.1), 0.02, 0.02, POLE2)

# ---- the tents -------------------------------------------------------------------------------------------------
def tent0():
    """A canvas A-frame, as soldiers' and carters' tents were: about 3.5 m long and 2.6 m high at the poles (the mock-up's size: a man and a half), the ridge
    sagging between them, a pair of crossed poles at each end standing out above it, the front flaps tied back on a
    dark inside with bedrolls in it, guy ropes to pegs. The canvas greyed and stained low down."""
    L, W, H = 1.75, 1.4, 2.6
    m = Model(2.6, 2.2, 3.0)
    rng = random.Random(7)
    def ridge(x): return H - 0.12 * math.cos(math.pi * x / (2 * L))  # (high at the poles, sagging between)
    def sheet(g):
        x, y, z = g[..., 0], g[..., 1], g[..., 2]
        h = H - 0.12 * np.cos(np.pi * x / (2 * L))
        s = W * (1.0 - z / h) + 0.04 * np.sin(np.pi * z / h)  # (a little belly in the canvas)
        return (np.abs(x) <= L) & (z <= h) & (np.abs(y) <= s) & (np.abs(y) >= s - 2.2 / M)
    def shade(g):
        x, z = g[..., 0], g[..., 2]
        c = np.full(g.shape[:3], CANVAS, np.uint8)
        c[(np.abs(((x + L) * M) % 15 - 7.5) < 0.5)] = CANVAS2   # the seams between the canvas's widths
        c[z < 0.16 + 0.05 * np.sin(x * 9.0)] = CANVAS3          # mud splashed up the hem
        c[(z > 0.55) & (z < 0.8) & (x > 0.2) & (x < 0.5)] = CANVAS2  # a patch
        return c
    m.put((-L - 0.1, -W - 0.2, 0), (L + 0.1, W + 0.2, H + 0.1), sheet, shade)
    # the back end closed with a triangle; the front's flaps folded back against the sides
    def end(g):
        y, z = g[..., 1], g[..., 2]
        return np.abs(y) <= W * (1.0 - z / H) + 0.02
    m.put((-L - 0.04, -W, 0), (-L, W, H), end, CANVAS2)
    for s in (-1, 1):
        def flap(g, s=s):
            x, y, z = g[..., 0], g[..., 1], g[..., 2]
            s0 = W * (1.0 - z / H)
            return (x > L - 0.05) & (x < L + 0.5 * (1 - z / H)) & (np.abs(y * s - s0 - 0.06) < 1.1 / M) & (z < H * 0.8)
        m.put((L - 0.1, -W - 0.2, 0), (L + 0.6, W + 0.2, H), flap, CANVAS2)
    # inside: the dark of it, and two bedrolls
    m.box((-L + 0.05, -W + 0.2, 0.0), (L - 0.05, W - 0.2, 0.03), INSIDE)
    m.capsule((L - 0.25, -0.35, 0.1), (L - 1.5, -0.35, 0.1), 0.1, 0.1, BROWN, over=False)
    m.capsule((L - 0.3, 0.3, 0.1), (L - 1.4, 0.3, 0.1), 0.1, 0.1, RED, over=False)
    # the poles: a crossed pair at each end, the ridge pole in their fork
    for x in (-L - 0.03, L + 0.03):
        for s in (-1, 1):
            m.capsule((x, s * 0.14, 0.0), (x, -s * 0.12, H + 0.28), 0.03, 0.025, POLE)
    m.capsule((-L - 0.15, 0, H + 0.02), (L + 0.15, 0, H + 0.02), 0.03, 0.03, POLE2)
    # guy ropes from the pole tops to pegs, and pegs along the hem
    for x in (-L, L):
        d = 1 if x > 0 else -1
        rope(m, (x + d * 0.04, 0, H + 0.1), (x + d * 0.75, 0, 0.04))
        peg(m, (x + d * 0.75, 0))
    for x in np.linspace(-L + 0.1, L - 0.1, 4):
        for s in (-1, 1): peg(m, (x, s * (W + 0.05)))
    return m


def stripes(t):
    """a Rhodope rug's bands (cherga), across its width t (0..1): red grounds, black and white bands, ochre, blue"""
    bands = [(RED, 6), (BLACK, 2), (WHITE, 2), (BLACK, 2), (RED, 5), (OCHRE, 2), (BLUE, 3), (WHITE, 1), (RED, 6),
             (BLACK, 3), (WHITE, 2), (GREEN, 2), (RED, 5), (BLACK, 2), (WHITE, 2), (BLACK, 2), (RED, 6)]
    total = sum(n for _, n in bands)
    k = np.clip(t, 0, 0.9999) * total
    out = np.zeros(np.shape(t), np.uint8)
    at = 0
    for c, n in bands:
        out[(k >= at) & (k < at + n)] = c
        at += n
    return out


def tent1():
    """A lean-to of striped wool rugs (chergi) thrown over a ridge pole on two forked sticks, the back down to the
    ground and held there with stones, a short fringe hanging at the front; open at both ends, the men's packs and a
    bedroll under it. About 4 m long and 1.9 m high, as in the mock-up."""
    L, H, back, front = 2.0, 1.9, 1.7, 0.45
    m = Model(2.5, 2.3, 2.3)
    def slope(g):
        x, y, z = g[..., 0], g[..., 1], g[..., 2]
        t = np.clip((0.3 - y) / (0.3 + back), 0, 1)  # 0 at the ridge, 1 at the ground behind
        h = H * (1 - t) - 0.06 * np.sin(np.pi * t) * (1 - 0.3 * np.cos(np.pi * x / L))
        return (np.abs(x) <= L) & (y <= 0.3) & (y >= -back) & (z <= h) & (z >= h - 2.2 / M)
    def slope_col(g):
        y = g[..., 1]
        return stripes((0.3 - y) / (0.3 + back + front))
    m.put((-L, -back - 0.05, 0), (L, 0.32, H + 0.1), slope, slope_col)
    # the front: hanging down from the ridge, its fringe below
    def hang(g):
        x, y, z = g[..., 0], g[..., 1], g[..., 2]
        return (np.abs(x) <= L) & (np.abs(y - 0.34 - (H - z) * 0.15) <= 1.1 / M) & (z <= H) & (z >= H - front)
    def hang_col(g):
        z = g[..., 2]
        return stripes((0.3 + back + (H - z)) / (0.3 + back + front))
    m.put((-L, 0.25, H - front - 0.05), (L, 0.45, H + 0.05), hang, hang_col)
    for x in np.arange(-L + 0.02, L, 2.0 / M):
        n = 2 + (int(x * M * 7) % 3)
        for k in range(n):
            p = (int(x * M) + m.o[0], int((0.33 + front * 0.15) * M) + m.o[1], int((H - front) * M) - 1 - k)
            m.v[p] = WHITE if k < n - 1 else RED
    # the frame: two forked sticks and the ridge pole
    for x in (-L - 0.05, L + 0.05):
        m.capsule((x, 0.3, 0), (x, 0.3, H + 0.02), 0.03, 0.028, POLE)
        m.capsule((x, 0.3, H - 0.05), (x + 0.06 * (1 if x > 0 else -1), 0.3, H + 0.15), 0.02, 0.018, POLE)
    m.capsule((-L - 0.2, 0.3, H + 0.04), (L + 0.2, 0.3, H + 0.04), 0.03, 0.03, POLE2)
    # stones on the back hem
    rng = random.Random(3)
    for x in np.linspace(-L + 0.15, L - 0.15, 8):
        m.blob((x + rng.uniform(-0.08, 0.08), -back - 0.02, 0.03), (0.09, 0.07, 0.06), rng.choice([STONE, STONE2, STONE3]), turn=rng.uniform(0, 180))
    # under it: two packs and a bedroll
    m.blob((-0.6, -0.2, 0.18), (0.2, 0.15, 0.18), SACK, over=False)
    m.blob((-0.15, -0.3, 0.14), (0.16, 0.13, 0.14), SACK2, over=False)
    m.capsule((0.25, -0.05, 0.1), (1.1, -0.05, 0.1), 0.1, 0.1, BROWN, over=False)
    return m

# ---- the fireplace ---------------------------------------------------------------------------------------------
def fireplace():
    """A ring of split gneiss stones round a bed of ash, the ends of three logs pushed in toward the middle (the
    fire itself is the game's own, D-038), and over it a tripod of poles lashed at the top, a chain down to a copper
    cauldron (kotel). The ring about 1 m across, the tripod 1.6 m high."""
    m = Model(1.0, 1.0, 1.8)
    rng = random.Random(11)
    # the ash, a little proud of the ground
    m.blob((0, 0, 0.0), (0.38, 0.38, 0.05), ASH)
    m.blob((0.05, -0.04, 0.0), (0.2, 0.2, 0.06), ASH2)
    for k in range(10):
        a = math.radians(k * 36 + rng.uniform(-8, 8))
        r = 0.46 + rng.uniform(-0.03, 0.03)
        m.blob((r * math.cos(a), r * math.sin(a), 0.03), (rng.uniform(0.1, 0.13), rng.uniform(0.07, 0.09), rng.uniform(0.07, 0.1)),
               rng.choice([STONE, STONE2, STONE3]), turn=math.degrees(a) + 90 + rng.uniform(-15, 15))
    # three log ends, charred where they reach the fire
    for k in range(3):
        a = math.radians(k * 120 + 30)
        out = (0.62 * math.cos(a), 0.62 * math.sin(a), 0.08)
        inn = (0.12 * math.cos(a), 0.12 * math.sin(a), 0.05)
        mid = (0.3 * math.cos(a), 0.3 * math.sin(a), 0.07)
        m.capsule(out, mid, 0.05, 0.05, WOOD2)
        m.capsule(mid, inn, 0.05, 0.04, CHAR)
        m.capsule((inn[0] * 1.1, inn[1] * 1.1, 0.05), inn, 0.035, 0.03, EMBER)
    # the tripod
    top = (0.0, 0.0, 1.62)
    for k in range(3):
        a = math.radians(k * 120 + 90)
        m.capsule((0.75 * math.cos(a), 0.75 * math.sin(a), 0.0), (top[0] - 0.08 * math.cos(a), top[1] - 0.08 * math.sin(a), top[2] + 0.12), 0.036, 0.03, POLE)
    m.blob((0, 0, 1.6), (0.05, 0.05, 0.06), ROPE)
    # the chain and the cauldron
    for z in np.arange(1.06, 1.56, 2.0 / M):
        m.v[m.o[0], m.o[1], int(z * M)] = IRON
    m.capsule((-0.15, 0, 1.0), (0, 0, 1.08), 0.008, 0.008, IRON)
    m.capsule((0.15, 0, 1.0), (0, 0, 1.08), 0.008, 0.008, IRON)
    m.blob((0, 0, 0.9), (0.17, 0.17, 0.15), lambda g: np.where(g[..., 2] < 0.82, CHAR, COPPER))
    m.box((-0.18, -0.18, 0.97), (0.18, 0.18, 1.06), 0)  # (its open top)
    m.blob((0, 0, 0.96), (0.13, 0.13, 0.02), INSIDE)
    m.capsule((-0.155, 0, 0.97), (0.155, 0, 0.97), 0.02, 0.02, COPPER2)  # the rim
    return m


def woodpile():
    """Firewood the men have cut (fresh split wood, light, so it reads in shade): split logs stacked crosswise on two bearers, a chopping block beside, an axe in it."""
    m = Model(0.9, 0.7, 0.8)
    rng = random.Random(5)
    for s in (-1, 1): m.capsule((-0.55, s * 0.22, 0.05), (0.55, s * 0.22, 0.05), 0.05, 0.05, LOG2)
    for row in range(4):
        n = 6 - row
        for i in range(n):
            x = (i - (n - 1) / 2) * 0.17
            z = 0.15 + row * 0.13
            m.capsule((x, -0.35, z), (x + rng.uniform(-0.03, 0.03), 0.35, z), 0.065, 0.065, rng.choice([LOG, LOG2]))
            m.capsule((x, 0.33, z), (x, 0.36, z), 0.055, 0.055, CUT)  # (the cut ends, pale)
    m.capsule((0.75, -0.35, 0), (0.75, -0.35, 0.32), 0.17, 0.17, LOG2)
    m.blob((0.75, -0.35, 0.32), (0.15, 0.15, 0.02), CUT)
    m.capsule((0.75, -0.35, 0.36), (0.72, -0.15, 0.62), 0.016, 0.016, WOOD)
    m.box((0.68, -0.4, 0.3), (0.82, -0.32, 0.4), IRON)
    return m

# ---- the shepherds' hut ---------------------------------------------------------------------------------------
def hut():
    """An empty shepherds' hut at a side path's end (smyana/finds.lobster): walls of dry-stacked gneiss, no mortar,
    a low gable roof of split gneiss slabs on poles, one low door with a wooden lintel and no window, its hearth in the
    middle (summer-pasture huts of the Balkan mountains: dry-stacked stone, one door the only opening, the hearth in the
    middle, parksdinarides.org; the slab roofs of the Rhodope villages). About 3.6 by 3 m, the walls 1.4 m high, the
    ridge 2.3 m. The door is on -y, toward the camera."""
    X, Y, Hw, Hr = 1.8, 1.5, 1.4, 2.3
    m = Model(2.2, 1.9, 2.5)
    rng = random.Random(17)
    t = 0.32  # (the walls' thickness)
    # the walls: courses of flat stones, each its own size and tone, laid long side out
    z = 0.0
    while z < Hw:
        h = rng.uniform(0.09, 0.15)
        for side in range(4):
            along = X if side < 2 else Y
            s = -along
            while s < along:
                w = rng.uniform(0.18, 0.42)
                c = rng.choice([STONE, STONE2, STONE3, STONE, STONE2])
                a, b = s, min(s + w, along)
                if side == 0: lo, hi = (a, -Y, z), (b, -Y + t, z + h)
                elif side == 1: lo, hi = (a, Y - t, z), (b, Y, z + h)
                elif side == 2: lo, hi = (-X, a, z), (-X + t, b, z + h)
                else: lo, hi = (X - t, a, z), (X, b, z + h)
                # (a stone a little in or out of the face, the joints dark)
                d = rng.uniform(-0.03, 0.03)
                if side == 0: lo, hi = (lo[0], lo[1] + d, lo[2]), (hi[0] - 1.0 / M, hi[1], hi[2] - 1.0 / M)
                elif side == 1: lo, hi = (lo[0], lo[1], lo[2]), (hi[0] - 1.0 / M, hi[1] + d, hi[2] - 1.0 / M)
                elif side == 2: lo, hi = (lo[0] + d, lo[1], lo[2]), (hi[0], hi[1] - 1.0 / M, hi[2] - 1.0 / M)
                else: lo, hi = (lo[0], lo[1], lo[2]), (hi[0] + d, hi[1] - 1.0 / M, hi[2] - 1.0 / M)
                m.box(lo, hi, c)
                s += w
        z += h
    # the joints behind the stones, dark (what shows between them)
    for side in range(4):
        if side == 0: m.box((-X + 0.02, -Y + 0.03, 0), (X - 0.02, -Y + t - 0.02, Hw - 0.02), ASH, over=False)
        elif side == 1: m.box((-X + 0.02, Y - t + 0.02, 0), (X - 0.02, Y - 0.03, Hw - 0.02), ASH, over=False)
        elif side == 2: m.box((-X + 0.03, -Y + 0.02, 0), (-X + t - 0.02, Y - 0.02, Hw - 0.02), ASH, over=False)
        else: m.box((X - t + 0.02, -Y + 0.02, 0), (X - 0.03, Y - 0.02, Hw - 0.02), ASH, over=False)
    # the gable ends, stone up to the ridge
    for sx in (-1, 1):
        x0 = sx * X
        def gable(g, x0=x0):
            x, y, zz = g[..., 0], g[..., 1], g[..., 2]
            return (np.abs(x - x0 + sx * t / 2) <= t / 2) & (zz >= Hw) & (zz <= Hw + (Hr - Hw) * (1 - np.abs(y) / Y) - 0.05)
        m.put((x0 - t if sx > 0 else x0, -Y, Hw), (x0 if sx > 0 else x0 + t, Y, Hr), gable, lambda g: np.where((np.floor(g[..., 2] * M / 4) + np.floor(g[..., 1] * M / 9)) % 3 == 0, STONE2, STONE))
    # the door: a low dark gap in the front wall, a wooden lintel over it, a sill stone
    m.box((-0.36, -Y - 0.05, 0.0), (0.36, -Y + t + 0.02, 1.15), 0)
    m.box((-0.33, -Y + t - 0.01, 0.0), (0.33, -Y + t + 0.04, 1.12), INSIDE)
    m.box((-0.52, -Y - 0.02, 1.15), (0.52, -Y + t, 1.26), WOOD2)
    m.box((-0.4, -Y - 0.12, 0.0), (0.4, -Y + 0.02, 0.05), STONE3)
    for sx in (-1, 1): m.box((sx * 0.36 - 0.03, -Y + 0.0, 0.0), (sx * 0.36 + 0.03, -Y + 0.06, 1.15), WOOD)
    # the roof: slabs in rows, each row lapping the one below, the ridge capped, eaves out over the walls
    ov = 0.22
    rows = 6
    for side in (-1, 1):
        for r in range(rows):
            y0 = side * (Y + ov) * (1 - r / rows)
            y1 = side * (Y + ov) * (1 - (r + 1.25) / rows)
            z0 = Hw - 0.05 + (Hr - Hw + 0.05) * r / rows
            z1 = Hw - 0.05 + (Hr - Hw + 0.05) * (r + 1.25) / rows
            x = -X - ov
            while x < X + ov:
                w = rng.uniform(0.35, 0.7)
                c = rng.choice([STONE2, STONE3, STONE, STONE2, ASH2])
                xa, xb = x, min(x + w, X + ov)
                lift = rng.uniform(-0.01, 0.03)
                def slab(g, y0=y0, y1=y1, z0=z0, z1=z1, xa=xa, xb=xb, lift=lift):
                    xx, yy, zz = g[..., 0], g[..., 1], g[..., 2]
                    f = (yy - y0) / (y1 - y0)
                    want = z0 + (z1 - z0) * f + lift
                    return (xx >= xa) & (xx <= xb - 1.0 / M) & (f >= 0) & (f <= 1) & (zz >= want - 0.07) & (zz <= want)
                lo_y, hi_y = min(y0, y1), max(y0, y1)
                m.put((xa, lo_y, z0 - 0.1), (xb, hi_y, z1 + 0.1), slab, c)
                x += w
    m.box((-X - ov, -0.12, Hr - 0.03), (X + ov, 0.12, Hr + 0.08), STONE3)
    # (a gap at the ridge's middle for the smoke, sooted)
    m.box((-0.25, -0.13, Hr - 0.05), (0.25, 0.13, Hr + 0.1), 0)
    m.box((-0.25, -0.1, Hr - 0.08), (0.25, 0.1, Hr - 0.03), CHAR)
    # the poles' ends under the eaves at the gables
    for sx in (-1, 1):
        for yy in (-0.9, 0.0, 0.9):
            m.capsule((sx * (X + 0.05), yy * Y / 1.0, Hw + (Hr - Hw) * (1 - abs(yy)) - 0.08), (sx * (X + ov), yy * Y / 1.0, Hw + (Hr - Hw) * (1 - abs(yy)) - 0.08), 0.04, 0.04, POLE2)
    # stones fallen from the wall, and a flat stone by the door to sit on
    for k in range(4):
        m.blob((rng.uniform(-X, X), -Y - rng.uniform(0.15, 0.45), 0.03), (rng.uniform(0.08, 0.14), rng.uniform(0.06, 0.1), 0.06), rng.choice([STONE, STONE2, STONE3]), turn=rng.uniform(0, 180))
    m.box((0.75, -Y - 0.45, 0), (1.2, -Y - 0.15, 0.32), STONE)
    return m


# ---- the village's houses ---------------------------------------------------------------------------------------
def courses(m, rng, X, Y, z0, z1, t=0.5, dy=0.0):
    """Four walls of coursed gneiss round a box X by Y (half sizes), from z0 to z1, the joints dark behind the stones."""
    z = z0
    while z < z1:
        h = min(rng.uniform(0.12, 0.2), z1 - z)
        for side in range(4):
            along = X if side < 2 else Y
            s = -along
            while s < along:
                w = rng.uniform(0.25, 0.6)
                c = rng.choice([STONE, STONE2, STONE3, STONE, STONE2, ASH2])
                a, b = s, min(s + w, along)
                d = rng.uniform(-0.03, 0.03)
                g = 1.0 / M
                if side == 0: lo, hi = (a, -Y + d + dy, z), (b - g, -Y + t + dy, z + h - g)
                elif side == 1: lo, hi = (a, Y - t, z), (b - g, Y + d, z + h - g)
                elif side == 2: lo, hi = (-X + d, a + dy * (a < 0), z), (-X + t, b - g, z + h - g)
                else: lo, hi = (X - t, a + dy * (a < 0), z), (X + d, b - g, z + h - g)
                m.box(lo, hi, c)
                s += w
        z += h
    m.box((-X + 0.03, -Y + 0.03 + dy, z0), (X - 0.03, Y - 0.03, z1), ASH, over=False)


def slab_roof(m, rng, X, Y, Hw, Hr, ov, rows):
    """A low gable roof of split gneiss slabs (the Rhodope 'tikli'), the ridge along x, each row lapping the one below."""
    for side in (-1, 1):
        for r in range(rows):
            y0 = side * (Y + ov) * (1 - r / rows)
            y1 = side * (Y + ov) * (1 - (r + 1.25) / rows)
            z0 = Hw - 0.08 + (Hr - Hw + 0.08) * r / rows
            z1 = Hw - 0.08 + (Hr - Hw + 0.08) * (r + 1.25) / rows
            x = -X - ov
            while x < X + ov:
                w = rng.uniform(0.45, 0.95)
                c = rng.choice([STONE2, STONE3, STONE, STONE2, ASH2, STONE])
                xa, xb = x, min(x + w, X + ov)
                lift = rng.uniform(-0.02, 0.04)
                def slab(g, y0=y0, y1=y1, z0=z0, z1=z1, xa=xa, xb=xb, lift=lift):
                    xx, yy, zz = g[..., 0], g[..., 1], g[..., 2]
                    f = (yy - y0) / (y1 - y0)
                    want = z0 + (z1 - z0) * f + lift
                    return (xx >= xa) & (xx <= xb - 1.0 / M) & (f >= 0) & (f <= 1) & (zz >= want - 0.1) & (zz <= want)
                m.put((xa, min(y0, y1), z0 - 0.15), (xb, max(y0, y1), z1 + 0.15), slab, c)
                x += w
    m.box((-X - ov, -0.16, Hr - 0.04), (X + ov, 0.16, Hr + 0.09), STONE3)


def hip_roof(m, rng, X, Y, Hw, ov, pitch):
    """A low hipped roof of split gneiss slabs (the Rhodope 'tikli') with wide eaves, each row lapping the one below,
    as on the houses in Dominic's photograph of 2026-11-25."""
    EX, EY = X + ov, Y + ov
    roww = 0.42
    sd = rng.randrange(1000)
    def parts(g):
        x, y = g[..., 0], g[..., 1]
        dx, dy = EX - np.abs(x), EY - np.abs(y)
        d = np.minimum(dx, dy)
        row = np.floor(d / roww)
        return x, y, dx, dy, d, row
    def inside(g):
        x, y, dx, dy, d, row = parts(g)
        top = Hw + 0.04 + pitch * row * roww + pitch * (d - row * roww) * 0.35
        return (d >= 0) & (g[..., 2] <= top) & (g[..., 2] >= top - 0.13 - pitch * roww)
    def colour(g):
        x, y, dx, dy, d, row = parts(g)
        along = np.where(dy < dx, x, y)
        cell = np.floor((along + row * 0.31) / 0.62)
        h = np.mod((cell * 7 + row * 13 + sd).astype(int) * 2654435 // 1000, 6)
        return np.array([STONE2, STONE3, STONE, STONE2, ASH2, STONE], np.uint8)[h]
    m.put((-EX, -EY, Hw - 0.4), (EX, EY, Hw + pitch * EY + 0.3), inside, colour)
    if X > Y: m.box((-(X - Y) - 0.2, -0.18, Hw + pitch * EY - 0.02), (X - Y + 0.2, 0.18, Hw + pitch * EY + 0.1), STONE3)


def house(seed, X, Y, floors, kind):
    """A house of the men's village, as the old houses of the Western Rhodope villages are (the village is made up;
    Kovachevitsa is its model). Read: "two, three and even four storeys", "the builders used stone and wood", roofs
    "covered entirely in stone slates" (Radio Bulgaria, 30 Oct 2024); "the ground floor ... sheltering the domestic
    animals", "the very residence was located on the upper one or two floors", "bow-windows overlooking the narrow
    cobblestone streets" (bulgarianproperties.com, 2007). The look is from the photograph Dominic sent on 2026-11-25
    with "Village looks quite wrong" (archive/notes/2026-11-25-dominic-the-village-looks-wrong.md): a ground storey of
    rough stone; the storeys above plastered white, standing a little out over it, with rows of tall windows in dark
    frames, dark timber belts and corner posts; wooden galleries with plank railings and a bay of red-brown planks on
    the top storey; a low hipped roof of heavy slabs with very wide eaves and dark timber under them; white chimneys
    with slab caps. (The houses of D-166 and D-196 were bare stone to the eaves, with gabled roofs.)
    X, Y: half the footprint in metres; floors: the storeys' heights; kind: "gallery", "bay" or "both". The front is
    on -y."""
    rng = random.Random(seed)
    Hw = sum(floors)
    ov, pitch, j = 0.9, 0.4, 0.14
    Hr = Hw + pitch * (Y + ov)
    m = Model(X + ov + 0.12, Y + ov + 0.12, Hr + 1.0)
    z1 = floors[0]
    courses(m, rng, X, Y, 0.0, z1)
    # the door below: wide and low, of planks, a stone step; a slit for the byre
    dx = -X * 0.35
    m.box((dx - 0.75, -Y - 0.05, 0.0), (dx + 0.75, -Y + 0.3, 1.75), 0)
    m.put((dx - 0.72, -Y + 0.1, 0.0), (dx + 0.72, -Y + 0.2, 1.72), lambda g: g[..., 0] > -1e9,
          lambda g: np.where(np.floor(g[..., 0] * M / 4) % 2 == 0, WOOD, WOOD2))
    m.box((dx - 0.95, -Y - 0.03, 1.75), (dx + 0.95, -Y + 0.3, 1.93), WOOD2)
    m.box((dx - 0.9, -Y - 0.3, 0.0), (dx + 0.9, -Y + 0.02, 0.08), STONE3)
    m.box((X * 0.45 - 0.08, -Y - 0.05, 1.0), (X * 0.45 + 0.08, -Y + 0.12, 1.4), INSIDE)
    m.box((X - 0.12, -0.08, 1.0), (X + 0.05, 0.08, 1.4), INSIDE)
    # the storeys above: plaster, a little out over the stone
    def plaster(g):
        h = np.mod(np.floor(g[..., 0] * M * 0.37) + np.floor(g[..., 2] * M * 0.61) * 3 + np.floor(g[..., 1] * M * 0.53) * 5, 23)
        return np.where(h == 0, CANVAS, WHITE).astype(np.uint8)
    UX, UY = X + j, Y + j
    m.put((-UX, -UY, z1), (UX, UY, Hw), lambda g: g[..., 0] > -1e9, plaster)
    # timber: a belt under each storey and under the eaves, posts at the corners
    z = z1
    for f in floors[1:]:
        m.box((-UX - 0.03, -UY - 0.03, z - 0.09), (UX + 0.03, UY + 0.03, z + 0.09), WOOD2)
        z += f
    m.box((-UX - 0.03, -UY - 0.03, Hw - 0.2), (UX + 0.03, UY + 0.03, Hw), WOOD2)
    for sx in (-1, 1):
        for sy in (-1, 1):
            m.box((sx * UX - 0.09, sy * UY - 0.09, z1), (sx * UX + 0.09, sy * UY + 0.09, Hw), WOOD2)
    # windows: tall, dark, in rows, wood round them and a bar across
    def window(face, s, z, w=0.5, h=1.0):
        if face < 2:
            y = -UY if face == 0 else UY
            m.box((s - w / 2 - 0.07, y - 0.05, z - 0.07), (s + w / 2 + 0.07, y + 0.05, z + h + 0.07), WOOD2)
            m.box((s - w / 2, y - 0.06, z), (s + w / 2, y + 0.06, z + h), INSIDE)
            m.box((s - w / 2, y - 0.06, z + h * 0.55), (s + w / 2, y + 0.06, z + h * 0.55 + 0.04), WOOD2)
            m.box((s - 0.02, y - 0.06, z), (s + 0.02, y + 0.06, z + h), WOOD2)
        else:
            x = -UX if face == 2 else UX
            m.box((x - 0.05, s - w / 2 - 0.07, z - 0.07), (x + 0.05, s + w / 2 + 0.07, z + h + 0.07), WOOD2)
            m.box((x - 0.06, s - w / 2, z), (x + 0.06, s + w / 2, z + h), INSIDE)
            m.box((x - 0.06, s - w / 2, z + h * 0.55), (x + 0.06, s + w / 2, z + h * 0.55 + 0.04), WOOD2)
            m.box((x - 0.06, s - 0.02, z), (x + 0.06, s + 0.02, z + h), WOOD2)
    top0 = Hw - floors[-1]
    bay_w = 2.4 if kind in ("bay", "both") else 0.0
    z = z1
    for f in floors[1:]:
        for face in range(4):
            half = UX if face < 2 else UY
            n = max(2, int((2 * half - 0.7) / 1.15))
            for i in range(n):
                s = -half + 0.35 + (i + 0.5) * (2 * half - 0.7) / n
                if face == 0 and z == top0 and bay_w and abs(s) < bay_w / 2 + 0.3: continue
                window(face, s, z + f * 0.3, h=min(1.0, f * 0.48))
        z += f
    # (hollow inside: only its faces are ever seen)
    m.box((-X + 0.62, -Y + 0.62, 0.0), (X - 0.62, Y - 0.62, z1), 0)
    m.box((-UX + 0.2, -UY + 0.2, z1), (UX - 0.2, UY - 0.2, Hw - 0.25), 0)
    # the gallery: a floor of boards out over the lane on brackets, a railing of planks, posts up to the eaves
    def gallery(x0, x1, z0, ztop):
        out = 0.72
        m.box((x0, -UY - out, z0 - 0.1), (x1, -UY, z0), WOOD2)
        m.put((x0, -UY - out, z0), (x1, -UY - out + 0.06, z0 + 0.85), lambda g: g[..., 0] > -1e9,
              lambda g: np.where(np.floor(g[..., 0] * M / 3) % 2 == 0, BAY, BAY2).astype(np.uint8))
        for yy in (0, 1):
            xs = x0 if yy == 0 else x1 - 0.06
            m.box((xs, -UY - out, z0), (xs + 0.06, -UY, z0 + 0.85), BAY2)
        m.box((x0 - 0.02, -UY - out - 0.02, z0 + 0.85), (x1 + 0.02, -UY - out + 0.08, z0 + 0.92), WOOD2)
        n = max(2, int((x1 - x0) / 1.4) + 1)
        for i in range(n):
            px = x0 + 0.05 + i * (x1 - x0 - 0.1) / (n - 1)
            m.box((px - 0.05, -UY - out, z0), (px + 0.05, -UY - out + 0.1, ztop), WOOD2)
            m.capsule((px, -UY + 0.02, z0 - 0.7), (px, -UY - out + 0.08, z0 - 0.1), 0.05, 0.05, WOOD2)
        m.box((x0, -UY - out, ztop - 0.1), (x1, -UY - out + 0.1, ztop), WOOD2)
    # the bay: planks of red-brown wood out over the lane on brackets, its own windows in a row
    def bay(w, z0, ztop):
        out = 0.6
        m.put((-w / 2, -UY - out, z0), (w / 2, -UY + 0.05, ztop), lambda g: g[..., 0] > -1e9,
              lambda g: np.where(np.floor(g[..., 0] * M / 4) % 3 == 0, BAY2, BAY).astype(np.uint8))
        m.box((-w / 2 + 0.08, -UY - out + 0.08, z0 + 0.08), (w / 2 - 0.08, -UY + 0.05, ztop - 0.08), 0)
        m.box((-w / 2 - 0.03, -UY - out - 0.03, z0 - 0.1), (w / 2 + 0.03, -UY, z0 + 0.04), WOOD2)
        m.box((-w / 2 - 0.03, -UY - out - 0.03, ztop - 0.1), (w / 2 + 0.03, -UY, ztop), WOOD2)
        for sx in (-1, 1):
            m.capsule((sx * (w / 2 - 0.15), -UY + 0.02, z0 - 0.75), (sx * (w / 2 - 0.15), -UY - out + 0.05, z0 - 0.08), 0.06, 0.06, WOOD2)
        nb = max(2, int(w / 0.8))
        for i in range(nb):
            s = -w / 2 + (i + 0.5) * w / nb
            zz, hh = z0 + (ztop - z0) * 0.32, (ztop - z0) * 0.45
            m.box((s - 0.27, -UY - out - 0.04, zz - 0.06), (s + 0.27, -UY - out + 0.04, zz + hh + 0.06), WOOD2)
            m.box((s - 0.2, -UY - out - 0.05, zz), (s + 0.2, -UY - out + 0.05, zz + hh), INSIDE)
    if kind == "gallery": gallery(-UX * 0.8, UX * 0.8, top0, Hw - 0.2)
    elif kind == "bay": bay(bay_w, top0 + 0.05, Hw - 0.2)
    else:
        bay(bay_w, top0 + 0.05, Hw - 0.2)
        if len(floors) > 2: gallery(0.2, UX * 0.95, z1 + 0.0, z1 + floors[1] - 0.09)
    # the eaves' underside: dark boards from the wall out
    m.box((-X - ov + 0.06, -Y - ov + 0.06, Hw - 0.02), (X + ov - 0.06, Y + ov - 0.06, Hw + 0.04), WOOD2, over=False)
    hip_roof(m, rng, X, Y, Hw, ov, pitch)
    # the chimneys: plastered white, a slab on four stones over each
    for cx, cy in ((X * 0.45, Y * 0.3), (-X * 0.5, -Y * 0.15)):
        cz = Hw + pitch * min(X + ov - abs(cx), Y + ov - abs(cy))
        ct = min(cz + 0.85, Hr + 0.72)
        m.box((cx - 0.27, cy - 0.27, cz - 0.4), (cx + 0.27, cy + 0.27, ct), WHITE)
        for sx in (-1, 1):
            for sy in (-1, 1): m.box((cx + sx * 0.2 - 0.06, cy + sy * 0.2 - 0.06, ct), (cx + sx * 0.2 + 0.06, cy + sy * 0.2 + 0.06, ct + 0.14), STONE2)
        m.box((cx - 0.18, cy - 0.18, ct - 0.04), (cx + 0.18, cy + 0.18, ct + 0.02), CHAR)
        m.box((cx - 0.4, cy - 0.4, ct + 0.14), (cx + 0.4, cy + 0.4, ct + 0.22), STONE3)
    # (only the skin is kept: a voxel with all six neighbours solid is never seen)
    s = m.v > 0
    inner = np.zeros_like(s)
    inner[1:-1, 1:-1, 1:-1] = s[1:-1, 1:-1, 1:-1] & s[:-2, 1:-1, 1:-1] & s[2:, 1:-1, 1:-1] & s[1:-1, :-2, 1:-1] & s[1:-1, 2:, 1:-1] & s[1:-1, 1:-1, :-2] & s[1:-1, 1:-1, 2:]
    m.v[inner] = 0
    return m


def street_room(seed):
    """A room built across a street from one house to the next (Dominic, 2026-11-25: "the houses connecting to each
    other over the top of them"): the upper storey carried over the street on beams, plastered white, a row of windows
    each side, a low roof of slabs. It spans along x, 6 m; the street runs under it along y. Its measures follow the
    houses' own upper storey; no text or picture of one has been read yet, so its look is the houses' look."""
    rng = random.Random(seed)
    X, Y, z0, z1 = 3.0, 1.5, 2.3, 4.4
    ov, pitch = 0.45, 0.4
    m = Model(X + 0.1, Y + ov + 0.1, z1 + pitch * (Y + ov) + 0.3)
    # the beams it stands on, from wall to wall, and boards over them
    y = -Y + 0.15
    while y < Y:
        m.box((-X, y - 0.08, z0 - 0.2), (X, y + 0.08, z0), POLE2)
        y += 0.55
    m.box((-X, -Y, z0), (X, Y, z0 + 0.08), WOOD2)
    def plaster(g):
        h = np.mod(np.floor(g[..., 0] * M * 0.37) + np.floor(g[..., 2] * M * 0.61) * 3 + np.floor(g[..., 1] * M * 0.53) * 5, 23)
        return np.where(h == 0, CANVAS, WHITE).astype(np.uint8)
    m.put((-X, -Y, z0 + 0.08), (X, Y, z1), lambda g: g[..., 0] > -1e9, plaster)
    m.box((-X, -Y - 0.03, z0), (X, Y + 0.03, z0 + 0.16), WOOD2)
    m.box((-X, -Y - 0.03, z1 - 0.18), (X, Y + 0.03, z1), WOOD2)
    n = 4
    for i in range(n):
        sx = -X + 0.5 + (i + 0.5) * (2 * X - 1.0) / n
        for y in (-Y, Y):
            m.box((sx - 0.32, y - 0.05, z0 + 0.6), (sx + 0.32, y + 0.05, z0 + 1.65), WOOD2)
            m.box((sx - 0.25, y - 0.06, z0 + 0.67), (sx + 0.25, y + 0.06, z0 + 1.58), INSIDE)
            m.box((sx - 0.02, y - 0.06, z0 + 0.67), (sx + 0.02, y + 0.06, z0 + 1.58), WOOD2)
    m.box((-X + 0.2, -Y + 0.2, z0 + 0.1), (X - 0.2, Y - 0.2, z1 - 0.2), 0)
    # its roof: slabs in rows down each side from a ridge along x
    m.box((-X, -Y - ov + 0.05, z1 - 0.02), (X, Y + ov - 0.05, z1 + 0.04), WOOD2, over=False)
    EY, roww, sd = Y + ov, 0.42, rng.randrange(1000)
    def parts(g):
        d = EY - np.abs(g[..., 1])
        return d, np.floor(d / roww)
    def inside(g):
        d, row = parts(g)
        top = z1 + 0.04 + pitch * row * roww + pitch * (d - row * roww) * 0.35
        return (d >= 0) & (g[..., 2] <= top) & (g[..., 2] >= top - 0.13 - pitch * roww)
    def colour(g):
        d, row = parts(g)
        cell = np.floor((g[..., 0] + row * 0.31) / 0.62)
        h = np.mod((cell * 7 + row * 13 + sd).astype(int) * 2654435 // 1000, 6)
        return np.array([STONE2, STONE3, STONE, STONE2, ASH2, STONE], np.uint8)[h]
    m.put((-X, -EY, z1 - 0.4), (X, EY, z1 + pitch * EY + 0.3), inside, colour)
    m.box((-X, -0.15, z1 + pitch * EY - 0.02), (X, 0.15, z1 + pitch * EY + 0.1), STONE3)
    s = m.v > 0
    inner = np.zeros_like(s)
    inner[1:-1, 1:-1, 1:-1] = s[1:-1, 1:-1, 1:-1] & s[:-2, 1:-1, 1:-1] & s[2:, 1:-1, 1:-1] & s[1:-1, :-2, 1:-1] & s[1:-1, 2:, 1:-1] & s[1:-1, 1:-1, :-2] & s[1:-1, 1:-1, 2:]
    m.v[inner] = 0
    return m


HOUSES = [(41, 3.3, 3.0, (2.3, 2.2, 2.1), "gallery"), (42, 3.0, 2.8, (2.3, 2.1, 2.2), "both"), (43, 3.4, 2.7, (2.2, 2.3), "bay")]


# ---- the village's yard walls and its fountain -------------------------------------------------------------------
def yard_wall(seed):
    """A stretch of the wall between a yard and the lane: unhewn gneiss laid in courses with slabs along its top, a
    little under a man's shoulder. ("authentic cobblestone streets, lining one after the other charming yards",
    "stacked unhewn stones cemented with a mixture of clay and water", bg-guide.org, Kovachevitsa; Leshten's "stone
    walls stand out", Radio Bulgaria. Its height and the coping are from photographs of the villages, not from those
    texts.) Its length runs along x, just under a tile, so stretches stand end to end."""
    X, T, H = 2.4, 0.24, 1.2
    m = Model(X + 0.1, T + 0.2, H + 0.3)
    rng = random.Random(seed)
    g = 1.0 / M
    z = 0.0
    while z < H:
        h = min(rng.uniform(0.12, 0.2), H - z)
        s = -X
        while s < X:
            w = rng.uniform(0.25, 0.6)
            d = rng.uniform(-0.03, 0.03)
            m.box((s, -T + d, z), (min(s + w, X) - g, T + d, z + h - g), rng.choice([STONE, STONE2, STONE3, STONE, STONE2, ASH2]))
            s += w
        z += h
    m.box((-X + 0.03, -T + 0.04, 0), (X - 0.03, T - 0.04, H), ASH, over=False)
    s = -X
    while s < X:
        w = rng.uniform(0.5, 0.95)
        m.box((s, -T - 0.08, H), (min(s + w, X) - g, T + 0.08, H + 0.06 + rng.uniform(0, 0.04)), rng.choice([STONE2, STONE3, STONE]))
        s += w
    return m


def fenced_wall(seed):
    """A stretch of the lane's wall as in Dominic's photograph of 2026-11-25: the stone wall lower, a fence of dark
    upright boards between posts on top of it, and a narrow roof of slabs along the fence's top. Its measures are
    read off the photograph against the houses' doors."""
    X, T, H, F = 2.4, 0.24, 0.85, 0.8
    m = Model(X + 0.1, T + 0.35, H + F + 0.45)
    rng = random.Random(seed)
    g = 1.0 / M
    z = 0.0
    while z < H:
        h = min(rng.uniform(0.12, 0.2), H - z)
        s = -X
        while s < X:
            w = rng.uniform(0.25, 0.6)
            d = rng.uniform(-0.03, 0.03)
            m.box((s, -T + d, z), (min(s + w, X) - g, T + d, z + h - g), rng.choice([STONE, STONE2, STONE3, STONE, STONE2, ASH2]))
            s += w
        z += h
    m.box((-X + 0.03, -T + 0.04, 0), (X - 0.03, T - 0.04, H), ASH, over=False)
    # the fence: posts, two rails, upright boards with a gap between
    m.put((-X, -0.03, H), (X, 0.03, H + F), lambda gg: np.floor((gg[..., 0] + X) * M / 3) % 2 == 0,
          lambda gg: np.where(np.floor((gg[..., 0] + X) * M / 6) % 3 == 0, BAY2, WOOD2).astype(np.uint8))
    for zz in (H + 0.12, H + F - 0.14):
        m.box((-X, -0.06, zz), (X, 0.06, zz + 0.07), WOOD2)
    x = -X + 0.05
    while x < X:
        m.box((x - 0.06, -0.07, H), (x + 0.06, 0.07, H + F + 0.02), POLE2)
        x += (2 * X - 0.1) / 4
    # its little roof: two rows of slabs either side of a ridge
    for side in (-1, 1):
        s = -X
        while s < X:
            w = rng.uniform(0.3, 0.55)
            c = rng.choice([STONE2, STONE3, STONE, STONE2])
            def slab(gg, side=side):
                f = np.abs(gg[..., 1]) / 0.3
                want = H + F + 0.2 - 0.16 * f
                return (gg[..., 1] * side >= 0) & (f <= 1) & (gg[..., 2] <= want) & (gg[..., 2] >= want - 0.08)
            m.put((s, -0.3, H + F), (min(s + w, X) - g, 0.3, H + F + 0.25), slab, c)
            s += w
    m.box((-X, -0.05, H + F + 0.16), (X, 0.05, H + F + 0.24), STONE3)
    return m


def cobbles(seed, fade):
    """A tile of the lane's cobbles ("authentic cobblestone streets", bg-guide.org, Kovachevitsa; "cobblestone
    streets", Radio Bulgaria, Leshten): river and field stones of gneiss a hand or two across, set close in earth,
    worn flat. Their size and the earth between are from photographs of the villages' lanes, not from those texts.
    A tile square and two voxels thick, so tiles lie edge to edge; with fade, the stones thin out toward +x, where
    the lane leaves the village and is earth again."""
    X = 4.85 / 2
    m = Model(X + 0.6, X + 0.6, 0.2)
    rng = random.Random(seed)
    # (the stones run a little over the tile's edge, whole, so no straight seam shows where two tiles meet)
    y = -X - rng.uniform(0.0, 0.2)
    while y < X + 0.1:
        d = rng.uniform(0.2, 0.34)
        x = -X - rng.uniform(0.0, 0.25)
        while x < X + 0.1:
            w = rng.uniform(0.2, 0.42)
            keep = not fade or rng.random() < (1.0 - min(1.0, max(0.0, x + X) / (2 * X))) ** 1.3
            if keep and rng.random() > 0.04:
                m.box((x, y, 0.0), (x + w - 1.5 / M, y + d - 1.5 / M, 0.07 if rng.random() < 0.8 else 0.1), rng.choice([STONE, STONE2, STONE3, STONE, STONE2, ASH2]))
            x += w
        y += d
    return m


def fountain():
    """The village's fountain (a cheshma: Dolen's is named, the "Nikolovskata Cheshma", visitbulgaria.com): a wall of
    dressed gneiss with a slab over it, an iron spout in a niche, and a stone trough the animals drink from under it.
    Its shape is the common one of the Balkans' wall fountains, from photographs; no text read gives its measures. Its
    face is toward -y."""
    m = Model(1.3, 0.9, 1.9)
    rng = random.Random(9)
    g = 1.0 / M
    z = 0.0
    while z < 1.55:
        h = min(rng.uniform(0.16, 0.24), 1.55 - z)
        s = -0.95
        while s < 0.95:
            w = rng.uniform(0.3, 0.6)
            m.box((s, 0.0, z), (min(s + w, 0.95) - g, 0.45, z + h - g), rng.choice([STONE, STONE2, STONE3, STONE2]))
            s += w
        z += h
    m.box((-0.92, 0.04, 0), (0.92, 0.42, 1.55), ASH, over=False)
    m.box((-1.08, -0.08, 1.55), (1.08, 0.53, 1.66), STONE3)          # the slab over it
    m.box((-0.3, -0.01, 0.75), (0.3, 0.06, 1.25), ASH)                # the niche, dark
    m.box((-0.24, -0.02, 0.8), (0.24, 0.02, 1.2), STONE3)             # its face stone, pale
    m.capsule((0.0, 0.0, 0.95), (0.0, -0.2, 0.9), 0.025, 0.025, IRON)  # the spout
    m.capsule((0.0, -0.2, 0.88), (0.0, -0.2, 0.5), 0.012, 0.012, WHITE)  # the water falling
    m.box((-0.85, -0.62, 0), (0.85, -0.02, 0.48), STONE2)             # the trough
    m.box((-0.74, -0.52, 0.34), (0.74, -0.12, 0.5), 0, over=True)
    m.box((-0.74, -0.52, 0.3), (0.74, -0.12, 0.4), BLUE)              # the water in it
    return m


# ---- the women of the village --------------------------------------------------------------------------------------
def woman(kind):
    """A woman of the village, standing with her hands together before her, facing +x. Her dress is the saya's, as
    read: for "the Rhodopes and parts of Pirin (Blagoevgrad)" a long-sleeved saya to the calf or ankle (eliznik.org.uk,
    women's open tunic, saya); in the Blagoevgrad region "quite dark" and of wool even in summer, with "the black or
    red woollen belt" and an apron "most often woollen - red, striped" (Radio Bulgaria, the history of the black
    saya); married women in "square headscarves made of white home-made cloth", folded and put on the head with the
    ends loose at the back (eliznik.org.uk, women's headwear); "knitted patterned socks and leather sandals
    (tsarvuli)" (eliznik.org.uk, aprons and tunics). The white of the chemise at the saya's open front is from
    photographs: the pages name the chemise (koshulya) and not its colour. kind 0: a red apron and a red belt; kind 1:
    a striped apron and a black belt."""
    m = Model(0.4, 0.4, 1.7)
    for y in (-1, 1):
        m.blob((0.04, y * 0.08, 0.04), (0.11, 0.055, 0.04), LEATHER)          # tsarvuli
        m.capsule((0.0, y * 0.08, 0.06), (0.0, y * 0.08, 0.2), 0.05, 0.05, WHITE)  # socks
    def skirt(g):
        front = (g[..., 0] > 0.06) & (np.abs(g[..., 1]) < 0.13) & (g[..., 2] > 0.28) & (g[..., 2] < 0.93)
        if kind == 0: apron = np.full(g.shape[:3], RED)
        else: apron = np.where((np.floor(g[..., 2] * M / 2) % 4) == 0, OCHRE, np.where((np.floor(g[..., 2] * M / 2) % 4) == 2, BLACK, RED))
        return np.where(front, apron, BLACK)
    m.capsule((0.0, 0, 0.3), (0.0, 0, 0.92), 0.21, 0.15, skirt)                # the saya's skirt, to the ankle, and the apron
    m.put((-0.3, -0.3, 0.17), (0.3, 0.3, 0.32), lambda g: (g[..., 0] ** 2 + g[..., 1] ** 2) < 0.2 ** 2, lambda g: skirt(g))
    def body(g): return np.where((g[..., 0] > 0.08) & (np.abs(g[..., 1]) < 0.035), WHITE, BLACK)
    m.capsule((0.0, 0, 0.95), (0.0, 0, 1.28), 0.15, 0.16, body)               # the bodice, the chemise at its opening
    m.blob((0.0, 0, 0.95), (0.165, 0.165, 0.045), RED if kind == 0 else CHAR)  # the belt
    for y in (-1, 1):
        m.capsule((0.0, y * 0.19, 1.3), (0.06, y * 0.2, 1.08), 0.055, 0.05, BLACK)
        m.capsule((0.06, y * 0.2, 1.08), (0.17, y * 0.05, 1.0), 0.05, 0.042, BLACK)
        m.blob((0.19, y * 0.035, 1.0), (0.04, 0.04, 0.04), SKIN)
    m.capsule((0.0, 0, 1.3), (0.0, 0, 1.38), 0.05, 0.05, SKIN)
    m.blob((0.01, 0, 1.47), (0.095, 0.09, 0.11), SKIN)
    def scarf(g):
        d = ((g[..., 0] - 0.0) / 0.115) ** 2 + (g[..., 1] / 0.11) ** 2 + ((g[..., 2] - 1.49) / 0.125) ** 2
        return (d <= 1.0) & ((g[..., 0] < 0.035) | (g[..., 2] > 1.53))
    m.put((-0.2, -0.2, 1.3), (0.2, 0.2, 1.65), scarf, WHITE)
    m.put((-0.2, -0.12, 1.12), (-0.07, 0.12, 1.42), lambda g: (np.abs(g[..., 1]) < 0.1 - (1.42 - g[..., 2]) * 0.18) & (g[..., 0] < -0.09), WHITE)  # its ends, loose at the back
    # (drawn a third bigger, as the men are beside the houses: at her true size she stood to a man's chest)
    k = 1.32
    ix, iy, iz = [np.floor(np.arange(int(n * k)) / k).astype(int) for n in m.v.shape]
    m.v = m.v[ix][:, iy][:, :, iz]
    m.o = np.array([int(m.o[0] * k), int(m.o[1] * k), 0])
    return m


# ---- the horses and mules --------------------------------------------------------------------------------------
COATS = {
    # coat, its shade (belly, legs), mane and tail, lower legs, muzzle
    "bay": (BAY, BAY2, HAIR, HAIR, BAY2),
    "grey": (GREY, GREY2, GREY3, GREY2, GREY2),
    "chestnut": (CHESTNUT, CHESTNUT2, CHESTNUT2, CHESTNUT, CHESTNUT2),
    "dark": (BAY2, HAIR, HAIR, HAIR, BAY2),
    "mule": (DUN2, DUN2, HAIR, HAIR, MUZZLE),
    "mule_dun": (DUN, DUN2, HAIR, DUN2, MUZZLE),
}


def animal(coat, mule, tall=2.3):
    """A small Balkan mountain horse (about 1.5 m at the withers, the mock-up's size), or
    a mule (longer ears and head, a thin tail with a tuft, a short upright mane). Faces +x."""
    c, shade, hair, low, muzzle = COATS[coat]
    m = Model(1.6, 1.0, tall)
    s = 1.0 if mule else 1.1  # (the mock-up's horses stand a little bigger than a Rhodope pony)
    def S(p): return (p[0] * s, p[1] * s, p[2] * s)
    def belly(g): return np.where(g[..., 2] < 0.86 * s, shade, c)
    m.blob(S((0, 0, 1.0)), (0.62 * s, 0.25 * s, 0.27 * s), belly)
    m.blob(S((0.48, 0, 1.03)), (0.26 * s, 0.22 * s, 0.27 * s), belly)
    m.blob(S((-0.5, 0, 1.08)), (0.3 * s, 0.25 * s, 0.26 * s), belly)
    # the neck and head
    m.capsule(S((0.55, 0, 1.12)), S((0.86, 0, 1.52)), 0.18 * s, 0.1 * s, c)
    head_end = (1.15, 0, 1.24) if mule else (1.12, 0, 1.28)
    m.capsule(S((0.88, 0, 1.58)), S(head_end), 0.1 * s, 0.065 * s, c)
    m.capsule(S((head_end[0] - 0.07, 0, head_end[2] + 0.06)), S(head_end), 0.07 * s, 0.065 * s, muzzle)
    for y in (-1, 1):
        m.v[tuple(np.floor(np.array(S((0.95, y * 0.075, 1.55))) * M).astype(int) + m.o)] = EYE
        ear = (0.86, y * 0.08, 1.88) if mule else (0.86, y * 0.06, 1.75)
        m.capsule(S((0.88, y * 0.05, 1.64)), S(ear), 0.03 * s, 0.018 * s, c)
    # the mane, and the forelock
    for t in np.linspace(0, 1, 9):
        a = np.array(S((0.55, 0, 1.12))) + (np.array(S((0.86, 0, 1.52))) - np.array(S((0.55, 0, 1.12)))) * t
        if mule: m.capsule(a + [-0.06 * s, 0, 0.1 * s], a + [-0.08 * s, 0, 0.16 * s - t * 0.05], 0.03 * s, 0.025 * s, hair)
        else: m.capsule(a + [-0.07 * s, 0, 0.09 * s], a + [-0.12 * s, (-1) ** int(t * 8) * 0.07, 0.02 - 0.08 * t], 0.04 * s, 0.03 * s, hair)
    if not mule: m.capsule(S((0.9, 0, 1.68)), S((0.97, 0, 1.56)), 0.03, 0.02, hair)
    # the tail
    if mule:
        m.capsule(S((-0.78, 0, 1.18)), S((-0.86, 0, 0.75)), 0.03 * s, 0.025 * s, c)
        m.capsule(S((-0.86, 0, 0.75)), S((-0.88, 0, 0.5)), 0.05 * s, 0.03 * s, hair)
    else:
        m.capsule(S((-0.78, 0, 1.16)), S((-0.9, 0, 0.9)), 0.07, 0.08, hair)
        m.capsule(S((-0.9, 0, 0.9)), S((-0.87, 0, 0.45)), 0.08, 0.06, hair)
    # the legs: forelegs straight, hind legs angled at the hock
    for y in (-0.12, 0.12):
        ly = y * s
        for joints, rr in (([(0.47, 0.98), (0.48, 0.48), (0.49, 0.12), (0.51, 0.04)], [0.1, 0.05, 0.04, 0.045]),
                           ([(-0.5, 1.0), (-0.64, 0.52), (-0.57, 0.12), (-0.55, 0.04)], [0.14, 0.055, 0.04, 0.045])):
            pts = [S((x, ly / s, z)) for x, z in joints]
            m.capsule(pts[0], pts[1], rr[0] * s, rr[1] * s, lambda g: np.where(g[..., 2] < 0.6 * s, low, c))
            m.capsule(pts[1], pts[2], rr[1] * s, rr[2] * s, low)
            m.capsule(pts[2], pts[3], rr[2] * s, rr[3] * s, low)
            m.capsule((pts[3][0], pts[3][1], 0.0), (pts[3][0], pts[3][1], 0.06), rr[3] * s + 0.005, rr[3] * s, HOOF)
    # a halter
    m.capsule(S((0.88, -0.1, 1.62)), S((0.88, 0.1, 1.62)), 0.012, 0.012, LEATHER2)
    nb = (head_end[0] - 0.09, 0, head_end[2] + 0.07)
    m.blob(S(nb), (0.03, 0.085 * s, 0.06 * s), lambda g: np.where(np.abs(g[..., 1]) > 0.06 * s, LEATHER2, 0), over=True)
    return m, s


def pack_saddle(m, s, load, rng):
    """the samar: a felt pad, two wooden bucks over the back, a girth; then the load, hung on both sides and on top"""
    z0 = 1.0 * s
    m.blob((0, 0, z0 + 0.02), (0.42 * s, 0.27 * s, 0.29 * s), lambda g: np.where(g[..., 2] > z0 + 0.12 * s, FELT, 0), over=True)
    for x in (-0.22, 0.22):
        def buck(g, x=x):
            d = g - [x * s, 0, z0]
            r = np.sqrt(d[..., 1] ** 2 + d[..., 2] ** 2)
            return (np.abs(d[..., 0]) < 1.6 / M) & (r > 0.29 * s) & (r < 0.33 * s) & (d[..., 2] > 0.05)
        m.put((x * s - 0.1, -0.4, z0), (x * s + 0.1, 0.4, z0 + 0.4), buck, WOOD)
        m.capsule((x * s, -0.08, z0 + 0.36 * s), (x * s, 0.08, z0 + 0.36 * s), 0.03, 0.03, WOOD2)
    def girth(g):
        d = g - [0.12 * s, 0, z0]
        return (np.abs(d[..., 0]) < 1.2 / M)
    m.put((0.08 * s, -0.3, 0.6), (0.16 * s, 0.3, z0 + 0.2), lambda g: girth(g) & (m.v[m.grid((0.08 * s, -0.3, 0.6), (0.16 * s, 0.3, z0 + 0.2))[1]] > 0), LEATHER)
    side = z0 - 0.05
    if load == "sacks":
        for y in (-1, 1):
            m.blob((0.0, y * 0.36 * s, side), (0.3 * s, 0.14 * s, 0.22 * s), lambda g: np.where(g[..., 2] > side + 0.12, SACK2, SACK))
            m.capsule((-0.2, y * 0.36 * s, side + 0.2), (0.2, y * 0.36 * s, side + 0.2), 0.03, 0.03, SACK2)
        m.capsule((-0.42 * s, 0, z0 + 0.42 * s), (0.42 * s, 0, z0 + 0.42 * s), 0.11 * s, 0.11 * s, lambda g: stripes((g[..., 0] + 0.5) / 1.0 * 0.6 + 0.2))
    elif load == "kegs":
        for y in (-1, 1):
            m.capsule((-0.28, y * 0.38 * s, side), (0.28, y * 0.38 * s, side), 0.15 * s, 0.15 * s,
                      lambda g: np.where(np.abs(np.abs(g[..., 0]) - 0.18) < 1.0 / M, IRON, WOOD))
        for k in range(3):
            m.capsule((-0.45, -0.1 + k * 0.1, z0 + 0.4 * s), (0.5, -0.12 + k * 0.1, z0 + 0.46 * s), 0.018, 0.018, WOOD2)  # tool hafts
        m.box((0.48, -0.16, z0 + 0.42 * s), (0.56, 0.12, z0 + 0.52 * s), IRON)
    elif load == "baskets":
        for y in (-1, 1):
            def basket(g, y=y):
                return np.where((np.floor(g[..., 2] * M) + np.floor(g[..., 0] * M)) % 3 == 0, WICKER2, WICKER)
            m.capsule((0.0, y * 0.4 * s, side - 0.22), (0.0, y * 0.4 * s, side + 0.14), 0.2 * s, 0.22 * s, basket)
            m.blob((0.0, y * 0.4 * s, side + 0.16), (0.17 * s, 0.17 * s, 0.05), rng.choice([CHESTNUT, OCHRE, GREEN]))
        m.box((-0.3, -0.12, z0 + 0.36 * s), (0.3, 0.12, z0 + 0.5 * s), SACK2)
    elif load == "poles":
        for y in (-1, 1):
            m.blob((0.0, y * 0.36 * s, side), (0.28 * s, 0.13 * s, 0.2 * s), FELT)
        for k in range(5):
            m.capsule((-1.0, -0.1 + k * 0.05, z0 + 0.38 * s + (k % 2) * 0.05), (1.05, -0.1 + k * 0.05, z0 + 0.42 * s + (k % 2) * 0.05), 0.03, 0.03, POLE)
        for x in (-0.3, 0.3): m.capsule((x, -0.2, z0 + 0.45 * s), (x, 0.2, z0 + 0.45 * s), 0.012, 0.012, ROPE)
    # ropes over the load
    for x in (-0.12, 0.14):
        def band(g, x=x):
            return np.abs(g[..., 0] - x * s) < 0.8 / M
        lo, hi = (x * s - 0.05, -0.6, side - 0.25), (x * s + 0.05, 0.6, z0 + 0.6)
        g, sl = m.grid(lo, hi)
        if g is not None:
            sub = m.v[sl]
            near = sub > 0
            sub[band(g) & near & (sub != LEATHER) & (g[..., 2] > side - 0.1)] = ROPE


def riding_saddle(m, s, blanket):
    """a wooden saddle with a high pommel on a striped or felt blanket; stirrups, a bridle and reins"""
    z0 = 1.0 * s
    m.blob((-0.02, 0, z0 + 0.02), (0.36, 0.27, 0.29), lambda g: np.where(g[..., 2] > z0 + 0.14, blanket(g), 0), over=True)
    m.blob((0.0, 0, z0 + 0.06), (0.24, 0.24, 0.29), lambda g: np.where(g[..., 2] > z0 + 0.2, LEATHER, 0), over=True)
    m.capsule((0.2, 0, z0 + 0.28), (0.24, 0, z0 + 0.38), 0.05, 0.035, LEATHER2)
    m.capsule((-0.22, 0, z0 + 0.28), (-0.26, 0, z0 + 0.35), 0.06, 0.05, LEATHER2)
    for y in (-1, 1):
        rope(m, (0.0, y * 0.26, z0 + 0.15), (0.0, y * 0.28, 0.62), LEATHER2)
        m.box((-0.04, y * 0.29 - 0.02, 0.58), (0.04, y * 0.29 + 0.02, 0.62), IRON)
        rope(m, (0.9, y * 0.07, 1.42), (0.3, y * 0.12, z0 + 0.32), LEATHER2)
    m.capsule((0.12, -0.27, 0.78), (0.12, 0.27, 0.78), 0.015, 0.015, LEATHER)  # the girth


def rider(m, s):
    """A horseman in the saddle, for a look at how riders read at a wood's edge (Dominic, 2026-11-11; the mock-up's
    patrol): a blue coat, white breeches, black boots, a yellow sash, a red fez, a long gun slung across his back."""
    z0 = 1.0 * s + 0.3
    m.blob((-0.02, 0, z0 + 0.06), (0.16, 0.19, 0.13), WHITE)
    for y in (-1, 1):
        m.capsule((-0.02, y * 0.13, z0 + 0.05), (0.16, y * 0.27, z0 - 0.26), 0.085, 0.07, WHITE)
        m.capsule((0.16, y * 0.27, z0 - 0.26), (0.1, y * 0.29, z0 - 0.5), 0.065, 0.055, BLACK)
        m.capsule((0.1, y * 0.29, z0 - 0.62), (0.2, y * 0.29, z0 - 0.64), 0.055, 0.045, BLACK)
        m.capsule((0.0, y * 0.2, z0 + 0.52), (0.08, y * 0.25, z0 + 0.3), 0.065, 0.055, COAT)
        m.capsule((0.08, y * 0.25, z0 + 0.3), (0.26, y * 0.14, z0 + 0.24), 0.055, 0.045, COAT2)
        m.blob((0.3, y * 0.13, z0 + 0.24), (0.045, 0.045, 0.045), SKIN)
    m.capsule((-0.02, 0, z0 + 0.14), (0.0, 0, z0 + 0.5), 0.17, 0.19, lambda g: np.where(g[..., 1] < 0, COAT2, COAT))
    m.blob((-0.02, 0, z0 + 0.2), (0.19, 0.2, 0.05), SASH)
    m.blob((0.03, 0, z0 + 0.74), (0.105, 0.1, 0.12), SKIN)
    m.capsule((0.01, 0, z0 + 0.82), (0.0, 0, z0 + 0.95), 0.105, 0.09, FEZ)
    m.capsule((-0.2, -0.16, z0 + 0.1), (-0.14, 0.2, z0 + 0.85), 0.022, 0.018, lambda g: np.where(g[..., 2] > z0 + 0.4, IRON, WOOD2))


def banner(m, s):
    """The patrol's standard (the ridge's mock-up, D-084): the leading rider holds up a tall pole with a red swallow-tailed
    banner streaming back from its top, a brass knob over it; the one accent of colour in the fog."""
    z0 = 1.0 * s + 0.3
    top = z0 + 2.1
    m.capsule((0.3, 0.16, z0 - 0.1), (0.3, 0.16, top), 0.025, 0.025, WOOD2)
    m.blob((0.3, 0.16, top + 0.05), (0.05, 0.05, 0.06), BRASS)
    def cloth(g):
        # (it streams back from the pole, its fly cut into two tails, and sags a little toward its end)
        back = 0.3 - g[..., 0]
        mid = top - 0.36 - back * 0.14
        off = np.abs(g[..., 2] - mid)
        return (off < 0.32) & ~((back > 0.75) & (off < 0.32 * np.clip((back - 0.75) * 3.0, 0, 1)))
    m.put((-0.95, 0.13, top - 0.9), (0.27, 0.19, top - 0.02), cloth, FEZ)


def blanket_red(g): return np.where((np.floor(g[..., 0] * M / 3) % 4) == 0, BLACK, BLANKET)
def blanket_blue(g): return np.where((np.floor(g[..., 0] * M / 2) % 5) == 0, RED, BLANKET2)
def blanket_felt(g): return np.where(np.abs(g[..., 2] - 1.05) < 1.0 / M, RED, FELT)


HORSES = [("bay", blanket_red), ("grey", blanket_blue), ("chestnut", blanket_felt), ("dark", blanket_red)]
MULES = [("mule", "sacks"), ("mule_dun", "kegs"), ("bay", "baskets"), ("mule", "poles")]


def models():
    out = [("tent_canvas", tent0()), ("tent_rugs", tent1()), ("fireplace", fireplace()), ("woodpile", woodpile()), ("hut", hut()), ("wall", yard_wall(3)), ("wall_fence", fenced_wall(4)), ("street_room", street_room(6)), ("fountain", fountain()), ("woman_0", woman(0)), ("woman_1", woman(1)), ("cobbles_0", cobbles(5, False)), ("cobbles_1", cobbles(9, False)), ("cobbles_2", cobbles(13, True))]
    for i, (seed, X, Y, floors, kind) in enumerate(HOUSES): out.append(("house_%d" % i, house(seed, X, Y, floors, kind)))
    for i, (coat, blanket) in enumerate(HORSES):
        m, s = animal(coat, False)
        riding_saddle(m, s, blanket)
        out.append(("horse_%d_%s" % (i, coat), m))
    for i, (coat, blanket) in enumerate(HORSES):  # (the same horses, each with a rider up)
        m, s = animal(coat, False, 2.8)
        riding_saddle(m, s, blanket)
        rider(m, s)
        out.append(("rider_%d_%s" % (i, coat), m))
    m, s = animal("dark", False, 4.2)  # (the standard-bearer on the dark horse)
    riding_saddle(m, s, blanket_red)
    rider(m, s)
    banner(m, s)
    out.append(("rider_banner", m))
    for i, (coat, load) in enumerate(MULES):
        m, s = animal(coat, coat.startswith("mule"))
        pack_saddle(m, s, load, random.Random(i))
        out.append(("mule_%d_%s_%s" % (i, coat, load), m))
    return out


# ---- the .vox file (as art/men/tools/men.py writes it) -----------------------------------------------------------
def _chunk(cid, content): return cid.encode() + struct.pack("<ii", len(content), 0) + content


def _dict(kv):
    s = struct.pack("<i", len(kv) // 2)
    for t in kv:
        b = t.encode(); s += struct.pack("<i", len(b)) + b
    return s


def write_vox(path, vs):
    """one model; its corner at (lo.x, lo.y, 0) in the file's frame. Returns its foot: where x = y = 0 is in it."""
    ks = list(vs.keys())
    lo = [min(k[a] for k in ks) for a in range(3)]
    hi = [max(k[a] for k in ks) for a in range(3)]
    lo[2] = 0
    size = [hi[a] - lo[a] + 1 for a in range(3)]
    assert max(size) <= 256, size
    xyzi = struct.pack("<i", len(ks)) + b"".join(struct.pack("<4B", k[0] - lo[0], k[1] - lo[1], k[2] - lo[2], vs[k]) for k in ks)
    rgba = b"".join(struct.pack("<4B", (c >> 16) & 255, (c >> 8) & 255, c & 255, 255) for c in (COLOURS + [0] * 256)[:256])
    content = _chunk("SIZE", struct.pack("<3i", *size)) + _chunk("XYZI", xyzi) + _chunk("RGBA", rgba)
    with open(path, "wb") as fh:
        fh.write(b"VOX " + struct.pack("<i", 150) + b"MAIN" + struct.pack("<ii", 0, len(content)) + content)
    return -lo[0], -lo[1]


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    feet = []
    for name, m in models():
        vs = m.voxels()
        fx, fy = write_vox("%s/%s.vox" % (OUT, name), vs)
        feet.append("%s %d %d" % (name, fx, fy))
        print(name, len(vs))
    with open(OUT + "/feet.txt", "w") as f: f.write("\n".join(feet) + "\n")
