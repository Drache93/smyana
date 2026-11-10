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

1. **Time: 21 days left.** The deadline is 1 December at 21:37 UTC, and today is 10 November. Our plans (a one-hour run, giant multi-tile trees, a season clock, three enemy AIs, an orchestral intro, 30 to 40 minutes of music, Bulgarian voice acting, recorded singers, a homecoming cutscene) are far more than three weeks of spare-time work, even with AI help. This is the main conflict. We need a jam cut: one season, or a shorter run, with the rest kept for after the jam. Hiring and recording remote soloists and voice actors inside three weeks is especially tight.
2. **"Most of the work during the jam" and Age of Anything.** Creel as an engine is fine. Game content reused from Age of Anything (voxel units, tree models, art) is a grey area: if much of what players see is lifted from the earlier game, it can look like an old project changed a little. Keep the line clear: the engine is reused, the game content is new, and the archive says which is which.
3. **The public repo must build.** If Creel lives only in a private repo (`Casaide/age-of-whatever`), people can't build Smyana from its public repo. Either Creel is public and linked (submodule or a pinned version), or the parts we use are copied in. Our memory notes call Creel open source, but we haven't checked that its repo is public.
4. **Commercial sample libraries.** Sounds rendered from Strezov or LibreWave libraries can go in the repo as finished audio, but the libraries themselves can't. Check each library's licence about putting rendered audio in a public repo. Sound effects from Freesound need their CC credits in the repo.
5. **Platform: make sure people can play it.** There's no platform rule, but entrants vote on what they can play, and many play only in the browser. Lobster (the language Creel is written in) can compile to WebAssembly, but we haven't checked that Creel builds for the web. If it can't, ship Windows, macOS and Linux downloads (and say whether it runs on Steam Deck).
6. **Voting starts at once.** After 1 December the game can't change except for critical fixes, so the version we submit is the one people rate. Plan a buffer of a couple of days before the deadline for the itch.io page, builds and testing.
7. **"Respectful".** The Ottomans are an enemy faction. That's fine for a historical survival game, but they should be shown as a historical threat, not as a caricature of Turkish people. Using real Turkish lines (as the music plan proposes) helps.

### Not a conflict, but worth a note

- **AI-generated singing or voices are allowed.** The music plan asked whether the competition allows AI-generated audio: it does, with disclosure. The reason to prefer real singers is quality (AI gets the Rhodope ornaments and open-throated tone wrong), not the rules.
- **Our own recording of a traditional song** for the intro is fine. The melody is public domain and the recording would be ours.

## Open questions for Dominic

- What is the jam cut: which part of the summer-to-spring run do we ship by 1 December?
- Is the Creel repo public, and can it build for the web?
- Does any Age of Anything art go into the jam build, and if so, how much?
