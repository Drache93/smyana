# 2026-11-10: Dominic on the lighting and mood, in his own words

Typed in the project chat, kept as he wrote them.

On the first runnable version's frames, beside the mock-ups:

> The are mockuoa right? Because they dont match our final style

On picture 23 (the beech clearing after leaf-fall), in the trees thread:

> This is our target, please work towards it, ans start a other thread on the lighting and mood

> With caveat that picture was also mockup, its just closest we have to rich and deep environment that draws a player in

> Any engine changes needed are possible also I'd limiting us

## Summary (Claude)

Picture 23 is the target for the light as well as the trees: a low sun with long shadows, a hard
lit side and deep shade, dark woods round a lit clearing, haze and rays in the air, and a fire.
It is a mock-up too, so it's the direction rather than a pixel match. The engine can change
wherever it stands in the way.

## On the first lighting pass (21:48 and 21:49)

> Shadows seem a but messy, I think we're overlapping with other ones? Add more trees for a more fair comparison with the design

> Design the shadows at much less dark. Normal show shade basically. Your implementation they're stretched and super dark

Summary (Claude): the shadows should be an ordinary soft shade, not long black stretches. The
comparison needs a wood as close as the mock-up's.

## On the second pass (21:54 and 21:55)

> Yeh o was right. Totally bugged. Overlapping loog like bug smudges

> Should be harder edged too. Biggest difference with the design is evryhting crisp and sharp. Our new stuff is looking soft so far, engine issue?

Summary (Claude): the smudges were Claude's air and woods layers, and the soft shadow edges were a
blur Claude added. The target is crisp: hard-edged light shade, sharp art.

## On the crisp pass (22:00)

> Much closer!

> Shadows very close now. Unsure if lighting work needed still until the ground texture and bushes are done

## After the crisp pass merged (22:18)

> merged for now. But between lighting and ground we still have bunch more work. The trees in the example had shadows in the branches too. Our pic still looks like big bright omni light on everything

Summary (Claude): the light still falls the same everywhere. In the mock-up the trees carry
shade in their branches (the trees thread took that, in how trees are baked) and the wood behind
the clearing is dark and misty, so the clearing reads as a lit room in a dark wood (this thread).

## When the dark-wood PR merged (2026-11-11, 05:44)

> but you're not done there, why did you stop?

Summary (Claude): keep going toward the mock-ups across the moods, the seasons and seeing the men
(issues #14, #11, #7), and don't stop after each PR.
