# Development Backlog

This document extends the shipped roadmap beyond Cycle 116 and re-prioritizes the external review captured in [REVIEW.md](../REVIEW.md) on April 23, 2026.

## Current Baseline

The active development line is Cycle 116. The previous backlog treated several REVIEW items as effectively complete because they had metadata, HUD readouts, preview states, or architecture decisions. That was too generous.

The corrected rule is simple: **if a REVIEW item is not implemented as usable player/developer functionality, it is not done.** If it is only implemented as telemetry, metadata, a deferred decision, or a partial prototype, it must be pulled into the next 30 cycles.

## Priority Rules

- **Top priority, Cycles 99-108:** any REVIEW item that is not done yet.
- **Next priority, Cycles 109-118:** any REVIEW item that is only partly done.
- **Secondary overdue priority, Cycles 119-128:** anything that had an earlier allocation but is still incomplete, plus hardening and verification for the prior two bands.
- A task is complete only when it is usable in the build, has visible verification or tooling, and has smoke-test coverage.
- Architecture decisions, placeholder telemetry, metadata-only records, and preview-only routes/tools do not close a REVIEW item.

## Honest Review Recovery Status After Cycle 116

### Done Enough For Regression Only

| Review Item | Evidence | Follow-Up |
| --- | --- | --- |
| Ballistics solver | `GameCore` exposes ballistic prediction, drop, flight time, observer hits, and fire feedback. | Keep in regression coverage. |
| Automated capture pipeline | Cycle 99 adds `Tools/capture_review.sh` for title/live/map/scope/pause screenshots and `Tools/image_diff.swift` for optional baseline diffs. | Keep in release/package validation and expand later if district-specific capture framing needs more automation. |
| LOD system for distant buildings | Cycle 100 adds renderer-side LOD roles, switch thresholds, and 6-vertex impostor cards for configured landmark grayboxes. | Keep in scope/capture regression and expand with authored low meshes in later renderer work if needed. |
| Time-of-day system | Cycle 101 adds scenario-authored time controls that drive renderer sun angle, sky/fog color, haze, ambient/diffuse light, shadow strength, and shadow coverage. | Keep in smoke/capture regression. |
| Clustered deferred / Forward+ lighting | Cycle 102 adds scene-authored diagnostic dynamic lights, CPU-side drawable light selection, and forward shader accumulation for up to four local point lights. | Expand from bounded forward light lists to a fuller clustered light grid when dynamic light counts grow. |
| Temporal anti-aliasing / scoped-safe AA | Cycle 103 adds depth-aware postprocess edge anti-aliasing with cross-depth rejection for scoped skyline stability. | Keep in scope/capture regression; full temporal reprojection remains optional if shimmer persists. |
| Physically based atmosphere and sky | Cycle 104 adds scene-authored Rayleigh/Mie/ozone atmosphere controls tied to the active time-of-day sun, feeding clear color, object fog, terrain haze, and HUD evidence. | Keep in smoke/capture regression; full volumetric sky/cloud work remains a later renderer gate. |
| GPU-driven indirect rendering | Cycle 105 adds a fallback-safe per-frame `MTLIndirectCommandBuffer` path for shadow-casting object draws. | Expand to material-pass indirect draws and GPU culling only after capture/profiling proves the next useful target. |
| SDF font and UI rendering | Cycle 106 adds a reusable SDF-style outlined scalable text path for mission overlay, scope labels, map sector labels, road labels, and the north marker. | Replace with a generated MSDF atlas later only if custom font atlas generation becomes necessary. |
| Screen-space reflections with IBL fallback | Cycle 107 adds bounded postprocess SSR samples with sky-probe fallback controls for lake/glass readability. | Expand to material-masked SSR, richer reflection probes, and render-graph-managed resources after material ID or graph support lands. |
| Render graph / frame graph architecture | Cycle 108 adds a declarative frame graph scaffold for the current shadow, scene, and presentation passes with imported/transient resources and dependency validation. | Expand to resource aliasing and fuller graph scheduling as CSM, SSAO, capture, water, and volumetric passes become real nodes. |
| Audio system | Cycle 109 promotes procedural cues into a scene-authored category mix with separate ambience, movement, scope, weapon, and observer gains, a persisted master-volume setting, richer footstep/threat ambience variants, and smoke-test readouts. | Replace procedural/generated cue sources with authored assets later if asset production becomes the limiting factor. |
| Firing feedback loop | Cycle 110 adds visible scoped muzzle flash, recoil kick/recovery animation, and `Shot Feedback:` classification for hits, blockers, ground impacts, and clear misses. | Expand with weapon model animation and richer impact VFX when first-person weapon art is introduced. |
| Group NPC behavior | Cycle 111 turns authored paired-observer metadata into runtime formation patrol movement, live overhead-map positions, alert halt/resume behavior, and smoke-testable `Patrol Pairs:` moving/sweep readouts. | Expand with richer tactics once route variety and mission scripting create better encounter contexts. |
| Black Mountain and West Basin texture coverage | Cycle 112 extends source-backed dry-grass, asphalt, concrete, water, and facade material assignments across West Basin/Yarralumla, Black Mountain/Bruce, Belconnen, and the playable scope perch, with acceptance docs. | Future texture work should add new district-specific bitmap sources only when a route or district expands beyond the shared Canberra texture library. |
| Multiple rehearsal routes | Cycle 113 turns the route selector into a fresh-run route picker for the primary route and both authored alternate routes, with restart-stable active-route binding and map/checkpoint rebinding. | Cycle 123 must still formally verify minimap accuracy across all playable routes. |
| Sniper scope optics refinement | Cycle 114 adds visible lens dirt, chromatic edge aberration rings, calibrated mil-dot spacing labels, parallax compensation reporting, and scope-mode smoke coverage. | Keep in scope capture regression as route and rendering systems change. |
| Collision volume authoring tools | Cycle 115 turns the overhead collision preview into a briefing workflow with selectable blockers, highlighted footprints, dimension/sector/clearance validation, and source-ID export guidance for JSON edits. | Keep in map-authoring regression and expand into direct editing only if the JSON authoring flow becomes a bottleneck. |
| Save/resume session state | Cycle 116 turns persisted review cards into route-bound saved-run resume with explicit title UX, guarded checkpoint restore, and checkpoint performance readouts. | Keep in regression as route binding, difficulty, and mission scripting expand. |
| Difficulty tuning knobs | Difficulty presets scale observer suspicion, decay, fail threshold, and weapon cycle. | Re-test after richer group AI and multi-route work in Cycle 119. |

