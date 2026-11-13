#!/usr/bin/env python3
"""Makes the trees' voxel models (art/trees/vox/<kind>_<size>.vox) from their design sheets (art/trees/design/,
tools/tree_design.py; D-035: the 2D design first, then the vox). One model a size. A voxel is one pixel of the game's art, as the men's
are (VOX_K in src/smyana/trees.lobster: 135.76 a tile), so the trees are as crisp as the men. Sizes are given in men,
measured from the mock-ups: a man in the game stands 49 voxels.
Palette: 1..4 bark, light to dark (4: the scars); 10 leaves lit from above, 11 mid, 12 the underside and the crown's
dark inside; 13 and 14 the leaves that still cling after leaf-fall (the game draws only these in autumn, on the twigs). The game reads the
index as the material and its tone, and colours the leaves by the season; the colours stored here are summer's, so the
file looks right in a voxel editor. Run from the repo's root: python3 tools/tree_vox.py   (numpy)"""
import glob, math, os, random, struct
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
        for old in glob.glob(path[:-4] + ".c[0-9][0-9][0-9].vox"): os.remove(old)   # (a smaller tree needs fewer pieces)
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


def broadleaf(height, girth, bole, spread, boughs, seed, cling=0.4, stout=1.0, fill=16, body=0.0, skirt=0.0, split=0, dead=0.0):
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
        if rng.random() < dead:
            # (an old oak's dead limb, "stag-headed": bare grey wood standing out of the top of the crown, a stub or two)
            m.capsule(end, end + [rng.uniform(-2, 2) * F, rng.uniform(-2, 2) * F, up * 0.35], 1.0 * F, 0.6 * F, BARK)
            for k in range(2):
                at = mid + (end - mid) * rng.uniform(0.3, 0.9)
                a2 = az + rng.uniform(-1.2, 1.2)
                m.capsule(at, at + np.array([math.cos(a2), math.sin(a2), 0.6]) * S * 0.15, 0.8 * F, 0.55 * F, BARK)
            return
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


def plate(m, c, w, rng, cling, n=None):
    """A spray of beech leaves: a flat, level plate of leaf dabs w across and a third as deep, lit on top and dark
    beneath, as a beech holds its leaves out in layers along a branch (Dominic's photos, 2026-11-13)."""
    for i in range(n or max(4, int(w / F * 1.6))):
        a = rng.uniform(0, 2 * math.pi)
        r = w * math.sqrt(rng.random())
        p = c + np.array([math.cos(a) * r, math.sin(a) * r, rng.gauss(0, w * 0.12) - r * r / (w * 4.0)])
        dabs(m, p, 0.35 * F, 2, cling, rng)


def buttresses(m, cx, cy, r0, rng, n):
    """the root flare: buttresses running out from the foot of the trunk into the ground"""
    for k in range(n):
        a = 2 * math.pi * (k + rng.uniform(-0.2, 0.2)) / n
        out = r0 * rng.uniform(1.7, 2.3)
        m.capsule((cx, cy, r0 * 1.8), (cx + math.cos(a) * out, cy + math.sin(a) * out, 0), r0 * 0.55, r0 * 0.22, BARK)


def burrs(m, cx, cy, r0, top, rng):
    """an old trunk's burrs and wounds: lumps of bark and darker scars up to `top`"""
    for i in range(6):
        z = rng.uniform(0.25, 1.0) * top
        a = rng.uniform(0, 2 * math.pi)
        c = np.array([cx + math.cos(a) * r0 * 0.85, cy + math.sin(a) * r0 * 0.85, z])
        m.capsule(c, c + [0, 0, rng.uniform(1, 4) * F], r0 * rng.uniform(0.2, 0.35), r0 * 0.18, BARK if i % 2 else SCAR)


