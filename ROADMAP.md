# Development Roadmap

## Goal

Deliver a playable Mac demo that launches into a first-person Canberra experience centered on New Parliament House, using a Metal renderer, a SwiftUI application shell, and a C-heavy core engine.

## Current Starting Point

- The repository currently contains art assets under `MilsimPonyGame/Assets/PrimaryAssets/`.
- There is no `MilsimPonyGame.xcodeproj` yet.
- There is no engine, gameplay, or tooling code checked in yet.
- The README defines the immediate target as a first-person Canberra rendering demo that can be played end to end.

## Planning Assumptions

- One cycle equals one week.
- The base plan assumes a four-lane team:
  - `Engine/Core`: C runtime, math, scene management, streaming, collision.
  - `Rendering/Platform`: Metal renderer, SwiftUI shell, input, build integration.
  - `World/Data`: Canberra layout, terrain, roads, landmarks, asset prep.
  - `Gameplay/QA`: first-person controller, demo flow, test coverage, tuning.
- If this is a solo effort, keep the same order of work and expect the schedule to roughly double.
- The first playable demo should prioritize the Parliament House precinct and the first ring of suburban escape routes over full-city coverage.

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

## Workstream Division

### Engine/Core

- Own the C runtime, math library, transform system, scene objects, collision, streaming, and performance instrumentation.
- Deliver stable interfaces that Rendering/Platform and Gameplay/QA can build on without frequent rewrites.

### Rendering/Platform

- Own the Xcode project, SwiftUI shell, Metal view lifecycle, shader pipeline, camera submission, lighting, and render debugging.
- Keep macOS integration thin so the engine remains portable and the C core remains authoritative.

### World/Data

- Own Canberra reference gathering, coordinate conventions, terrain/road data preparation, blockouts, landmark placement, and asset conversion.
- Focus detail where the demo path needs it most rather than spreading fidelity evenly across the whole city.

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

## Standard Cycle Rhythm

- `Day 1`: lock scope, acceptance criteria, and the demoable outcome for the week.
- `Day 2`: complete the primary implementation tasks in each lane.
- `Day 3`: integrate across lanes and cut anything that threatens the weekly exit gate.
- `Day 4`: performance pass, bug fixing, and demo route cleanup.
- `Day 5`: playtest, record findings, and rewrite the next cycle backlog from what was learned.

## Recommended Sequencing Rules

- Do not start broad Canberra content production before the coordinate system, scale rules, and chunk format are stable.
- Treat the Parliament House district as the anchor slice; every later cycle should keep that slice runnable.
- Keep the SwiftUI layer minimal and avoid moving engine logic out of the C core unless there is a strong platform reason.
- Add fidelity only after traversal and performance are acceptable, otherwise the project will accumulate expensive rework.

## Near-Term Next Actions

1. Create `MilsimPonyGame.xcodeproj` in the repo root as the first deliverable of cycle `0`.
2. Establish the initial source tree for `App`, `Renderer`, `Core`, `World`, and `Gameplay`.
3. Build a one-room or open-pad render test using one imported asset and the intended first-person camera path.
4. Choose the first Canberra reference set and lock scale conventions before any large content pass begins.
