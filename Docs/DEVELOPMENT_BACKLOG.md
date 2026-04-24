# Development Backlog

This document extends the shipped roadmap beyond Cycle 21 and absorbs the external review captured in `REVIEW.md` on April 23, 2026.

The intent is not to replace the existing plan in [ROADMAP.md](../ROADMAP.md). It is to continue it from the current combat-rehearsal build and turn the reviewer feedback into a real backlog that can survive after `REVIEW.md` is removed.

This backlog assumes the project now has at least `60` additional cycles of work, covering cycles `22` to `81`.

## Planning Rules

- Canberra readability still has to ship every cycle. No backlog item is worth a renderer rewrite if the basin gets less legible.
- Combat credibility now takes priority over atlas-only expansion. The project is past pure review-pack validation.
- Review items that directly unlock the core premise move first:
  - ballistics
  - firing feedback
  - audio
  - observer behavior
  - route breadth
  - scope-grade rendering stability
- Renderer modernization is scheduled in layers:
  - first the pieces that directly help long-range combat and review readability
  - then the expensive architectural work once the pass count justifies it
- Existing renderer plans are not duplicated. They are merged into this backlog with updated cycle placement.

## Reprioritization Summary

The external review is directionally right, but not every suggestion should jump to the front.

### Pulled Forward

- `Ballistics solver`
- `Audio system`
- `Firing feedback loop`
- `Group NPC behavior`
- `Multiple rehearsal routes`
- `Difficulty tuning knobs`
- `Performance profiling pass`
- `NPC line-of-sight debug overlay`
- `Objective and mission scripting layer`
- `Minimap accuracy pass`
- `Cascaded shadow maps`
- `LOD, HLOD, impostors, and anti-aliasing stability`

These are now treated as project-defining rather than optional polish.

### Kept Mid-Band

- `Black Mountain and West Basin texture coverage`
- `Automated capture pipeline`
- `Collision volume authoring tools`
- `Save and resume session state`
- `Vegetation interaction`
- `Water system`
- `SSAO`
- `SDF UI`

These matter, but they are best delivered after the combat loop and scope readability become trustworthy.

### Intentionally Deferred

- `Clustered deferred lighting`
- `GPU-driven indirect rendering`
- `SSR with IBL fallback`
- `Physically-based atmosphere`
- `Render graph`
- `Packaging and distribution`

These are important, but they pay off most once the gameplay slice is deeper, the content set is broader, and the renderer has enough passes to justify more architecture.

## Existing Roadmap Integration

The current repo already has a live rendering plan in [RENDERING_ROADMAP.md](./RENDERING_ROADMAP.md). The review does not replace it. The merged schedule is:

- `Single shadow map groundwork`: already landed.
- `Cascaded shadows`: cycles `22` to `26`.
- `Material plumbing`: already landed for the base object path.
- `District-specific texture completion and material variety`: cycles `34` to `39`.
- `SMAA plus HLOD and impostors`: cycles `40` to `43`.
- `Optional TAA`: cycles `44` to `46`, only if scope ghosting is acceptable.
- `Decals and landmark-specific breakup`: cycles `54` to `57`.
- `HDR post and grading`: already landed, then tuned incrementally whenever district lighting changes.

This keeps the existing renderer plan intact while aligning it with the reviewer's modernization list.

## Post-Cycle-21 Milestones

