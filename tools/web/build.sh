#!/bin/bash
# Builds Smyana for the browser (WebAssembly + WebGL 2), into build/web/, and zips it for itch.io (build/smyana-web.zip).
#   tools/web/build.sh
# Needs: Emscripten (EMSDK=<emsdk dir>, default ~/emsdk), and the Lobster fork (LOBSTER_DIR, default ~/Dev/lobster) at the
# commit in creel/LOBSTER_VERSION with tools/web/lobster-web.patch applied (git apply), its bin/lobster built as usual.
# The browser build runs the C++ the Lobster compiler writes (lobster --cpp), not the JIT; the link takes a few minutes.
# Serve build/web/ over http to try it (python3 -m http.server -d build/web), since a browser won't load it from a file.
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOBSTER_DIR="${LOBSTER_DIR:-$HOME/Dev/lobster}"
EMSDK="${EMSDK:-$HOME/emsdk}"
. "$EMSDK/emsdk_env.sh" > /dev/null 2>&1
OUT="$ROOT/build/web"
EMDIR="$LOBSTER_DIR/dev/emscripten"

# The game as C++ (the compiler must run from the Lobster checkout's root).
(cd "$LOBSTER_DIR" && bin/lobster --silent --cpp "$ROOT/src/smyana.lobster")

# The files the game reads, where it reads them: it asks for ../data and so on from src/, which from the browser's
# root folder is /data. Lobster's own shaders go in data/shaders.
rm -rf "$EMDIR/assets"
mkdir -p "$EMDIR/assets/data" "$EMDIR/assets/bake_cache"
cp -r "$ROOT/data/." "$EMDIR/assets/data/"
cp -r "$LOBSTER_DIR/data/shaders" "$EMDIR/assets/data/"
cp -r "$ROOT/art" "$ROOT/baked" "$ROOT/assets" "$EMDIR/assets/"
# (the tree models are only read to check the baked trees are current; the web build takes that key from baked/)
find "$EMDIR/assets/art/trees/vox" -name '*.vox' -delete

mkdir -p "$OUT"
make -C "$EMDIR" -j4 cpp EFLAGS="-sWASM=1 -sUSE_WEBGL2=1 -sFULL_ES3=1 -sALLOW_MEMORY_GROWTH=1 -sMAXIMUM_MEMORY=4GB \
    -sASYNCIFY -sASYNCIFY_STACK_SIZE=1048576 -sSTACK_SIZE=8388608 -sBINARYEN_IGNORE_IMPLICIT_TRAPS=1 -sEXPORTED_RUNTIME_METHODS=FS,ENV \
    --preload-file assets@/ --shell-file $ROOT/tools/web/shell.html -o $OUT/index.html"
(cd "$OUT" && rm -f ../smyana-web.zip && zip -q -9 ../smyana-web.zip index.html index.js index.wasm index.data)
ls -l "$OUT" "$ROOT/build/smyana-web.zip"
