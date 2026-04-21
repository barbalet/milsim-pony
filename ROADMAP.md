# Development Roadmap

## Goal

Deliver a playable Mac demo that launches into a first-person Canberra experience using a Metal renderer, a SwiftUI application shell, and a C-heavy core engine, with visible basin-scale coverage from Woden to Belconnen, Lake Burley Griffin as a readable landmark, and a usable sniper rifle with 4x magnification.

## Current Starting Point

- The repository currently contains art assets under `MilsimPonyGame/Assets/PrimaryAssets/`.
- `MilsimPonyGame.xcodeproj` exists and builds on macOS.
- The current demo includes a functioning app shell, renderer, packaged world data, and a small Parliament-adjacent playable slice.
- Reviewer feedback has established that the current slice is too narrow and does not yet show Canberra in part or whole.
- The next five calibrated cycles must prioritize a basin-scale Canberra view including Lake Burley Griffin and the landscape from Woden to Belconnen.
- The first usable weapon will be a sniper rifle with 4x magnification, which raises the required terrain, landmark, collision, and long-range rendering resolution.

## Planning Assumptions

- A cycle is now a Canberra coverage gate rather than a fixed one-week sprint.
- Basin-modeling cycles should budget two weeks minimum and keep a third week open for integration, reference cleanup, or data rework when the Woden-to-Belconnen model is still not readable enough.
- A cycle does not count as complete unless the build materially improves the readable Canberra model between Woden, Lake Burley Griffin, and Belconnen.
- The base plan assumes a four-lane team:
  - `Engine/Core`: C runtime, math, scene management, streaming, collision.
  - `Rendering/Platform`: Metal renderer, SwiftUI shell, input, build integration.
  - `World/Data`: Canberra layout, terrain, roads, landmarks, asset prep.
  - `Gameplay/QA`: first-person controller, demo flow, test coverage, tuning.
- For a four-lane team, cycles `10` to `14` now imply roughly `10` to `15` weeks of work. For a solo effort, keep the same order of work and expect roughly `20` to `30` weeks.
- Every lane must ship Canberra-model value each cycle. Engine, rendering, and gameplay tasks are support work unless they directly improve or validate basin coverage.
- Basin-scale Canberra coverage now takes priority over adding more corridor-only scripting.
- The world plan must support hierarchical resolution: macro Canberra coverage plus denser streamed data around long-range viewpoints and combat lanes.
- The sniper rifle requires stable distant rendering, high-confidence collision queries, and authored long-sightline tests.

## Milestones

### Milestone 1: Foundation

Cycles `0` to `2`

Exit criteria:

- `MilsimPonyGame.xcodeproj` exists and builds on macOS.
- A Metal-backed view renders a 3D scene.
- First-person camera movement works with keyboard and mouse input.
- Existing assets can be imported and drawn in-engine.

### Milestone 2: Canberra Vertical Slice

Cycles `3` to `4`

Exit criteria:

- The New Parliament House hill and surrounding roads are explorable.
- Terrain, basic buildings, and landmark placement establish readable Canberra geography.
- Collision and scene streaming work for the initial district.

### Milestone 3: Playable Demo Loop

Cycles `5` to `7`

Exit criteria:

- A player can spawn, navigate, and complete a short escape route.
- Basic evasion pressure exists through detection, timing, or patrol placeholders.
- UI and state transitions support a clean start, fail, and restart loop.

### Milestone 4: Demo Hardening

Cycles `8` to `9`

Exit criteria:

- The demo runs reliably on target Mac hardware.
- Performance, controls, and level readability are tuned.
- A distributable demo package and review build checklist exist.

### Milestone 5: Canberra Basin And Sniper Foundation

Cycles `10` to `14`

Exit criteria:

- The demo visibly includes Lake Burley Griffin and the broader landscape from Woden to Belconnen.
- Basin-scale terrain, roads, landmark silhouettes, and collision are available at a resolution that supports long-range observation.
- The first usable weapon is a sniper rifle with 4x magnification.
- Scoped observation and firing are stable enough to be used as a core gameplay pillar rather than a prototype gimmick.

## Workstream Division

### Engine/Core

- Own the C runtime, math library, transform system, scene objects, collision, streaming, and performance instrumentation.
- Deliver stable interfaces that Rendering/Platform and Gameplay/QA can build on without frequent rewrites.

### Rendering/Platform

- Own the Xcode project, SwiftUI shell, Metal view lifecycle, shader pipeline, camera submission, lighting, and render debugging.
- Keep macOS integration thin so the engine remains portable and the C core remains authoritative.

### World/Data

- Own Canberra reference gathering, coordinate conventions, terrain/road data preparation, blockouts, landmark placement, and asset conversion.
- Deliver basin-wide Canberra readability first, then concentrate extra fidelity around travel lanes, major landmarks, and sniper firing positions.

### Gameplay/QA

- Own the first-person controller, stamina or movement tuning, objective flow, restart logic, playtest scripts, and bug triage.
- Turn engine slices into a genuinely playable demo every cycle rather than waiting for a final polish phase.

## Cycle Plan

