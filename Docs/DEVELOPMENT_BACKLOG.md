# Development Backlog

This document extends the shipped roadmap beyond Cycle 116 and now folds together [REVIEW.md](../REVIEW.md), [REVIEW2.md](../REVIEW2.md), and the April 28, 2026 playability directive: the aim is a fully playable, fun, notarized Mac game in the next eighty cycles.

## Current Baseline

The active development line is Cycle 122. Cycles 99-116 closed many earlier REVIEW items as usable slices, Cycle `117` closed the formal profiling pass, and Cycles `118`-`122` now close vegetation interaction, difficulty regression, water closeout reporting, LOS authoring overlay telemetry, and conditional mission scripting. REVIEW2 still raises the bar from "reviewable prototype" to "complete playable game." The next open playable-game cycles are Cycles `123` through `196`.

The corrected rule remains simple: **if an item is not implemented as usable player/developer functionality, it is not done.** Telemetry, metadata, smoke text, architecture notes, and partial prototypes are evidence, not closure.

## Priority Rules

- **Immediate recovery, Cycles 117-128:** finish the already allocated REVIEW/REVIEW2 recovery tail without slipping the foundational work.
- **Playable game core, Cycles 129-136:** tutorial, simplified HUD, real sniper objectives, recommended campaign, after-action report, route audio validation, performance presets, and automated gameplay harness foundation.
- **REVIEW2 modernization, Cycles 137-147:** close the graphics/gameplay systems that were explicitly unallocated in the first REVIEW2 pass.
- **Campaign and fun loop, Cycles 148-180:** turn the systems into one polished recommended route campaign with win/fail pressure, validated routes, balanced difficulty, and tester-ready pacing.
- **Release hardening, Cycles 181-196:** bug bash, capture/gameplay CI, notarized release candidate, tester feedback, final REVIEW2 audit, and playable-game signoff.
- A cycle is complete only when the feature is usable in the build, has a smoke or automated verification path, and has honest documentation that names any remaining limitations.

## Honest Status After Cycle 116

### Done Enough For Regression Only

| Review Item | Evidence | Follow-Up |
| --- | --- | --- |
| Ballistics solver | `GameCore` exposes ballistic prediction, drop, flight time, observer hits, and fire feedback. | Expand into explicit sniper kill objectives in Cycle `131` and harness tests in Cycle `162`. |
| Automated capture pipeline | Cycle 99 adds `Tools/capture_review.sh` and optional image diffs. | Fold into release CI by Cycle `188`. |
| LOD system for distant buildings | Cycle 100 adds renderer-side LOD roles and impostor cards. | Regress during profiling, CSM, TAA, and release performance work. |
| Time-of-day system | Cycle 101 drives sun angle, sky/fog color, haze, ambient/diffuse light, and shadow strength. | Regress during volumetric fog, HDR, and campaign polish. |
| Clustered deferred / Forward+ lighting start | Cycle 102 adds bounded dynamic local lights. | Full tiled/clustered GPU lighting is Cycle `139`. |
| Scoped-safe AA | Cycle 103 adds depth-aware post edge AA. | Full temporal reprojection TAA is Cycle `138`. |
| Physically based atmosphere and sky baseline | Cycle 104 adds Rayleigh/Mie/ozone controls. | Volumetric fog/light shafts are Cycle `144`. |
| GPU-driven indirect rendering prototype | Cycle 105 adds shadow-caster ICBs. | Material-pass ICB and GPU culling are Cycle `137`. |
| SDF font and UI rendering | Cycle 106 adds scalable outlined text for HUD/scope/map labels. | Simplified HUD and accessibility work happen in Cycles `130`, `152`, and `181`. |
| SSR with IBL fallback | Cycle 107 adds bounded SSR/probe fallback. | Hi-Z SSR is Cycle `145`. |
| Render graph / frame graph scaffold | Cycle 108 describes current pass/resource ordering. | Resource aliasing and fuller scheduling are Cycle `166`. |
| Audio system | Cycle 109 adds authored category mix and master volume. | All-route audio validation is Cycle `134`; audio polish is Cycle `156`. |
| Firing feedback loop | Cycle 110 adds muzzle flash, recoil, shot classification, and crack-thump timing. | Full weapon animation/reload is Cycle `140`; combat feel polish is Cycle `186`. |
| Group NPC behavior | Cycle 111 adds patrol-pair formation movement and alert halt/resume. | Advanced tactics are Cycles `141`, `159`, and `160`. |
| District texture coverage | Cycle 112 covers Black Mountain/West Basin/Belconnen materials for current scope. | Outer-district completeness audit is Cycle `143`; content density pass is Cycle `182`. |
| Multiple rehearsal routes | Cycle 113 makes the primary plus two alternates selectable and bindable. | All-route minimap, audio, difficulty, and campaign validation happen in Cycles `123`, `134`, `179`, and `180`. |
| Sniper scope optics | Cycle 114 adds lens dirt, aberration, mil labels, and parallax reporting. | Full sniper objectives and campaign integration are Cycles `131`, `150`, and `173`. |
| Collision authoring workflow | Cycle 115 adds selectable blocker review and validation/export guidance. | Regress through minimap validation, harness tests, and route polish. |
| Save/resume session state | Cycle 116 adds guarded route-bound checkpoint resume and performance readouts. | Basic AAR is Cycle `133`; session replay capture is Cycle `142`; integrated AAR/replay is Cycle `174`. |

