# Dominic, on the README and running the game, 2026-11-24

Written in the project's chat at 13:06 (Bulgarian time). His words, unchanged:

> lets updated our readme too, it still shows original mock up. Test commands etc (they can be pushed to a dev section) and installing lobster should be automatic in our script -> plus we need to plan making a mac os build

And a few seconds later:

> or not, if it means signing, let them just run `./play.sh` ?

What was done (Claude, D-184): the README shows four pictures from the game in place of the mock-up, has a "Play it"
section of three commands, and keeps the test commands in "Development". `./play.sh` fetches and builds Lobster by
itself the first time. A signed macOS app was not made; the unsigned zip the workflow already builds is kept.
