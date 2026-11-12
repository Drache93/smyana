import men, crowd, random, os
OUT = "../vox/"
for d in ("", "looks", "gear", "samples"): os.makedirs(OUT + d, exist_ok=True)
B = dict(hat="none", coat="black", cloak="none", face="droop")
def diff(a, b): return {k: m for k, m in a.items() if b.get(k) != m}
n = 0
for c in ["black", "brown", "blue"]:
    n += men.write_vox(OUT + "looks/body_%s_coat.vox" % c, men.pieces(dict(B, coat=c)), men.POINTS)
base_head = men.head_piece(B)
for h in ["kalpak", "tall", "lamb", "felt", "bare"]:
    men.write_vox(OUT + "looks/hat_%s.vox" % h, [("head", diff(men.head_piece(dict(B, hat=h)), base_head))])
men.write_vox(OUT + "looks/face_grey.vox", [("head", diff(men.head_piece(dict(B, face="grey")), base_head))])
base = dict(men.pieces(B))
for c in ["fleece", "yamurluk", "kozhuh", "gunya", "blanket"]:
    ps = [(name, diff(vs, base[name])) for name, vs in men.pieces(dict(B, cloak=c))]
    men.write_vox(OUT + "looks/cloak_%s.vox" % c, [(nm, vs) for nm, vs in ps if vs])
for name, g in [("rifle_swallow_tail", men.rifle()), ("tesla_adze_hammer", men.tesla()), ("dressing_hammer", men.pick_hammer()), ("stone_sledge", men.sledge()), ("trowel", men.trowel())]:
    men.write_vox(OUT + "gear/%s.vox" % name, [(name, g)])
rng = random.Random(1878)
for xs in (crowd.HATS, crowd.COATS, crowd.CLOAKS): rng.shuffle(xs)
for i in range(12):
    lk, g = crowd.random_man(rng, i)
    lk["pack"] = ["roll", "torba", "both", "roll"][i % 4]  # what each carries on the road (Dominic, 2026-11-12)
    men.write_vox(OUT + "samples/man_%02d_%s_%s_%s.vox" % (i + 1, lk["hat"], lk["coat"], lk["cloak"]), men.pieces(lk), men.POINTS)
# the patrol (docs/threats.md): the same rig, the zaptiye's fez or turban and dark blue coat
PATROL = [dict(hat="fez", coat="patrol", cloak="none", face="droop"), dict(hat="turban", coat="patrol", cloak="none", face="grey"),
          dict(hat="fez", coat="patrol", cloak="none", face="grey"), dict(hat="turban", coat="blue", cloak="none", face="droop")]
os.makedirs(OUT + "patrol", exist_ok=True)
for i, lk in enumerate(PATROL):
    men.write_vox(OUT + "patrol/patrol_%02d_%s_%s.vox" % (i + 1, lk["hat"], lk["face"]), men.pieces(lk), men.POINTS)
print("ok")
