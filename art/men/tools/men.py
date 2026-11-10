# The Smyana men: the haidut voxel man (Age of Anything's mods/vox_example/tools/haidut.lobster) rebuilt
# voxel for voxel, with looks that can be mixed at random: hats, coats, cloaks, faces. Plus their gear:
# the swallow-tail-butt rifle and the masons' tools. Body voxels: x right, y forward, z up, ground at 0,
# a head 10 voxels, the man 79 tall.
import math, struct

# the palette: the haidut's 19, then the new looks' colours
NAMES = ["SKIN", "HAIR", "FUR", "LINEN", "COAT", "TRIM", "SASH", "BELT", "SILVER", "WRAP", "CORD", "SHOE",
         "MOUSTACHE", "WOOD", "FLEECE", "FLEECE2", "WOOL", "PIPING", "EYE",
         "LAMB", "LAMB2", "FELT", "FELT2", "BROWNCOAT", "BROWNTRIM", "GOAT", "GOAT2", "HIDE", "HIDE2",
         "STRIPE_R", "STRIPE_K", "STRIPE_W", "GREY", "WALNUT", "WALNUT2", "BRASS", "IRON", "IRON2", "ASH",
         "BLUECOAT", "STEEL"]
COLOURS = [0xd9a27c, 0x3a2a20, 0x2b2420, 0xe6dfcd, 0x2e2925, 0xb03228, 0xa8302a, 0x6b4a2e, 0xc8c8c0, 0x1f1d1b,
           0xcfc6b0, 0x7a5236, 0x7a5a40, 0x5a3a22, 0xdccfb2, 0xb9aa8a, 0x4a3628, 0xd8cfb8, 0x2a1d16,
           0x8d877e, 0x6f6a62, 0x6b4f36, 0x553e2a, 0x5e4430, 0x8a3a24, 0x3b3029, 0x2a221d, 0x9a6a40, 0x7d5232,
           0xa33328, 0x2a2522, 0xe0d6be, 0xa39d92, 0x4e3220, 0x3a2416, 0xc49a48, 0x55575a, 0x3c3e41, 0xb59a74,
           0x2c3444, 0x8c9096]
for _i, _n in enumerate(NAMES):
    globals()[_n] = _i + 1


def sq(x): return x * x


def in_taper(c, z0, z1, a0, a1, r0, r1):
    x, y, z = c
    if z < z0 or z > z1: return False
    t = (z - z0) / (z1 - z0)
    ax = a0[0] + (a1[0] - a0[0]) * t; ay = a0[1] + (a1[1] - a0[1]) * t
    rx = r0[0] + (r1[0] - r0[0]) * t; ry = r0[1] + (r1[1] - r0[1]) * t
    return sq((x - ax) / rx) + sq((y - ay) / ry) <= 1.0


def in_ball(c, at, r):
    return sq((c[0] - at[0]) / r[0]) + sq((c[1] - at[1]) / r[1]) + sq((c[2] - at[2]) / r[2]) <= 1.0


def lock(x, y):  # the haidut's hash, 0..1
    return float((((x * 73856093) ^ (y * 19349663)) & 1023)) / 1023.0


def atan2d(x, y):  # Lobster's atan2(float2 {x, y}) in degrees
    return math.degrees(math.atan2(y, x))


def sign(x): return 1.0 if x > 0 else (-1.0 if x < 0 else 0.0)


def fill(vox, lo, hi, f):
    for z in range(lo[2], hi[2] + 1):
        for y in range(lo[1], hi[1] + 1):
            for x in range(lo[0], hi[0] + 1):
                m = f((x + 0.5, y + 0.5, z + 0.5))
                if m: vox[(x, y, z)] = m


# ---- a look: what he wears -------------------------------------------------------------------------
# hat: kalpak (black, red band: the original) | tall (black, no band, taller) | lamb (short grey lambskin,
#      curly) | felt (brown felt cap, rolled brim) | bare (dark hair)
# coat: black (the original) | brown (undyed wool, rust trim) | blue (dark blue, red trim)
# cloak: none | fleece | yamurluk (the originals) | kozhuh (a sheepskin jacket, hide out, fleece at the edges,
#        sleeves) | gunya (a shaggy goat-hair shepherd's cloak to the knee) | blanket (a striped wool rug over
#        the left shoulder)
# face: droop (the original) | grey (an older man: grey moustache and a short grey beard)

