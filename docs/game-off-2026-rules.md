# Game Off 2026: the rules that affect Smyana

Checked 2026-11-10, after Dominic shared the FAQ link: <https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq>

**Sources.** The itch.io FAQ page itself could not be loaded from our tools (itch.io refused the request), so this summary comes from:

- the jam page: <https://itch.io/jam/game-off-2026>
- GitHub's announcement, "Game Off 2026: the theme is SHIFT": <https://github.blog/open-source/gaming/game-off-2026-the-theme-is-shift/>
- Gamedev.js's write-up, which quotes the 2026 FAQ: <https://gamedevjs.com/competitions/game-off-2026-theme-shift/>
- the 2024 FAQ, which the 2026 one follows closely: <https://itch.io/jam/game-off-2024/topic/4220573/frequently-asked-questions-faq>

Anything taken only from the 2024 FAQ is marked *(2024 FAQ)*. Those points should be checked against the 2026 FAQ by eye.

## The rules

| Topic | Rule |
|---|---|
| Theme | **Shift.** Can be read strongly or loosely. Theme Interpretation is a voting category. |
| Jam period | 1 November 2026 to 1 December 2026. |
| **Deadline** | **1 December 2026, 13:37 PST (21:37 UTC, 23:37 in Bulgaria).** By then the code must be pushed to GitHub *and* the game submitted on itch.io. A GitHub push alone is not an entry. |
| Voting | Ends 1 January 2027, 13:37 PST. Entrants play and rate each other's games; there are no judges. Categories: Overall, Gameplay, Graphics, Audio, Innovation, Theme Interpretation. |
| AI | **Allowed.** "AI-assisted development is allowed." At submission you are asked how you used AI, so players can see how the game was made. No separate rule for AI code, art, audio or voice was found. |
| Engines and code | Any language, engine or library. Templates, starter projects, libraries and reusable code are allowed, but "the vast majority of development" must happen during the jam. Old projects with small changes don't count *(2024 FAQ)*. |
| Repository | The game must live in a **public GitHub repository** holding the source and every asset you are allowed to share. For assets you can't share, leave placeholders and a note in the README *(2024 FAQ)*. |
| Licence | Any licence, or none (then normal copyright applies). Open source is encouraged, not required. |
| Third-party assets | Open-source, commercial, commissioned and original assets are all allowed, with credit where needed. |
| Music | No music-specific rule. It falls under the asset rule above, so normal copyright applies. |
| Team | Solo or team, no maximum size. More than one entry is allowed *(2024 FAQ)*. |
| Platforms | No platform requirement. The game is submitted through itch.io; browser games are pointed out as a good fit. |
| After submitting | Critical bugs can be fixed with a note explaining the change. Don't change the game during voting otherwise *(2024 FAQ)*. |
| Conduct | Entries should be "creative, respectful, and fun". |

## How this meets our plans

### Fine as planned

