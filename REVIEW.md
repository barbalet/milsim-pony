# milsim-pony Project Review
*Generated: April 23, 2026 — Cycle 21*

---

## Project Summary

**milsim-pony** is a macOS-native military simulation game prototype set in Canberra, Australia. It is a first-person urban navigation and combat rehearsal experience built on three pillars: large-scale terrain readability at basin scale (Woden to Belconnen), long-range observation through a 4x scoped weapon system, and a playable route-based rehearsal loop with observer pressure and checkpoints.

The tech stack is Swift/Metal for rendering and UI, C for the portable gameplay core (physics, collision, NPC, detection), and a separate Jungle library for terrain rendering. World configuration is fully JSON-driven, enabling data-driven district and scenario design without code changes. The project is at Cycle 21 of a planned 21-cycle roadmap — the foundation is mature and clean, and the project is transitioning from atlas/readability validation into combat mechanics and content production.

---

## Top 20 Things That Need Doing

1. **Ballistics solver** — implement long-range sniper rifle mechanics with bullet drop, travel time, and hit confirmation. The whole game premise hinges on this and it is the single largest missing system.

2. **Audio system** — there is no audio at all. Footsteps, ambient environment, scope toggle feedback, and observer alert audio are all absent and critically affect immersion.

3. **Firing feedback loop** — muzzle flash, recoil animation, hit/miss visual feedback, and the observable "crack-thump" cycle for distant shots.

4. **Group NPC behavior** — current NPCs are solo waypoint-followers with basic stuck detection. Patrol pairs, formation movement, and scan-halt-resume cycles are needed for realistic observer pressure.

5. **Black Mountain and West Basin texture coverage** — these districts have lighter reference photo sourcing than Woden/Civic. A sourcing and atlas pass is required before they can enter the combat rehearsal rotation.

6. **Automated capture pipeline** — the screenshot gallery and comparison workflow is still manual. A batch export and diff tool would dramatically speed up per-cycle QA.

7. **Multiple rehearsal routes** — Cycle 21 ships one route (Woden–Belconnen). Combat scenario breadth requires at least 2–3 more distinct routes with different threat geometries.

8. **LOD system for distant buildings** — large-scene draw calls currently carry full geometry at all distances. A proper LOD chain (high/med/low/billboard) would both cut GPU cost and improve distant silhouette readability.

9. **Difficulty tuning knobs** — observer FOV, suspicion rate, range, and decay rate are currently hardcoded defaults. These need to be exposed as scenario parameters for rehearsal difficulty scaling.

10. **Sniper scope optics refinement** — the 4x scope works but lacks chromatic aberration at edges, lens dirt, parallax compensation, and reticle mil-dot calibration useful for actual range estimation.

11. **Time-of-day system** — sun angle, sky color, shadow length, and ambient light are static. A dynamic time-of-day with configurable scenario start times would dramatically expand rehearsal utility.

12. **Collision volume authoring tools** — collision AABBs and ground surfaces are hand-authored in JSON. A visual preview tool or at minimum a debug overlay mode would reduce placement errors in new districts.

13. **Save/resume session state** — the game currently has no persistent save. Players cannot resume a rehearsal or review checkpoint performance across sessions.

14. **Performance profiling pass** — no formal GPU frame profiling results are documented for Cycle 21. A Metal GPU Capture baseline with identified bottlenecks is needed before the next district expansion.

15. **Vegetation interaction** — the Jungle terrain layer renders layered vegetation but there is no movement (wind sway), occlusion feedback, or traversal friction when moving through it.

16. **Water system** — Lake Burley Griffin is the visual anchor of the basin but currently rendered as a static flat plane. Subtle animated reflection and caustic ripple would significantly improve landmark recognition.

17. **NPC line-of-sight debug overlay** — the detection system samples 256 LOS points but there is no visual debugging mode to verify observer coverage during scenario design.

18. **Objective/mission scripting layer** — checkpoints are the only mission primitive. A lightweight scripting hook for conditional triggers (e.g. "observer alerted → route failed"), timed windows, and alternate objectives would enable richer rehearsal design.