def head_piece(look):
    hat, face = look["hat"], look["face"]
    v = {}
    mous_lo = [65, 65, 65, 64, 63]; mous_hi = [66, 66, 66, 65, 64]
    mous_y0 = [4.0, 4.0, 2.0, 2.0, 1.0]; mous_y1 = [5.0, 5.0, 4.0, 4.0, 3.0]
    tache_col = GREY if face == "grey" else HAIR

    def f(c):
        x, y, z = c
        ax = abs(x)
        face_ = in_ball(c, (0.0, 0.3, 67.8), (3.7, 4.1, 5.3)) or \
            in_taper(c, 62.0, 65.0, (0.0, 0.2), (0.0, 0.6), (2.6, 3.0), (3.0, 3.4))
        col = int(ax); cz = int(math.floor(z))
        tache = col < 5 and mous_lo[col] <= cz <= mous_hi[col] and mous_y0[col] < y < mous_y1[col]
        eye = y > 2.4 and 1.0 < ax < 2.0 and 68.4 < z < 69.4
        # hats
        if hat == "kalpak":
            if in_taper(c, 71.6, 78.0, (0.0, -0.6), (0.0, -0.8), (4.0, 4.3), (3.8, 4.0)) and z > 71.6 + max(0.0, y) * 0.25:
                return TRIM if z < 73.0 + max(0.0, y) * 0.25 else FUR
        elif hat == "tall":
            if in_taper(c, 71.6, 80.0, (0.0, -0.6), (0.0, -1.4), (4.0, 4.3), (3.6, 3.8)) and z > 71.6 + max(0.0, y) * 0.25:
                return FUR if lock(int(x * 2), int(z)) > 0.12 else HAIR
        elif hat == "lamb":  # short, a little wider at the top, tight grey curls
            if in_taper(c, 71.4, 76.2, (0.0, -0.5), (0.0, -0.6), (4.1, 4.4), (4.4, 4.7)) and z > 71.4 + max(0.0, y) * 0.2:
                return LAMB2 if lock(int(math.floor(x)) + 40, int(math.floor(z)) * 7 + int(math.floor(y))) > 0.6 else LAMB
        elif hat == "felt":  # a rounded brown felt cap with its brim rolled up all round
            brim = in_taper(c, 71.0, 72.6, (0.0, -0.4), (0.0, -0.4), (5.4, 5.7), (5.4, 5.7)) and z > 71.0 + max(0.0, y) * 0.2
            dome = in_ball(c, (0.0, -0.6, 72.0), (3.9, 4.2, 4.0)) and z > 71.6
            if dome: return FELT
            if brim: return FELT2 if not (y > 3.0 and abs(x) < 1.0) else FELT
        elif hat == "bare":  # dark hair: over the crown, longer at the back
            hair = in_ball(c, (0.0, -0.3, 69.6), (4.0, 4.5, 4.8)) and z > 71.8 - max(0.0, -y) * 0.9 - max(0.0, abs(x) - 2.5) * 0.6
            if hair: return HAIR
        if tache: return tache_col
        if face == "grey" and face_ and y > 1.2 and 61.5 < z < 64.2 and ax < 3.2 and not (ax < 1.0 and z > 63.5):
            return GREY  # a short beard, a skin chin row above the jaw line, joined to the moustache
        if face_ and y < -2.2 and z > 67.0 and hat != "bare": return HAIR  # his hair at the back, under the hat
        if face_ and eye: return EYE
        if face_: return SKIN
        if in_ball(c, (3.8, -0.2, 67.5), (0.8, 1.2, 1.6)) or in_ball(c, (-3.8, -0.2, 67.5), (0.8, 1.2, 1.6)): return SKIN
        if in_ball(c, (0.0, 4.5, 67.5), (0.8, 0.8, 1.2)): return SKIN
        return 0
    fill(v, (-7, -6, 61), (7, 7, 81), f)
    return v


def coat_cols(look):
    return {"black": (COAT, TRIM), "brown": (BROWNCOAT, BROWNTRIM), "blue": (BLUECOAT, TRIM)}[look["coat"]]


