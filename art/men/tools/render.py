# A small voxel renderer for looking at the men: orthographic, the game's 3/4 view from above, one light from
# the upper left, a soft drop shadow on the ground, a dark outline round the figure.
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import men

BG = (233, 228, 218)
FACES = [((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]),
         ((-1, 0, 0), [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)]),
         ((0, 1, 0), [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)]),
         ((0, -1, 0), [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)]),
         ((0, 0, 1), [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]),
         ((0, 0, -1), [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)])]


def rgb(i):
    c = men.COLOURS[i - 1]
    return np.array([(c >> 16) & 255, (c >> 8) & 255, c & 255], float)


def render(vox, facing=0.0, scale=3.0, elev=35.0, pad=6, shadow=True, outline=True, size=None, origin=None):
    """facing in degrees: 0 he looks at the camera (a little to its right, the 3/4 view), 180 his back."""
    a = math.radians(180.0 + facing + 30.0)  # the game camera sits off to the side: the default facing reads 3/4
    e = math.radians(elev)
    ca, sa = math.cos(a), math.sin(a)

    def rot(p):  # the model turned so its +y faces toward -Y (the camera) at facing 0
        x, y, z = p
        return (x * ca - y * sa, x * sa + y * ca, z)
    # camera looks along +Y and down: right (1,0,0), up (0, sin e, cos e), forward (0, cos e, -sin e)
    def projw(P):
        X, Y, Z = P
        return X * scale, -(Y * math.sin(e) + Z * math.cos(e)) * scale, Y * math.cos(e) - Z * math.sin(e)

    def proj(p):
        X, Y, Z = rot(p)
        return X * scale, -(Y * math.sin(e) + Z * math.cos(e)) * scale, Y * math.cos(e) - Z * math.sin(e)
    light = np.array([-0.55, -0.45, 0.70]); light /= np.linalg.norm(light)
    polys = []
    keys = vox.keys()
    for (x, y, z), m in vox.items():
        for n, corners in FACES:
            if (x + n[0], y + n[1], z + n[2]) in keys: continue
            N = rot(n)
            if N[1] * math.cos(e) - N[2] * math.sin(e) >= -1e-6: continue  # facing away
            pts = [proj((x + c[0], y + c[1], z + c[2])) for c in corners]
            d = sum(p[2] for p in pts) / 4
            lam = max(0.0, float(np.dot(N, light)))
            col = rgb(m) * (0.58 + 0.55 * lam)
            polys.append((d, [(p[0], p[1]) for p in pts], tuple(int(min(255, v)) for v in col)))
    # the shadow: every voxel dropped to the ground along the light
    sh = []
    if shadow:
        for (x, y, z), m in vox.items():
            if z < 0: continue
            X, Y, _ = rot((x + 0.5, y + 0.5, 0))
            sh.append(projw((X + (z + 0.5) * 0.42, Y + (z + 0.5) * 0.22, 0)))
    allx = [q[0] for p in polys for q in p[1]] + [s[0] for s in sh]
    ally = [q[1] for p in polys for q in p[1]] + [s[1] for s in sh]
    if origin is None:
        ox, oy = -min(allx) + pad, -min(ally) + pad
        W, H = int(max(allx) + ox + pad), int(max(ally) + oy + pad)
    else:
        ox, oy = origin; W, H = size
    img = Image.new("RGB", (W, H), BG)
    if sh:
        smask = Image.new("L", (W, H), 0)
        sd = ImageDraw.Draw(smask)
        r = scale * 0.9
        for sx, sy, _ in sh: sd.ellipse([sx + ox - r, sy + oy - r * 0.7, sx + ox + r, sy + oy + r * 0.7], fill=255)
        smask = smask.filter(ImageFilter.GaussianBlur(scale * 0.6))
        img.paste(Image.new("RGB", (W, H), (128, 122, 112)), (0, 0), smask.point(lambda v: int(v * 0.85)))
    fig = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fig)
    for d, pts, col in sorted(polys, key=lambda p: -p[0]):
        fd.polygon([(px + ox, py + oy) for px, py in pts], fill=col + (255,))
    if outline:
        alpha = fig.split()[3]
        grown = alpha.filter(ImageFilter.MaxFilter(3 if scale < 6 else 5))
        ol = Image.new("RGBA", (W, H), (34, 28, 24, 255))
        img.paste(ol, (0, 0), grown)
    img.paste(fig, (0, 0), fig)
    return img, (ox, oy)


def sheet(images, gap=4, bg=BG, labels=None):
    W = sum(i.width for i in images) + gap * (len(images) + 1)
    H = max(i.height for i in images) + gap * 2 + (14 if labels else 0)
    out = Image.new("RGB", (W, H), bg)
    x = gap
    d = ImageDraw.Draw(out)
    for k, i in enumerate(images):
        out.paste(i, (x, gap + (H - gap * 2 - (14 if labels else 0) - i.height)))
        if labels: d.text((x + 2, H - 14), labels[k], fill=(70, 60, 50))
        x += i.width + gap
    return out
