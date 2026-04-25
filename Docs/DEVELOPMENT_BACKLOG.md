# Development Backlog

This document extends the shipped roadmap beyond Cycle 21 and absorbs the external review captured in [REVIEW.md](../REVIEW.md) on April 23, 2026.

## Current Baseline

The active development line is now past Cycle 78. `REVIEW.md` was generated at Cycle 21, so it is no longer accurate as a raw missing-work list. Several items have landed, several were only partially addressed, and a number were planned but not implemented because cycles 58 through 78 shifted toward review persistence and guarded restore-state reporting.

This backlog is reengineered from the Cycle 78 state. The next twenty cycles, `79` through `98`, prioritize REVIEW items that are only partially complete or not yet started. Completed items remain acknowledged, but they no longer occupy primary schedule space unless they need closeout work.

## Planning Rules

- Every cycle must keep Canberra readability intact. A system cycle still needs a visible validation line, smoke test, or authored scene proof.
- Finish partial REVIEW items before opening more speculative renderer architecture.
- Prefer playable combat and authoring leverage over more restore-reporting work.
- Treat "partly taken care of" as unfinished unless the player can use it in the live route, the map/HUD can verify it, and a smoke test can regress it.
- Keep large renderer modernizations behind evidence. If profiling does not prove a bottleneck, do not pull GPU-driven rendering or render-graph work ahead of gameplay-critical gaps.
- Do not enable automatic checkpoint restore until the restore-review safety work has a clear manual execution design and smoke coverage.

## Cycle 78 Review Status

### Already Substantially Covered

| Review Item | Current Evidence | Follow-Up |
| --- | --- | --- |
| Ballistics solver | `GameCore` exposes ballistic prediction, drop, flight time, observer hits, shot feedback, and `GameCoreRequestFire`. | Keep tuning, but no longer a top backlog blocker. |
| Difficulty tuning knobs | Difficulty presets and observer/suspicion scaling are surfaced through the app shell and telemetry. | Tune with group AI once behavior expands. |
| Objective and mission scripting layer | Cycle 30 added data-driven mission phases and checkpoint hook reporting. | Expand after more routes exist. |
| SSAO / screen-space surface depth | Cycle 54 and renderer post-process path include depth contact darkening and SSAO controls. | Tune during visual closeout. |
| Procedural wind and foliage motion | Cycles 52-57 added scene-authored wind, vegetation response, and surface-fidelity reporting. | Extend into traversal and concealment behavior. |

### Partially Covered And Now Pulled Forward

| Review Item | Gap To Close | Priority Window |
| --- | --- | --- |
| Audio system | Weapon and observer alert cues exist, but footsteps, ambient bed, scoped feedback, and mix state are incomplete. | `79`, `84`, `92` |
| Firing feedback loop | Shot/impact/hit confirmation exists, but muzzle flash, recoil animation, miss readability, and crack-thump presentation need player-facing polish. | `79`, `80` |
| Group NPC behavior | Paired observer relay exists, but patrol pairs, formation movement, and scan-halt-resume behavior are not complete. | `81`, `82`, `83` |
| Black Mountain and West Basin texture coverage | Districts exist and material breakup exists, but district-specific sourcing and atlas closeout are incomplete. | `87`, `88` |
| Multiple rehearsal routes | Alternate route metadata, preview, and gates exist, but the route is not live-playable. | `85`, `86`, `89` |
| Sniper scope optics refinement | 4x scope and stability exist, but mil calibration, parallax cues, lens dirt, and edge aberration remain. | `80`, `93` |
| Collision volume authoring tools | Cycle 51 reports authoring readiness, but no visual preview or editing helper exists. | `90` |
| Save/resume session state | Review persistence and guarded restore reporting exist, but actual manual restore remains disabled. | `91`, `92` |
| Performance profiling pass | Runtime telemetry exists, but formal Metal/GPU/CPU baselines are not documented. | `79`, `94` |
| Vegetation interaction | Wind motion exists, but concealment, movement friction, and traversal feedback are missing. | `88`, `93` |
| Water system | Water material and motion exist, but reflections, stronger shoreline read, and caustic/specular polish remain. | `88`, `95` |
| NPC line-of-sight debug overlay | Threat cones and LOS telemetry exist, but a dedicated design overlay/debug mode is not complete. | `82` |
| Minimap accuracy pass | Map is rich, but it still needs a formal geometry/marker/threat accuracy closeout as route count expands. | `86`, `89` |
| Packaging and distribution | Cycle 9 packaging exists, but notarization, CI, versioning policy, and tester delivery are incomplete. | `96`, `97` |
| Cascaded shadow maps | A real single shadow-map pass exists, but multi-cascade CSM is not complete. | `94` |