def chest_piece(look):
    cape = look["cloak"]
    coat, trim = coat_cols(look)
    v = {}

    def f(c):
        x, y, z = c
        ax = abs(x)
        butt = in_ball(c, (2.6 * sign(x), 5.4, 49.4), (0.9, 1.5, 1.0)) or \
            in_taper(c, 45.0, 49.0, (2.6 * sign(x), 4.0), (2.6 * sign(x), 4.8), (0.8, 0.9), (0.8, 0.9))
        strap = z >= 48.0 and abs(x - (z - 54.5)) < 1.3
        body = in_taper(c, 44.0, 57.0, (0.0, 0.0), (0.0, -0.3), (7.0, 4.4), (9.4, 5.0)) or \
            in_taper(c, 57.0, 61.5, (0.0, -0.3), (0.0, -0.6), (9.4, 5.0), (7.0, 3.8))
        around = atan2d(x, y + 1.0)
        shag = lock(int(math.floor(around / 9.0)), int(math.floor(z / 3.0)))
        if cape == "fleece":
            o = in_taper(c, 42.0 - shag * 4.0, 63.0, (0.0, -1.0), (0.0, -0.4), (12.8 + shag * 1.2, 8.4 + shag), (9.4, 6.2))
            i = in_taper(c, 30.0, 61.0, (0.0, -1.0), (0.0, -0.4), (10.0, 5.8), (7.6, 4.2))
            op = y > 2.0 and ax < 1.5 + (62.0 - z) * 0.18
            if o and not i and not op: return FLEECE2 if shag > 0.55 else FLEECE
        elif cape == "yamurluk":
            o = in_taper(c, 12.0, 62.4, (0.0, -3.2), (0.0, -0.6), (14.0, 10.0), (10.4, 5.6))
            i = in_taper(c, 11.0, 61.2, (0.0, -3.2), (0.0, -0.6), (12.8, 8.8), (9.2, 4.4))
            op = y > 0.5 and ax < 3.0 + (62.0 - z) * 0.16
            if o and not i and not op:
                return PIPING if (z < 13.2 or (y > 0.0 and ax < 4.2 + (62.0 - z) * 0.16)) else WOOL
        elif cape == "gunya":  # long shaggy goat hair from the shoulders to below the knee, closed at the neck
            g = lock(int(math.floor(around / 7.0)) + 11, int(math.floor(z / 4.0)))
            o = in_taper(c, 16.0 - g * 5.0, 62.6, (0.0, -3.6), (0.0, -0.8), (13.6 + g * 1.4, 9.6 + g), (10.2, 5.8))
            i = in_taper(c, 10.0, 61.4, (0.0, -3.6), (0.0, -0.8), (12.2, 8.2), (8.8, 4.4))
            op = y > 0.5 and ax < 2.4 + (60.0 - z) * 0.20 and z < 60.0
            if o and not i and not op:
                return GOAT2 if lock(int(math.floor(around / 4.0)), int(z)) > 0.62 else GOAT
        elif cape == "kozhuh":  # a sheepskin jacket to the hip: hide out, the fleece showing at collar, front and hem
            o = in_taper(c, 35.0, 62.0, (0.0, -0.6), (0.0, -0.5), (10.4, 6.6), (9.8, 6.0))
            i = in_taper(c, 34.0, 60.8, (0.0, -0.6), (0.0, -0.5), (9.0, 5.4), (8.0, 4.4))
            op = y > 1.5 and ax < 1.6 + (62.0 - z) * 0.10
            if o and not i and not op:
                edge = z < 37.0 or z > 59.4 or (y > 1.0 and ax < 3.0 + (62.0 - z) * 0.10)
                if edge: return FLEECE2 if shag > 0.5 else FLEECE
                return HIDE2 if (int(math.floor(z)) % 6 == 0 and abs(x) > 3) else HIDE
        elif cape == "blanket":  # a striped rug over the left shoulder, hanging down the back and the front-left
            # a band 9 voxels wide running from the right hip at the back, over the left shoulder, to the left hip in front
            d = (x + (z - 50.0) * 0.55)  # across the band
            o = in_taper(c, 34.0, 63.6, (0.0, -0.4), (0.0, -0.5), (10.4, 6.8), (10.2, 6.4))
            i = in_taper(c, 33.0, 62.0, (0.0, -0.4), (0.0, -0.5), (9.0, 5.4), (8.4, 4.8))
            if o and not i and -14.0 < d - 6.0 < -5.0 + 9.0 and x < 6.0:
                s = int(math.floor(z + y * 0.3)) % 8
                return STRIPE_R if s < 3 else (STRIPE_K if s < 5 else (STRIPE_W if s < 6 else STRIPE_R))
        if 1.4 < ax < 3.8 and butt: return SILVER if (y > 6.0 and z > 49.6) else WOOD
        if not body: return 0
        if strap: return SILVER if (y > 0.0 and int(math.floor(z)) % 2 == 0 and abs(x - (z - 54.5)) < 0.6) else BELT
        if z < 48.0: return SASH
        if y > 2.0 and abs(x) < 2.6 + (z - 48.0) * 0.12: return LINEN
        if y > 2.0 and abs(x) < 3.6 + (z - 48.0) * 0.12: return trim
        if abs(x) > 8.2 and z > 55.0: return trim
        return coat
    fill(v, (-16, -15, 8), (16, 10, 65), f)
    return v


