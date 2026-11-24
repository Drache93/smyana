#!/bin/sh
# Prints the path of a Lobster binary for Smyana, fetching and building one the first time if there is none.
#   tools/lobster.sh          the lobster binary
#   tools/lobster.sh fmt      the same, making sure lobsterfmt is built beside it (for src/lint.sh)
# Order: $LOBSTER if it is set and runs; ~/Dev/lobster/bin/lobster if it is there; else .lobster/ in this repo, a
# clone of the Drache93/lobster fork at the commit in creel/LOBSTER_VERSION, built with cmake (a few minutes, once).
# Everything it says goes to stderr; only the path goes to stdout.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
want_fmt="$1"
ok() { [ -x "$1" ] && { [ "$want_fmt" != "fmt" ] || [ -x "$(dirname "$1")/lobsterfmt" ]; }; }
if [ -n "$LOBSTER" ] && ok "$LOBSTER"; then echo "$LOBSTER"; exit 0; fi
if [ -z "$LOBSTER" ] && ok "$HOME/Dev/lobster/bin/lobster"; then echo "$HOME/Dev/lobster/bin/lobster"; exit 0; fi
L="$ROOT/.lobster"
if ok "$L/bin/lobster"; then echo "$L/bin/lobster"; exit 0; fi
say() { echo "$@" >&2; }
missing=""
for tool in git cmake; do command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"; done
command -v c++ >/dev/null 2>&1 || command -v g++ >/dev/null 2>&1 || command -v clang++ >/dev/null 2>&1 || missing="$missing a-C++-compiler"
if [ -n "$missing" ]; then
	say "Smyana needs Lobster, and to build it this computer needs:$missing"
	if [ "$(uname)" = "Darwin" ]; then
		say "  On a Mac:  xcode-select --install   (git and the compiler)"
		say "             brew install cmake       (from https://brew.sh), or the installer at https://cmake.org/download/"
	else
		say "  On Debian or Ubuntu:  sudo apt install git cmake g++ libgl1-mesa-dev libxext-dev libasound2-dev"
	fi
	say "Then run this again."
	exit 1
fi
[ -f "$ROOT/creel/LOBSTER_VERSION" ] || (cd "$ROOT" && git submodule update --init >&2) || exit 1
ver="$(cat "$ROOT/creel/LOBSTER_VERSION")"
say "Fetching and building Lobster (once, a few minutes) into $L ..."
if [ ! -d "$L/.git" ]; then git clone https://github.com/Drache93/lobster "$L" >&2 || exit 1; fi
git -C "$L" fetch -q origin >&2
git -C "$L" checkout -q "$ver" >&2 || { say "could not check out Lobster at $ver"; exit 1; }
targets="lobster"
[ "$want_fmt" = "fmt" ] && targets="lobster lobsterfmt"
jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"
(cd "$L/dev" && cmake -B build -DCMAKE_BUILD_TYPE=Release >&2 && cmake --build build --target $targets -j "$jobs" >&2) || {
	say "Lobster did not build. On Linux it needs the OpenGL, X11 and ALSA headers: sudo apt install libgl1-mesa-dev libxext-dev libasound2-dev"
	exit 1
}
ok "$L/bin/lobster" || { say "Lobster built but $L/bin/lobster is not there"; exit 1; }
say "Lobster is ready."
echo "$L/bin/lobster"