19. **Minimap accuracy pass** — the overhead atlas map needs verification that checkpoint markers, threat arcs, and sector boundaries accurately reflect the 3D world geometry as new districts are added.

20. **Packaging and distribution** — the release script (`package_release.sh`) exists but there is no notarization workflow, versioning scheme, or automated build pipeline for sharing builds with testers.

---

## Top 10 Graphics Engine Modernizations

These are the highest-leverage changes to bring the engine in line with modern real-time renderers.

1. **Clustered deferred lighting** — replace the current single-directional-light model with a clustered deferred or forward+ approach. This enables multiple dynamic light sources (muzzle flash, vehicle headlights, night scenario lighting) without a per-light draw call explosion.

2. **Screen-space ambient occlusion (SSAO) or HBAO** — contact shadows and crevice occlusion are currently baked into AO textures. A real-time SSAO pass on top of the G-buffer would capture dynamic occlusion at doorways, under overhangs, and between close buildings that pre-baked AO misses entirely.

3. **Temporal anti-aliasing (TAA)** — the current pipeline likely uses MSAA or no AA. TAA with a jitter pattern and reprojection would eliminate shimmer on distant geometry and scope reticle edges with almost no additional per-frame cost — critical for long-range readability.

4. **Physically-based atmosphere and sky (Bruneton or Hillaire model)** — the current sky is a gradient with horizon glow. A single-scatter or multi-scatter atmospheric model would give correct Canberra sky color at different times of day, accurate haze at long range, and sun disc rendering — all directly useful for the game's long-range observation core.

5. **GPU-driven indirect rendering** — move draw calls to indirect command buffers via `MTLIndirectCommandBuffer`. This shifts culling to the GPU (via mesh shaders or a compute pre-pass) and reduces CPU-side draw call overhead for the 200+ placed world assets, which is the current CPU bottleneck.

6. **Cascaded shadow maps (CSM)** — the current single 8192×8192 shadow map covers the full scene, causing resolution waste on nearby geometry and artifacts at long range. A 3–4 cascade CSM allocates shadow texels efficiently by distance, giving sharp contact shadows at the player's feet and stable shadows out to draw distance.

7. **Signed-distance field (SDF) font and UI rendering** — scope reticle, HUD text, and map overlays currently rely on texture-based rendering. SDF rendering would make all UI elements crisp at any resolution or scale and would be essential for a future HiDPI or Apple Silicon optimization pass.

8. **Screen-space reflections (SSR) with IBL fallback** — Lake Burley Griffin and glass-faced buildings are visually flat without reflections. Even a low-quality SSR pass with fallback to a pre-convolved sky probe IBL would dramatically improve material read on wet and glass surfaces.

9. **Procedural noise-driven wind and foliage animation** — a compute shader that offsets vegetation vertex positions using a scrolling noise texture (Gerstner or simple sin/cos with per-leaf phase offset) would bring the Jungle terrain layer to life with essentially zero art work, just a shader addition.

10. **Render graph / frame graph architecture** — the current render loop in `GameRenderer.swift` manually sequences passes (shadow → geometry → sky → post-process). Formalizing this as a declarative render graph would make adding new passes (SSR, SSAO, TAA, volumetric fog) safe and composable, and would enable automatic resource aliasing to reduce Metal heap pressure as the pass count grows.

---

## Development Status Check

*Reviewed against the current Cycle 116 development line. This section uses a stricter interpretation than the first planning pass: metadata, readouts, preview-only tools, deferrals, and "architecture decisions" do not count as done. Anything not actually usable in the current build is scheduled into the recovery cycles.*

### Priority Rules From Cycle 116

- **Completed recovery groundwork, Cycles 99-116:** earlier REVIEW items received usable implementation slices or honest partial-status documentation.
- **Immediate recovery, Cycles 117-128:** finish the remaining REVIEW tail before broader campaign polish displaces it.
- **Playable-game completion, Cycles 129-196:** complete REVIEW2, the added playability recommendations, and all outstanding fun-game/release work.
- **Done means playable, inspectable, smoke-tested, and no longer dependent on a future implementation note.**