def hip_piece(look):
    coat, trim = coat_cols(look)
    v = {}

    def f(c):
        x, y, z = c
        belt = in_taper(c, 40.0, 44.0, (0, 0), (0, 0), (7.2, 4.6), (7.2, 4.6))
        outer = in_taper(c, 18.0, 44.0, (0.0, -1.2), (0.0, 0.0), (11.0, 7.0), (7.4, 4.8))
        inner = in_taper(c, 17.0, 45.0, (0.0, -1.2), (0.0, 0.0), (9.8, 5.8), (6.2, 3.6))
        op = y > 0.0 and abs(x) < 2.0 + (44.0 - z) * 0.12
        if belt and z >= 40.0:
            if y > 3.0 and 41.0 < z < 43.0 and (int(math.floor(x + 0.5)) % 3 + 3) % 3 == 0 and abs(x) < 5.0: return SILVER
            return BELT
        if outer and not inner and not op:
            return trim if (z < 19.5 or (y > 0.0 and abs(x) < 3.2 + (44.0 - z) * 0.12)) else coat
        return 0
    fill(v, (-12, -8, 18), (12, 7, 44), f)
    return v


def right_leg():
    v = {}
    fill(v, (0, -5, 20), (8, 5, 37), lambda c: LINEN if in_taper(c, 20.0, 37.0, (3.8, 0.0), (4.0, 0.0), (2.6, 2.8), (3.6, 3.8)) else 0)

    def shin(c):
        if in_taper(c, 3.0, 19.0, (3.8, 0.0), (3.8, 0.2), (1.6, 1.6), (2.4, 2.6)):
            a = atan2d(c[0] - 3.8, c[1]); u = c[2] * 72.0
            if abs(((a - u) % 360.0 + 360.0) % 360.0 - 180.0) < 26.0 or abs(((a + u) % 360.0 + 360.0) % 360.0 - 180.0) < 26.0:
                return CORD
            return WRAP
        return 0
    fill(v, (0, -4, 3), (7, 4, 19), shin)
    fill(v, (1, -3, 0), (7, 6, 2), lambda c: SHOE if in_taper(c, 0.0, 2.6, (3.9, 1.0), (3.9, 0.6), (2.2, 4.4), (1.8, 3.4)) else 0)
    return v


def right_arm(look):
    sleeve = HIDE if look["cloak"] == "kozhuh" else LINEN
    v = {}
    fill(v, (6, -4, 48), (14, 4, 60), lambda c: sleeve if in_taper(c, 48.0, 60.0, (9.9, 0.0), (9.7, -0.2), (2.0, 2.1), (2.4, 2.4)) else 0)
    def fore(c):
        if in_taper(c, 37.0, 47.0, (10.2, 0.4), (10.0, 0.1), (1.6, 1.6), (2.0, 2.0)):
            if look["cloak"] == "kozhuh": return FLEECE if c[2] < 39.5 else HIDE
            return TRIM if c[2] < 39.0 else LINEN
        return 0
    fill(v, (7, -4, 37), (14, 4, 47), fore)
    fill(v, (8, -3, 32), (14, 4, 36), lambda c: SKIN if in_ball(c, (10.3, 0.5, 34.5), (1.4, 1.6, 2.2)) else 0)
    return v


