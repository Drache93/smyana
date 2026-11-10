import men, render, random
from kit import kitman
from PIL import Image
rng = random.Random(1878)
HATS = ["kalpak"] * 3 + ["tall", "lamb", "lamb", "felt", "bare"]
COATS = ["black"] * 3 + ["brown", "brown", "blue"]
CLOAKS = ["none", "none", "fleece", "yamurluk", "kozhuh", "gunya", "blanket"]
TOOLS = [men.tesla, men.pick_hammer, men.trowel]
def random_man(r, i=None):
    pick = (lambda xs: xs[i % len(xs)]) if i is not None else r.choice
    lk = dict(hat=pick(HATS), coat=pick(COATS), cloak=pick(CLOAKS), face="grey" if r.random() < 0.2 else "droop")
    gear = [men.rifle_on_back() if (i if i is not None else r.randrange(3)) % 3 != 1 else men.rifle_at_side()]
    if r.random() < 0.7: gear.append(men.tool_in_sash(r.choice(TOOLS)()))
    return lk, gear
if __name__ == "__main__":
    for xs in (HATS, COATS, CLOAKS): rng.shuffle(xs)
    group = [random_man(rng, i) for i in range(12)]
    for lk, g in group: print(lk)
    big = [kitman(lk, *g, facings=(rng.choice([0, 15, -25]),), scale=3)[0] for lk, g in group]
    render.sheet(big).save("crowd.png")
    small = [kitman(lk, *g, facings=(0,), scale=1.2)[0] for lk, g in group]
    s = render.sheet(small, gap=2)
    s.resize((s.width * 3, s.height * 3), Image.NEAREST).save("crowd_game_size_x3.png")
    s.save("crowd_game_size.png")
