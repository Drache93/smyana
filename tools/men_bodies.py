#!/usr/bin/env python3
"""Writes data/voxel/bodies/man_NN.json: one Creel voxel body for each sample man in art/men/vox/samples.
Every man is the same rig (the walk, the arms' reach, the joints) over his own .vox, so only the file differs.
Run from the repo's root: python3 tools/men_bodies.py"""
import json, os, re

RIG = {
    "skin": "#d9a27c", "pale": "#ebbf99", "size": 0.73, "fur": 0.0, "reach": 5.0,
    "points": {"hip": {"at": [0, 0, 21.0], "bob": 0.5}, "chest": {"at": [0, 0.3, 29.6], "bob": 0.5}, "head": {"at": [0, 0.7, 37.1]}},
    "legs": [{"hip": ["hip", 1.75, 0, 0], "foot": [1.9, 0, 1.9], "stride": 5.0, "lift": 2.2, "bones": [9.58, 9.58], "pole": [0, 1, 0],
              "r": [2.0, 1.4, 1.3, 0.85], "mats": ["skin", "skin"], "shapes": []}],
    "arms": {"shoulder": ["chest", 4.3, -0.2, 1.2], "bone": 6.7, "thick": 1.3, "sleeve": "skin", "hand": "skin"},
    "helm": {"at": ["head", 0, -0.3, 1.0], "r": 2.75},
    "armour": {"a": ["hip", 0, 0.1, 2.6], "b": ["chest", 0, 0, 0.4], "r": [2.7, 3.2]},
    "seat": {"z": 21.5, "astride": ["white", "hair", "leather"]},
    "shapes": [],
    # palette indices as art/men/tools/men.py numbers them: 1 SKIN, 2 HAIR, 7 SASH, 8 BELT, 9 SILVER
    "mats": {"1": "skin", "2": "hair", "7": "team", "8": "leather", "9": "metal"},
    "bare": True,
}
SAMPLES = "art/men/vox/samples"
OUT = "data/voxel/bodies"
os.makedirs(OUT, exist_ok=True)
for name in sorted(os.listdir(SAMPLES)):
    m = re.match(r"(man_\d\d)_(.*)\.vox$", name)
    if not m: continue
    body = dict(RIG)
    body = {"_doc": "A Smyana man (%s): written by tools/men_bodies.py, don't edit by hand." % m.group(2).replace("_", ", "), **body}
    # Creel reads a body's model from <data>/voxel/models/: this path walks from there to the art folder, so the
    # .vox files live in one place.
    body["vox"] = "../../../" + SAMPLES + "/" + name
    with open("%s/%s.json" % (OUT, m.group(1)), "w") as f:
        json.dump(body, f, indent=1)
        f.write("\n")
print("ok")
