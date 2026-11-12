#!/bin/sh
# Plays Smyana.  ./play.sh [windowed] [debug] [script:tour] [shot:<png> at:<seconds>]
#   A fast playthrough: ./play.sh windowed script:play fast:40 [fresh]  (the men walk every leg, fight what they meet,
#   camp at night, and "play:" lines log the run; fresh keeps them fed; a stuck run says where everyone is and stops)
#   LOBSTER=<path to the lobster binary> (default ~/Dev/lobster/bin/lobster: the Drache93/lobster fork's master,
#   at the commit in creel/LOBSTER_VERSION). After a clone: git submodule update --init --remote (Creel follows its main)
LOBSTER="${LOBSTER:-$HOME/Dev/lobster/bin/lobster}"
cd "$(dirname "$0")" || exit 1
[ -f creel/src/lib/world.lobster ] || git submodule update --init --remote || exit 1
mkdir -p bake_cache baked
cd src && exec "$LOBSTER" smyana.lobster -- "$@"
