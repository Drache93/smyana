#!/usr/bin/env python3
"""Makes the trees' voxel models (art/trees/vox/<kind>_<size>.vox) from their design sheets (art/trees/design/,
tools/tree_design.py; D-035: the 2D design first, then the vox). One model a size. A voxel is 1/112 of a tile (VOX_K in
src/smyana/trees.lobster), and sizes are given in men, measured from the mock-ups: a man in the game stands 40 voxels; a .vox model can be 256 voxels a side at most.
Palette: 1..4 bark, light to dark (4: the scars); 10 leaves lit from above, 11 mid, 12 the underside and the crown's
dark inside; 13 and 14 the leaves that still cling after leaf-fall (the game draws only these in autumn, on the twigs). The game reads the
index as the material and its tone, and colours the leaves by the season; the colours stored here are summer's, so the
file looks right in a voxel editor. Run from the repo's root: python3 tools/tree_vox.py   (numpy)"""
import math, random, struct
import numpy as np

K = 64 / 3.0     # voxels a metre
N = 384
BARK, SCAR, LIT, MID, UNDER, CLING, CLING_LOW = 2, 4, 10, 11, 12, 13, 14
COLOURS = {1: 0xC4C4BC, 2: 0xA4A59E, 3: 0x80827C, 4: 0x60625E, 10: 0x7EA842, 11: 0x568232, 12: 0x325826, 13: 0x7EA842, 14: 0x568232}


class Model:
    def __init__(self):
        self.v = np.zeros((N, N, N), np.uint8)   # x, y, z (z up); the trunk stands at x = y = N/2, z = 0

    def capsule(self, a, b, ra, rb, idx, over=False):
        a, b = np.array(a, float), np.array(b, float)
        r = max(ra, rb) + 1
        lo = np.maximum(np.floor(np.minimum(a, b) - r).astype(int), 0)
        hi = np.minimum(np.ceil(np.maximum(a, b) + r).astype(int) + 1, N)
        if (hi <= lo).any(): return
        g = np.stack(np.meshgrid(*[np.arange(lo[i], hi[i]) + 0.5 for i in range(3)], indexing="ij"), -1)
        ab = b - a
        t = np.clip(((g - a) @ ab) / max(ab @ ab, 1e-6), 0, 1)
        d = np.linalg.norm(g - a - t[..., None] * ab, axis=-1)
        inside = d <= ra + (rb - ra) * t
        sub = self.v[lo[0]:hi[0], lo[1]:hi[1], lo[2]:hi[2]]
        sub[inside & ((sub == 0) | (over & (sub >= 10)))] = idx

    def spray(self, c, w, h, rng, fill):
        """a level spray of leaves round c: w across, h deep, lit on top and dark beneath, with gaps"""
        c = np.array(c, float)
        lo = np.maximum(np.floor(c - [w, w, h]).astype(int), 0)
        hi = np.minimum(np.ceil(c + [w, w, h]).astype(int) + 1, N)
        if (hi <= lo).any(): return
        g = np.stack(np.meshgrid(*[np.arange(lo[i], hi[i]) + 0.5 for i in range(3)], indexing="ij"), -1)
        q = (g - c) / [w, w, h]
        d = np.linalg.norm(q, axis=-1)
        keep = (d < 1) & (rng.random(d.shape) < fill * (1.15 - d * 0.7))
        tone = np.where(q[..., 2] > 0.25, LIT, np.where(q[..., 2] > -0.3, MID, UNDER)).astype(np.uint8)
        sub = self.v[lo[0]:hi[0], lo[1]:hi[1], lo[2]:hi[2]]
        m = keep & (sub == 0)
        sub[m] = tone[m]

    def save(self, path):
        xs, ys, zs = np.nonzero(self.v)
        lo = [int(xs.min()), int(ys.min()), 0]
        size = [int(xs.max()) - lo[0] + 1, int(ys.max()) - lo[1] + 1, int(zs.max()) + 1]
        idx = self.v[xs, ys, zs]
        body = np.stack([xs - lo[0], ys - lo[1], zs, idx], -1).astype(np.uint8).tobytes()

        def chunk(name, data): return name.encode() + struct.pack("<ii", len(data), 0) + data
        rgba = b"".join(struct.pack("<4B", (COLOURS.get(i, 0) >> 16) & 255, (COLOURS.get(i, 0) >> 8) & 255, COLOURS.get(i, 0) & 255, 255) for i in range(1, 257))
        content = chunk("SIZE", struct.pack("<3i", *size)) + chunk("XYZI", struct.pack("<i", len(xs)) + body) + chunk("RGBA", rgba)
        with open(path, "wb") as f: f.write(b"VOX " + struct.pack("<i", 150) + b"MAIN" + struct.pack("<ii", 0, len(content)) + content)
        # where the trunk's foot is in the saved model: the game stands the tree on it
        return size, (N // 2 - lo[0], N // 2 - lo[1]), len(xs)


MAN = 40.25       # voxels to a man's height, as he stands in the game beside a tree (measured from a frame)
F = MAN / 23.0   # the sizes below given in voxels were set at 23 to a man


def dabs(m, tip, reach, count, cling, rng):
    """A cluster of leaves at a twig's end: each leaf a dab, a small flattened ball two or three voxels across, lit on
    top and dark beneath. cling: these stay on after leaf-fall."""
    for i in range(count):
        p = tip + np.array([rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0.3, 0.6)]) * reach
        r = rng.uniform(1.25, 1.9) * F * 0.8
        lo = np.maximum(np.floor(p - r - 1).astype(int), 0)
        hi = np.minimum(np.ceil(p + r + 1).astype(int) + 1, N)
        if (hi <= lo).any(): continue
        g = np.stack(np.meshgrid(*[np.arange(lo[k], hi[k]) + 0.5 for k in range(3)], indexing="ij"), -1)
        q = (g - p) / [r, r, r * 0.7]
        inside = np.linalg.norm(q, axis=-1) < 1
        up = q[..., 2] > -0.1
        sub = m.v[lo[0]:hi[0], lo[1]:hi[1], lo[2]:hi[2]]
        sub[inside & up & (sub == 0)] = CLING if cling else LIT
        sub[inside & ~up & (sub == 0)] = CLING_LOW if cling else UNDER