| Cycles | Phase | Primary Outcomes | Main Lanes |
| --- | --- | --- | --- |
| `22` to `27` | Combat Foundations And Visual Legibility | Ballistics, firing feedback foundation, audio foundation, cascaded shadows, profiling baseline, LOS and minimap debug | Engine/Core, Rendering/Platform, Gameplay/QA |
| `28` to `33` | AI Pressure And Scenario Hooks | Group NPC behavior, mission scripting, difficulty authoring, scope optics refinement, route authoring framework | Engine/Core, Gameplay/QA, World/Data |
| `34` to `39` | Route Breadth And District Completion | More rehearsal routes, Black Mountain and West Basin texture completion, district-specific materials, minimap accuracy closeout | World/Data, Rendering/Platform, Gameplay/QA |
| `40` to `45` | Scope-Grade Renderer Stability | LOD chains, HLOD and impostors, SMAA, conditional TAA, long-range profiling, shadow polish | Rendering/Platform, Engine/Core |
| `46` to `51` | Authoring And QA Toolchain | Automated capture, collision authoring tools, scenario tuning helpers, debug overlays that make content production faster | Tools, World/Data, Gameplay/QA |
| `52` to `57` | Environmental Motion And Surface Depth | Vegetation response, procedural wind, water animation, SSAO, decals, material breakup | Rendering/Platform, World/Data |
| `58` to `63` | Session And UX Hardening | Save and resume, SDF UI, review persistence, capture packaging, data-quality guardrails | Gameplay/QA, Rendering/Platform, Tools |
| `64` to `69` | Throughput And Lighting Modernization | GPU-driven indirect rendering, clustered lighting, deeper profiling, SSR groundwork | Rendering/Platform, Engine/Core |
| `70` to `75` | Time, Atmosphere, And Dynamic Scenario Lighting | Time of day, physically-based sky, night lighting path, reflected water and glass read | Rendering/Platform, World/Data |
| `76` to `81` | Release Architecture And Distribution | Render graph hardening, CI and notarization, packaging, tester pipeline, release QA | Tools, Rendering/Platform, Gameplay/QA |

## Review Item Placement

### Top 20 Gameplay, World, And Tooling Items

| ID | Review Item | Priority | Cycle Placement | Why It Lands There |
| --- | --- | --- | --- | --- |
| `1` | Ballistics solver | `P1` | `22` to `27` | It is the missing system most directly tied to the sniper premise. It must arrive before broader combat content multiplies around it. |
| `2` | Audio system | `P1` | `23` to `29` | The demo is still too silent to sell combat rehearsal. Start the audio foundation immediately after ballistics work begins, then expand it across weapon, world, and alert states. |
| `3` | Firing feedback loop | `P1` | `23` to `26` | This belongs beside ballistics and early audio so the rifle becomes legible as a weapon rather than a debug tool. |
| `4` | Group NPC behavior | `P1` | `28` to `33` | Solo watchers are enough for the first lane, but route depth depends on pairs, scan-halt-resume behavior, and more believable observer pressure. |
| `5` | Black Mountain and West Basin texture coverage | `P2` | `34` to `37` | This is content-critical, but it should follow the combat foundation and second-route work so the texture pass lands on the right route set. |
| `6` | Automated capture pipeline | `P2` | `46` to `49`, then `58` to `60` | First make it usable for QA, then productionize it once save state and review persistence exist. |
| `7` | Multiple rehearsal routes | `P1` | `31` to `39` | More routes matter more than late-engine niceties because they prove the game is a rehearsal platform rather than a one-route showcase. |
| `8` | LOD system for distant buildings | `P1` | `40` to `44` | This is one of the highest-value scope-readability tasks and should be scheduled with HLOD and impostors, not as an isolated optimization. |
| `9` | Difficulty tuning knobs | `P1` | `26` to `29` | These become useful as soon as observer behavior grows beyond placeholders. They should ship before route count expands. |
| `10` | Sniper scope optics refinement | `P2` | `24` to `30` | The optic needs better usability early, but the base weapon and hit logic still come first. |
| `11` | Time-of-day system | `P3` | `70` to `75` | It is valuable, but it depends on a more mature atmosphere, lighting, and content set to avoid multiplying unfinished looks. |
| `12` | Collision volume authoring tools | `P2` | `48` to `51` | Tooling should arrive once route authoring expands and collision edits start to dominate content cost. |
| `13` | Save and resume session state | `P2` | `58` to `62` | This matters for longer rehearsals, but only after multi-route and session review become normal use cases. |
| `14` | Performance profiling pass | `P1` | `22` to `23`, `40` to `41`, `64` to `65` | This is not one task. It should be treated as three formal baselines: combat foundation, scope renderer, and throughput modernization. |
| `15` | Vegetation interaction | `P2` | `52` to `55` | It belongs with the environmental-motion phase, after the combat core and route structure are more stable. |
| `16` | Water system | `P2` | `52` to `56`, then `68` to `72` | Start with believable lake motion and material read, then revisit it when reflections are worth the extra pass count. |
| `17` | NPC line-of-sight debug overlay | `P1` | `25` to `27` | This is a high-priority design tool because observer pressure becomes harder to tune once group behavior and more routes arrive. |
| `18` | Objective and mission scripting layer | `P1` | `30` to `35` | Route count and combat depth both need richer mission primitives before they scale cleanly. |
| `19` | Minimap accuracy pass | `P1` | `26` to `30`, then `34` to `36` | First establish correctness for the current rehearsal flow, then revalidate during district and route expansion. |
| `20` | Packaging and distribution | `P3` | `76` to `81` | Real release automation matters, but it should land after the game loop and test pipeline are worth distributing widely. |

