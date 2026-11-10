#!/usr/bin/env python3
"""Writes src/gen/reset.lobster: reset_world() puts every global of Creel's sim (creel/src/lib) and its match setup
(gen/setup, gen/start) back as it was declared, so one run of the game can set up one place after another (D-020:
one map per place). Creel doesn't ship this yet (its roadmap), so Smyana makes its own.
Run from the repo's root after moving Creel to a newer commit: python3 tools/gen_reset.py"""
import glob, re

FILES = sorted(glob.glob("creel/src/lib/*.lobster")) + ["creel/src/gen/setup.lobster", "creel/src/gen/start.lobster"]


def code_of(line):
    """the line without its // comment (a // inside a string stays)"""
    out, quote = "", False
    i = 0
    while i < len(line):
        c = line[i]
        if c == '"' and (i == 0 or line[i - 1] != "\\"): quote = not quote
        if not quote and line.startswith("//", i): break
        out += c
        i += 1
    return out.rstrip()


lines = []
for path in FILES:
    for raw in open(path):
        raw = raw.rstrip("\n")
        m = re.match(r"var ([A-Za-z_0-9]+)(:[^=]+?)? = (.+)$", code_of(raw))
        if m:
            name, init = m.group(1), m.group(3)
            assert init.count("[") == init.count("]") and init.count("(") == init.count(")"), "a declaration over several lines: " + raw
            lines.append("    %s = %s" % (name, init))
            continue
        m = re.match(r"let ([A-Za-z_0-9]+) = dictionary<.*>\(\d+\)$", code_of(raw))
        if m: lines.append("    %s.clear()" % m.group(1))
        assert not re.match(r"let [A-Za-z_0-9]+ = \[\]", raw), "a list declared with let that the sim may fill: " + raw

with open("src/gen/reset.lobster", "w") as f:
    f.write("// Written by tools/gen_reset.py from Creel's sources: don't edit by hand.\n")
    f.write("// Every global of the sim and the match setup, back as declared: the world is empty again, ready for setup_world.\n\n")
    f.write("def reset_world():\n" + "\n".join(lines) + "\n")
print("%d globals" % len(lines))
