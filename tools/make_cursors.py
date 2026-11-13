#!/usr/bin/env python3
"""Makes Smyana's mouse cursors (issue #86: "We need custom cursors") into data/cursors/: each one at the size it is
shown (<name>.png) and twice that for a high DPI display (<name>@2x.png, every pixel doubled, so it stays pixel art like
the game). The game hands them to the OS (src/smyana/cursors.lobster), so they never lag the mouse.

  point  the plain pointer: an arrow, in the parchment of the game's few marks (the rings round the chosen men)
  go     the men are chosen and the ground under the mouse is where they would walk: the arrow and the ring an order leaves
  fell   the men are chosen and a young tree is under the mouse where a bridge is down: a felling axe (2026-11-13:
         felling only for mending a bridge)
  gather a find the wood gives: a wicker basket
  take   a pile (a cache, the honey, the men's own packs): an open hand
  knife  a carcass to butcher: a knife
  shoot  game or a foe: a front sight's ring
  camp   a shepherds' hut to camp in: a small flame
  study  the Roman ruins to study: an open book
  dig    fallen rock to clear: a spade

(Dominic, 2026-11-13: no words under the mouse, "lots of text instead of visual"; the cursor alone says what a
right-click will do.)

Each is drawn as a mask of fill, shade and edge pixels; a dark outline is put round it all, so it reads on the light
grass and in the dark wood alike. Run from the repo's root: python3 tools/make_cursors.py   (Pillow)"""
import os
from PIL import Image

OUT = "data/cursors"
EDGE = (24, 19, 14, 255)      # the outline: near black, warm
FILL = (242, 232, 201, 255)   # parchment (the rings' colour, 0.95 0.91 0.79)
SHADE = (196, 182, 148, 255)  # the parchment's shaded side
IRON = (150, 154, 158, 255)   # the axe's head
IRON2 = (104, 108, 112, 255)
STEEL = (226, 230, 232, 255)  # its ground edge
HAFT = (150, 104, 60, 255)    # the haft: beech wood
HAFT2 = (108, 72, 40, 255)
WICKER = (196, 150, 84, 255)  # the basket: peeled willow
WICKER2 = (140, 100, 50, 255)
FLAME = (240, 160, 50, 255)   # the hut's fire
FLAME2 = (250, 220, 120, 255)
EMBER = (190, 70, 30, 255)
COLOURS = {"o": FILL, "s": SHADE, "i": IRON, "j": IRON2, "e": STEEL, "h": HAFT, "g": HAFT2, "#": EDGE,
           "w": WICKER, "v": WICKER2, "f": FLAME, "y": FLAME2, "r": EMBER}

ARROW = """
o
oo
ooo
oooo
ooooo
oooooo
ooooooo
oooosss
oos oo
os  oo
s    oo
     oo
      s
"""

RING = """
  oooo
 o    o
o      o
 o    o
  oooo
"""

AXE = """
        eij
       eiijj
      eiiijj
     eiiiijhh
      eiiihhg
       eijhhg
         hhg
        hhg
       hhg
      hhg
     hhg
    hhg
   hhg
   gg
"""


BASKET = """
   vvvvvv
  v      v
 v        v
wwwwwwwwwwww
wvwvwvwvwvwv
 wwwwwwwwww
 wvwvwvwvwv
  wwwwwwww
  vvvvvvvv
"""

HAND = """
    o o o
  o o o o
  o o o o
  o o o o o
  ooooooo o
  oooooooo
o ooooooo
 oooooooo
  oooooos
   ooooss
    ssss
"""

KNIFE = """
          e
         ei
        eij
       eij
      eij
     eij
    eij
   gg
  hhg
 hhg
hhg
gg
"""

SIGHT = """
    ooo
  oo   oo
 o       o
 o   s   o
o   sss   o
 o   s   o
 o       o
  oo   oo
    ooo
"""

FLAMES = """
    y
   yf
   yff
  fyyf
  fyyff
 ffyyyf
 ffyyyff
 rfyyyfr
  rfffr
 hhhhhhh
"""

BOOK = """
 sooo ooos
soooo oooos
soooo oooos
soooo oooos
soooo oooos
soooo oooos
ssssshsssss
"""

SPADE = """
         gg
        hhg
       hhg
      hhg
     hhg
 ee hhg
eiijhg
eiiij
eiiij
 ejj
"""


def parse(art, at=(0, 0)):
    """The pixels of a piece of art as {(x, y): colour}, its top left at `at`."""
    px = {}
    for y, row in enumerate(art.strip("\n").split("\n")):
        for x, ch in enumerate(row):
            if ch in COLOURS:
                px[(x + at[0], y + at[1])] = COLOURS[ch]
    return px


def cursor(name, parts, size, hot):
    px = {}
    for art, at in parts:
        px.update(parse(art, at))
    # the outline: every empty pixel beside a drawn one, its eight neighbours
    edge = {}
    for (x, y) in px:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                p = (x + dx, y + dy)
                if p not in px:
                    edge[p] = EDGE
    px.update(edge)
    xs = [p[0] for p in px]
    ys = [p[1] for p in px]
    ox, oy = -min(xs), -min(ys)
    assert max(xs) + ox < size and max(ys) + oy < size, name
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    for (x, y), c in px.items():
        img.putpixel((x + ox, y + oy), c)
    img.save(os.path.join(OUT, name + ".png"))
    img.resize((size * 2, size * 2), Image.NEAREST).save(os.path.join(OUT, name + "@2x.png"))
    print(name, "hot spot", (hot[0] + ox, hot[1] + oy))


os.makedirs(OUT, exist_ok=True)
cursor("point", [(ARROW, (0, 0))], 20, (0, 0))
cursor("go", [(ARROW, (0, 0)), (RING, (8, 11))], 20, (0, 0))
cursor("fell", [(AXE, (0, 0))], 20, (5, 3))
# (the rest: the arrow small at the top left, so the hot spot is still its tip, and the picture beside it)
ARROW_S = """
o
oo
ooo
oooo
oos
os
"""
cursor("gather", [(ARROW_S, (0, 0)), (BASKET, (5, 7))], 20, (0, 0))
cursor("take", [(ARROW_S, (0, 0)), (HAND, (6, 6))], 20, (0, 0))
cursor("knife", [(ARROW_S, (0, 0)), (KNIFE, (6, 5))], 20, (0, 0))
cursor("shoot", [(SIGHT, (0, 0))], 20, (5, 4))
cursor("camp", [(ARROW_S, (0, 0)), (FLAMES, (6, 6))], 20, (0, 0))
cursor("study", [(ARROW_S, (0, 0)), (BOOK, (5, 8))], 20, (0, 0))
cursor("dig", [(ARROW_S, (0, 0)), (SPADE, (6, 6))], 20, (0, 0))