### Top Priority Completion Note

All REVIEW items classified as not done at the start of the recovery pass have now received Cycle `99`-`108` implementation coverage. Remaining work moves through the partly-done and overdue closeout bands below.

### Partly Done: Next Priority In Cycles 109-118

| Review Item | Remaining Gap | New Cycle |
| --- | --- | --- |
| Performance profiling pass | Runtime counters exist, but formal Metal GPU capture and bottleneck artifacts are missing. | `117` |
| Vegetation interaction | Wind/response exists, but traversal friction, occlusion feedback, and concealment mechanics need closeout. | `118` |

### Overdue Or Partial: Secondary Priority In Cycles 119-128

| Review Item | Remaining Gap | New Cycle |
| --- | --- | --- |
| Difficulty tuning knobs | Retune and regress against richer group AI and multiple playable routes. | `119` |
| Water system | Water motion/materials exist, but reflection/caustic/specular closeout remains. | `120` |
| NPC line-of-sight debug overlay | HUD telemetry exists, but a real route-author overlay/debug mode needs closeout. | `121` |
| Objective/mission scripting layer | Checkpoint hooks exist, but conditional triggers, timed windows, fail conditions, and alternates remain. | `122` |
| Minimap accuracy pass | Current route checks exist, but all playable routes need formal geometry/threat/sector verification. | `123` |
| Packaging and distribution | Packaging scripts exist, but notarization, CI/build automation, and tester flow remain incomplete. | `124` |
| SSAO or HBAO | Contact darkening exists, but a proper SSAO/HBAO-class pass or equivalent closeout remains. | `125` |
| Cascaded shadow maps | Readiness metadata exists, but actual multi-cascade rendering is not complete. | `126` |
| Procedural wind and foliage animation | Scene-authored motion exists, but the requested procedural renderer-level foliage animation is incomplete. | `127` |
| REVIEW recovery audit | The full REVIEW list needs a final smoke-test pack and honest status audit after the recovery cycles. | `128` |

## Next Thirty Cycle Plan

