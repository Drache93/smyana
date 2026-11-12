#!/usr/bin/env python3
"""Makes the trees' voxel models (art/trees/vox/<kind>_<size>.vox) from their design sheets (art/trees/design/,
tools/tree_design.py; D-035: the 2D design first, then the vox). One model a size. A voxel is one pixel of the game's art, as the men's
are (VOX_K in src/smyana/trees.lobster: 135.76 a tile), so the trees are as crisp as the men. Sizes are given in men,
measured from the mock-ups: a man in the game stands 49 voxels.
Palette: 1..4 bark, light to dark (4: the scars); 10 leaves lit from above, 11 mid, 12 the underside and the crown's
dark inside; 13 and 14 the leaves that still cling after leaf-fall (the game draws only these in autumn, on the twigs). The game reads the
index as the material and its tone, and colours the leaves by the season; the colours stored here are summer's, so the
file looks right in a voxel editor. Run from the repo's root: python3 tools/tree_vox.py   (numpy)"""
import math, random, struct
import numpy as np

K = 64 / 3.0     # voxels a metre
N = 448
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
        """A .vox model can be 256 voxels a side at most, so a bigger tree is saved in pieces: <name>.vox, and
        <name>.cXYZ.vox for the piece X, Y, Z pieces along (256 voxels each). Returns the whole size, where the
        trunk's foot is in it (the game stands the tree on it), and how many voxels."""
        xs, ys, zs = np.nonzero(self.v)
        lo = np.array([int(xs.min()), int(ys.min()), 0])
        size = [int(xs.max()) - lo[0] + 1, int(ys.max()) - lo[1] + 1, int(zs.max()) + 1]
        idx = self.v[xs, ys, zs]
        pts = np.stack([xs - lo[0], ys - lo[1], zs], -1)

        def chunk(name, data): return name.encode() + struct.pack("<ii", len(data), 0) + data
        rgba = b"".join(struct.pack("<4B", (COLOURS.get(i, 0) >> 16) & 255, (COLOURS.get(i, 0) >> 8) & 255, COLOURS.get(i, 0) & 255, 255) for i in range(1, 257))
        piece = pts // 256
        for c in np.unique(piece, axis=0):
            sel = (piece == c).all(axis=1)
            local = pts[sel] - c * 256
            body = np.concatenate([local, idx[sel][:, None]], -1).astype(np.uint8).tobytes()
            psize = [int(min(256, size[k] - c[k] * 256)) for k in range(3)]
            content = chunk("SIZE", struct.pack("<3i", *psize)) + chunk("XYZI", struct.pack("<i", len(local)) + body) + chunk("RGBA", rgba)
            name = path if not c.any() else path[:-4] + ".c%d%d%d.vox" % tuple(c)
            with open(name, "wb") as f: f.write(b"VOX " + struct.pack("<i", 150) + b"MAIN" + struct.pack("<ii", 0, len(content)) + content)
        return size, (N // 2 - lo[0], N // 2 - lo[1]), len(xs)


MAN = 48.79       # voxels to a man's height, as he stands in the game beside a tree (measured from a frame)
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


def broadleaf(height, girth, bole, spread, boughs, seed, cling=0.4, stout=1.0, fill=16, body=0.0, skirt=0.0, split=0):
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
    # (2026-11-12, Dominic, from a beech wood: "the trees have foliage all the way up the branch, or we've got the ones
    # where the tree splits early at the bottom". split: the trunk forks low into that many stems, each with a crown of
    # its own, the crowns leaning apart.)
    stems = []
    if split > 1:
        low = np.array([cx, cy, H * rng.uniform(0.1, 0.17)])
        m.capsule((cx, cy, r0), low, r0, r0 * 0.9, BARK)
        turn = rng.uniform(0, 6.28)
        for k in range(split):
            a = turn + 2 * math.pi * (k + rng.uniform(-0.15, 0.15)) / split
            lean = S * rng.uniform(0.28, 0.42)
            top_k = np.array([cx + math.cos(a) * lean, cy + math.sin(a) * lean, H * bole * rng.uniform(1.05, 1.3)])
            m.capsule(low, top_k, r0 * 0.78, r0 * 0.55, BARK)
            stems.append((low, top_k, a))
    else:
        m.capsule((cx, cy, r0), fork, r0, r0 * 0.74, BARK)
        stems.append((np.array([cx, cy, r0 * 2.6]), fork, None))
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

    if split > 1:
        # each stem's crown: boughs mostly on its outer side, so the crowns part and the tree reads as two or three
        for low, top_k, a in stems:
            nb = max(3, boughs // split + 2)
            for i in range(nb):
                az = a + (2 * math.pi * (i + rng.uniform(-0.25, 0.25)) / nb) * 0.75
                bough(top_k - [0, 0, rng.uniform(0, 0.15) * top_k[2]], az, S * rng.uniform(0.45, 0.7), (H - top_k[2]) * rng.uniform(0.5, 0.85), r0 * 0.4 * stout)
            bough(top_k, a, S * 0.1, (H - top_k[2]) * 0.92, r0 * 0.45)
    else:
        for i in range(boughs):
            az = 2 * math.pi * (i + rng.uniform(-0.25, 0.25)) / boughs
            bough(fork - [0, 0, rng.uniform(0, 0.12) * H * bole], az, S * rng.uniform(0.6, 0.9), top * rng.uniform(0.5, 0.85), r0 * 0.52 * stout)
        bough(fork, rng.uniform(0, 6.28), S * 0.12, top * 0.95, r0 * 0.6)          # the leader
    if skirt > 0:
        # leaves all the way down: short leafy shoots off the stems from `skirt` of the height up to the crown, longer
        # the higher they are, so the green runs down the trunk in a narrowing skirt rather than sitting on a bare pole
        for low, top_k, a in stems:
            z0, z1 = H * skirt, max(top_k[2], H * 0.62)
            n = int((z1 - z0) / (0.9 * F))
            for i in range(max(0, n)):
                u = (i + rng.random()) / max(1, n)
                z = z0 + (z1 - z0) * u
                at = low + (top_k - low) * (min(z, top_k[2]) - low[2]) / max(1e-6, top_k[2] - low[2])
                at = np.array([at[0], at[1], z])
                az = rng.uniform(0, 6.28)
                ln = S * (0.12 + 0.5 * u * (1 - u * 0.4)) * rng.uniform(0.6, 1.1)
                tw = at + np.array([math.cos(az), math.sin(az), rng.uniform(-0.1, 0.35)]) * ln
                m.capsule(at, tw, 0.6 * F, 0.45 * F, BARK)
                clings = rng.random() < cling + 0.25         # (a young beech's low shoots keep their dead leaves)
                dabs(m, tw, (1.8 + 1.8 * u) * F, 8 + int(10 * u), clings, rng)
                dabs(m, (at + tw) / 2, 1.4 * F, 4, False, rng)
    for tip in tips:
        clings = rng.random() < cling
        dabs(m, tip, 2.6 * F, 10 if clings else 13, clings, rng)
        # (summer's body: more leaves round each twig's end, none of which outlast the fall)
        dabs(m, tip + np.array([rng.gauss(0, 1), rng.gauss(0, 1), rng.uniform(-0.2, 0.8)]) * 3.0 * F, 3.4 * F, fill, False, rng)
    if body > 0 and tips:
        # (2026-11-12, a Bulgarian's eye: the crowns were flat sprays on a bare trunk, an acacia's outline. A beech's
        # crown is a full dome: summer's leaves fill out the shell over the twigs' ends, thick at the top and sides,
        # thinner underneath, with a few gaps the sky shows through. None of these outlast the fall.)
        t = np.array(tips)
        c = t.mean(axis=0)
        rx = max(np.abs(t[:, 0] - c[0]).max(), np.abs(t[:, 1] - c[1]).max()) * 1.02
        lo_z, hi_z = t[:, 2].min(), t[:, 2].max()
        cz = (lo_z + hi_z) / 2 + (hi_z - lo_z) * 0.05
        rz = (hi_z - lo_z) / 2 * 1.12 + 3 * F
        for i in range(int(body * 140 * (1 if height < 2 else height / 5.5))):
            a = rng.uniform(0, 2 * math.pi)
            cz_t = rng.uniform(-0.55, 1.0)                     # (more of the shell over the middle than under it)
            ring = math.sqrt(max(0.0, 1 - cz_t * cz_t))
            sh = rng.uniform(0.72, 1.0)
            p = np.array([c[0] + math.cos(a) * ring * rx * sh, c[1] + math.sin(a) * ring * rx * sh, cz + cz_t * rz * sh])
            # (only near the twigs: the dome is leaves on branches, not a ball)
            if np.min(np.linalg.norm(t - p, axis=1)) < rx * 0.45:
                dabs(m, p, 2.8 * F, 9, False, rng)
    return m


def spruce(height, girth, bole, spread, seed):
    """Norway spruce: a narrow spire on one straight trunk, boughs in whorls that droop and turn up at the tip, the
    needles in dabs along each bough. Sizes in men, as broadleaf's."""
    rng = random.Random(seed)
    m = Model()
    H = height * MAN
    r0 = girth * MAN / 2
    S = spread * MAN
    cx = cy = N / 2
    m.capsule((cx, cy, 0), (cx, cy, r0 * 1.6), r0 * 1.5, r0, BARK)
    m.capsule((cx, cy, 0), (cx, cy, H), r0, 0.6 * F, BARK)
    for i in range(int(height * 1.2)):                   # dead stubs below the green
        z = rng.uniform(0.25, 1.0) * H * bole
        a = rng.uniform(0, 6.28)
        l = rng.uniform(0.15, 0.4) * S
        m.capsule((cx, cy, z), (cx + math.cos(a) * l, cy + math.sin(a) * l, z - l * 0.2), 0.6 * F, 0.45 * F, BARK)
    z = H * bole
    while z < H * 0.97:
        t = (z - H * bole) / (H * (1 - bole))
        reach = S * (1 - t) ** 0.8 + 1.5 * F
        n = 4 if t > 0.85 else 7
        turn = rng.uniform(0, 6.28)
        for i in range(n):
            a = turn + i * 6.283 / n + rng.uniform(-0.2, 0.2)
            l = reach * rng.uniform(0.8, 1.1)
            droop = l * (0.5 - t * 0.6)
            steps = max(2, int(l / (2.2 * F)))
            last = np.array([cx, cy, z])
            for k in range(steps):
                u = (k + 1) / steps
                at = np.array([cx + math.cos(a) * l * u, cy + math.sin(a) * l * u, z - droop * u * u + (droop * 0.2 if k == steps - 1 else 0)])
                m.capsule(last, at, 0.55 * F, 0.45 * F, BARK)
                dabs(m, at, 0.5 * F, 2, False, rng)
                dabs(m, at - [0, 0, 1.6 * F], 0.4 * F, 1, False, rng)   # the hanging branchlets
                last = at
        z += (2.6 + 2.0 * t) * F
    return m


def fir(height, girth, bole, spread, seed):
    """Silver fir: like the spruce a spire on one straight trunk, but its boughs stand out level in clean tiers with
    their tips turned up, not hanging, the needles in flat sprays along them; an old fir's top stops growing and
    spreads flat (the "stork's nest"). Sizes in men, as broadleaf's."""
    rng = random.Random(seed)
    m = Model()
    H = height * MAN
    r0 = girth * MAN / 2
    S = spread * MAN
    cx = cy = N / 2
    nest = height > 5.5
    top = H * (0.9 if nest else 0.98)
    m.capsule((cx, cy, 0), (cx, cy, r0 * 1.5), r0 * 1.45, r0, BARK)
    m.capsule((cx, cy, 0), (cx, cy, top), r0, 0.8 * F, BARK)
    for i in range(int(height * 1.0)):                   # dead stubs below the green
        z = rng.uniform(0.3, 1.0) * H * bole
        a = rng.uniform(0, 6.28)
        l = rng.uniform(0.1, 0.3) * S
        m.capsule((cx, cy, z), (cx + math.cos(a) * l, cy + math.sin(a) * l, z), 0.6 * F, 0.45 * F, BARK)
    z = H * bole
    while z < top:
        t = (z - H * bole) / (top - H * bole)
        # (the crown is a blunt cone: the tiers keep most of their reach till near the top; a nest's top is flat)
        reach = S * (1 - t ** 1.6) ** 0.7 + 1.5 * F
        if nest and t > 0.85: reach = S * 0.55
        n = 5 if t > 0.85 else 6
        turn = rng.uniform(0, 6.28)
        for i in range(n):
            a = turn + i * 6.283 / n + rng.uniform(-0.25, 0.25)
            l = reach * rng.uniform(0.8, 1.05)
            steps = max(2, int(l / (2.4 * F)))
            last = np.array([cx, cy, z])
            for k in range(steps):
                u = (k + 1) / steps
                lift = (u ** 3) * l * 0.12                  # level, the tip turned up
                at = np.array([cx + math.cos(a) * l * u, cy + math.sin(a) * l * u, z + lift])
                m.capsule(last, at, 0.6 * F, 0.45 * F, BARK)
                for side in (-1, 1):                        # flat sprays out to each side of the bough
                    b = a + side * 1.3
                    sp = at + np.array([math.cos(b), math.sin(b), 0.05]) * rng.uniform(1.0, 2.4) * F
                    dabs(m, sp, 0.35 * F, 2, False, rng)
                last = at
        z += (2.8 + 2.4 * t) * F * (1.25 if t < 0.5 else 1.0)
    return m


def black_pine(height, girth, bole, spread, boughs, seed):
    """Black pine (Pinus nigra, the Rhodopes' own): a dark grey furrowed trunk, clean for half its height, then a few
    heavy boughs that rise and spread into a broad flattened dome, the needles in dense dark tufts at the ends of the
    branchlets, so the crown reads as clumps with the sky between them. Sizes in men, as broadleaf's."""
    rng = random.Random(seed)
    m = Model()
    H = height * MAN
    r0 = girth * MAN / 2
    S = spread * MAN
    cx = cy = N / 2
    fork = np.array([cx + rng.uniform(-0.03, 0.03) * H, cy + rng.uniform(-0.03, 0.03) * H, H * bole])
    m.capsule((cx, cy, 0), (cx, cy, r0 * 2.2), r0 * 1.6, r0, BARK)
    m.capsule((cx, cy, r0), fork, r0, r0 * 0.8, BARK)
    for i in range(int(H * bole / 6 / F)):               # the bark's deep furrows, dark
        z = r0 * 2 + rng.random() * max(1.0, H * bole - r0 * 2.5)
        a = rng.uniform(0, 2 * math.pi)
        for dz in range(int(rng.uniform(3, 9) * F)):
            x, y = int(cx + math.cos(a) * (r0 * 0.92)), int(cy + math.sin(a) * (r0 * 0.92))
            zz = int(z + dz)
            if zz < N and m.v[x, y, zz] == BARK: m.v[x, y, zz] = SCAR
    for i in range(int(height * 1.2)):                   # dead stubs on the bole
        z = rng.uniform(0.3, 0.95) * H * bole
        a = rng.uniform(0, 6.28)
        l = rng.uniform(0.1, 0.25) * S
        m.capsule((cx, cy, z), (cx + math.cos(a) * l, cy + math.sin(a) * l, z + l * 0.2), 0.7 * F, 0.5 * F, BARK)
    top = H - fork[2]
    tufts = []
    for i in range(boughs):
        az = 2 * math.pi * (i + rng.uniform(-0.2, 0.2)) / boughs
        out = S * rng.uniform(0.55, 0.85)
        up = top * rng.uniform(0.35, 0.65)
        start = fork - [0, 0, rng.uniform(0, 0.15) * top]
        d = np.array([math.cos(az), math.sin(az), 0.0])
        mid = start + d * out * 0.4 + [0, 0, up * 0.75]
        end = start + d * out + [0, 0, up]
        r = r0 * 0.5
        m.capsule(start, mid, r, r * 0.7, BARK)
        m.capsule(mid, end, r * 0.7, 0.9 * F, BARK)
        for k in range(7):                               # branchlets out from the bough, level, ending in tufts
            at = mid + (end - mid) * rng.uniform(0.0, 1.0)
            a2 = az + rng.uniform(-1.5, 1.5)
            ln = S * rng.uniform(0.15, 0.32)
            br = at + np.array([math.cos(a2), math.sin(a2), rng.uniform(0.0, 0.35)]) * ln
            m.capsule(at, br, 0.9 * F, 0.6 * F, BARK)
            tufts.append(br)
        tufts.append(end)
    m.capsule(fork, fork + [rng.uniform(-3, 3) * F, rng.uniform(-3, 3) * F, top * 0.95], r0 * 0.5, 0.9 * F, BARK)
    tufts.append(fork + [0, 0, top * 0.95])
    for tip in tufts:                                    # a tuft: a dense flattened mass of needles
        dabs(m, tip, 3.0 * F, 26, False, rng)
        dabs(m, tip + [0, 0, 2.0 * F], 2.2 * F, 12, False, rng)
    return m


def make(kind, name, h, g, b, s, n, seed):
    if kind == "spruce": return spruce(h, g, b, s, seed)
    if kind == "fir": return fir(h, g, b, s, seed)
    if kind == "bpine": return black_pine(h, g, b, s, n, seed)
    if kind == "oak": return broadleaf(h, g, b, s, n, seed, cling=0.65, stout=1.3, fill=20, body=1.0)        # holds its russet leaves
    if kind == "hornbeam": return broadleaf(h, g, b, s, n, seed, cling=0.35, stout=0.9, fill=14, body=0.9, skirt=0.2, split=2 if tag_now == "hornbeam_old_1" else 0)
    if kind == "pine": return broadleaf(h, g, b, s, n, seed, cling=0.0, stout=1.0, fill=10)        # a bare bole, a high flat crown
    if kind == "beech": return broadleaf(h, g, b, s, n, seed, body=1.0, skirt=SKIRT.get(name, 0.0), split=SPLIT.get(tag_now, 0))
    return broadleaf(h, g, b, s, n, seed, body=1.0)


# (Dominic's beech wood, 2026-11-12: leafy shoots from this far up the trunk, of the height; these beeches fork low)
SKIRT = {"sapling": 0.2, "young": 0.14, "mature": 0.18, "old": 0.22}
SPLIT = {"beech_young_1": 2, "beech_mature_1": 2, "beech_old_1": 3}
tag_now = ""


# In men, measured from the route mock-ups (an old tree five or six men tall, its trunk a quarter to a third of a man
# wide): height, the trunk's width, how far up the clean bole goes, the crown's half width, boughs.
KINDS = {
    "beech": {"sapling": (1.1, 0.06, 0.35, 0.4, 3), "young": (2.7, 0.13, 0.4, 0.9, 4), "mature": (4.5, 0.27, 0.31, 1.6, 5), "old": (5.5, 0.34, 0.3, 2.0, 6)},
    "oak": {"mature": (4.0, 0.3, 0.3, 1.6, 5), "old": (5.0, 0.4, 0.28, 1.95, 6)},
    "hornbeam": {"mature": (3.4, 0.17, 0.32, 1.1, 5), "old": (4.2, 0.22, 0.3, 1.4, 6)},
    "pine": {"mature": (5.0, 0.2, 0.62, 1.1, 4), "old": (5.6, 0.26, 0.64, 1.4, 5)},
    "spruce": {"mature": (5.0, 0.2, 0.12, 0.95, 0), "old": (6.1, 0.26, 0.16, 1.15, 0)},
    "fir": {"mature": (5.0, 0.22, 0.14, 1.0, 0), "old": (6.2, 0.3, 0.2, 1.25, 0)},
    "bpine": {"mature": (4.6, 0.24, 0.5, 1.6, 5), "old": (5.4, 0.32, 0.5, 2.1, 6)},
}
lines = []
for kind, sizes in KINDS.items():
    for name, (h, g, b, s, n) in sizes.items():
        for variant in range(2 if name in ("old", "young") or (kind == "beech" and name == "mature") else 1):
            tag = "%s_%s_%d" % (kind, name, variant)
            tag_now = tag
            size, foot, count = make(kind, name, h, g, b, s, n, 100 + len(lines)).save("art/trees/vox/%s.vox" % tag)
            lines.append("%s %d %d" % (tag, foot[0], foot[1]))
            print("%s: %s voxels %d, foot %s" % (tag, size, count, foot))
# saplings of the other kinds (#98): a stem, a few twigs, a tuft of leaves or needles; made after the rest so the
# others keep their seeds
SAPLINGS = {"oak": (1.0, 0.07, 0.3, 0.45, 3), "hornbeam": (0.9, 0.05, 0.3, 0.36, 3), "spruce": (0.95, 0.05, 0.04, 0.3, 0), "fir": (0.85, 0.05, 0.05, 0.33, 0)}
for i, (kind, (h, g, b, s, n)) in enumerate(SAPLINGS.items()):
    tag = "%s_sapling_0" % kind
    size, foot, count = make(kind, "sapling", h, g, b, s, n, 900 + i).save("art/trees/vox/%s.vox" % tag)
    lines.append("%s %d %d" % (tag, foot[0], foot[1]))
    print("%s: %s voxels %d, foot %s" % (tag, size, count, foot))
# (where each trunk's foot is in its model: x y, voxels from the model's corner)
open("art/trees/vox/feet.txt", "w").write("\n".join(lines) + "\n")