def mirror(v):
    return {(-x - 1, y, z): m for (x, y, z), m in v.items()}


def man(look):
    """the whole man standing, every piece in one voxel set (for pictures); later pieces don't overwrite cloaks"""
    out = {}
    for part in [right_leg(), mirror(right_leg()), hip_piece(look), right_arm(look), mirror(right_arm(look)), chest_piece(look), head_piece(look)]:
        for k, m in part.items():
            if k not in out: out[k] = m
            else: out[k] = m  # the later piece is the outer one (the chest's cloak over the arms)
    return out


def pieces(look):
    """the pieces as the haidut .vox has them"""
    return [("head", head_piece(look)), ("chest", chest_piece(look)), ("hip", hip_piece(look)),
            ("thigh.r", {k: m for k, m in right_leg().items() if k[2] >= 20}),
            ("shin.r", {k: m for k, m in right_leg().items() if 3 <= k[2] < 20}),
            ("foot.r", {k: m for k, m in right_leg().items() if k[2] < 3}),
            ("upper_arm.r", {k: m for k, m in right_arm(look).items() if k[2] >= 48}),
            ("forearm.r", {k: m for k, m in right_arm(look).items() if 37 <= k[2] < 48}),
            ("hand.r", {k: m for k, m in right_arm(look).items() if k[2] < 37})]


# ---- the gear (each in its own frame, in the same body voxels) ------------------------------------------

def rifle():
    """The long Balkan flintlock with the swallow-tail butt (a rashak, the 'boyliya' the builders carried):
    a long thin barrel bound to the full stock by many brass bands, a lock on the right, and the butt
    split into two long horns with a deep V between them, inlaid with silver. Lying along y (muzzle at +y),
    the butt's fork opening at -y, its horns up and down (z). About 66 voxels: 1.5 m against his 1.75 m."""
    v = {}
    L0, L1 = -33, 33
    for y in range(L0, L1):
        t = y + 0.5
        if t > -12:  # the fore-stock and barrel
            v[(0, y, 1)] = IRON  # the barrel on top
            if t < 26: v[(0, y, 0)] = WALNUT  # the full stock under it, to near the muzzle
            if int(t) % 7 == 0 and t < 26: v[(0, y, 1)] = BRASS; v[(0, y, 0)] = BRASS  # the bands
            if t > 30: v[(0, y, 1)] = IRON2
        # the wrist (the small of the stock) behind the lock
        if -18 < t <= -12:
            for z in (0, 1): v[(0, y, z)] = WALNUT
            v[(0, y, -1)] = WALNUT2 if t < -15 else WALNUT  # the grip deepens toward the butt
        # the swallow tail: the stock deepens into two long horns with a deep V cut between them, the lower
        # horn the longer; silver studs along the top and the V's edges
        if t <= -18:
            k = min(1.0, (-18 - t) / 15.0)
            top = 1.0 + 4.6 * k ** 0.85
            bot = -1.0 - 6.4 * k ** 0.9
            mid = (top + bot) / 2 + 0.4
            g = max(0.0, (k - 0.4) / 0.6) ** 0.7 * ((top - bot) / 2 - 1.4)
            for z in range(-9, 9):
                zc = z + 0.5
                if bot - 0.5 <= zc <= top + 0.5 and abs(zc - mid) >= g:
                    edge = g > 0 and abs(zc - mid) < g + 1.0
                    stud = (abs(zc - top) < 0.6 and int(-t) % 3 == 0) or (edge and int(-t) % 3 == 1)
                    col = SILVER if stud else (WALNUT2 if zc < mid else WALNUT)
                    v[(0, y, z)] = col
                    if abs(zc - mid) < g + 2.2 and k < 0.9 or abs(zc - mid) < 2.0:
                        v[(1, y, z)] = col; v[(-1, y, z)] = col
    # the lock on the right side, a hammer (cock) standing up, a trigger guard below
    for y in range(-12, -7):
        v[(1, y, 0)] = IRON; v[(1, y, 1)] = IRON
    v[(1, -11, 2)] = IRON2; v[(1, -11, 3)] = IRON2; v[(1, -10, 3)] = IRON2
    v[(0, -10, -1)] = BRASS; v[(0, -11, -2)] = BRASS; v[(0, -13, -2)] = BRASS; v[(0, -12, -2)] = BRASS
    # a silver plate on the wrist (their rifles were richly decorated)
    v[(1, -15, 0)] = SILVER; v[(1, -16, 1)] = SILVER; v[(-1, -15, 0)] = SILVER
    # the ramrod under the stock
    for y in range(-9, 28): v.setdefault((0, y, -1), WOOD)
    return v


