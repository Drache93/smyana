import men, render, crowd, random
from kit import kitman
from PIL import Image, ImageDraw
OUT = "../../../archive/images/2026-11-10/"
import os; os.makedirs(OUT, exist_ok=True)
B = dict(hat="kalpak", coat="black", cloak="none", face="droop")
def titled(img, title):
    out = Image.new("RGB", (img.width, img.height + 22), render.BG)
    out.paste(img, (0, 22)); ImageDraw.Draw(out).text((8, 6), title, fill=(60, 50, 40)); return out
def stack(imgs):
    W = max(i.width for i in imgs); H = sum(i.height for i in imgs)
    out = Image.new("RGB", (W, H), render.BG); y = 0
    for i in imgs: out.paste(i, (0, y)); y += i.height
    return out
hats = ["kalpak", "tall", "lamb", "felt", "bare"]
hn = {"kalpak": "kalpak, red band", "tall": "tall black kalpak", "lamb": "grey lambskin", "felt": "brown felt cap", "bare": "bare head"}
heads = render.sheet([render.render(men.head_piece(dict(B, hat=h)), 0, scale=8, shadow=False, size=(150, 170), origin=(75, 548))[0] for h in hats] +
                     [render.render(men.head_piece(dict(B, face="grey")), 0, scale=8, shadow=False, size=(150, 170), origin=(75, 548))[0]],
                     gap=10, labels=[hn[h] for h in hats] + ["older: grey moustache, beard"])
bodies = render.sheet([kitman(dict(B, hat=h), scale=4)[0] for h in hats] + [kitman(dict(B, face="grey"), scale=4)[0]], gap=10)
stack([titled(heads, "Hats and faces (close, 8x)"), bodies]).save(OUT + "24-men-hats-and-faces.png")
cl = ["none", "fleece", "yamurluk", "kozhuh", "gunya", "blanket"]
cn = {"none": "no cloak", "fleece": "fleece", "yamurluk": "yamurluk", "kozhuh": "kozhuh (sheepskin jacket)", "gunya": "gunya (goat hair)", "blanket": "striped rug"}
ims, labs = [], []
for c in cl:
    ims += kitman(dict(B, cloak=c), scale=4); labs += [cn[c], "back"]
titled(render.sheet(ims, gap=8, labels=labs), "Cloaks: the three from before, and three new").save(OUT + "25-men-cloaks.png")
ims, labs = [], []
for c in ["black", "brown", "blue"]:
    ims += kitman(dict(B, coat=c), scale=4); labs += [c + " coat", "back"]
titled(render.sheet(ims, gap=8, labels=labs), "Coats").save(OUT + "26-men-coats.png")
r = men.rifle()
titled(render.sheet([render.render(r, 60, scale=12, shadow=False)[0], render.render(r, 15, scale=7, shadow=False)[0]], gap=16),
       "The rifle with the swallow-tail butt: a long flintlock, brass bands, silver studs (side, 12x; 3/4, 7x)").save(OUT + "27-swallow-tail-rifle.png")
tools = [(men.tesla(), "tesla (adze-hammer)", 60), (men.pick_hammer(), "dressing hammer", 60), (men.sledge(), "stone sledge", 60), (men.trowel(), "trowel", 20)]
titled(render.sheet([render.render(t, f, scale=10, shadow=False)[0] for t, _, f in tools], gap=20, labels=[n for _, n, _ in tools]),
       "The masons' tools (10x)").save(OUT + "28-mason-tools.png")
ims = kitman(B, men.rifle_on_back(), men.tool_in_sash(men.tesla()), scale=5)
ims += kitman(dict(B, hat="lamb", cloak="fleece"), men.rifle_at_side(), men.tool_in_sash(men.pick_hammer()), scale=5)
titled(render.sheet(ims, gap=8), "Carrying them: rifle slung or stood by his foot, a tool in the sash (5x)").save(OUT + "29-men-with-rifle-and-tools.png")
rng = random.Random(1878)
for xs in (crowd.HATS, crowd.COATS, crowd.CLOAKS): rng.shuffle(xs)
group = [crowd.random_man(rng, i) for i in range(12)]
fac = [rng.choice([0, 15, -25]) for _ in group]
big = [kitman(lk, *g, facings=(f,), scale=3)[0] for (lk, g), f in zip(group, fac)]
titled(render.sheet(big), "Twelve men mixed at random (3x)").save(OUT + "30-men-random-mix.png")
small = render.sheet([kitman(lk, *g, facings=(f,), scale=1.2)[0] for (lk, g), f in zip(group, fac)], gap=2)
titled(small.resize((small.width * 3, small.height * 3), Image.NEAREST), "The same twelve at about game size, blown up 3x so the pixels show").save(OUT + "31-men-random-mix-game-size.png")
for lk, g in group: print(lk)
