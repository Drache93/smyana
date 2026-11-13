# Dominic, 2026-11-13: off the path, one goal, and no keys to learn

Text messages in the project, verbatim. Times UTC. Written after playing the build with hunting (PR 119) and reading
`docs/clarity.md`.

**14:19**

> i think seeing through the tree we either do more, or reduce trees a tiny bit around the path. But of course we REAALY wannt people to go off the path and explore. Right now the game is setup all about the path, there's no reason to do anything else. Going off the path to avoid a patrol, and then you run into a bear, or find some reasources, or camp for the night and weight for them to go etc

**14:20**

> each place shouldnt have fixed goals. The goal is getting bak home with enough resources, knowledge and men to improve your village

**14:20**

> teaching them to press C is pretty bad. This is where we need a minimal level of UI somehow

**14:21**

> but i love your men saying "i cant feel my hands" etc

**14:26**, after reading the plan (`docs/off-the-path.md`):

> thats much better. i feel potentially going off the beaten path there might be some other paths to the woods - again the bigger the path, more likely the patrols go there, or look there. They might decide to turn left and go down another path. So hiding down a path is less good

## What Claude took from it

- The trail should be the dangerous, obvious way; the wood beside it is where the reasons are: cover from patrols,
  game, things to find, places to hide a camp, and the bear.
- See the men better under the trees, rather than thinning the woods we were asked to make dense.
- No goal per place. One goal for the run: home with men, resources and knowledge.
- Orders need a small piece of UI, not keys to learn. Keep the men's own lines ("I can't feel my hands").
  Plan in `docs/off-the-path.md`.
- Side paths into the woods, big and small. Patrols take or look down the bigger ones more often, so hiding on a path
  is worse than hiding in the trees.

## Later the same day: there is no work

**18:32**, answering Claude's proposal to pay the men in bread at the ridge ("the work") for the winter walk home:

> But we previously agreed there isn't work. I know the whole original premise is kind of like, it's Mayana, like seasonal work, but we always agreed it's more of an adventure thing. They're not going somewhere to work and coming back. They're going out to collect things and then coming back. The whole point of the game is to safely go through the whole season, exploring and gathering and surviving, and coming back to your village with more knowledge and more things.

What Claude took from it: no pay and no work stop. Winter food has to come from the season itself: what the
autumn gives and is carried or cached, what is found on the way, and what is hunted.

## Evening: "Yes", and a playtest

**18:52**, to Claude's next step ("more to find on the way home (an old hut, another gatherers' cache, wild bees'
honey) and make the winter walk faster"):

> Yes

**19:41**, after playing, with a screenshot (`archive/images/2026-11-13/25-dominic-playing-make-camp-and-no-fire.jpg`):

> telling them to make camp, i got no fire. The UI youve done i pretty bad. You went for minimal, but it just looks like placholder. The over over trees to see if we can cut is just lots of text instead of visual, and majority of trees cant be done, so gameplay is moving my mouse over everything to find something. Im not sure yet actually how or why we would cut trees, just to make a cart to carry other stuff? I think the collecting stuff gameplay needs some thought so we can make it enjoyable

What Claude took from it: the fire was being laid (fifty seconds with no wood carried) and nothing showed until it
caught, so it looked like no fire; fixed (D-133). The rest is a design question, not a fix: what is worth collecting,
why, how it shows without words under the mouse, and whether felling stays. Claude is to bring a short proposal before
building more UI.

## Evening: the gathering proposal, "go ahead"

Claude brought the proposal Dominic asked for (a Claude Doc, "Gathering in Smyana: a proposal"): two kinds of
collecting sharing the pack, fewer bigger finds the men call out, no words under the mouse but drawn cursors, no
felling, drawn order icons and a row of loaves. Dominic ticked all five questions and wrote, **20:39**:

> go ahead

What Claude took from it: build it in the proposal's order (words off the mouse and no felling; stands and call-outs;
things for home in the tally; drawn signs and loaves). Built the same evening: D-134 to D-137, `docs/gathering.md`.