def tesla():
    """The adze-hammer (tesla), the Bulgarian builder's tool: a short haft, a square hammer face on one side
    of the head and a broad curved adze blade on the other. Haft along z (head at the top), blade at +y."""
    v = {}
    for z in range(0, 18): v[(0, 0, z)] = ASH
    for y in range(-3, 6):
        for z in range(17, 20):
            v[(0, y, z)] = IRON
    for y in (-3, -4):  # the hammer face, a little proud and square
        for z in range(16, 21):
            for x in (-1, 0, 1): v[(x, y, z)] = IRON2
    for y in range(4, 8):  # the adze blade, dropping and widening into a curved edge
        d = y - 4
        for z in range(17 - d * 2, 20 - d):
            for x in (-1, 0, 1) if d >= 1 else (0,):
                v[(x, y, z)] = STEEL if y == 7 or z == 17 - d * 2 else IRON
    for x in (-1, 1): v[(x, 0, 18)] = IRON
    return v


def pick_hammer():
    """The stonemason's dressing hammer: a heavy flat square face on one side, a tapering point on the other
    (to rough out stone), a longer haft. Haft along z, the point at +y."""
    v = {}
    for z in range(0, 22): v[(0, 0, z)] = ASH
    for y in range(-4, 2):
        for z in range(20, 24):
            for x in (-1, 0, 1): v[(x, y, z)] = IRON2 if y == -4 else IRON
    for y in range(2, 8):  # the point: thinning toward the end
        r = 1.6 - (y - 2) * 0.28
        for z in range(19, 25):
            for x in (-1, 0, 1):
                if abs(x) <= r - 0.6 and abs(z + 0.5 - 22.0) <= r + 0.2:
                    v[(x, y, z)] = STEEL if y >= 6 else IRON
    return v


def sledge():
    """The big two-handed stone hammer (the 'stone hammer' for splitting and driving): a long haft and a
    heavy double-faced block head."""
    v = {}
    for z in range(0, 34): v[(0, 0, z)] = ASH
    for y in range(-5, 6):
        for z in range(31, 37):
            for x in (-2, -1, 0, 1, 2):
                if abs(x) == 2 and (z in (31, 36) or abs(y) == 5): continue
                v[(x, y, z)] = IRON2 if abs(y) == 5 else IRON
    return v


def trowel():
    """The mason's trowel (mistriya): a flat pointed steel blade, a cranked tang up to a wooden handle."""
    v = {}
    for y in range(0, 11):
        w = 3.2 * (1 - y / 11.0) + 0.3
        for x in range(-4, 4):
            if abs(x + 0.5) <= w: v[(x, y, 0)] = STEEL if abs(x + 0.5) > w - 1 else IRON
    for z in range(1, 4): v[(0, 0, z)] = IRON2
    for y in range(-6, 1): v[(0, y, 4)] = WALNUT
    return v


def chisel():
    v = {}
    for z in range(0, 9): v[(0, 0, z)] = STEEL if z < 2 else IRON
    v[(0, 0, 9)] = IRON2
    return v


# ---- the .vox file (as haidut.lobster writes it) ---------------------------------------------------------

def _chunk(cid, content): return cid.encode() + struct.pack("<ii", len(content), 0) + content