### Not Yet Started Or Deferred Into The Next Twenty Cycles

| Review Item | Reason To Pull Forward | Priority Window |
| --- | --- | --- |
| LOD system for distant buildings | Scope readability and performance need HLOD/impostors before more route breadth. | `94`, `95` |
| Time-of-day system | Scenario variety needs a controlled day-phase path, but only after combat routes become playable. | `98` |
| Clustered deferred / Forward+ lighting | Needed for muzzle flash, night lighting, and future dynamic sources, but not before route and profiling closeouts. | `98+` |
| Temporal anti-aliasing | Still risky for scope ghosting. Try only after LOD/impostor stability. | `95+` |
| Physically based atmosphere and sky | Pair with time-of-day work once the lighting path is ready. | `98+` |
| GPU-driven indirect rendering | Depends on a proven CPU draw-call bottleneck. | `98+` |
| SDF font and UI rendering | Useful for polish, but lower priority than gameplay and route tooling. | `97+` |
| Screen-space reflections with IBL fallback | Valuable for water/glass, but comes after water polish and profiling. | `95+` |
| Render graph / frame graph | Useful only after pass count and release architecture justify it. | `98+` |

## Next Twenty Cycle Plan

The following schedule starts from the current Cycle 78 state.

| Cycle | Primary Goal | REVIEW Items Closed Or Advanced | Exit Gate |
| --- | --- | --- | --- |
| `79` | Weapon Feel And Profiling Reset | Firing feedback loop, audio system, performance profiling | Formal CPU/GPU/frame baseline is documented; shot loop has visible recoil state, muzzle feedback placeholder, and clearer miss/hit telemetry. |
| `80` | Scoped Rifle Presentation | Firing feedback loop, sniper scope optics refinement | Scope reticle, stability, recoil recovery, crack-thump timing, and hit/miss status read clearly during live firing. |
| `81` | Patrol Pair Foundation | Group NPC behavior | Observers can be authored as patrol pairs with shared route state and formation spacing, even if scan behavior remains basic. |
| `82` | LOS Debug And Scan States | Group NPC behavior, NPC LOS debug overlay | A debug overlay or mode visualizes observer LOS state, scan arcs, blocked samples, and relay state for route authors. |
| `83` | Scan-Halt-Resume Behavior | Group NPC behavior | Patrol observers can halt, scan, resume, and hand off alert state without breaking checkpoint recovery. |
| `84` | World And Movement Audio Bed | Audio system | Footsteps, scope toggle, ambient basin bed, and alert mix states are audible and smoke-tested. |
| `85` | Alternate Route Live Binding First Pass | Multiple rehearsal routes | The staged alternate route can become the active checkpoint sequence at a guarded briefing/restart boundary. |
| `86` | Route Breadth And Map Accuracy | Multiple rehearsal routes, minimap accuracy pass | Active-route switching, checkpoint markers, threat rings, and route footer data agree for both primary and alternate routes. |
| `87` | Black Mountain Texture Closeout | Black Mountain texture coverage | Black Mountain/Telstra/Bruce surfaces use district-specific source-backed material assignments and capture notes. |
| `88` | West Basin, Vegetation, And Water Closeout | West Basin texture coverage, vegetation interaction, water system | West Basin materials, shoreline motion, vegetation response, and water readability pass a route smoke test. |
| `89` | Third Rehearsal Route Authoring | Multiple rehearsal routes, minimap accuracy pass | A third route exists as authored data with map preview, threat geometry, and readiness metadata. |
| `90` | Collision Authoring Preview Tool | Collision volume authoring tools | Collision volumes and blocker inventories can be visually inspected in-app or through a repeatable local tool. |
| `91` | Manual Restore Execution Design | Save/resume session state | Manual restore has a concrete UI/logic contract, safety checks, and smoke-test plan; execution remains disabled until the contract passes. |
| `92` | Manual Restore Execution And Session Audio Polish | Save/resume session state, audio system | A guarded manual restore can resume to a checkpoint only when identity, freshness, target, and user intent checks pass. |
| `93` | Scope Optics And Concealment Polish | Sniper scope optics refinement, vegetation interaction | Scope calibration cues and vegetation concealment/traversal feedback are visible enough to support route tuning. |
| `94` | CSM And Formal Renderer Profile | Cascaded shadow maps, performance profiling | Multi-cascade shadow prototype or scoped CSM plan lands with profiling proof and before/after capture notes. |
| `95` | Distant LOD And Water Reflection Probe | LOD system, water system, SSR groundwork | Key distant landmarks gain LOD/impostor metadata; water/glass reflection approach is prototyped or explicitly deferred with evidence. |
| `96` | Packaging Automation | Packaging and distribution | Release packaging has version policy, manifest validation, archive naming, and repeatable smoke packaging. |
| `97` | Tester Distribution Pipeline | Packaging and distribution, SDF UI planning | Notarization/CI/tester delivery plan is implemented or scripted; UI crispness/SDF migration is scoped for later polish. |
| `98` | Time-Of-Day And Lighting Architecture Decision | Time-of-day, atmosphere, clustered lighting, render graph | A minimal time-of-day scenario path lands or the lighting/render-graph modernization plan is locked with measured prerequisites. |

