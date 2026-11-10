#!/bin/sh
# Smyana's checks: lint (lobsterfmt's layout, no warnings in our files: src/lint.sh), the game compiles, and the whole
# route plays through with no window (src/run_check.lobster).
#   ./check.sh    LOBSTER=<path to the lobster binary> (default ~/Dev/lobster/bin/lobster; lobsterfmt beside it)
LOBSTER="${LOBSTER:-$HOME/Dev/lobster/bin/lobster}"
export LOBSTER
cd "$(dirname "$0")/src" || exit 1
./lint.sh || exit 1
out="$("$LOBSTER" --compile-only smyana.lobster 2>&1 | grep 'error:')"
if [ -n "$out" ]; then
	echo "smyana.lobster:"
	echo "$out"
	exit 1
fi
echo "smyana.lobster: compiles"
"$LOBSTER" run_check.lobster 2>&1 | grep -v 'warning:' | tee /dev/stderr | grep -q '^run_check: ok$'