### Top 20 Things That Need Doing

| ID | Item | Honest Status | Required Allocation |
| --- | --- | --- | --- |
| 1 | Ballistics solver | Done for current scope | Keep in regression only; no new priority cycle unless tests fail. |
| 2 | Audio system | Done for authored mix closeout | Cycle 109: scene-authored category gains now drive ambience, movement, scope, weapon, and observer playback nodes; settings expose a persisted master-volume control; route smoke readouts report `Session Audio:` and `Audio Mix:` state. |
| 3 | Firing feedback loop | Done for player-facing closeout | Cycle 110: scoped firing now shows a visible muzzle flash pulse, recoil kick/recovery, clearer `Shot Feedback:` classification, and retained crack-thump timing. |
| 4 | Group NPC behavior | Done for formation-patrol closeout | Cycle 111: authored patrol pairs now drive runtime formation sweep movement, halt while alerted/neutralized, resume after recovery, feed live overhead-map positions, and expose moving/sweep state in `Patrol Pairs:` smoke readouts. |
| 5 | Black Mountain and West Basin texture coverage | Done for source-backed district closeout | Cycle 112: West Basin/Yarralumla and Black Mountain/Bruce/Belconnen sectors now have source-backed dry-grass, asphalt, concrete, water, and facade assignments with smoke and acceptance docs. |
| 6 | Automated capture pipeline | Done for canonical review states | Cycle 99: `Tools/capture_review.sh` batches title/live/map/scope/pause screenshots and `Tools/image_diff.swift` produces optional baseline diffs. District-specific acceptance captures still feed later texture/map closeouts. |
| 7 | Multiple rehearsal routes | Done for current selectable-route scope | Cycle 113: the briefing route selector now cycles the primary Woden-to-Belconnen route plus both alternate rehearsal routes, and Start Demo binds the selected route at a fresh-run boundary. |
| 8 | LOD system for distant buildings | Done for configured landmark grayboxes | Cycle 100: `SceneDrawable` now carries LOD roles and switch thresholds, and configured landmarks swap from full graybox geometry to 6-vertex impostor cards past the authored distance. |
| 9 | Difficulty tuning knobs | Done, needs regression | Cycle 119: secondary overdue validation against richer group AI and route breadth. |
| 10 | Sniper scope optics refinement | Done for current optic closeout | Cycle 114: scoped view now has visible lens dirt, edge aberration rings, calibrated mil-dot spacing labels, parallax compensation reporting, and scope-mode smoke coverage. |
| 11 | Time-of-day system | Done for configurable scenario lighting | Cycle 101: `timeOfDay` scene data now drives renderer sun angle, sky/fog color, haze, ambient/diffuse light, shadow strength, and shadow coverage, with HUD/session smoke visibility. |
| 12 | Collision volume authoring tools | Done for current authoring workflow | Cycle 115: the briefing map now cycles selectable blocker volumes, highlights the selected footprint, reports sector/dimensions/clearance validation, and exposes export/review source IDs for JSON edits. |
| 13 | Save/resume session state | Done for current resume scope | Cycle 116: saved review cards now carry route identity, checkpoint progress, map/scope state, checkpoint performance metrics, and an explicit `Resume Saved Run` action that rebinds the saved route before guarded checkpoint restore. |
| 14 | Performance profiling pass | Partial | Cycle 117: produce formal Metal GPU capture, CPU/GPU bottleneck notes, and before/after profile artifacts. |
| 15 | Vegetation interaction | Partial | Cycle 118: finish traversal friction, occlusion feedback, and concealment mechanics as gameplay systems. |
| 16 | Water system | Partial | Cycle 120: secondary overdue closeout for animated reflections/caustic/specular polish after SSR/IBL groundwork starts. |
| 17 | NPC line-of-sight debug overlay | Partial | Cycle 121: secondary overdue closeout for a real debug overlay mode, not just HUD text telemetry. |
| 18 | Objective/mission scripting layer | Partial | Cycle 122: secondary overdue expansion to conditional triggers, timed windows, route-fail conditions, and alternate objectives. |
| 19 | Minimap accuracy pass | Partial | Cycle 123: secondary overdue verification against all playable routes, threat arcs, sector boundaries, and 3D geometry. |
| 20 | Packaging and distribution | Partial | Cycle 124: secondary overdue completion of notarization, CI/build automation, version policy, and tester distribution. |

