#!/bin/sh
# Plays Smyana by hand with no screen, for an agent that plays as a first-time player (D-139, docs/final-push.md).
# It sends real mouse and key input to the game's window and gets back a picture and what a player would have heard.
#   tools/playtest.sh start [game args]     the game in a hidden 1600x900 window (the size the game opens at: on a smaller screen its foot and right side were cut off), frozen till the first step
#   tools/playtest.sh step <seconds> [actions...]
#        the game runs <seconds> of its own clock with the actions done at the start, then freezes; prints the picture's path and the
#        log since the last step (music, sounds, the men's words)
#   tools/playtest.sh stop
# Actions: click X Y | rclick X Y | dclick X Y | drag X1 Y1 X2 Y2 | key K | hold K SECONDS | move X Y
#   (K as xdotool names keys: c, x, space, Escape, Left, w ...)
# What the log's names mean, for a player who cannot hear: tools/playtest-key.md.
# Needs Xvfb, xdotool and ImageMagick's import. LOBSTER as for play.sh. PLAYTEST_DIR: where it keeps its files.
LOBSTER="$("$(dirname "$0")/lobster.sh")" || exit 1
DIR="${PLAYTEST_DIR:-/tmp/smyana-playtest}"
export DISPLAY=:77
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "$1" in
start)
	shift
	mkdir -p "$DIR"
	rm -f "$DIR"/*.png "$DIR/game.log" "$DIR/seen" "$DIR/n"
	setsid Xvfb :77 -screen 0 1600x900x24 >/dev/null 2>&1 </dev/null &
	echo $! >"$DIR/xvfb.pid"
	sleep 1
	(cd "$ROOT/src" && exec setsid stdbuf -oL "$LOBSTER" smyana.lobster -- windowed heard "$@" >"$DIR/game.log" 2>&1 </dev/null) &
	echo $! >"$DIR/game.pid"
	# (till the game says it has started, a minute at most)
	n=0
	until grep -aq '^start: ' "$DIR/game.log" || [ $n -ge 60 ]; do
		sleep 1
		n=$((n + 1))
	done
	sleep 2
	kill -STOP "$(cat "$DIR/game.pid")"
	echo 0 >"$DIR/n"
	echo 0 >"$DIR/seen"
	echo "started: $(cat "$DIR/game.pid")"
	;;
step)
	secs="$2"
	shift 2
	pid="$(cat "$DIR/game.pid")"
	kill -CONT "$pid" || exit 1
	win="$(xdotool search --onlyvisible --name . 2>/dev/null | head -1)"
	[ -n "$win" ] && xdotool windowfocus "$win" 2>/dev/null
	while [ $# -gt 0 ]; do
		case "$1" in
		# (a button is held a moment: on a slow machine a press and release inside one frame is not seen)
		click) xdotool mousemove "$2" "$3" sleep 0.3 mousedown 1 sleep 0.25 mouseup 1; shift 3 ;;
		rclick) xdotool mousemove "$2" "$3" sleep 0.3 mousedown 3 sleep 0.25 mouseup 3; shift 3 ;;
		dclick) xdotool mousemove "$2" "$3" sleep 0.3 mousedown 1 sleep 0.12 mouseup 1 sleep 0.12 mousedown 1 sleep 0.12 mouseup 1; shift 3 ;;
		move) xdotool mousemove "$2" "$3"; shift 3 ;;
		drag) xdotool mousemove "$2" "$3" sleep 0.4 mousedown 1 sleep 0.5 mousemove "$4" "$5" sleep 0.5 mouseup 1; shift 5 ;;
		key) xdotool key "$2"; shift 2 ;;
		hold) xdotool keydown "$2" sleep "$3" keyup "$2"; shift 3 ;;
		*) echo "unknown action: $1"; shift ;;
		esac
		sleep 0.3
	done
	# (till the run's clock has moved on that many seconds: the game says "tick: <second>" as it goes; a slow machine
	# is given six times as long, and then it is taken as it is)
	from="$(grep -a '^tick: ' "$DIR/game.log" | tail -1 | cut -d' ' -f2)"
	from="${from:-0}"
	w=0
	while [ "$w" -lt $((secs * 12 + 40)) ]; do
		now="$(grep -a '^tick: ' "$DIR/game.log" | tail -1 | cut -d' ' -f2)"
		[ "${now:-0}" -ge $((from + secs)) ] && break
		sleep 0.5
		w=$((w + 1))
	done
	n=$(($(cat "$DIR/n") + 1))
	echo "$n" >"$DIR/n"
	shot="$DIR/$(printf '%04d' "$n").png"
	import -window root "$shot"
	kill -STOP "$pid"
	seen="$(cat "$DIR/seen")"
	total="$(wc -l <"$DIR/game.log")"
	echo "picture: $shot"
	tail -n +"$((seen + 1))" "$DIR/game.log" | grep -a '^heard: \|^said: \|^music: \|^clock: ' | cut -c1-200
	echo "$total" >"$DIR/seen"
	;;
stop)
	kill -CONT "$(cat "$DIR/game.pid")" 2>/dev/null
	kill "$(cat "$DIR/game.pid")" "$(cat "$DIR/xvfb.pid")" 2>/dev/null
	;;
*) sed -n 2,12p "$0" ;;
esac
