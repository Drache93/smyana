# Dominic in his own words, 2026-11-11

His messages about the game, word for word, in the order he sent them (times in UTC).

## The environment: carrying on, the comparison scene, the camera

**05:44** (after PRs #31 and #32 were merged and the work paused)
> but you're not done there, why did you stop?

**05:45** (of the comparison scene, archive picture `2026-11-10/96`)
> ew're still missing lot of detail. The ebankment is too sharp, should be softly going down. And missing all the soft grass

**05:45**
> Also.... should we adjust the camera angle i wonder, feels more special in the mockup with the angle

## 06:50, on the comparison picture and the camera (chat)

> Pleaelse start a critical fable agent to look carefully at yhr comparison picture. And let's try lowering camera angle

## 06:53, on where the camera angle is set (chat)

> Camera angle should be game setting not engine enforced

## 07:04, on documenting Creel (chat)

> Need to ensure creel settings and features documented as we go. We'll do full api docs, CLI etc later

## 07:37, on pull request 42 (chat)

> 42 needs rebase

## 07:37, on the comparison picture (chat)

> That comparison pic uses old camer a angle

(Claude checked: the picture was at 22 degrees. Rendered again with 22 and with 30 forced, the default matched 22.)

## 07:38, on the ground and the water (chat)

> Is the ground still being worked on? Maybe last part thats not rich enough yet. And the water

## 07:39, on the trees after leaf-fall (chat)

> Trees are a bit naked there. Depends how we end up.showing the change to winter. But the rhodope autumn trees are rich with shades. Some tree yellowz some red, some orange. Like our pallette that was designed for the trees

## 07:55, on the ground's leaves and the mock-up's riders (chat)

> Leaf shades look great. What's your recommendation for the riders, and why?

(Claude's answer: leave the riders out of the camp scene, where they read as cavalry resting with the masons, and keep
them for an Ottoman patrol that passes while the men hide. Not decided.)

## 07:57, on the riders and what the scene is for (voice, as transcribed in chat)

> Doesn't really matter, this is just so that we can sort out the environment. Look, this scene isn't going to be a final scene necessarily, although if it looks good enough, it could be a scene we show in a picture, in which case, yes, we might add more detail to it, add some brightness on the edge, but all we're focusing for is just trying to make sure the environment looks as good as possible. So actually, that said, let's put the riders there on the edge just to see how they look with the shadows and everything, make sure they're still visible enough so that yeah, we can see that if we use that as a gameplay mechanic, if it works well or not, and or whether there'll need to be some environmental adjustments or some bloom to help highlight them.

## 07:57, on finishing the environment and starting the music (voice, as transcribed in chat)

> With that said, I think the environment is getting really close now, so we should get a fable agent if it's not already finished, or if it should be continuing to go through all the issues and make sure they're all ticked off. So remind it that it needs to close off all the open issues for environment, and I think it's time to also start an agent, a fable agent, on putting together all the music that we planned. So we can get first draft of that. We should then be in a situation where we can get a very minimal demo, just men standing around a camp with music playing.

## 08:02, on drawing a line under the long threads (as written in chat)

> The lighting and environment threads, I think, are starting to get too long. The lighting one doesn't seem to be using the latest version of everything, so we're still seeing old pictures with old stuff. We should draw a line on them. If there's, find a good place for them both to stop and then start a fresh thread to close all the open issues.

(Claude stopped the environment thread here and wrote [the handoff](2026-11-11-environment-handoff.md).)

## 07:59, on the next phases and the world map (voice, as transcribed in chat)

> And that then brings us ready for our next phase. So we should get another fable agent to plan out our next steps. Put together a plan, we'll then make issues for that plan, and then we'll start working on it. Presumably, since we already have issues to do with locations and stuff, we need to check if there's any gaps, because we haven't really planned out what our game world map will be, the size and shape and scale. I think it's worth us putting together a two-dimensional design of the world that we're going to be moving around, where then we can then create that in 3D, decide which sections of that will be their own maps that need to be loaded and when. We'll then be in a situation where we should be able to have our 20 men walking around the entire game world with obviously nothing to do, but that's our, then our next stage. After that, we can then start on the resources, etc. mechanics. And then the very, very last one is all the threats.

## 08:09 to 08:14, comments on the world plan (typed on the plan itself)

Claude's plan had seven questions at its end. Each comment below was made on the part of the plan named.

On "Not covered by the three phases: the village set, the intro, the homecoming and the ending":

> yes of course. The phases i gave dont cover everything. But i want to focus on the feel of the game first, actually wonder now if the "risks" should be done before resources to get the sounds and music and flintlock fighting - sound and smoke is soooooo important there for the right feel

On the picture of the world:

> could be fun if stretch goal we have a old fashioned looking map we show in the loader

On the seven maps, each loading behind a letter:

> we'll need to ensure at the end of development we get the load time down

On the timings of a one-hour run (two minutes at the ruins on the way home):

> all of this suggets a 2 hour first game is more realistic. 2mins at the roman ruins wont ever happen

On "A line, out and back, with the turn on the ridge?":

> this is good. Because we coem back through different season/weather

On "Seven maps, with the ruins as their own map and the pass before the ridge?":

> sounds good, we'll adjust after we play if needed

On "Where does the frame go?":

> at the end basically

On "Village in the west, climbing east?":

> yes

On "Are bandits a threat in the demo, or only wolves, the bear and the patrol?":

> bandits we can merge with ottomans for now maybe. All that matters is some fighting vs people that also have guns

On the target dates Claude guessed (phase 1 by 15 November):

> realistically much shorter. We have done the whole env in less than a day. We will complete phase 1 today i expect

(On the 07:57 message above, the music's first draft was made the same morning: [journal](../journal/2026-11-11-the-whole-score-in-first-draft.md).)

## 10:10, on hearing the first draft of the score (chat, five messages in a minute)

> autumn dusk and the fire bit samey. I worrry the trumpet type instrument and pipes are over used or just too flat? im listening with airpods and hearing a lot of the same tones across them all

> each song needs a clear design stage. Like we did for 2D before 3D

> worry we're just churning out songs with not much thoughts

> ottomans sounds too synth

> all the music though is basically pipe going up and down quick

(What Claude measured, and the design stage it led to: [`docs/music-design.md`](../../docs/music-design.md).)