### Existing Recovery Tail

| Review Item | Remaining Gap | Cycle |
| --- | --- | --- |
| Formal Metal GPU profiling | Complete for Cycle `117`: target-correct Time Profiler trace, exportable Metal System Trace fallback, bottleneck notes, and direct-target Metal export limitation are documented in `Docs/CYCLE_117_PROFILING_REVIEW.md`. | `117` |
| Vegetation interaction | Complete for Cycle `118`: live vegetation friction, masking telemetry, traversal rustle state, and smoke coverage exist. | `118` |
| Difficulty tuning knobs | Complete for Cycle `119`: difficulty regression telemetry and a core regression cover preset pressure and route-failure hook behavior. | `119` |
| Water system | Complete for Cycle `120`: runtime water closeout line validates SSR/probe fallback, water targets, and environmental motion during play. | `120` |
| NPC line-of-sight debug overlay | Complete for Cycle `121`: route-author LOS overlay vector, focus scan state, sample categories, and mask counts are exposed live. | `121` |
| Objective/mission scripting layer | Complete for Cycle `122`: mission phases now support alert/suspicion/time failure conditions and alternate objectives with a core route-failure hook. | `122` |
| Minimap accuracy pass | Needs formal all-route geometry/threat/sector verification. | `123` |
| Packaging and distribution | Needs notarization, CI/build automation, versioning, and tester flow. | `124` |
| SSAO/HBAO | Needs a real screen-space AO path or measured equivalent. | `125` |
| Cascaded shadow maps | Needs multi-cascade shadows or a documented measured replacement. | `126` |
| Procedural wind and foliage animation | Needs renderer-level procedural/compute foliage animation or equivalent. | `127` |
| REVIEW recovery audit | Needs an honest post-recovery smoke pack and status audit. | `128` |

### Newly Allocated REVIEW2 And Playability Work

| Work | Cycle |
| --- | --- |
| Route tutorial | `129` |
| Simplified HUD mode | `130` |
| Full sniper hit/kill objectives | `131` |
| Recommended route campaign skeleton | `132` |
| Basic after-action report | `133` |
| Audio mix validation across all routes | `134` |
| Performance presets | `135` |
| Automated gameplay test harness foundation | `136` |
| Material-pass GPU indirect rendering and GPU culling | `137` |
| Full TAA with temporal reprojection | `138` |
| Tiled/clustered Forward+ lighting | `139` |
| First-person weapon animation and reload cycles | `140` |
| Advanced observer tactics and coordination | `141` |
| Session replay capture | `142` |
| Black Mountain and outer-district texture completeness audit | `143` |
| Volumetric fog and light shafts | `144` |
| Hi-Z screen-space reflections | `145` |
| Parallax occlusion mapping and detail normal blending | `146` |
| HDR display output and physical camera model | `147` |

## Next Eighty Cycle Plan

