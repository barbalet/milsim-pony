# Cycle 117-156 Execution Packet

## Purpose

Open the next forty planned cycles as an executable work batch without pretending that implementation-heavy features are already complete. This packet covers Cycles `117` through `156`, the first forty cycles in the Cycle `117`-`196` playable-game plan.

## Completion Rule

A cycle is complete only when its feature is usable in the build, has a smoke or automated verification path, and has honest documentation naming any remaining limits. Planning text, HUD copy, metadata, or a placeholder status line is not completion.

## Batch Status

| Cycle | Work | Status | Required Evidence |
| --- | --- | --- | --- |
| `117` | Formal Performance Profiling | Complete | `Tools/profile_cycle117.sh`, `MilsimPonyProfile117.app` profiling build, target-correct Time Profiler trace, exportable Metal System Trace fallback, CPU/GPU bottleneck notes, and [CYCLE_117_PROFILING_REVIEW.md](CYCLE_117_PROFILING_REVIEW.md). Direct target Metal export remains an Instruments limitation for Cycle `165` retry. |
| `118` | Vegetation Interaction Closeout | Complete | Live sector-aware vegetation friction, concealment/masking telemetry, traversal rustle state, and [CYCLE_118_SMOKE_TEST.md](CYCLE_118_SMOKE_TEST.md). |
| `119` | Difficulty Retuning Regression | Complete | Live preset regression telemetry, grouped observer/route/save-resume reporting, `Tools/gamecore_cycle119_regression.c`, and [CYCLE_119_SMOKE_TEST.md](CYCLE_119_SMOKE_TEST.md). |
| `120` | Water System Closeout | Complete | Runtime `Water Closeout:` validation line for SSR/probe fallback, shoreline/water motion reporting, and [CYCLE_120_SMOKE_TEST.md](CYCLE_120_SMOKE_TEST.md). |
| `121` | LOS Debug Overlay Closeout | Complete | Route-author `LOS Overlay:` vector telemetry, sample category reporting, focus scan state, mask counts, and [CYCLE_121_SMOKE_TEST.md](CYCLE_121_SMOKE_TEST.md). |
| `122` | Mission Scripting Expansion | Complete | Conditional mission phase fields, runtime phase evaluation, core forced-failure hook, scene-authored alert/time/alternate objectives, and [CYCLE_122_SMOKE_TEST.md](CYCLE_122_SMOKE_TEST.md). |
| `123` | All-Route Minimap Accuracy | Opened, not complete | Formal validation for markers, route paths, threat arcs, sectors, collision footprints, and all routes. |
| `124` | Notarized Packaging Pipeline | Opened, not complete | Package validation, signing/notarization path, CI gate, tester handoff, and archive verification. |
| `125` | SSAO/HBAO Closeout | Opened, not complete | Real screen-space AO path or measured equivalent with visual/regression proof. |
| `126` | CSM Closeout | Opened, not complete | Multi-cascade shadows or measured replacement with bias/scope stability evidence. |
| `127` | Procedural Foliage Animation | Opened, not complete | Renderer-level procedural/compute foliage motion or equivalent, plus performance proof. |
| `128` | REVIEW/REVIEW2 Recovery Audit | Opened, not complete | Honest post-recovery audit against REVIEW, REVIEW2, tests, and build evidence. |
| `129` | Route Tutorial | Opened, not complete | First-time-player tutorial for movement, map, scope, concealment, checkpoints, and route choice. |
| `130` | Simplified HUD Mode | Opened, not complete | Low-noise HUD mode with mission-critical prompts and telemetry hidden by default. |
| `131` | Sniper Hit/Kill Objectives | Opened, not complete | Scoped identification, hit confirmation, kill/neutralize objectives, and safe failure logic. |
| `132` | Recommended Route Campaign Skeleton | Opened, not complete | Recommended route campaign state, brief/debrief, objective order, and replayable start flow. |
| `133` | Basic After-Action Report | Opened, not complete | Completion/failure report with time, checkpoints, shots, hits, alerts, restarts, and rating. |
| `134` | Audio Mix All-Route Validation | Opened, not complete | Balanced footsteps, scope, weapon, ambience, and observer cues across all routes. |
| `135` | Performance Presets | Opened, not complete | Low/medium/high presets for shadows, foliage, reflections, AO, AA, draw distance, and HUD cost. |
| `136` | Automated Gameplay Harness Foundation | Opened, not complete | Programmatic route, ballistics, collision, and observer checks outside screenshot-only smoke tests. |
| `137` | Material-Pass GPU Indirect Rendering | Opened, not complete | Material/object draw submission uses ICB/GPU-culling where profiling proves value. |
| `138` | Full Temporal Reprojection TAA | Opened, not complete | Jitter, velocity/history buffers, reprojection, and scope-safe fallback with comparison captures. |
| `139` | Tiled/Clustered Forward+ Lighting | Opened, not complete | GPU light lists support many dynamic lights without the four-light-per-drawable cap. |
| `140` | First-Person Weapon Animation | Opened, not complete | Sniper sway, bolt/reload cycle, ready/lower transitions, and reload feedback are playable. |
| `141` | Advanced Observer Tactics | Opened, not complete | Observers coordinate with flanking, signalling, and cover-aware pressure while staying readable. |
| `142` | Session Replay Capture | Opened, not complete | Compact session timeline records positions, shots, alerts, objectives, and checkpoint events. |
| `143` | Outer-District Texture Audit | Opened, not complete | Black Mountain, Belconnen, Ginninderra, Bruce, and lower-density districts have audited material coverage. |
| `144` | Volumetric Fog And Light Shafts | Opened, not complete | Raymarched or equivalent volumetric fog/light shafts improve dawn/dusk readability with scope checks. |
| `145` | Hi-Z Screen-Space Reflections | Opened, not complete | SSR uses hierarchical traversal and broader material masks for water, glass, wet pavement, and vehicles. |
| `146` | POM And Detail Normal Blending | Opened, not complete | Brick, concrete, ground, and close terrain gain depth/detail without extra geometry. |
| `147` | HDR Output And Physical Camera | Opened, not complete | HDR/EDR path, exposure model, DOF/bokeh policy, and scope-safe tone mapping are implemented or explicitly gated. |
| `148` | True Mission Fail/Win Loop | Opened, not complete | Campaign route has clean win, fail, retry, abandon, checkpoint, and scoring transitions. |
| `149` | Mission Objective Variants | Opened, not complete | Timed windows, stealth routes, kill/no-kill branches, extraction, and alternate objectives are data-authored. |
| `150` | Target/Kill Feedback Polish | Opened, not complete | Hit reactions, neutralization clarity, impact VFX/audio, and objective credit are unambiguous. |
| `151` | Tutorial Usability Pass | Opened, not complete | Tutorial prompts are playtested, skippable, restart-safe, and friendly to experienced players. |
| `152` | HUD Accessibility And Options | Opened, not complete | Simplified HUD gains scale, contrast, opacity, subtitle, color, and telemetry toggles. |
| `153` | Notarized Release Dry Run | Opened, not complete | Release candidate is built, signed/notarized where credentials allow, packaged, and install-tested. |
| `154` | Performance Preset QA | Opened, not complete | Presets are validated on route, scope, map, combat, water, and foliage-heavy scenes. |
| `155` | Map/Collision Consistency Audit | Opened, not complete | Minimap, blockers, checkpoints, objective markers, and route geometry agree in all routes. |
| `156` | Audio Mix Polish | Opened, not complete | Route-specific ambience, alert escalation, weapon tails, footsteps, and AAR/replay cues are balanced. |

