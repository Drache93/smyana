#!/bin/sh
# Plays Smyana.  ./play.sh [windowed] [debug] [script:tour] [shot:<png> at:<seconds>]
#   A fast playthrough: ./play.sh windowed script:play fast:40 [fresh]  (the men walk every leg, fight what they meet,
#   camp at night, and "play:" lines log the run; fresh keeps them fed; a stuck run says where everyone is and stops)
#   Nothing to set up after a clone: the first run fetches Creel (the submodule, at the commit this repo pins) and
#   fetches and builds Lobster into .lobster/ (tools/lobster.sh; it says what to install if git, cmake or a compiler
#   is missing). LOBSTER=<path to a lobster binary> uses that one instead, as does one at ~/Dev/lobster/bin/lobster.
cd "$(dirname "$0")" || exit 1
[ -f creel/src/lib/world.lobster ] || git submodule update --init || exit 1
LOBSTER="$(tools/lobster.sh)" || exit 1
mkdir -p bake_cache baked
cd src && exec "$LOBSTER" smyana.lobster -- "$@"