def beech(height, girth, bole, spread, boughs, seed):
    """As on the sheet and in the target picture: a flared foot, one clean slim silver bole, boughs that rise steeply
    from the fork and then spread, each breaking into branches and fine twigs that can be seen, and the leaves in
    clusters of dabs at the twigs' ends. Sizes in men: height, the trunk's width, how far up the clean bole goes (of the
    height), the crown's half width."""
    rng = random.Random(seed)
    m = Model()
    H = height * MAN
    r0 = girth * MAN / 2
    S = spread * MAN
    cx = cy = N / 2
    fork = np.array([cx + rng.uniform(-0.02, 0.02) * H, cy + rng.uniform(-0.02, 0.02) * H, H * bole])
    m.capsule((cx, cy, 0), (cx, cy, r0 * 2.6), r0 * 1.7, r0 * 1.02, BARK)          # the elephant's foot
    m.capsule((cx, cy, r0), fork, r0, r0 * 0.74, BARK)
    for i in range(int(H * bole / 7 / F)):                                               # scars across the bark
        z = r0 * 2.6 + rng.random() * max(1.0, H * bole - r0 * 3)
        a = rng.uniform(0, 2 * math.pi)
        for da in np.linspace(-0.6, 0.6, max(3, int(r0 * 1.5))):
            x, y = int(cx + math.cos(a + da) * (r0 * 0.9)), int(cy + math.sin(a + da) * (r0 * 0.9))
            if m.v[x, y, int(z)] == BARK: m.v[x, y, int(z)] = SCAR
    top = H - fork[2]
    small = height < 2
    tips = []

    def twigs(at, az, length):
        for k in range(2 if small else 3):
            a2 = az + rng.uniform(-1.3, 1.3)
            tw = at + np.array([math.cos(a2), math.sin(a2), rng.uniform(-0.1, 0.7)]) * length
            m.capsule(at, tw, 0.7 * F, 0.5 * F, BARK)
            tips.append(tw)
            for q in range(2):                           # bare twiglets: the bristle that shows after leaf-fall
                a3 = a2 + rng.uniform(-1.5, 1.5)
                t3 = at + (tw - at) * rng.uniform(0.3, 0.9)
                m.capsule(t3, t3 + np.array([math.cos(a3), math.sin(a3), rng.uniform(0.0, 0.9)]) * length * rng.uniform(0.5, 0.9), 0.5 * F, 0.42 * F, BARK)

    def bough(start, az, out, up, r):
        d = np.array([math.cos(az), math.sin(az), 0.0])
        mid = start + d * out * 0.3 + [0, 0, up * 0.55]
        end = start + d * out + [0, 0, up]
        m.capsule(start, mid, r, r * 0.7, BARK)
        m.capsule(mid, end, r * 0.7, 0.8 * F, BARK)
        for k in range(2 if small else 4):               # branches off it, out and up
            t = rng.uniform(0.25, 1.0)
            at = mid + (end - mid) * t
            a2 = az + rng.uniform(-1.4, 1.4)
            ln = S * rng.uniform(0.25, 0.45)
            br = at + np.array([math.cos(a2), math.sin(a2), rng.uniform(0.1, 0.8)]) * ln
            m.capsule(at, br, max(0.8 * F, r * 0.3), 0.65 * F, BARK)
            twigs(br, a2, S * rng.uniform(0.12, 0.22))
            twigs((at + br) / 2, a2 + rng.uniform(-1, 1), S * rng.uniform(0.1, 0.18))
        twigs(end, az, S * rng.uniform(0.12, 0.22))

    for i in range(boughs):
        az = 2 * math.pi * (i + rng.uniform(-0.25, 0.25)) / boughs
        bough(fork - [0, 0, rng.uniform(0, 0.12) * H * bole], az, S * rng.uniform(0.6, 0.9), top * rng.uniform(0.5, 0.85), r0 * 0.52)
    bough(fork, rng.uniform(0, 6.28), S * 0.12, top * 0.95, r0 * 0.6)              # the leader
    for tip in tips:
        cling = rng.random() < 0.4
        dabs(m, tip, 2.6 * F, 10 if cling else 13, cling, rng)
    return m


SIZES = {  # in men, measured from the route mock-ups (an old tree six men tall, its trunk a quarter of a man wide)
    "sapling": (1.1, 0.06, 0.35, 0.4, 3), "young": (2.7, 0.13, 0.4, 0.9, 4),
    "mature": (4.5, 0.22, 0.36, 1.6, 5), "old": (5.5, 0.28, 0.36, 2.0, 6),
}
lines = []
for name, (h, g, b, s, n) in SIZES.items():
    for variant in range(2 if name in ("mature", "old", "young") else 1):
        tag = "%s_%d" % (name, variant)
        size, foot, count = beech(h, g, b, s, n, 100 + len(lines)).save("art/trees/vox/beech_%s.vox" % tag)
        lines.append("beech_%s %d %d" % (tag, foot[0], foot[1]))
        print("beech_%s: %s voxels %d, foot %s" % (tag, size, count, foot))
# (where each trunk's foot is in its model: x y, voxels from the model's corner)
open("art/trees/vox/feet.txt", "w").write("\n".join(lines) + "\n")
