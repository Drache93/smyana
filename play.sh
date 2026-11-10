#!/bin/sh
# Plays Smyana.  ./play.sh [windowed] [debug] [script:tour] [shot:<png> at:<seconds>]
#   LOBSTER=<path to the lobster binary> (default ~/Dev/lobster/bin/lobster: the Drache93/lobster fork's master,
#   at the commit in creel/LOBSTER_VERSION). After a clone: git submodule update --init
LOBSTER="${LOBSTER:-$HOME/Dev/lobster/bin/lobster}"
cd "$(dirname "$0")" || exit 1
[ -f creel/src/lib/world.lobster ] || git submodule update --init || exit 1
mkdir -p bake_cache
cd src && exec "$LOBSTER" smyana.lobster -- "$@"
