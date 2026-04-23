# Development Roadmap

## Goal

Deliver a playable Mac demo that launches into a first-person Canberra experience using a Metal renderer, a SwiftUI application shell, and a C-heavy core engine, with visible basin-scale coverage from Woden to Belconnen, Lake Burley Griffin as a readable landmark, and a usable sniper rifle with 4x magnification.

## Current Starting Point

- The repository currently contains art assets under `MilsimPonyGame/Assets/PrimaryAssets/`.
- `MilsimPonyGame.xcodeproj` exists and builds on macOS.
- The current demo includes a functioning app shell, renderer, packaged world data, and an expanded Canberra street-atlas review covering the east basin, Parliament axis, Civic, Woden, Black Mountain, and Belconnen.
- Reviewer feedback has established that the current Canberra model still needs denser district detail, more named roads, and stronger online reference coverage before it reads as a convincing city-scale environment.
- The next six calibrated cycles must prioritize a basin-scale Canberra atlas including Lake Burley Griffin, the district street network from Woden to Belconnen, and a reference-backed gallery drawn from online sources plus in-game captures.
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
- For a four-lane team, cycles `10` to `20` now imply roughly `12` to `24` weeks of work. For a solo effort, keep the same order of work and expect roughly `24` to `40` weeks.
- Every lane must ship Canberra-model value each cycle. Engine, rendering, and gameplay tasks are support work unless they directly improve or validate basin coverage.
- Basin-scale Canberra coverage now takes priority over adding more corridor-only scripting.
- The world plan must support hierarchical resolution: macro Canberra coverage plus denser streamed data around long-range viewpoints and combat lanes.
- The sniper rifle requires stable distant rendering, high-confidence collision queries, and authored long-sightline tests.
- From cycles `15` to `20`, the review build should drive toward full texture coverage for every shipped scene drawable, with Canberra-sourced source imagery, provenance notes, and derived outputs stored under `MilsimPonyGame/Assets/Textures/`.

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

### Milestone 6: Canberra Street Atlas Expansion

Cycles `15` to `17`

Exit criteria:

- The overhead map reads as a Canberra street atlas rather than only a sector sketch.
- Civic, Barton-Russell, Woden Town Centre, and Belconnen Town Centre each have their own higher-detail street pass.
- Online reference capture from Google Maps and official ACT transport material is attached to the repo as a reusable gallery.
- The Canberra texture library under `MilsimPonyGame/Assets/Textures/` expands with district-specific source images and derived materials for the street-atlas build.

### Milestone 7: District Integration And Combat Readiness

Cycles `18` to `20`

Exit criteria:

- Black Mountain, Belconnen, Woden, the central basin, and the east approach connect into one coherent review route.
- The street-atlas layer, scoped review flow, and future combat lanes all agree on district names, road anchors, and capture viewpoints.
- Review builds include evidence packs that compare in-game results against source references.
- Every shipped scene drawable in the review build has a texture assignment backed by Canberra-sourced imagery stored and documented under `MilsimPonyGame/Assets/Textures/`.

## Workstream Division

### Engine/Core

- Own the C runtime, math library, transform system, scene objects, collision, streaming, and performance instrumentation.
- Deliver stable interfaces that Rendering/Platform and Gameplay/QA can build on without frequent rewrites.

### Rendering/Platform

- Own the Xcode project, SwiftUI shell, Metal view lifecycle, shader pipeline, camera submission, lighting, texture assignment, and render debugging.
- Keep macOS integration thin so the engine remains portable and the C core remains authoritative.

### World/Data