def beech(height, girth, bole, spread, limbs, seed, cling=0.4, skirt=0.0, split=0, veteran=False):
    """A beech as in Dominic's photos (2026-11-13: an open-grown beech, and old beeches of the Balkan beech woods): one
    crown shaped like an egg, widest a little below its middle, from low on the tree to the top, and round over all of
    it, not a cap on a pole. The trunk runs up through it as a leader, and the limbs leave it all the way up: the low
    ones long, reaching out near level and drooping at their ends, the high ones short and steep, each just reaching
    the egg's shell. The leaves lie in flat layered sprays along every limb and branch from near the trunk out, so the
    crown is leafy through its depth, with the sky and the grey limbs showing between the layers. split: the trunk
    forks low into that many great limbs, each its own leader (the old forest's beeches). veteran: an old giant of the
    forest, a thick fluted bole on a wide root flare, burrs and old wounds, and dead stubs in the crown. Sizes in men,
    as broadleaf's."""
    rng = random.Random(seed)
    m = Model()
    H = height * MAN
    r0 = girth * MAN / 2
    S = spread * MAN
    cx = cy = N / 2
    zb = H * (0.44 if veteran else max(0.12, bole * 0.55))   # the crown's foot (a giant's high, over its great limbs)
    zw = zb + (H - zb) * 0.42               # where it is widest
    lo_ax, hi_ax = zw - zb, H - zw

    ph = [rng.uniform(0, 6.28) for _ in range(4)]

    def shell(z, a=0.0):
        """the egg's half width at height z, toward a: not a smooth egg but lobed, as the big limbs each carry their
        own mass of leaves"""
        t = (z - zw) / (lo_ax if z < zw else hi_ax)
        lobes = 1.0 + 0.11 * math.sin(3 * a + ph[0] + z / (9 * F)) + 0.07 * math.sin(5 * a + ph[1] - z / (6 * F)) + 0.05 * math.sin(z / (5 * F) + ph[2])
        return S * math.sqrt(max(0.0, 1 - t * t)) * lobes

    def inside(p, k=1.0):
        d = math.hypot(p[0] - cx, p[1] - cy)
        a = math.atan2(p[1] - cy, p[0] - cx)
        return d <= shell(min(max(p[2], zb), H), a) * k + 1e-6 and zb * 0.85 <= p[2] <= H * 1.02

    def reach_out(start, d):
        """how far along d from start before the shell"""
        lo, hi = 0.0, 2.5 * S + H
        for _ in range(24):
            mid = (lo + hi) / 2
            if inside(start + d * mid): lo = mid
            else: hi = mid
        return lo

    # the foot: the root flare, wide and low, in buttresses
    m.capsule((cx, cy, 0), (cx, cy, r0 * 2.6), r0 * (1.35 if veteran else 1.6), r0 * 1.02, BARK)
    buttresses(m, cx, cy, r0, rng, 7 if veteran else 5)
    stems = []
    if split > 1:
        low = np.array([cx, cy, H * rng.uniform(0.14, 0.22)])
        m.capsule((cx, cy, r0), low, r0, r0 * 0.92, BARK)
        turn = rng.uniform(0, 6.28)
        for k in range(split):
            a = turn + 2 * math.pi * (k + rng.uniform(-0.12, 0.12)) / split
            lean = S * (rng.uniform(0.4, 0.55) if veteran else rng.uniform(0.25, 0.4))
            # (a great limb: up and out, then up again, a little crooked, as on the old Balkan beeches; a giant's
            # crooked and kinked)
            kink = rng.uniform(-0.35, 0.35) if veteran else 0.0
            mid = low + np.array([math.cos(a + kink) * lean * 0.8, math.sin(a + kink) * lean * 0.8, (H - low[2]) * 0.3])
            top_k = np.array([cx + math.cos(a) * lean, cy + math.sin(a) * lean, H * rng.uniform(0.82, 0.92)])
            rk = r0 * (0.72 if split == 2 else 0.62)
            m.capsule(low, mid, rk, rk * 0.85, BARK)
            m.capsule(mid, top_k, rk * 0.85, 0.9 * F, BARK)
            stems.append((low, mid, top_k, a, rk))
    else:
        top_k = np.array([cx + rng.uniform(-0.03, 0.03) * S, cy + rng.uniform(-0.03, 0.03) * S, H * 0.9])
        mid = np.array([cx, cy, H * 0.5])
        m.capsule((cx, cy, r0), mid, r0, r0 * 0.7, BARK)
        m.capsule(mid, top_k, r0 * 0.7, 0.9 * F, BARK)
        stems.append((np.array([cx, cy, r0 * 2.6]), mid, top_k, None, r0 * 0.7))
    for i in range(int(H * 0.4 / 7 / F) * (2 if veteran else 1)):                       # scars across the bark
        z = r0 * 2.6 + rng.random() * max(1.0, H * 0.35 - r0 * 3)
        a = rng.uniform(0, 2 * math.pi)
        for da in np.linspace(-0.6, 0.6, max(3, int(r0 * 1.5))):
            x, y = int(cx + math.cos(a + da) * (r0 * 0.9)), int(cy + math.sin(a + da) * (r0 * 0.9))
            if m.v[x, y, int(z)] == BARK: m.v[x, y, int(z)] = SCAR
    if veteran: burrs(m, cx, cy, r0, H * 0.3, rng)

    def along(stem, z):
        """the point on a stem's axis at height z"""
        low, mid, top_k = stem[0], stem[1], stem[2]
        a, b = (low, mid) if z <= mid[2] else (mid, top_k)
        t = min(1.0, max(0.0, (z - a[2]) / max(1e-6, b[2] - a[2])))
        return a + (b - a) * t

    def leafy(at, d, length, r, depth):
        """a limb or branch from `at` along d, `length` long and r thick at its foot: out, its end drooping if it
        is near level, the branches off it, and its leaves in sprays along it"""
        n = max(2, int(length / (3.0 * F)))
        level = 1.0 - min(1.0, max(0.0, d[2] / 0.7))      # (a near-level limb droops at its end)
        pts = [at]
        for k in range(n):
            u = (k + 1) / n
            p = at + d * length * u + np.array([0, 0, -level * length * 0.18 * u * u])
            pts.append(p)
        for k in range(n):
            u = k / n
            m.capsule(pts[k], pts[k + 1], max(0.55 * F, r * (1 - u * 0.8)), max(0.5 * F, r * (1 - (k + 1) / n * 0.8)), BARK)
            if u > 0.2: wood.append(pts[k + 1])
        if depth == 0 and veteran and rng.random() < 0.25:
            return                                         # (a dead limb: bare grey wood, no leaves)
        for k in range(1, n + 1):
            p = pts[k]
            u = k / n
            if depth < 2:
                # branches off it to either side, level or a little up, shorter toward the end
                for side in (-1, 1):
                    if rng.random() < (0.75 if depth == 0 else 0.5) and u > 0.12:
                        az = math.atan2(d[1], d[0]) + side * rng.uniform(0.6, 1.3)
                        dd = np.array([math.cos(az), math.sin(az), rng.uniform(-0.05, 0.35)])
                        dd /= np.linalg.norm(dd)
                        ln = min(reach_out(p, dd) * 0.95, length * rng.uniform(0.25, 0.45) * (1.1 - u * 0.5))
                        if ln > 2.5 * F: leafy(p, dd, ln, max(0.6 * F, r * 0.45 * (1 - u * 0.6)), depth + 1)
            # its leaves: flat sprays along it from a third of the way out, and a fuller one at its end
            if u > 0.3 or depth > 0:
                q = p + np.array([rng.gauss(0, 1.0), rng.gauss(0, 1.0), rng.uniform(0.3, 1.5)]) * F
                if inside(q, 1.06): plate(m, q, (2.6 + 2.2 * u) * F * (1.0 if depth else 1.2), rng, rng.random() < cling)
        end = pts[-1] + np.array([0, 0, 0.8 * F])
        if inside(end, 1.08): plate(m, end, 4.5 * F, rng, rng.random() < cling, n=14)
        # (bare twiglets at its end: the bristle that shows after leaf-fall)
        for q in range(2):
            az = math.atan2(d[1], d[0]) + rng.uniform(-1.4, 1.4)
            t3 = pts[-1] + np.array([math.cos(az), math.sin(az), rng.uniform(0.0, 0.8)]) * rng.uniform(2, 4) * F
            m.capsule(pts[-1], t3, 0.5 * F, 0.42 * F, BARK)

    wood = []   # (points along the branches, where the shell's sprays below grow from)

    # the limbs, up each stem in a spiral (a beech's leaves and limbs alternate round it), from the crown's foot up
    for stem in stems:
        low, mid, top_k, a_out, rk = stem
        z0 = max(zb, low[2] + 2 * F)
        nl = int(limbs * 4 * (1.0 if split <= 1 else 0.6))
        turn = rng.uniform(0, 6.28)
        for i in range(nl):
            u = (i + rng.uniform(0.1, 0.9)) / nl
            z = z0 + (top_k[2] - z0) * u ** 0.9
            at = along(stem, z)
            az = turn + i * 2.39996 + rng.uniform(-0.3, 0.3)       # (the golden angle)
            if a_out is not None:                                  # (on a forked tree, mostly to the outer side)
                da = (az - a_out + math.pi) % (2 * math.pi) - math.pi
                az = a_out + da * 0.65
            rise = 0.05 + 0.95 * u ** 1.3 + rng.uniform(-0.08, 0.08)   # (low ones near level, high ones steep)
            d = np.array([math.cos(az), math.sin(az), rise * 1.4])
            d /= np.linalg.norm(d)
            ln = reach_out(at, d) * rng.uniform(0.8, 0.95)
            if ln > 3 * F: leafy(at, d, ln, max(0.8 * F, rk * (0.5 - 0.3 * u)), 0)
        # its top: a short leafy leader
        plate(m, top_k + [0, 0, 2 * F], 4 * F, rng, False, n=16)
    if wood:
        # the round of it: sprays out to the egg's shell all over, under as well as on top, each on a twig from the
        # nearest branch, so the outline is the egg and not the limbs' ends
        w = np.array(wood)
        for i in range(int(520 * (height / 5.5) ** 2)):
            a = rng.uniform(0, 2 * math.pi)
            t = rng.uniform(-1.0, 1.0)
            if t < -0.5 and rng.random() < 0.5: continue   # (a little thinner underneath)
            z = zw + t * (lo_ax if t < 0 else hi_ax)
            k = rng.uniform(0.82, 1.0) if rng.random() < 0.85 else rng.uniform(0.5, 0.82)
            p = np.array([cx + math.cos(a) * shell(z, a) * k, cy + math.sin(a) * shell(z, a) * k, z])
            dist = np.linalg.norm(w - p, axis=1)
            j = int(np.argmin(dist))
            if dist[j] > S * 0.3: continue                   # (no branch near: a gap the sky shows through)
            if dist[j] > 2.5 * F: m.capsule(w[j], p, 0.5 * F, 0.42 * F, BARK)
            plate(m, p, rng.uniform(2.2, 3.6) * F, rng, rng.random() < cling, n=7)
    if skirt > 0 and not veteran:
        # leafy shoots up the trunk below the crown (D-112), short, as the photos have on the lower bole
        for stem in stems[:1]:
            z0, z1 = H * skirt, zb
            n = int((z1 - z0) / (1.6 * F))
            for i in range(max(0, n)):
                z = z0 + (z1 - z0) * (i + rng.random()) / max(1, n)
                at = along(stem, z)
                az = rng.uniform(0, 6.28)
                ln = (1.5 + rng.random() * 3.0) * F
                tw = at + np.array([math.cos(az) * (r0 + ln), math.sin(az) * (r0 + ln), rng.uniform(0, 1.5) * F])
                m.capsule(at, tw, 0.55 * F, 0.45 * F, BARK)
                plate(m, tw, 2.2 * F, rng, rng.random() < cling + 0.25, n=6)
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
    if kind == "oak": return broadleaf(h, g, b, s, n, seed, cling=0.65, stout=1.3, fill=20, body=1.0, dead=0.25 if tag_now in VETERANS else 0.0)        # holds its russet leaves
    if kind == "hornbeam": return broadleaf(h, g, b, s, n, seed, cling=0.35, stout=0.9, fill=14, body=0.9, skirt=0.2, split=2 if tag_now == "hornbeam_old_1" else 0)
    if kind == "pine": return broadleaf(h, g, b, s, n, seed, cling=0.0, stout=1.0, fill=10)        # a bare bole, a high flat crown
    if kind == "beech": return beech(h, g, b, s, n, seed, skirt=SKIRT.get(name, 0.0), split=SPLIT.get(tag_now, 0), veteran=tag_now in VETERANS)
    return broadleaf(h, g, b, s, n, seed, body=1.0)


