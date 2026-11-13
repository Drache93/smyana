#!/bin/sh
# Bakes every picture the game draws (the men, the beasts, the trees in every season, the snow, the camp) into baked/,
# which ships in the repo so that no start has to bake (Dominic, 2026-11-12: "we shouldnt be baking at load").
# Run it after changing the art, the light or the camera, and commit baked/ with the change. Stale sheets are removed.
#   LOBSTER=<path to the lobster binary> tools/prebake.sh      (needs a window: on a headless box, DISPLAY=:99 under Xvfb)
LOBSTER="${LOBSTER:-$HOME/Dev/lobster/bin/lobster}"
cd "$(dirname "$0")/.." || exit 1
rm -rf baked && mkdir -p baked bake_cache
cd src && "$LOBSTER" smyana.lobster -- windowed prebake music:off 2>&1 | grep -E "^prebake|^start|error"
ls ../baked | wc -l | xargs echo "baked files:"