### Top 10 Graphics Engine Modernizations

| ID | Item | Honest Status | Required Allocation |
| --- | --- | --- | --- |
| G1 | Clustered deferred lighting / Forward+ | Done for implementation start | Cycle 102: scene-authored dynamic lights now feed CPU-side drawable light selection and the forward object shader accumulates up to four local point lights without breaking the single-sun path. |
| G2 | SSAO or HBAO | Partial | Cycle 125: secondary overdue closeout from contact darkening into a proper SSAO/HBAO-class pass or explicit replacement. |
| G3 | Temporal anti-aliasing | Done as scoped-safe alternative prototype | Cycle 103: postprocess now applies depth-aware edge anti-aliasing with explicit depth rejection so scoped silhouettes can be smoothed without temporal history ghosting. |
| G4 | Physically based atmosphere and sky | Done for baseline | Cycle 104: scene-authored Rayleigh/Mie/ozone controls now drive sky clear color, horizon lift, and distance haze from the active time-of-day sun. |
| G5 | GPU-driven indirect rendering | Done for prototype | Cycle 105: shadow-casting object draws now use a per-frame `MTLIndirectCommandBuffer` with direct-draw fallback; material-pass indirect draws and GPU culling remain expansion work. |
| G6 | Cascaded shadow maps | Partial | Cycle 126: secondary overdue closeout from CSM readiness metadata to multi-cascade shadow rendering or a documented replacement. |
| G7 | SDF font and UI rendering | Done for scalable UI prototype | Cycle 106: HUD, scope, and map labels now use a scalable SDF-style outlined text path with scene-authored coverage and smoke-test checks; generated MSDF atlas work remains optional expansion. |
| G8 | Screen-space reflections with IBL fallback | Done for bounded prototype | Cycle 107: postprocess now blends bounded screen-space reflection samples with a sky-probe fallback for lake/glass readability; material-masked SSR and richer probes remain expansion work. |
| G9 | Procedural wind and foliage animation | Partial | Cycle 127: secondary overdue closeout with procedural/compute foliage animation or an equivalent renderer-level implementation. |
| G10 | Render graph / frame graph architecture | Done for scaffold | Cycle 108: current shadow, scene, and presentation passes are represented as a frame graph with imported/transient resources and dependency validation; resource aliasing and fuller scheduling remain expansion work. |

### Recovery Plan Superseded By The Eighty-Cycle Playable-Game Plan

The old Cycle `99`-`128` recovery table is now the front end of the broader Cycle `117`-`196` playable-game plan in [Docs/DEVELOPMENT_BACKLOG.md](Docs/DEVELOPMENT_BACKLOG.md). The remaining REVIEW items still keep their original slots:

| Cycle Band | Work |
| --- | --- |
| `117`-`128` | Formal profiling, vegetation interaction, difficulty regression, water, LOS overlay, mission scripting, all-route minimap validation, notarized packaging path, SSAO/HBAO, CSM, procedural foliage, and final recovery audit. |
| `129`-`136` | Route tutorial, simplified HUD, sniper kill objectives, recommended campaign skeleton, basic AAR, all-route audio validation, performance presets, and automated gameplay harness foundation. |
| `137`-`147` | REVIEW2 renderer/gameplay modernizations that were previously unallocated. |
| `148`-`180` | True win/fail loop, campaign content, advanced AI, replay/AAR, release CI, all-route validation, performance presets, and fun-factor balance. |
| `181`-`196` | Accessibility, content density, bug bash, final graphics/combat polish, capture/gameplay CI, release candidate locks, tester feedback, final REVIEW2 audit, and fully playable game candidate. |