## Execution Order

1. Run Cycle `117` first because the profiling artifact informs renderer-heavy work in Cycles `120`, `125`, `126`, `127`, `135`, and `137`-`147`.
2. Run Cycles `118`-`124` before playability polish because vegetation, difficulty, mission scripting, map accuracy, and packaging are foundational.
3. Run Cycles `125`-`128` to close the original recovery tail before marking REVIEW recovery complete.
4. Run Cycles `129`-`136` as the first playable-game layer: tutorial, simplified HUD, sniper objectives, campaign skeleton, AAR, audio validation, performance presets, and gameplay harness foundation.
5. Run Cycles `137`-`147` as the first REVIEW2 modernization block, using Cycle `117` and Cycle `135` evidence to protect frame time.
6. Run Cycles `148`-`156` as the first campaign/fun-loop integration block, tying the renderer and gameplay improvements into fail/win flow, objective variants, release dry run, preset QA, map/collision audit, and audio polish.

## Batch Exit Gate

The batch is complete only when:

- `Docs/CYCLE_117_SMOKE_TEST.md` through `Docs/CYCLE_156_SMOKE_TEST.md` or equivalent cycle-specific verification docs exist.
- Each cycle has implementation evidence, not just a plan.
- `Tools/package_release.sh --validate-only` and `Tools/capture_review.sh --validate-only` pass for the current release cycle.
- The build passes after the final cycle in the batch.
- [Docs/DEVELOPMENT_BACKLOG.md](DEVELOPMENT_BACKLOG.md), [REVIEW.md](../REVIEW.md), and [REVIEW2.md](../REVIEW2.md) are updated from "opened" to "completed" only for cycles whose evidence actually exists.
