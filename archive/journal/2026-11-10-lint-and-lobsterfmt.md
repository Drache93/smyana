# 2026-11-10: Lint and lobsterfmt

## What happened

Dominic asked whether the work was following "our lobster skill", and the formatter too, "primarily to ensure high
quality and therefore less bugs" ([his words](../notes/2026-11-10-dominic-in-his-own-words.md#lobster-style-and-the-formatter)).

Claude looked for the skill: there is no Lobster skill among Dominic's Claude skills, in Creel, or in Age of Anything's
`.claude/skills` (which holds `make-mod` and `voxel-art`). What Age of Anything does have is a rule, Dominic's of
2026-11-03: every Lobster file in `lobsterfmt`'s layout, every program compiling with no warnings, checked before each
commit. `lobsterfmt` is in the Lobster fork (`dev/lobsterfmt`), formatting to Lobster's own style guide. Smyana had
neither: `check.sh` only looked for compile errors.

## What the check found

On `main` at the time (after PR #25):

- Three files out of `lobsterfmt`'s layout: `smyana.lobster`, `smyana/route.lobster`, `smyana/trees.lobster`. Small
  differences (comment alignment, a few spaces), about 13 lines in all.
- Four real warnings: `MEN_DRAW_K` and `men_looks` (`smyana/men_view.lobster`) and `waiting_lines` and `waiting_t0`
  (`smyana.lobster`) are globals never set again, so they should be `let`.
- Two false warnings: `season_force` and `hour_force` look unassigned to `run_check.lobster`, but `smyana.lobster` sets them.
- Open PR #29 adds one more: an unused variable `n` in `smyana/trees.lobster`.

## What changed

- `src/lint.sh` (new): `lobsterfmt -l` over both programs, then every warning in a file of ours. Creel's own warnings are
  left to Creel. A "use `let`" warning doesn't count when another file assigns that name. `--fix` writes the formatting.
- `./check.sh` runs lint first, so a check fails on layout or a warning.
- `route.lobster` formatted, `men_view.lobster`'s two globals made `let`.
- `smyana.lobster` and `trees.lobster` were left alone while PR #29 changes them, so as not to cause conflicts; they are
  fixed with it.
- CLAUDE.md and README say how to run it and where `lobsterfmt` comes from.