| Cycle | Priority | Primary Goal | Exit Gate |
| --- | --- | --- | --- |
| `99` | Completed Top | Automated Capture Pipeline | Batch title/live/map/scope/pause captures run from one command and optional baseline comparison produces diff artifacts. |
| `100` | Completed Top | Distant Building LOD Implementation | Renderer switches configured landmark grayboxes from full geometry to impostor cards with scope-stability readouts. |
| `101` | Completed Top | Dynamic Time-Of-Day System | Scenario data sets time, sun angle, sky/fog color, haze, shadow coverage, and ambient/diffuse light. |
| `102` | Completed Top | Forward+ / Clustered Lighting Start | Multiple scene-authored dynamic light sources render without breaking the current single-sun path. |
| `103` | Completed Top | TAA Or Scoped-Safe Anti-Aliasing | Scope shimmer mitigation is active through depth-aware postprocess edge AA with ghosting-safe rejection. |
| `104` | Completed Top | Physically Based Atmosphere And Sky | Scene-authored Rayleigh/Mie/ozone controls now drive the time-of-day sky, clear color, and distance haze baseline. |
| `105` | Completed Top | GPU-Driven Indirect Rendering Prototype | Shadow-casting object draws use a per-frame ICB with fallback; material draws and GPU culling remain documented expansion points. |
| `106` | Completed Top | SDF Font And UI Rendering | HUD, map, and scope text render crisply through SDF or an equivalent scalable text path. |
| `107` | Completed Top | SSR With IBL Fallback | Lake/glass reflections render through SSR/probe fallback with scoped-readability checks. |
| `108` | Completed Top | Render Graph / Frame Graph Scaffolding | Shadow, geometry, presentation, and postprocess-adjacent AA/reflection work are represented in a composable frame graph scaffold. |
| `109` | Completed Next | Audio System Closeout | Footsteps, ambience, scope, observer, weapon, and session audio have scene-authored category gains, master-volume control, and smoke coverage. |
| `110` | Completed Next | Firing Feedback Closeout | Muzzle flash, recoil animation, hit/miss visual feedback, and crack-thump presentation are player-facing. |
| `111` | Completed Next | Group NPC Behavior Closeout | Patrol pairs move in formation, coordinate scans, halt/resume, and recover across checkpoint retries. |
| `112` | Completed Next | Black Mountain And West Basin Texture Closeout | District-specific textures, source notes, atlas captures, and acceptance screenshots are complete. |
| `113` | Completed Next | Multi-Route Playability | Primary plus both alternate rehearsal routes are selectable from briefing and bind checkpoints/map state at fresh-run boundaries. |
| `114` | Completed Next | Scope Optics Closeout | Lens dirt, edge aberration, calibrated mil-dot use, parallax compensation, and scope smoke coverage are complete. |
| `115` | Completed Next | Collision Authoring Workflow | Designers can inspect, select, validate, and export/review collision-volume changes. |
| `116` | Completed Next | Save/Resume Closeout | Players can resume sessions and review checkpoint performance safely across launches. |
| `117` | Next | Formal Performance Profiling | Metal GPU capture, CPU/GPU baseline, and bottleneck report are stored with the cycle docs. |
| `118` | Next | Vegetation Interaction Closeout | Vegetation affects concealment, occlusion, and traversal friction in the live route. |
| `119` | Secondary | Difficulty Retuning Regression | Difficulty settings are validated against group AI, multiple routes, and save/resume. |
| `120` | Secondary | Water System Closeout | Reflections, caustic/specular cues, shoreline motion, and lake readability are validated. |
| `121` | Secondary | LOS Debug Overlay Closeout | A route-author debug overlay visualizes observer coverage, samples, blockers, and scan state. |
| `122` | Secondary | Mission Scripting Expansion | Conditional triggers, timed windows, observer-alert failure, and alternate objectives are data-driven. |
| `123` | Secondary | Minimap Accuracy Closeout | Map markers, route paths, threat arcs, sectors, and collision footprints match all playable routes. |
| `124` | Secondary | Packaging And Distribution Closeout | Notarization, CI/build automation, versioning, tester handoff, and validation are complete. |
| `125` | Secondary | SSAO/HBAO Closeout | Contact shadows/occlusion use a real screen-space AO path or documented equivalent. |
| `126` | Secondary | CSM Closeout | Multi-cascade shadows render or a measured alternative replaces the CSM target. |
| `127` | Secondary | Procedural Foliage Animation Closeout | Vegetation animation is renderer-level/procedural or equivalent and survives performance tests. |
| `128` | Secondary | REVIEW Recovery Audit | Every REVIEW item is rechecked against implementation, smoke tests, and honest status wording. |

## Roadmap Discipline

No new feature block should displace Cycles 99-128 unless it directly closes one of these REVIEW items. If a cycle slips, the unfinished item moves to the next cycle before new work is accepted.
