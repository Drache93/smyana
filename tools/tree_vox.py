#!/usr/bin/env python3
"""Makes the trees' voxel models (art/trees/vox/<kind>_<size>.vox) from their design sheets (art/trees/design/,
tools/tree_design.py; D-035: the 2D design first, then the vox). One model a size. A voxel is 1/64 of a tile, and a
tile is 3 m at the game's scale (a man is 1.7 m: about 36 voxels).
Palette: 1..4 bark, light to dark (4: the scars); 10 leaves lit from above, 11 mid, 12 the underside. The game reads the
index as the material and its tone, and colours the leaves by the season; the colours stored here are summer's, so the
file looks right in a voxel editor. Run from the repo's root: python3 tools/tree_vox.py   (numpy)"""
import math, random, struct
import numpy as np

K = 64 / 3.0     # voxels a metre
N = 256
BARK, SCAR, LIT, MID, UNDER = 2, 4, 10, 11, 12
COLOURS = {1: 0xC4C4BC, 2: 0xA4A59E, 3: 0x80827C, 4: 0x60625E, 10: 0x7EA842, 11: 0x568232, 12: 0x325826}


class Model:
    def __init__(self):
        self.v = np.zeros((N, N, N), np.uint8)   # x, y, z (z up); the trunk stands at x = y = N/2, z = 0

    def capsule(self, a, b, ra, rb, idx):
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
        sub[inside & (sub == 0)] = idx

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


def beech(height, girth, bole, spread, seed):
    """As on the sheet: a flared foot, one clean silver bole, boughs that rise steeply and then spread, level sprays of
    leaves in layers making a tall dome. Sizes in metres."""
    rng = random.Random(seed)
    nrng = np.random.default_rng(seed)
    m = Model()
    H = height * K
    r0 = girth * K / 2
    cx = cy = N / 2
    fork = np.array([cx + rng.uniform(-0.02, 0.02) * H, cy + rng.uniform(-0.02, 0.02) * H, H * bole])
    m.capsule((cx, cy, 0), (cx, cy, r0 * 2.4), r0 * 1.8, r0 * 1.02, BARK)          # the elephant's foot
    m.capsule((cx, cy, r0), fork, r0, r0 * 0.72, BARK)
    for i in range(int(H * bole / 9)):                                               # scars across the bark
        z = r0 * 2.6 + rng.random() * max(1.0, H * bole - r0 * 3)
        a = rng.uniform(0, 2 * math.pi)
        for da in np.linspace(-0.5, 0.5, max(3, int(r0))):
            x, y = int(cx + math.cos(a + da) * (r0 * 0.95)), int(cy + math.sin(a + da) * (r0 * 0.95))
            if m.v[x, y, int(z)] == BARK: m.v[x, y, int(z)] = SCAR
    tips = []
    n = 6 if height > 6 else 5 if height > 3 else 3
    for i in range(n):
        az = 2 * math.pi * (i + rng.uniform(-0.25, 0.25)) / n
        t = (i * 0.618) % 1.0
        out = H * spread * rng.uniform(0.55, 1.0) * (0.4 + 0.6 * (1 - abs(t - 0.4)))
        up = H * (1 - bole) * rng.uniform(0.45, 0.9) * (0.5 + 0.5 * t)
        d = np.array([math.cos(az), math.sin(az), 0.0])
        start = fork - [0, 0, H * bole * 0.16 * (1 - t)]
        mid = start + d * out * 0.35 + [0, 0, up * 0.62]
        end = start + d * out + [0, 0, up]
        m.capsule(start, mid, r0 * 0.42, r0 * 0.26, BARK)
        m.capsule(mid, end, r0 * 0.26, max(0.8, r0 * 0.1), BARK)
        tips += [mid, end]
        for k in range(3):
            a2 = az + rng.uniform(-1.1, 1.1)
            tw = end + np.array([math.cos(a2), math.sin(a2), 0]) * H * spread * rng.uniform(0.12, 0.3) + [0, 0, rng.uniform(-0.03, 0.12) * H]
            m.capsule(end, tw, max(0.8, r0 * 0.1), 0.6, BARK)
            tips.append(tw)
    lead = np.array([fork[0] + rng.uniform(-0.03, 0.03) * H, fork[1] + rng.uniform(-0.03, 0.03) * H, H * 0.93])
    m.capsule(fork, lead, r0 * 0.5, max(0.8, r0 * 0.1), BARK)
    tips += [lead, (fork + lead) / 2]
    # the dome: more sprays between the boughs, leafy down its sides
    for i in range(int(6 + height * 1.5)):
        v = rng.random()
        z = fork[2] + (H * 0.95 - fork[2]) * v + H * 0.04
        half = H * spread * (0.35 + 0.75 * math.sin(math.pi * min(1.0, v * 0.85 + 0.12)))
        a = rng.uniform(0, 2 * math.pi)
        rad = half * math.sqrt(rng.random())
        tips.append(np.array([fork[0] + math.cos(a) * rad, fork[1] + math.sin(a) * rad, z]))
    for tip in tips:
        w = H * spread * rng.uniform(0.24, 0.4)
        m.spray(tip, w, max(1.6, w * 0.1), nrng, 0.8)
    return m


SIZES = {  # as on the sheet: height, girth, how far up the clean bole goes, spread
    "sapling": (1.6, 0.07, 0.25, 0.5), "young": (4.2, 0.2, 0.38, 0.4), "mature": (7.6, 0.5, 0.42, 0.4), "old": (10.2, 0.85, 0.4, 0.42),
}
lines = []
for name, (h, g, b, s) in SIZES.items():
    for variant in range(2 if name in ("mature", "old", "young") else 1):
        tag = "%s_%d" % (name, variant)
        size, foot, count = beech(h, g, b, s, 100 + len(lines)).save("art/trees/vox/beech_%s.vox" % tag)
        lines.append("beech_%s %d %d" % (tag, foot[0], foot[1]))
        print("beech_%s: %s voxels %d, foot %s" % (tag, size, count, foot))
# (where each trunk's foot is in its model: x y, voxels from the model's corner)
open("art/trees/vox/feet.txt", "w").write("\n".join(lines) + "\n")
