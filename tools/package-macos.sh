#!/bin/sh
# Puts the macOS download together (the workflow .github/workflows/macos-build.yml runs it on a Mac):
#   tools/package-macos.sh <a built Lobster checkout> <out dir>
# Makes <out>/Smyana/ (the game, its baked pictures, Creel's source, Lobster's binary with its modules and data, and
# Smyana.command to double-click) and <out>/Smyana-macos.zip. Left out: the archive, the music bench, git.
set -e
LOB="$1"
OUT="$2"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -x "$LOB/bin/lobster" ] || { echo "no lobster binary at $LOB/bin/lobster"; exit 1; }
rm -rf "$OUT/Smyana"
mkdir -p "$OUT/Smyana/lobster/bin" "$OUT/Smyana/creel"
cp "$LOB/bin/lobster" "$OUT/Smyana/lobster/bin/"
cp -R "$LOB/modules" "$LOB/data" "$OUT/Smyana/lobster/"
cp "$LOB/dev/LICENSE.txt" "$OUT/Smyana/lobster/LICENSE.txt" 2>/dev/null || true
for d in src data assets baked art; do cp -R "$ROOT/$d" "$OUT/Smyana/$d"; done
cp -R "$ROOT/creel/src" "$OUT/Smyana/creel/src"
for f in LICENSE NOTICE README.md LOBSTER_VERSION; do cp "$ROOT/creel/$f" "$OUT/Smyana/creel/" 2>/dev/null || true; done
find "$OUT/Smyana" -name "__pycache__" -prune -exec rm -rf {} +
find "$OUT/Smyana/art" -name "*.py" -delete
cp "$ROOT/README.md" "$OUT/Smyana/README.md"
for f in LICENSE CREDITS.md; do [ -f "$ROOT/$f" ] && cp "$ROOT/$f" "$OUT/Smyana/"; done
cat >"$OUT/Smyana/Smyana.command" <<'RUN'
#!/bin/sh
# Smyana: double-click to play. (The first time, macOS may ask: right-click this file, Open, Open.)
cd "$(dirname "$0")" || exit 1
mkdir -p bake_cache baked
cd src && exec ../lobster/bin/lobster smyana.lobster -- "$@"
RUN
chmod +x "$OUT/Smyana/Smyana.command" "$OUT/Smyana/lobster/bin/lobster"
cat >"$OUT/Smyana/HOW TO PLAY.txt" <<'TXT'
Smyana (Смяна)

To play: double-click Smyana.command.

The first time, macOS will say it cannot check the app, because this build is not signed. Right-click (or
Control-click) Smyana.command, choose Open, then Open again. If it still refuses, open Terminal and type:
    xattr -dr com.apple.quarantine
then a space, drag the Smyana folder onto the Terminal window, and press Return. Then double-click again.

Drag across the men to choose them (double-click a man for all of them). Right click to send them.
C makes camp, X sets the packs down, Space pauses, Tab finds the men, arrows or WASD move the view.
Walk every man into the far edge of a place to move on.

How the game was made, and by whom: README.md, and the archive at https://github.com/Drache93/smyana
TXT
cd "$OUT"
rm -f Smyana-macos.zip
if command -v ditto >/dev/null 2>&1; then ditto -c -k --keepParent Smyana Smyana-macos.zip; else zip -qry Smyana-macos.zip Smyana; fi
ls -la "$OUT/Smyana-macos.zip"
