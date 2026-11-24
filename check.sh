#!/bin/sh
# Smyana's checks: lint (lobsterfmt's layout, no warnings in our files: src/lint.sh), the game compiles, and the whole
# route plays through with no window (src/run_check.lobster).
#   ./check.sh    Lobster as play.sh finds it (tools/lobster.sh), with lobsterfmt beside it
cd "$(dirname "$0")" || exit 1
LOBSTER="$(tools/lobster.sh fmt)" || exit 1
export LOBSTER
cd src || exit 1
./lint.sh || exit 1
out="$("$LOBSTER" --compile-only smyana.lobster 2>&1 | grep 'error:')"
if [ -n "$out" ]; then
	echo "smyana.lobster:"
	echo "$out"
	exit 1
fi
echo "smyana.lobster: compiles"
"$LOBSTER" run_check.lobster 2>&1 | grep -v 'warning:' | tee /dev/stderr | grep -q '^run_check: ok$'
