import men, render, random
def kitman(lk, *gear, facings=(0, 160), scale=3):
    v = men.man(lk)
    for g in gear: v.update(g)
    S = scale
    return [render.render(v, f, scale=scale, size=(int(66*S), int(80*S)), origin=(int(28*S), int(70*S)))[0] for f in facings]
if __name__ == "__main__":
    B = dict(hat="kalpak", coat="black", cloak="none", face="droop")
    ims = kitman(B, men.rifle_on_back(), men.tool_in_sash(men.tesla()), scale=5)
    ims += kitman(dict(B, hat="lamb", cloak="fleece"), men.rifle_at_side(), men.tool_in_sash(men.pick_hammer()), scale=5)
    render.sheet(ims).save("kit.png")
