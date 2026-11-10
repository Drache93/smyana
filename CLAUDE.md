# Smyana (Смяна)

An atmospheric survival RPG built as an RTS, on the Creel engine (from Age of Anything), for a
game competition whose theme is "Shift". Read [`README.md`](README.md) and
[`docs/design.md`](docs/design.md) first.

## Names

- The game is **Смяна**, written **Smyana** in Latin letters (repo, competition submission,
  text). The Cyrillic can go on game imagery. It was called "Shift" before 2026-11-10.
- The village is fictional, inspired by Kovachevitsa. Don't name it Kovachevitsa in the game.
- The engine is **Creel**.

## Before a design call

Skim [`archive/decisions.md`](archive/decisions.md) so you don't undo a deliberate choice.
Items in `docs/design.md` marked **Proposal** aren't agreed.

## Lobster code (Dominic, 2026-11-10)

For quality, and so fewer bugs: every Lobster file of ours is in `lobsterfmt`'s layout, and our files compile with no
warnings. `src/lint.sh` checks both (`--fix` formats); `./check.sh` runs it first. Run `./check.sh` before every commit
and push, and fix a warning rather than living with it. `lobsterfmt` is in the Lobster fork (`dev/lobsterfmt`, built
beside `bin/lobster`); its layout is Lobster's [style guide](https://github.com/Drache93/lobster/blob/master/docs/source/style_guide.md),
and new code follows that guide too. A global that's never assigned again is a `let`. Creel's own warnings are Creel's
to fix, in its repo.

## The archive (keep it up to date)

`archive/` records how the game is made: pictures, notes, decisions, direction changes, bugs.
See [`archive/README.md`](archive/README.md) for the layout and templates. At the end of any
session that changed something meaningful:

1. **Pictures** in `archive/images/<YYYY-MM-DD>/NN-name.ext`, numbered within the day. Keep bug
   shots.
2. **Journal** entry in `archive/journal/<YYYY-MM-DD>-<title>.md` (game work) or
   `archive/engine/<YYYY-MM-DD>-<title>.md` (Creel changes).
3. **Decisions** appended to `archive/decisions.md` with the next D-number. Never edit old
   ones; supersede them.
4. **Timeline:** one line in `archive/timeline.md`.

**Keep Dominic's own words.** Every voice note and message he gives about the game goes into the
archive verbatim: audio in `archive/audio/<date>/` (Opus, mono) where there's a recording, text
in `archive/notes/<date>-...md`. The point is to show that the human direction drives the
AI-made game. Summaries go alongside, never instead.

The archive is append-only. Plain words, with dates, crediting who decided what (Dominic or
Claude). Only commit pictures and sounds we made or have the rights to.