def _dict(kv):
    s = struct.pack("<i", len(kv) // 2)
    for t in kv:
        b = t.encode(); s += struct.pack("<i", len(b)) + b
    return s


def write_vox(path, named, points=None):
    """named: [(name, {(x,y,z): idx})]; points: [(name, (x,y,z))] on a hidden layer"""
    named = list(named)
    layers = [0] * len(named)
    if points:
        for n, p in points:
            named.append((n, {p: SKIN})); layers.append(1)
    models = b""; nodes = b""; kids = []
    for i, (name, vs) in enumerate(named):
        ks = list(vs.keys())
        lo = [min(k[a] for k in ks) for a in range(3)]
        hi = [max(k[a] for k in ks) for a in range(3)]
        size = [hi[a] - lo[a] + 1 for a in range(3)]
        assert max(size) <= 256
        xyzi = struct.pack("<i", len(ks)) + b"".join(struct.pack("<4B", k[0] - lo[0], k[1] - lo[1], k[2] - lo[2], vs[k]) for k in ks)
        models += _chunk("SIZE", struct.pack("<3i", *size)) + _chunk("XYZI", xyzi)
        t = [lo[a] + size[a] // 2 for a in range(3)]
        tid = 2 + i * 2; kids.append(tid)
        nodes += _chunk("nTRN", struct.pack("<i", tid) + _dict(["_name", name]) + struct.pack("<iiii", tid + 1, -1, layers[i], 1) +
                        _dict(["_t", "%d %d %d" % tuple(t)]))
        nodes += _chunk("nSHP", struct.pack("<i", tid + 1) + _dict([]) + struct.pack("<ii", 1, i) + _dict([]))
    grp = struct.pack("<i", 1) + _dict([]) + struct.pack("<i", len(kids)) + b"".join(struct.pack("<i", k) for k in kids)
    root = _chunk("nTRN", struct.pack("<i", 0) + _dict([]) + struct.pack("<iiii", 1, -1, -1, 1) + _dict([]))
    rgba = b"".join(struct.pack("<4B", (c >> 16) & 255, (c >> 8) & 255, c & 255, 255) for c in (COLOURS + [0] * 256)[:256])
    lay = _chunk("LAYR", struct.pack("<i", 0) + _dict(["_name", "body"]) + struct.pack("<i", -1))
    if points: lay += _chunk("LAYR", struct.pack("<i", 1) + _dict(["_name", "points", "_hidden", "1"]) + struct.pack("<i", -1))
    content = models + root + _chunk("nGRP", grp) + nodes + _chunk("RGBA", rgba) + lay
    with open(path, "wb") as fh:
        fh.write(b"VOX " + struct.pack("<i", 150) + b"MAIN" + struct.pack("<ii", 0, len(content)) + content)
    return sum(len(vs) for _, vs in named)


POINTS = [("hip", (0, 0, 38)), ("chest", (0, 0, 57)), ("head", (0, 1, 67))]


def place(gear, ex, ey, ez, at):
    """the gear's voxels into the body's frame: its x, y, z along ex, ey, ez (unit vectors), its origin at `at`
    (sampled finely so a tilted thing has no holes)"""
    out = {}
    subs = [(a, b, c) for a in (0.25, 0.75) for b in (0.25, 0.75) for c in (0.25, 0.75)]
    for (x, y, z), m in gear.items():
        for s in subs:
            p = (x + s[0], y + s[1], z + s[2])
            q = [at[i] + p[0] * ex[i] + p[1] * ey[i] + p[2] * ez[i] for i in range(3)]
            out[(int(math.floor(q[0])), int(math.floor(q[1])), int(math.floor(q[2])))] = m
    return out


def norm(v):
    l = math.sqrt(sum(a * a for a in v)); return tuple(a / l for a in v)


def rifle_on_back():  # slung across the back: the butt at his left hip, the muzzle up over his right shoulder
    ax = norm((0.62, 0.0, 1.0)); pe = norm((-1.0, 0.0, 0.62))
    return place(rifle(), (0, -1, 0), ax, pe, (1.0, -7.4, 49.0))


def rifle_at_side():  # stood on its butt by his right foot, his hand round the fore-stock
    return place(rifle(), (1, 0, 0), (0, 0, 1), (0, 1, 0), (12.0, -0.5, 33.5))


def tool_in_sash(tool, x=-5.0):  # thrust through the sash at the left hip, the head up
    return place(tool, (1, 0, 0), (0, 1, 0), (0, 0, 1), (x, 5.2, 28.0))


def tool_in_hand(tool):  # hanging from the right hand, the head down by the knee
    return place(tool, (1, 0, 0), (0, 1, 0), (0, 0, -1), (10.3, 0.6, 38.0))