### Top 10 Graphics Engine Modernizations

| ID | Review Item | Priority | Cycle Placement | Why It Lands There |
| --- | --- | --- | --- | --- |
| `G1` | Clustered deferred lighting | `P3` | `66` to `70` | Dynamic multi-light scenarios are not the current blocker. Bring this in once muzzle flash, night lighting, and extra dynamic sources actually need it. |
| `G2` | SSAO or HBAO | `P2` | `54` to `57` | This pays off after materials, decals, and district breakup are real enough to benefit from contact shadowing. |
| `G3` | Temporal anti-aliasing | `P2` | `44` to `46` | Keep it behind `SMAA plus HLOD`. This repo's scope path is especially sensitive to ghosting, so TAA stays conditional. |
| `G4` | Physically-based atmosphere and sky | `P3` | `70` to `74` | Pair it with time of day so the work serves a larger lighting and scenario expansion instead of replacing one temporary sky model with another. |
| `G5` | GPU-driven indirect rendering | `P3` | `64` to `68` | It is a throughput and architecture play. Save it for the point where CPU draw overhead is the proven bottleneck. |
| `G6` | Cascaded shadow maps | `P1` | `22` to `26` | This is the modernization with the clearest immediate gameplay payoff for scope readability and close-range grounding. |
| `G7` | Signed-distance field font and UI rendering | `P2` | `60` to `63` | This is best timed with session and review UX hardening, once the UI set is stable enough to justify replacement. |
| `G8` | Screen-space reflections with IBL fallback | `P3` | `68` to `72` | It is attractive for the lake and glass, but it should follow a better water base and a more mature lighting model. |
| `G9` | Procedural wind and foliage animation | `P2` | `52` to `54` | This fits naturally with vegetation interaction and adds life without delaying combat-foundation work. |
| `G10` | Render graph or frame graph architecture | `P3` | `74` to `81` | This is worth doing only once the renderer actually carries enough passes to benefit from formal graph management. |

## Existing Backlog Items Continued Alongside The Review

These are already active repo threads and remain in the backlog even though they were not new in `REVIEW.md`.

| Existing Thread | Cycle Placement | Notes |
| --- | --- | --- |
| `Cascaded shadow follow-through from the current single-map pass` | `22` to `26` | Directly merged with review item `G6`. |
| `District-specific material coverage beyond shared Canberra sets` | `34` to `39` | This is where the current material plumbing becomes content-complete rather than system-complete. |
| `SMAA plus HLOD and impostors` | `40` to `43` | This remains the repo-preferred prerequisite before any TAA work. |
| `Optional TAA` | `44` to `46` | Only continue if scope ghosting stays acceptable in live builds. |
| `Decals and landmark-specific material breakup` | `54` to `57` | Merged with SSAO, vegetation, and water to form the environmental-fidelity block. |
| `Capture-friendly review pack evolution` | `46` to `60` | Capture automation and review persistence become a real production toolchain here. |

## Strategic Notes Per Phase

### Cycles 22 To 27

These cycles should feel unapologetically practical. The main goal is to stop the rifle, the observer pressure, and the scoped render path from feeling like separate prototypes.

