#!/bin/sh
# Smyana's lint: every Lobster file of ours is in lobsterfmt's layout, and our files compile with no warnings.
#   src/lint.sh [--fix]    --fix writes the formatting (warnings are still yours to fix). Exit 1 on anything found.
#   LOBSTER=<path to the lobster binary> (default ~/Dev/lobster/bin/lobster); lobsterfmt is beside it.
# Warnings in Creel's files are Creel's to fix (creel/check.sh), so only files under src/ count here.
# "use `let` to declare x" doesn't count when another program assigns x (run_check.lobster doesn't see smyana.lobster set hour_force).
cd "$(dirname "$0")" || exit 1
LOBSTER="${LOBSTER:-$HOME/Dev/lobster/bin/lobster}"
LOBSTERFMT="${LOBSTERFMT:-$(dirname "$LOBSTER")/lobsterfmt}"
PROGRAMS="smyana.lobster run_check.lobster"
out="$(mktemp)"
trap 'rm -f "$out"' EXIT
if [ "$1" = "--fix" ]; then
	"$LOBSTERFMT" -w $PROGRAMS >> "$out" 2>&1
else
	"$LOBSTERFMT" -l $PROGRAMS 2>&1 | sed 's/^/not formatted: /' >> "$out"
fi
for prog in $PROGRAMS; do
	"$LOBSTER" --compile-only "$prog" 2>&1 | grep 'warning:\|error:' | while IFS= read -r line; do
		file="${line%%(*}"
		[ -f "$file" ] || continue
		name="$(printf '%s\n' "$line" | sed -n 's/.*use `let` to declare `\([a-zA-Z0-9_]*\)`.*/\1/p')"
		# gen/reset.lobster sets every global back, so it doesn't count as assigning one.
		if [ -n "$name" ] && grep -rhE --include='*.lobster' --exclude-dir=gen "(^|[^.a-zA-Z0-9_])$name *(=[^=]|\+=|-=|\*=|/=|\+\+|--)" . |
			grep -vqE "^ *var $name *="; then
			continue
		fi
		printf '%s\n' "$line"
	done >> "$out"
done
sort -u "$out"
n="$(sort -u "$out" | wc -l | tr -d ' ')"
echo "lint: $n problems"
[ "$n" = 0 ]