- Own Canberra reference gathering, coordinate conventions, terrain/road data preparation, Canberra texture sourcing, blockouts, landmark placement, and asset conversion.
- Deliver basin-wide Canberra readability first, then concentrate extra fidelity around travel lanes, major landmarks, sniper firing positions, and the texture library needed to cover every shipped drawable.

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
| `15` | Street atlas expansion reset | Stabilize scene-package support for denser district data, route metadata, and drawable texture metadata | Draw named road strips in the overhead map, retune atlas readability, and stabilize per-drawable texture assignment hooks | Expand the Canberra package with Civic, Barton-Russell, Woden Town Centre, Belconnen Town Centre, and supporting sectors, plus seed `MilsimPonyGame/Assets/Textures/` with Canberra-sourced street-atlas materials and provenance notes | Reframe the demo as a district-atlas survey and capture the first reference gallery | The game opens into a street-atlas review with more districts and visible named roads, and the first district texture set is checked into `MilsimPonyGame/Assets/Textures/` |
| `16` | Woden and inner-south district pass | Improve local streaming transitions, collision ownership for overlapping district sectors, and drawable texture residency rules | Tune map legibility, labels, and district readouts for denser road clusters while applying Woden and inner-south texture coverage to shipped drawables | Densify Woden, Deakin, State Circle, and west-basin roads, landmarks, and blockers, and add Canberra-sourced Woden and inner-south texture sets under `MilsimPonyGame/Assets/Textures/` | Add Woden and inner-south verification checkpoints plus smoke coverage | Woden and the inner south read as connected districts rather than isolated pads, and newly shipped drawables for this pass have Canberra-sourced textures |
| `17` | Civic-Barton-Russell pass | Add higher-confidence sector residency, route telemetry, and texture-coverage tracking for dense central districts | Improve water-edge, bridge, and arterial readability around the central basin while extending texture coverage across Civic, Barton, Russell, and east-basin drawables | Densify Civic, City Hill, Barton, Russell, Mount Ainslie, and east-basin roads and massing, and expand `MilsimPonyGame/Assets/Textures/` with Canberra source images and derived materials for the central districts | Add central-district review markers and update the source gallery with corrected captures | Central Canberra reads as a connected street network from the lake to the inner north and east, and the central-district drawable set is texture-complete |
| `18` | Belconnen and Black Mountain pass | Extend long-range culling, collision support, and texture streaming coverage across denser northern district targets | Improve skyline layering and atlas readability for Black Mountain and Belconnen while texturing northern-district landmarks, blockers, and supporting drawables | Densify Belconnen Town Centre, Bruce, Ginninderra approaches, and Black Mountain connectors, and add Canberra-sourced northern-district materials under `MilsimPonyGame/Assets/Textures/` | Add Belconnen district review flow and long-range validation metrics | Belconnen and Black Mountain read as distinct, navigable components of the atlas, and their shipped drawable set is texture-complete |
| `19` | Cross-district route integration | Tune streaming, restart, route logic, and texture-audit reporting for a longer multi-district survey | Polish route visibility, map-state feedback, screenshot-ready overlays, and close remaining texture-binding gaps across the full review route | Close remaining holes between Woden, Civic, the lake, Black Mountain, and Belconnen, and expand `MilsimPonyGame/Assets/Textures/` with any missing Canberra-derived materials needed for full route coverage | Build one review loop that samples every major district and atlas corridor | A single route proves the expanded Canberra atlas without developer explanation, and any remaining untextured drawables are reduced to a reviewed final punch list |
| `20` | Reference-backed review pack | Lock data interfaces for capture automation, comparison notes, regression review, and final drawable texture validation | Polish review overlays, capture framing, atlas presentation, and the final per-drawable texture pass for release candidates | Finalize the first reference-backed Canberra package with curated Google Maps, in-game gallery assets, and the complete Canberra texture library in `MilsimPonyGame/Assets/Textures/` | Ship a review pack, smoke test, and capture notes that connect atlas work to future combat lanes | Reviewers can compare the in-game Canberra atlas against source references and confirm that every shipped scene drawable has a Canberra-sourced texture assignment |
| `21` | Combat-lane rehearsal | Promote review-pack lane notes into live checkpoint metadata, threat overlays, and basin-scale observer pressure | Surface next-contact cues, threat rings, recovery lines, and rehearsal summaries directly in the HUD and overhead map | Reuse the full Woden-to-Belconnen atlas route as the first combat rehearsal with live observers, cover guidance, and checkpoint recovery notes | Ship a combat rehearsal brief, smoke test, and updated lane documentation | One route proves Canberra readability, observer pressure, and checkpoint recovery together without losing the atlas framing |

## Standard Cycle Cadence

- `Week 1`: lock Canberra references, extents, acceptance criteria, texture-source needs, and the exact Woden-to-Belconnen coverage gain required for the cycle.
- `Week 2`: integrate terrain, roads, landmarks, textures, streaming, and review viewpoints until the demo reads as Canberra without developer narration.
- `Week 3`: use only when needed for reference correction, new source-image intake under `MilsimPonyGame/Assets/Textures/`, world-data rebuilds, performance cleanup, and another review pass if the coverage gate is still not met.

For cycles `15` to `21`, use `Week 1` to lock Google Maps, official Canberra reference captures, Canberra texture-source needs, and the exact live lane cues needed for the current pass, `Week 2` to author and integrate the district or combat rehearsal pass plus update `MilsimPonyGame/Assets/Textures/`, and `Week 3` to capture gallery deltas, add any missing Canberra source images, and fix atlas, texture-coverage, or threat-overlay regressions.

## Recommended Sequencing Rules

- Do not start broad Canberra content production before the coordinate system, scale rules, and chunk format are stable.
- Treat the Parliament House district as the anchor slice; every later cycle should keep that slice runnable.
- Treat Lake Burley Griffin and basin ridgelines as the new world anchors for scale, orientation, and long-range validation.
- Keep the SwiftUI layer minimal and avoid moving engine logic out of the C core unless there is a strong platform reason.
- Do not prioritize another corridor-only cycle ahead of basin-scale readability from Woden to Belconnen.
- Do not close a cycle that fails to add clear Canberra-model progress or still leaves the demo opening from an unconvincing survey location.
- Do not ship the sniper rifle until the map supports stable distant observation and reliable long-range collision.
- Add fidelity in layers: basin coverage first, then higher resolution around travel lanes, landmarks, and sniper perches.
- Treat the online reference gallery as production data: every district pass should add or replace source captures when the target streets change.
- Require each cycle from `15` to `21` to improve both the atlas overlay and the in-world district pass.
- Treat `MilsimPonyGame/Assets/Textures/` as the canonical Canberra texture library: source captures, provenance notes, and derived outputs should live there rather than in ad hoc side directories.
- Do not close a cycle from `15` to `21` while shipped drawables added or revised in that pass still lack Canberra-sourced texture assignments.

## Near-Term Next Actions

1. Lock the street-atlas sector list and district naming for Civic, Barton-Russell, Woden, Belconnen, Mount Ainslie, and the west basin.
2. Capture baseline Google Maps and official ACT transport references for each district and keep them in a reviewable gallery.
3. Densify the road network so the overhead map shows a convincing Canberra street structure rather than only coarse traversal lanes.
4. Keep the Woden-to-Belconnen route stable while tuning live observer placement, cover cues, and checkpoint recovery for the first combat rehearsal.
5. Audit every current scene drawable that still falls back to flat-color treatment and map it to a Canberra texture task.
6. Expand `MilsimPonyGame/Assets/Textures/Origin/` and `MilsimPonyGame/Assets/Textures/Final/` with additional Canberra source images and derived materials until the rehearsal build has no untextured shipped drawables.