# (Dominic's beech wood, 2026-11-12: leafy shoots from this far up the trunk, of the height; these beeches fork low)
SKIRT = {"sapling": 0.2, "young": 0.14, "mature": 0.18, "old": 0.22}
SPLIT = {"beech_young_1": 2, "beech_mature_1": 2, "beech_old_1": 3}
# (Dominic, 2026-11-13: "The forest is old, likely they've be some really big/thick ones": each kind's second old
# model is a giant of the old forest, which the men can't fell)
# (a real one: an ancient beech is over 4.5 m round, a metre and a half across, and old Balkan beeches fork low into
# great crooked limbs, Dominic's photos; sizes as KINDS's, in men)
# Others from field sources (2026-11-13): an ancient oak over 6 m round, the Rhodope-ish oaks of Velichka 5 m round
# and 18 to 22 m tall, their crowns holding dead wood; an old silver fir 2 to 2.5 m across, its top gone flat or
# stag-headed; an old Norway spruce 1 to 1.5 m across, tapering fast; the Scots pine of Pchelarovo in the Rhodopes,
# 500 years old, 25 m tall and 3.5 m round. The game's trees are a third of their real height, so the giants read
# stout. Hornbeam has no giant: it stays a smaller tree.
VETERANS = {"beech_old_1": (6.2, 0.7, 0.3, 2.5, 6), "oak_old_1": (5.4, 0.9, 0.24, 2.4, 7), "fir_old_1": (7.2, 0.75, 0.2, 1.45, 0),
            "spruce_old_1": (7.4, 0.62, 0.16, 1.35, 0), "pine_old_1": (6.2, 0.62, 0.62, 1.6, 6), "bpine_old_1": (5.8, 0.7, 0.45, 2.5, 7)}
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
def models():
    """Every model in order: its name, and how to make it (each with its own seed, whichever are made)."""
    out = []
    for kind, sizes in KINDS.items():
        for name, (h, g, b, s, n) in sizes.items():
            for variant in range(2 if name in ("old", "young") or (kind == "beech" and name == "mature") else 1):
                out.append(("%s_%s_%d" % (kind, name, variant), kind, name, (h, g, b, s, n), 100 + len(out)))
    # saplings of the other kinds (#98): a stem, a few twigs, a tuft of leaves or needles; made after the rest so the
    # others keep their seeds
    SAPLINGS = {"oak": (1.0, 0.07, 0.3, 0.45, 3), "hornbeam": (0.9, 0.05, 0.3, 0.36, 3), "spruce": (0.95, 0.05, 0.04, 0.3, 0), "fir": (0.85, 0.05, 0.05, 0.33, 0)}
    for i, (kind, dims) in enumerate(SAPLINGS.items()):
        out.append(("%s_sapling_0" % kind, kind, "sapling", dims, 900 + i))
    return out