## REVIEW Item Placement After Reengineering

### Top 20 Gameplay, World, And Tooling Items

| ID | Review Item | Cycle Placement | Status Target |
| --- | --- | --- | --- |
| `1` | Ballistics solver | Historical `22-27`; maintenance in `79-80` | Done, then tuned through weapon-feel cycles. |
| `2` | Audio system | `79`, `84`, `92` | Complete practical combat audio bed. |
| `3` | Firing feedback loop | `79-80` | Complete first player-facing rifle feedback loop. |
| `4` | Group NPC behavior | `81-83` | Complete patrol pair and scan-halt-resume baseline. |
| `5` | Black Mountain and West Basin texture coverage | `87-88` | Complete district-specific material/source closeout for those route districts. |
| `6` | Automated capture pipeline | `96-97` if packaging blocks are light; otherwise `99+` | Pull in after routes/tools stabilize. |
| `7` | Multiple rehearsal routes | `85-86`, `89` | Make alternate route live, then add third authored route. |
| `8` | LOD system for distant buildings | `95` | Add first landmark LOD/impostor implementation. |
| `9` | Difficulty tuning knobs | Historical `26-29`; tuning in `81-83` | Done, then retuned against richer AI. |
| `10` | Sniper scope optics refinement | `80`, `93` | Complete practical optic usability pass. |
| `11` | Time-of-day system | `98` | Minimal scenario path or locked implementation plan. |
| `12` | Collision volume authoring tools | `90` | Visual inspection or repeatable local preview. |
| `13` | Save/resume session state | `91-92` | Guarded manual checkpoint restore enabled. |
| `14` | Performance profiling pass | `79`, `94` | Documented baseline and renderer before/after profile. |
| `15` | Vegetation interaction | `88`, `93` | Motion plus gameplay-relevant concealment/traversal feedback. |
| `16` | Water system | `88`, `95` | Motion/material closeout, then reflection probe. |
| `17` | NPC LOS debug overlay | `82` | Dedicated route-authoring LOS debug view. |
| `18` | Objective and mission scripting layer | Historical `30`; expansion after `89` | Lightweight hooks done; richer scripting follows route breadth. |
| `19` | Minimap accuracy pass | `86`, `89` | Formal accuracy closeout across active routes. |
| `20` | Packaging and distribution | `96-97` | Move from release script to tester-ready pipeline. |

### Top 10 Graphics Engine Modernizations

| ID | Review Item | Cycle Placement | Status Target |
| --- | --- | --- | --- |
| `G1` | Clustered deferred / Forward+ lighting | `98+` | Do not start until dynamic-source needs are proven. |
| `G2` | SSAO or HBAO | Historical `54-57`; tune in `94-95` | Done as screen-space surface depth; tune with renderer profiling. |
| `G3` | Temporal anti-aliasing | `95+` | Conditional after LOD/impostor work. |
| `G4` | Physically based atmosphere and sky | `98+` | Pair with time-of-day architecture. |
| `G5` | GPU-driven indirect rendering | `98+` | Requires profiling evidence. |
| `G6` | Cascaded shadow maps | `94` | Finish or formally scope multi-cascade shadow path. |
| `G7` | SDF font and UI rendering | `97+` | Plan during tester pipeline/UI polish. |
| `G8` | SSR with IBL fallback | `95+` | Prototype after water closeout. |
| `G9` | Procedural wind and foliage animation | Historical `52-54`; gameplay extension in `88`, `93` | Motion done; interaction still pending. |
| `G10` | Render graph / frame graph architecture | `98+` | Architecture decision after pass-count/profile review. |

## Immediate Next Five Cycles

1. `79`: weapon feel and profiling reset.
2. `80`: scoped rifle presentation and practical optic feedback.
3. `81`: patrol pair foundation.
4. `82`: LOS debug overlay and observer scan-state visualization.
5. `83`: scan-halt-resume observer behavior.

These five cycles deliberately avoid more persistence-only work. They return the project to the REVIEW.md gaps that most directly affect playable combat rehearsal.