- **AI everywhere.** AI use is allowed and only needs to be disclosed. Our archive, which keeps all of Dominic's voice notes and messages to show the human direction behind the AI work, is exactly the kind of answer the disclosure question asks for. We can link the repo's archive from the submission form.
- **The Creel engine.** Any engine is allowed, and reusing libraries and starter code is allowed. Building Smyana as its own game pack on Creel (the design doc's recommendation) fits. Work on Smyana started on 10 November, inside the jam.
- **Creel engine changes made for the game** (lighting moods and so on) are jam work and help show it.
- **Music licensing.** The music plan already avoids copyrighted recordings and named arrangements, and uses only public-domain melodies, our own recordings, commissioned soloists and sample libraries. All of that is allowed.
- **The theme.** Smyana / Смяна means "shift", and the season shift, the shift of seasonal work and the men changing over the year all read as the theme.

### Conflicts and risks

1. **Time: 21 days left.** The deadline is 1 December at 21:37 UTC, and today is 10 November. The plans are large: a one-hour run, giant multi-tile trees, a season clock, three enemy AIs, an orchestral intro, 30 to 40 minutes of music, Bulgarian voice acting, recorded singers and a homecoming cutscene. **Decision (Dominic, 2026-11-10): keep the full scope and aim to finish by 1 December.** The tightest part is anything that depends on other people, like hiring and recording remote soloists and voice actors, so start those early. Each one has a fallback (the original theme sung solo, sampled instruments, subtitles).
2. **"Most of the work during the jam" and Age of Anything.** Creel as an engine is fine. Game content reused from Age of Anything (voxel units, tree models, art) is a grey area: if much of what players see is lifted from the earlier game, it can look like an old project changed a little. Keep the line clear: the engine is reused, the game content is new, and the archive says which is which. **Resolved (Dominic, 2026-11-10):** very little Age of Anything art, if any, goes into Smyana. The trees, forest and foliage, and almost all the other art, are made new in November. The Bulgarian builder designed early in the jam to test the new look was made for Smyana, even if it's later reused in Age of Anything.
3. **The public repo must build.** Creel currently lives inside the Age of Anything repo (`Casaide/age-of-whatever`). **Resolved (Dominic, 2026-11-10):** Creel is being split out into its own public repo on 11 November. Smyana's repo should then link it as a submodule or a pinned version, so anyone can build the game.
4. **Commercial sample libraries.** Sounds rendered from Strezov or LibreWave libraries can go in the repo as finished audio, but the libraries themselves can't. Check each library's licence about putting rendered audio in a public repo. Sound effects from Freesound need their CC credits in the repo.
5. **Platform: make sure people can play it.** There's no platform rule, but entrants vote on what they can play, and many play only in the browser. **Dominic (2026-11-10):** a WebAssembly build is believed possible but needs testing. It's nice to have, not required. Test it early, because a browser build can change what the game can afford (memory, loading and audio size). If it doesn't work, ship Windows, macOS and Linux downloads, and say whether it runs on Steam Deck.
6. **Voting starts at once.** After 1 December the game can't change except for critical fixes, so the version we submit is the one people rate. Plan a buffer of a couple of days before the deadline for the itch.io page, builds and testing.
7. **"Respectful".** The Ottomans are an enemy faction. That's fine for a historical survival game, but they should be shown as a historical threat, not as a caricature of Turkish people. Using real Turkish lines (as the music plan proposes) helps.

### Not a conflict, but worth a note

- **AI-generated singing or voices are allowed.** The music plan asked whether the competition allows AI-generated audio: it does, with disclosure. The reason to prefer real singers is quality (AI gets the Rhodope ornaments and open-throated tone wrong), not the rules.
- **Our own recording of a traditional song** for the intro is fine. The melody is public domain and the recording would be ours.

## Dominic's answers (2026-11-10)

In his words, as dictated:

> I think we can do it by 1st of December. Creole will be public. Tomorrow we'll split it out from the other game and we'll put it on its own public repo. The browser, it's a good question. I believe we can build for WebAssembly. But if we can't build for browser, then so be it. It's something we should test. But yeah.

("Creole" is the dictation of Creel.)

- **Scope:** the full plan, by 1 December.
- **Creel:** split into its own public repo on 11 November.
- **Browser:** try a WebAssembly build. If it doesn't work, that's fine.

Later the same day, on Age of Anything art:

> Yes, the majority of the work will be done in November. We have started in the game engine, obviously redoing the lighting and stuff. But all the trees, the forest, the foliage, I mean, everything is going to be done in November, and it's not going to be from Age of Anything. I think very little art will come from Age of Anything, if any. It'll be primarily newly made, but all the trees and stuff will all be replaced. On that note, if you haven't already added it into the archive, the Bulgarian man that we designed also needs to go into the archive as the first step that we did. Well, not the very first step, but yeah, one of the first stages we did. And yeah, although that stage, we might reuse that art in Age of Anything, it was of course created specifically for testing for this, for how the art would look in the new game.

- **Art:** primarily new, made in November. Very little from Age of Anything, if any.

## Still open

- Test the WebAssembly build.