def build(tag, kind, name, dims, seed):
    global tag_now
    tag_now = tag
    h, g, b, s, n = VETERANS.get(tag, dims)
    m = make(kind, name, h, g, b, s, n, seed)
    if tag in VETERANS:
        rng = random.Random(seed + 7)
        r0 = g * MAN / 2
        if kind != "beech":
            # (a giant's foot: its buttresses, and burrs and old wounds up its bole)
            buttresses(m, N / 2, N / 2, r0, rng, 6)
            burrs(m, N / 2, N / 2, r0, h * MAN * 0.3, rng)
        character(m, kind, h, g, b, s, seed, rng)
    return m


# What an old giant has lived through (Dominic, 2026-11-13: "a little more character with old ones than just bigger...
# They've survived a lot. They've maybe survived a lightning strike or two"). From the Woodland Trust's "What are
# ancient trees?": a hollowing trunk with openings to the outside and holes where limbs broke away; a crown "growing
# downwards", dead antler-like limbs standing out of it (stag-headed); in conifers a top flattened by storm or lightning
# "with many new stems"; dead broken lower branches kept on the trunk. And from Alabama Extension on lightning: bark
# "blown out along a narrow strip" that can "spiral down the trunk", a trunk split, the crown blown out.
CHARACTER = {
    "beech": ("strike", "hollow", "snags"),
    "oak": ("hollow", "strike", "snags"),
    "fir": ("broken", "strike"),
    "spruce": ("broken", "hollow"),
    "pine": ("strike", "snags", "hollow"),
    "bpine": ("snags", "hollow"),
}
WOOD, DARK = 1, 4   # bare wood where the bark is gone (palette 1, the lightest), and the dark of a hollow or a wound


