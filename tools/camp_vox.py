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
         "LEATHER", "LEATHER2", "FELT", "SACK", "SACK2", "BLANKET", "BRASS", "WICKER", "WICKER2", "BLANKET2", "GREY3", "LOG", "LOG2", "CUT"]
COLOURS = [0xd6ccb4, 0xbcb198, 0x9c9078, 0x2a231d, 0x6e4e32, 0x4e3624, 0xb2a282,
           0xa33328, 0x2a2522, 0xe0d6be, 0xc08a3a, 0x6b4a30, 0x2c3a52, 0x4c5a36,
           0x8d877e, 0x6f6a62, 0xa8a296, 0x5c5852, 0x8a857c, 0x1f1b18, 0xb4481c, 0xb0683a, 0x7a4428, 0x3c3e41, 0x8a6440, 0x6a4a2e,
           0x6a3e24, 0x55301c, 0x1e1916, 0xc8c3b8, 0xa29e95, 0x8c4c26, 0x6e3a1c, 0x8a7458, 0x6c5a44, 0xb5a48c, 0x2a2420, 0x120e0c,
           0x6b4a2e, 0x4a3220, 0x5e4a38, 0xb59a74, 0x957c5c, 0xa8302a, 0xc49a48, 0x9a7a48, 0x7a5e34, 0x2c3444, 0x8a857e, 0xa0825c, 0x8a6c4a, 0xd8c49a]
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


def animal(coat, mule):
    """A small Balkan mountain horse (about 1.5 m at the withers, the mock-up's size), or
    a mule (longer ears and head, a thin tail with a tuft, a short upright mane). Faces +x."""
    c, shade, hair, low, muzzle = COATS[coat]
    m = Model(1.6, 1.0, 2.3)
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


def blanket_red(g): return np.where((np.floor(g[..., 0] * M / 3) % 4) == 0, BLACK, BLANKET)
def blanket_blue(g): return np.where((np.floor(g[..., 0] * M / 2) % 5) == 0, RED, BLANKET2)
def blanket_felt(g): return np.where(np.abs(g[..., 2] - 1.05) < 1.0 / M, RED, FELT)


HORSES = [("bay", blanket_red), ("grey", blanket_blue), ("chestnut", blanket_felt), ("dark", blanket_red)]
MULES = [("mule", "sacks"), ("mule_dun", "kegs"), ("bay", "baskets"), ("mule", "poles")]


def models():
    out = [("tent_canvas", tent0()), ("tent_rugs", tent1()), ("fireplace", fireplace()), ("woodpile", woodpile())]
    for i, (coat, blanket) in enumerate(HORSES):
        m, s = animal(coat, False)
        riding_saddle(m, s, blanket)
        out.append(("horse_%d_%s" % (i, coat), m))
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
