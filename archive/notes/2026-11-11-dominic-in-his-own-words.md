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

## 08:04, on the two pull requests left by the old threads (chat)

> 45 has conflict, 46 can be merged?

## 08:37, on the riders at the wood's edge (chat)

> riders at the edge shouldnt be looking away, should be facing to the right - like they're following your path - and be much closer to the trees

(Claude turned them to face down the screen to the right, the way the trail runs to the ford, and stood them in under
the first trunks: picture 44.)

## 10:05, on the pull requests (chat)

> both have merge conflicts

## 10:12, on the trees' shadows on the camp's horses (chat, with a close-up of the horses)

> the way the shaddows fall on the horses isnt very realistic, feels like it flat from camera perspective? but shadows dont fall like that right?

> (trees shadow on the horse)

(Claude: he is right. The cause and the fix being tried are in
[the state at the pause](2026-11-11-environment-state-at-the-pause.md).)

## 10:15 to 10:18, on pacing (chat)

> Continue?

> Go

> Yes we need to pace ourselves, have them document current state and stop

## 10:18, a minute later (chat)

> Environment needs to be our focus

(So the environment thread went on, and the music and start-up threads stopped.)

## 08:35, issue #86 "Start up and QL" (GitHub)

> * Camera movement too slow
> * We need custom cursors
> * Default camera zoom seems too close, when i zoom out, i cant zoom back to the default
> * Trees with overlapping shadows you cant see the very base/ring shadow. Darkest point should be where anything touches the ground
> * Overlapping tree shadows seem to be brighter. Lone trees its dark, overlapping its grey
> * Game start is slow, we want very minimal loader. The game menu should show the village (once ready - just the men in forest for now is fine) alive in real time -> when you "start" , the menu should just fade away

**08:35** (chat)
> https://github.com/Drache93/smyana/issues/86 have an agent pick this up when youre back

**10:18** (chat)
> Yes we need to pace ourselves, have them document current state and stop

**10:19** (chat)
> Okay have 86 work be finished then if its close

**about 10:20** (chat)
> Environment needs to be our focus

**about 10:22** (chat, on pull request 47)
> 47 conflicts

**10:44** (chat, pull request 47 merged)
> Done

**12:22** (chat, pull requests 88 and 89 merged)
> ok

**16:00** (chat, pull request 91 merged)
> merged

**16:09** (chat, with two screenshots of the gorge in pull request 92)
> erm those are all hard edges on the gorge though

**16:11** (chat)
> stop the agent after that re-work. And we'll start a new opus thread focued on the remaining issues

**16:32** (chat, to the new thread on the remaining environment issues; "door around" is voice typing for "worked
around")
> Open an issue on creel for proper cliffs. Our work so far was door around

(Opened as Casaide/creel#25.)

**16:33** (chat, voice typed: "clips" is cliffs, "Creole" is Creel; added to Casaide/creel#25)
> It's important that we are able to do proper clips, because if you look at the original pictures from our very first designs, one of them is also a lot of depth in the map at some times. I don't think this will be something we do all the time, but I think there'll be some special occasions where we do it, where our units were sort of traversing along a mountain road, and below you could see the Ottomans like following them sort of at the distance, so it was clear that they were on the same path but just far away. So this is a way of that feeling that they're behind you and they're coming. So for that we'd obviously need some kind of depth and multi-leveled map, or potentially just a trick of perspective, but the point is it's not something that's easily doable in Creole. And second of all, the cliffs as we've done them now are just they're just sharp edges, and we've hidden those sharp edges now behind rocks, but it's still not real cliffs. So doing proper cliffs, proper mount cliffs over rivers with depth will require some clear work.

**16:48** (chat, on pull request 94, the Roman ruins)
> follow up issue after rest is done, the roman ruined road is quite samey

**20:45** (chat, starting the Opus thread to finish the environment, with a screenshot of a summer wood: archive
picture 97)
> okay lets start an opus thread to finish that off. Fir have lots of brown at the bottom, and lighting seems to be a ltitle washed out on the, any idea why? Worried the green scene (summer etc) is too green, and lacking variation. the lighter coloured trees are almost invisible on the grass