def strike(m, kind, H, r0, a0, rng):
    """one lightning scar down the trunk, from `H`'s top of the bole"""
    cx = cy = N / 2
    top = int(H * (0.55 if kind in ("fir", "spruce") else 0.45))
    twist = rng.choice((-1, 1)) * 2 * math.pi * rng.uniform(0.4, 0.7) / max(1, top)
    x0, x1 = int(cx - r0 * 2.5), int(cx + r0 * 2.5) + 1
    sub = m.v[x0:x1, x0:x1, :top]
    xs, ys, zs = np.nonzero((sub > 0) & (sub < 10))
    ang = np.arctan2(ys + x0 + 0.5 - cy, xs + x0 + 0.5 - cx)
    d = (ang - (a0 + zs * twist) + np.pi) % (2 * np.pi) - np.pi
    half = 0.42 * (0.5 + 0.5 * zs / top)   # (narrowing to the ground)
    sub[xs[np.abs(d) < half], ys[np.abs(d) < half], zs[np.abs(d) < half]] = WOOD
    edge = (np.abs(d) >= half) & (np.abs(d) < half + 0.1)
    sub[xs[edge], ys[edge], zs[edge]] = DARK


def character(m, kind, h, g, b, s, seed, rng):
    H = h * MAN
    r0 = g * MAN / 2
    cx = cy = N / 2
    for what in CHARACTER.get(kind, ()):
        if what == "strike":
            # a lightning scar: a strip of bare wood an eighth of the trunk round, spiralling down it from high on the
            # bole to the ground, its edges dark; struck twice ("a lightning strike or two"), on both sides
            a0 = rng.uniform(0, 2 * math.pi)
            strike(m, kind, H, r0, a0, rng)
            strike(m, kind, H * 0.8, r0, a0 + math.pi + rng.uniform(-0.6, 0.6), rng)
        elif what == "hollow":
            # a hollow at the foot, open to one side: dark inside, its lips rolled
            a = rng.uniform(0, 2 * math.pi)
            c = np.array([cx + math.cos(a) * r0 * 0.7, cy + math.sin(a) * r0 * 0.7, r0 * 2.0])
            rr = np.array([r0 * 0.7, r0 * 0.7, r0 * 2.2])
            lo = np.maximum(np.floor(c - rr * 1.4).astype(int), 0)
            hi = np.minimum(np.ceil(c + rr * 1.4).astype(int) + 1, N)
            gr = np.stack(np.meshgrid(*[np.arange(lo[i], hi[i]) + 0.5 for i in range(3)], indexing="ij"), -1)
            q = np.linalg.norm((gr - c) / rr, axis=-1)
            sub = m.v[lo[0]:hi[0], lo[1]:hi[1], lo[2]:hi[2]]
            wood = (sub > 0) & (sub < 10)
            sub[(q < 1.0) & wood] = 0
            sub[(q >= 1.0) & (q < 1.35) & wood] = DARK
            # (and a hole higher up, where a limb broke away)
            z = rng.uniform(0.25, 0.4) * H
            c2 = np.array([cx + math.cos(a + 2.2) * r0 * 0.9, cy + math.sin(a + 2.2) * r0 * 0.9, z])
            m.capsule(c2, c2 + [0, 0, r0 * 0.4], r0 * 0.3, r0 * 0.25, DARK, over=False)
            x, y, zz = np.round(c2).astype(int)
            m.v[x - 1:x + 2, y - 1:y + 2, zz - 1:zz + 3] = np.where(m.v[x - 1:x + 2, y - 1:y + 2, zz - 1:zz + 3] > 0, DARK, 0)
        elif what == "snags":
            # dead limbs standing out of the top of the crown, bare and grey, antler-like
            for k in range(rng.randint(2, 4)):
                a = rng.uniform(0, 2 * math.pi)
                out = s * MAN * rng.uniform(0.15, 0.55)
                start = np.array([cx + math.cos(a) * out * 0.5, cy + math.sin(a) * out * 0.5, H * rng.uniform(0.72, 0.85)])
                end = np.array([cx + math.cos(a) * out, cy + math.sin(a) * out, H * rng.uniform(1.0, 1.1)])
                m.capsule(start, end, 1.3 * F, 0.6 * F, 3, over=True)
                for j in range(2):
                    t = start + (end - start) * rng.uniform(0.4, 0.8)
                    b2 = a + rng.uniform(-1.2, 1.2)
                    m.capsule(t, t + np.array([math.cos(b2), math.sin(b2), 0.9]) * rng.uniform(3, 6) * F, 0.7 * F, 0.45 * F, 3, over=True)
        elif what == "broken":
            # the top snapped by storm or lightning: a jagged dead stub, and new tops grown up round it from the
            # highest whorls left ("flattening and broadening of the crown... with many new stems")
            zc = int(H * 0.66)
            m.v[:, :, zc:] = 0
            m.capsule((cx, cy, zc - 6 * F), (cx + 1.5 * F, cy, zc + 6 * F), r0 * 0.35, 0.8 * F, 3, over=True)
            m.capsule((cx + 1.5 * F, cy, zc + 6 * F), (cx + 0.5 * F, cy + 1.0 * F, zc + 9 * F), 0.9 * F, 0.5 * F, 3, over=True)
            maker = spruce if kind == "spruce" else fir
            for k in range(3):
                a = rng.uniform(0, 2 * math.pi) if k == 0 else a + 2 * math.pi / 3 + rng.uniform(-0.4, 0.4)
                sub_h = h * rng.uniform(0.2, 0.3)
                sm = maker(sub_h, g * 0.3, 0.05, s * 0.32, seed * 13 + k)
                base = np.array([cx + math.cos(a) * s * MAN * 0.42, cy + math.sin(a) * s * MAN * 0.42, H * rng.uniform(0.5, 0.58)])
                # (its stem bends up out of the whorl)
                m.capsule((cx, cy, base[2] - 4 * F), base, r0 * 0.25, r0 * 0.18, BARK, over=True)
                xs, ys, zs = np.nonzero(sm.v)
                tx = xs - N // 2 + int(base[0])
                ty = ys - N // 2 + int(base[1])
                tz = zs + int(base[2])
                ok = (tx >= 0) & (ty >= 0) & (tz >= 0) & (tx < N) & (ty < N) & (tz < N)
                tx, ty, tz, vals = tx[ok], ty[ok], tz[ok], sm.v[xs[ok], ys[ok], zs[ok]]
                free = m.v[tx, ty, tz] == 0
                m.v[tx[free], ty[free], tz[free]] = vals[free]


def main(only=None):
    """Writes every model, or only those whose name starts with one of `only`; feet.txt keeps the others' lines."""
    old = dict(l.split(" ", 1) for l in open("art/trees/vox/feet.txt").read().split("\n") if l)
    lines = []
    for tag, kind, name, dims, seed in models():
        if only and not any(tag.startswith(o) for o in only):
            lines.append("%s %s" % (tag, old[tag]))
            continue
        size, foot, count = build(tag, kind, name, dims, seed).save("art/trees/vox/%s.vox" % tag)
        lines.append("%s %d %d" % (tag, foot[0], foot[1]))
        print("%s: %s voxels %d, foot %s" % (tag, size, count, foot))
    # (where each trunk's foot is in its model: x y, voxels from the model's corner)
    open("art/trees/vox/feet.txt", "w").write("\n".join(lines) + "\n")


if __name__ == "__main__":
    import sys
    main(sys.argv[1:] or None)