- Build the ballistic query stack before adding more routes.
- Add the first real audio bed and the basic weapon feedback loop while the combat interaction surface is still small.
- Pull cascaded shadows forward now because they improve both visual grounding and sight-picture trust.
- Establish the first formal profiling and debug baselines early, not as cleanup.

### Cycles 28 To 33

This is where the game stops being a scripted single-lane proof and starts behaving like a reusable rehearsal system.

- Group NPC behavior, mission scripting, and difficulty tuning should land together.
- Scope optics refinement should keep pace so the sniper loop does not become mechanically correct but ergonomically weak.
- Route-authoring support has to start here so the next content phase does not bottleneck on one scenario format.

### Cycles 34 To 39

This is the first heavily content-weighted block after the combat core.

- Finish texture coverage and material variety in the districts that still feel under-sourced.
- Add at least two more rehearsal routes with distinct threat geometry.
- Keep the minimap honest while route and district density grows.

### Cycles 40 To 45

This block is about long-range trust.

- HLOD, impostors, and LOD chains do more for this project than flashy late-stage lighting work.
- Use `SMAA` first.
- Treat `TAA` as earned, not assumed.

### Cycles 46 To 51

These cycles make the rest of the roadmap cheaper.

- Capture automation, collision authoring helpers, and debug overlays are multiplicative investments.
- This is the right point to stop relying on manual review rituals and start building repeatable authoring tools.

### Cycles 52 To 57

This is the visual-depth block.

- Environmental motion should arrive together with surface-depth work so the world feels more alive, not just more post-processed.
- Water, vegetation, decals, and SSAO all help the Canberra basin feel less diagrammatic.

### Cycles 58 To 63

These cycles make longer sessions and broader review possible.

- Save and resume becomes more valuable once there are more routes, more scripting, and more QA capture states.
- UI crispness and review packaging belong here because the interaction vocabulary will finally be stable enough to harden.

### Cycles 64 To 69

This is the first renderer-architecture block that should be allowed to get ambitious.

- Do not pull GPU-driven rendering or clustered lighting earlier unless profiling proves they are the actual bottleneck.
- This block exists to scale the growing world and scenario count, not to chase novelty.

### Cycles 70 To 75

This is where the game can start varying light and time without collapsing readability.

- Time of day should be paired with a real atmosphere model and scenario-lighting support.
- Do not attempt night routes or more dynamic light sources until this block is staffed.

### Cycles 76 To 81

This is the release and sustainment phase.

- Distribution, CI, notarization, and render-graph cleanup matter most when the project is finally broad enough to share repeatedly.
- This block should turn the project from a review-driven prototype into a maintained external-test build.

## Immediate Backlog For The Next Ten Cycles

If work starts from the current Cycle 21 state, the next ten cycles should emphasize:

1. `22`: ballistic query groundwork, profiling baseline, cascade design lock.
2. `23`: first firing feedback slice, first audio slice, first cascade pass.
3. `24`: scoped hit confirmation, optics refinement start, shadow and grading tuning.
4. `25`: LOS debug overlay, alert audio, weapon feel pass.
5. `26`: difficulty knobs, minimap validation pass, cascade stabilization.
6. `27`: ballistics closeout for first combat-ready rifle build.
7. `28`: group NPC behavior phase one.
8. `29`: audio expansion and observer-state feedback polish.
9. `30`: mission scripting hooks and checkpoint trigger expansion.
10. `31`: second rehearsal route authoring start.
11. `32`: alternate-route preview path in the overhead map before live route selection.
12. `33`: alternate-route selection readiness metadata before checkpoint ownership is split.
13. `34`: alternate-route checkpoint ownership split before the live route loader can switch routes.
14. `35`: active-route loader staging before the alternate route can become the bound playable route.
15. `36`: staged alternate-route metrics before loader binding can validate route length and footprint.
16. `37`: alternate-route binding gate validation before the live route loader can switch the playable route.
17. `38`: alternate-route handoff planning before the loader can safely swap checkpoint order.

Those cycles bring the most reviewer-critical missing systems online without abandoning the existing Canberra and rendering work already underway.