| Cycle | Outcome | Engine/Core | Rendering/Platform | World/Data | Gameplay/QA | Exit Gate |
| --- | --- | --- | --- | --- | --- | --- |
| `0` | Project bootstrap | Set up C core targets and folder conventions | Create `MilsimPonyGame.xcodeproj`, app target, Metal view, debug launch path | Inventory existing assets and define import rules | Define smoke checklist and input map | App boots to a clear screen with logging and input hooks |
| `1` | First rendered frame | Add math, transforms, and scene object basics | Render loop, depth buffer, unlit shader, camera submission | Assemble a tiny test scene from existing props | Free-look and first-person camera controls | User can move around a rendered 3D scene |
| `2` | Engine slice ready for world data | Add asset loading, scene serialization, and sector layout stubs | Draw imported OBJ assets with stable scale and lighting | Prepare Canberra coordinate system and graybox data files | Add debug HUD and frame timing capture | Engine can load test content from data files instead of hardcoded objects |
| `3` | Parliament House district graybox | Add collision volume support and chunk loading | Terrain, road mesh, sky, and sun lighting pass | Block out New Parliament House hill, roads, and surrounding structures | Add grounded movement, sprinting, and spawn flow | Player can traverse the first Canberra district on foot |
| `4` | Vertical slice integration | Add streaming boundaries and scene culling hooks | Improve culling, shadows, and landmark readability | Extend to the first suburban escape corridor | Add checkpoints, reset loop, and route metrics | A stable end-to-end exploration slice exists from spawn to escape corridor |
| `5` | Evasion prototype | Add line-of-sight or trigger query support | Add visibility feedback, flashlight or contrast support if needed | Place cover, props, and route signposting | Add detection, failure state, and retry loop | The build feels like a stealth-evasion demo rather than a renderer test |
| `6` | Content credibility pass | Add config tuning hooks and profiling markers | Improve materials, fog, atmosphere, and performance hotspots | Refine landmarks, road widths, terrain silhouette, and suburb cues | Add onboarding prompts and tune traversal pacing | Canberra reads clearly and the route is understandable without explanation |
| `7` | Demo alpha | Stabilize saves or session state as needed, plus crash logging | Add menu shell, settings, and pause support | Lock playable bounds and final route dressing | Add win condition, fail condition, and full demo script | A full start-to-finish playable demo works without developer intervention |
| `8` | Beta hardening | Fix memory, streaming, and collision edge cases | Tune frame time, shadows, and LOD behavior | Clean collision gaps and visual seams | Run structured playtests and close blocker bugs | Demo is stable enough for outside review |
| `9` | Release candidate | Finalize build versioning and packaging steps | Final visual polish and capture settings | Lock content and fallback paths | Regression test, checklist sign-off, release notes | Shareable demo package is ready |
| `10` | Basin data reset | Replace corridor-first assumptions with basin-scale sector and tile rules | Add first macro Canberra render path for large extents and lake coverage | Import first-pass Canberra basin coverage from Woden to Belconnen, including Lake Burley Griffin footprint | Define sniper use cases, firing distances, and review criteria | App loads a basin-scale Canberra preview with lake and district extents visible |
| `11` | Macro Canberra readability | Add large-world streaming support, far-field terrain residency, and long-sightline culling rules | Improve distant terrain, water, haze, and skyline readability | Build recognizable basin silhouettes, district massing, and arterial layout | Add macro navigation and sightline review route | Lake, Woden-side landscape, and Belconnen-side landscape all read from authored viewpoints |
| `12` | Scope and resolution foundation | Add higher-resolution tile streaming and query hooks for long-range play | Add 4x magnified scope camera, reticle, and LOD stabilization | Densify terrain, roads, and landmark data around central basin and sniper lanes | Add sniper perch tests and scoped landmark validation | Player can inspect distant Canberra landmarks through a stable 4x scope |
| `13` | Sniper rifle usable pass | Add accurate long-range hit query support and firing validation hooks | Add scoped firing feedback, impact readability, and long-range target presentation | Raise collision and cover fidelity around firing lanes and target zones | Add the first usable sniper rifle: equip, zoom, fire, reload, and target confirmation | Sniper rifle works reliably against authored long-range targets across Canberra sightlines |
| `14` | Basin demo integration | Tune streaming, memory, and large-world edge cases for the expanded map | Polish water, skyline, terrain, and long-range clarity for review captures | Close major gaps between Woden, the lake, and Belconnen while preserving landmark readability | Integrate traversal and sniper observation into one reviewable loop | Review build demonstrates Lake Burley Griffin plus Woden-to-Belconnen landscape with a usable 4x sniper rifle |

## Standard Cycle Cadence

- `Week 1`: lock Canberra references, extents, acceptance criteria, and the exact Woden-to-Belconnen coverage gain required for the cycle.
- `Week 2`: integrate terrain, roads, landmarks, streaming, and review viewpoints until the demo reads as Canberra without developer narration.
- `Week 3`: use only when needed for reference correction, world-data rebuilds, performance cleanup, and another review pass if the coverage gate is still not met.

## Recommended Sequencing Rules

- Do not start broad Canberra content production before the coordinate system, scale rules, and chunk format are stable.
- Treat the Parliament House district as the anchor slice; every later cycle should keep that slice runnable.
- Treat Lake Burley Griffin and basin ridgelines as the new world anchors for scale, orientation, and long-range validation.
- Keep the SwiftUI layer minimal and avoid moving engine logic out of the C core unless there is a strong platform reason.
- Do not prioritize another corridor-only cycle ahead of basin-scale readability from Woden to Belconnen.
- Do not close a cycle that fails to add clear Canberra-model progress or still leaves the demo opening from an unconvincing survey location.
- Do not ship the sniper rifle until the map supports stable distant observation and reliable long-range collision.
- Add fidelity in layers: basin coverage first, then higher resolution around travel lanes, landmarks, and sniper perches.

## Near-Term Next Actions

1. Lock the expanded Canberra extents and tile plan for coverage from Woden through the lake basin to Belconnen.
2. Build a first-pass basin dataset that includes Lake Burley Griffin, macro terrain, and major landmark silhouettes.
3. Define the sniper rifle requirements in engine terms: target distances, zoom behavior, long-range collision, and scoped rendering acceptance.
4. Author the first review viewpoints that must prove Canberra reads at large scale before another corridor-only content pass is accepted.