The execution packets are opened in [CYCLE_117_156_EXECUTION.md](CYCLE_117_156_EXECUTION.md) and [CYCLE_157_196_EXECUTION.md](CYCLE_157_196_EXECUTION.md). These packets do not mark the cycles complete; they list the implementation and verification evidence required before any Cycle `117`-`196` item can be closed. Cycle `117` now has executable profiling tooling in [CYCLE_117_SMOKE_TEST.md](CYCLE_117_SMOKE_TEST.md), [../Tools/profile_cycle117.sh](../Tools/profile_cycle117.sh), and a closed bottleneck review in [CYCLE_117_PROFILING_REVIEW.md](CYCLE_117_PROFILING_REVIEW.md). The stored artifacts are `artifacts/profiling/cycle117-time-profiler-current.trace`, `artifacts/profiling/cycle117-time-profiler-current-toc.xml`, `artifacts/profiling/cycle117-time-profile-current.xml`, `artifacts/profiling/cycle117-metal-system-live.trace`, and `artifacts/profiling/cycle117-metal-system-live-toc.xml`. Direct target-launched Metal export still fails with Instruments `Document Missing Template Error`, so Cycle `165` must retry direct target Metal capture after renderer modernization.

| Cycle | Priority | Primary Goal | Exit Gate |
| --- | --- | --- | --- |
| `117` | Immediate | Formal Performance Profiling | Complete: target-correct CPU baseline, exportable Metal fallback, and bottleneck report are stored with cycle docs. |
| `118` | Immediate | Vegetation Interaction Closeout | Complete: vegetation affects concealment, occlusion feedback, and traversal friction in the live route. |
| `119` | Immediate | Difficulty Retuning Regression | Complete: difficulty settings have live route/group/save-resume telemetry and core regression coverage. |
| `120` | Immediate | Water System Closeout | Complete: reflections, shoreline motion, and lake readability are exposed through runtime validation. |
| `121` | Immediate | LOS Debug Overlay Closeout | Complete: route-author LOS overlay reports observer coverage, samples, blockers, mask count, and scan state. |
| `122` | Immediate | Mission Scripting Expansion | Complete: conditional triggers, timed windows, observer-alert failure, suspicion thresholds, and alternate objectives are data-driven. |
| `123` | Immediate | All-Route Minimap Accuracy | Map markers, route paths, threat arcs, sectors, and collision footprints match all playable routes. |
| `124` | Immediate | Notarized Packaging Pipeline | Package validation, notarization path, archive policy, CI gate, and tester handoff are wired. |
| `125` | Immediate | SSAO/HBAO Closeout | Contact shadows/occlusion use a real screen-space AO path or documented equivalent. |
| `126` | Immediate | CSM Closeout | Multi-cascade shadows render or a measured alternative replaces the CSM target. |
| `127` | Immediate | Procedural Foliage Animation | Vegetation animation is renderer-level/procedural or equivalent and survives performance tests. |
| `128` | Immediate | REVIEW/REVIEW2 Recovery Audit | Every REVIEW and REVIEW2 item is rechecked against implementation, tests, and honest status wording. |
| `129` | Playability | Route Tutorial | A first-time player can learn movement, map, scope, concealment, checkpoints, and route choice in-game. |
| `130` | Playability | Simplified HUD Mode | A low-noise HUD mode hides developer telemetry while preserving mission-critical prompts. |
| `131` | Playability | Sniper Hit/Kill Objectives | Missions can require scoped identification, hit confirmation, kill/neutralize objectives, and safe failure. |
| `132` | Campaign | Recommended Route Campaign Skeleton | One recommended route has campaign state, brief/debrief framing, objective order, and replayable start flow. |
| `133` | Playability | Basic After-Action Report | Completion/failure produces route time, checkpoints, shots, hits, alerts, restarts, and rating summary. |
| `134` | Validation | Audio Mix All-Route Validation | Footsteps, scope, weapon, ambience, and observer cues are balanced across all playable routes. |
| `135` | Performance | Performance Presets | Low/medium/high presets control shadows, foliage, reflections, AO, AA, draw distance, and HUD cost. |
| `136` | QA | Automated Gameplay Harness Foundation | Programmatic route, ballistics, collision, and observer checks run outside screenshot-only smoke tests. |
| `137` | Renderer | Material-Pass GPU Indirect Rendering | Material/object draw submission gains ICB/GPU-culling coverage where profiling proves value. |
| `138` | Renderer | Full Temporal Reprojection TAA | Jitter, velocity/history buffers, reprojection, and scope-safe fallback are implemented and compared. |
| `139` | Renderer | Tiled/Clustered Forward+ Lighting | GPU light lists support many dynamic lights without the four-light-per-drawable cap. |
| `140` | Combat | First-Person Weapon Animation | Sniper sway, bolt/reload cycle, ready/lower transitions, and reload feedback are visible and playable. |
| `141` | AI | Advanced Observer Tactics | Observers coordinate beyond formation patrols with flanking, signalling, and cover-aware pressure. |
| `142` | Review | Session Replay Capture | A compact session timeline records positions, shots, alerts, objectives, and checkpoint events for replay/AAR. |
| `143` | Content | Outer-District Texture Audit | Black Mountain, Belconnen, Ginninderra, Bruce, and lower-density outer districts have audited material coverage. |
| `144` | Renderer | Volumetric Fog And Light Shafts | Raymarched or equivalent volumetric fog/light shafts improve dawn/dusk readability without wrecking scope clarity. |
| `145` | Renderer | Hi-Z Screen-Space Reflections | SSR uses hierarchical traversal and broader material masks for water, glass, wet pavement, and vehicles. |
| `146` | Renderer | POM And Detail Normal Blending | Brick, concrete, ground, and close terrain gain depth/detail without extra geometry. |
| `147` | Renderer | HDR Output And Physical Camera | HDR/EDR path, exposure model, DOF/bokeh policy, and scope-safe tone mapping are implemented or explicitly gated. |
| `148` | Playability | True Mission Fail/Win Loop | Campaign route has clean win, fail, retry, abandon, checkpoint, and scoring state transitions. |
| `149` | Mission | Mission Objective Variants | Timed windows, stealth routes, kill/no-kill branches, extraction, and alternate objectives are data-authored. |
| `150` | Combat | Target/Kill Feedback Polish | Hit reactions, neutralization clarity, impact VFX/audio, and objective credit are unambiguous. |
| `151` | Onboarding | Tutorial Usability Pass | Tutorial prompts are playtested, skippable, restart-safe, and do not block experienced players. |
| `152` | UX | HUD Accessibility And Options | Simplified HUD gains scale, contrast, opacity, subtitle, color, and telemetry toggles. |
| `153` | Release | Notarized Release Dry Run | A release candidate is built, signed/notarized where credentials allow, packaged, and install-tested. |
| `154` | Performance | Performance Preset QA | Presets are validated on route, scope, map, combat, water, and foliage-heavy scenes. |
| `155` | Map | Map/Collision Consistency Audit | Minimap, collision blockers, checkpoint placement, objective markers, and route geometry agree in all routes. |
| `156` | Audio | Audio Mix Polish | Route-specific ambience, alert escalation, weapon tails, footsteps, and AAR/replay cues are balanced. |
| `157` | AAR | After-Action Comparison | AAR compares runs, highlights best checkpoint splits, alerts, accuracy, and objective success/failure reasons. |
| `158` | Campaign | Recommended Route Content Pass | The recommended route gets final objective beats, scenic anchors, threat pacing, and checkpoint rhythm. |
| `159` | AI | Observer Flanking Tactics | Observer groups can pressure from alternate angles while staying readable and fair. |
| `160` | AI | Cover-Bounding And Suppression Signals | Coordinated observer behavior includes bounded movement, callouts/signals, and suppression-style pressure. |
| `161` | Combat | Weapon Animation Polish | Sway/reload/bolt timing, scope interruption, breath recovery, and animation/audio sync are tuned. |
| `162` | QA | Ballistics Harness | Automated tests cover drop, time of flight, blocker hits, kill credit, and objective hit rules. |
| `163` | QA | Collision Harness | Automated tests cover player blockers, checkpoint spawns, route blockers, projectile blockers, and vegetation friction. |
| `164` | QA | Observer Detection Harness | Automated tests cover LOS samples, concealment, difficulty presets, group alerts, and fail thresholds. |
| `165` | Performance | Post-Modernization Profiling | Profiling is rerun after CSM, SSAO, TAA, clustered lighting, and indirect rendering land. |
| `166` | Renderer | Render Graph Resource Scheduling | Frame graph expands to resource aliasing, pass validation, and safer scheduling for modernized passes. |
| `167` | Materials | Terrain And Material Quality Pass | Terrain, roads, facades, props, and close materials are tuned under POM/detail/HDR lighting. |
| `168` | Water | Water Final Polish | Water is retuned with CSM, SSR, fog, HDR, shoreline cues, caustics/specular, and scope readability active. |
| `169` | Foliage | Foliage Gameplay Tuning | Procedural wind, concealment, friction, performance, and observer readability are tuned together. |
| `170` | Mission | Campaign Mission Breadth | Recommended route supports enough objective variety to feel like a mission, not a tech demo. |
| `171` | Onboarding | Route Tutorial Playtest Closeout | New-player route completion, failure recovery, map use, scope use, and tutorial skip paths are verified. |
| `172` | UX | Simplified HUD Playtest Closeout | Players can finish the recommended route in simplified HUD mode without developer telemetry. |
| `173` | Combat | Sniper Objectives Campaign Integration | Kill objectives, identification, no-fire states, and score/AAR are integrated into campaign flow. |
| `174` | AAR | Replay And AAR Integration | Session replay data feeds after-action summaries and route comparison without bloating save files. |
| `175` | Release | Distribution CI Automation | CI validates build, package inputs, gameplay harness, capture smoke, and release manifest. |
| `176` | Release | External Tester Handoff | Notarized or credential-blocked release package, tester guide, known issues, and feedback template are complete. |
| `177` | Performance | Preset Auto-Detect | Hardware/profile heuristics suggest safe defaults and expose override controls. |
| `178` | Campaign | Recommended Route Vertical Polish | One route is polished end to end for pacing, visuals, audio, objectives, failure, win, and AAR. |
| `179` | Validation | All-Route Campaign Validation | Every route can start, complete/fail, resume, show map state, play audio, and report AAR correctly. |
| `180` | Validation | Combined Route Regression | Difficulty, minimap, audio, save/resume, AAR, and observer pressure are validated across all routes. |
| `181` | UX | Accessibility And Input Polish | Controls, sensitivity, subtitles, HUD modes, remapping readiness, and pause/settings flows are release-grade. |
| `182` | Content | Outer-District Density Pass | Lower-density districts gain enough roads, facades, blockers, signage, and landmarks to support fun play. |
| `183` | Balance | Fun-Factor Balance Pass | Time pressure, route length, alerts, objective clarity, combat frequency, and scoring are tuned for repeat play. |
| `184` | Stability | Full Game Bug Bash | Crash, startup, save, restore, renderer, map, audio, and input bugs are triaged and fixed by severity. |
| `185` | Graphics | Final Graphics Audit | CSM, SSAO, TAA, clustered lights, HDR, fog, SSR, POM, water, and foliage are reviewed together. |
| `186` | Combat | Combat Feel Polish | Rifle handling, hit feedback, observer pressure, objective results, and audio/visual response feel coherent. |
| `187` | Gameplay | Fail/Win Stress Test | Repeated fail/retry/win/resume/quit/relaunch flows do not corrupt state or confuse the player. |
| `188` | QA | Capture And Gameplay CI | Automated capture plus gameplay harnesses run as repeatable release gates. |
| `189` | Release | Release Candidate Content Lock | Recommended route, tutorial, AAR, HUD, assets, docs, and known issues are locked for RC testing. |
| `190` | Release | Release Candidate Performance Lock | Presets, frame pacing, memory, GPU capture deltas, and route performance budgets are signed off. |
| `191` | Release | Release Candidate Notarization Lock | Signing, notarization/stapling, zip/package verification, and clean-machine launch are signed off. |
| `192` | Test | Tester Feedback Batch | External tester feedback is categorized into blocker, high, medium, polish, and post-release buckets. |
| `193` | Test | Post-Feedback Fixes | Blocker and high-priority tester issues are fixed and regression-tested. |
| `194` | Polish | Final Fun-Factor Smoke | A fresh-player pass verifies the recommended route is understandable, tense, fair, and replayable. |
| `195` | Audit | Final REVIEW2 Closure Audit | REVIEW2, added recommendations, and outstanding tasks are checked against build evidence. |
| `196` | Release | Fully Playable Fun Game Candidate | A notarized, packaged, documented, tested build is ready as the playable recommended-route game candidate. |

## Roadmap Discipline

No new feature block should displace Cycles `117`-`196` unless it directly closes one of the REVIEW2/playability items above. If a cycle slips, the unfinished item moves to the next cycle before new work is accepted, and the final audit must explicitly call out the slip.
