# REVIEW2 — Project Summary, Top 20 Backlog Items & Graphics Engine Modernizations

---

## Project Summary

**milsim-pony** is a macOS-native military simulation prototype set in Canberra, Australia — specifically the basin from Woden to Belconnen with Lake Burley Griffin. It is a first-person rehearsal experience built around three pillars: large-scale terrain readability at basin scale, long-range observation through a 4× magnified scope system, and a playable route-based rehearsal loop with observer pressure and checkpoints.

The stack is deliberately lean: Swift + SwiftUI for the app shell, Metal for GPU rendering, and a portable C core (`GameCore.c`) for all physics, collision, NPC AI, and ballistics. Terrain is handled by a custom internal library called **Jungle**, a C/Metal hybrid that layers vegetation from ground cover up through canopy. World content is entirely JSON-driven — no hardcoded geometry — which means design changes don't require recompilation. The project is currently at **Cycle 116** and now has an eighty-cycle completion roadmap through **Cycle 196**. The aim is a fully playable, fun, notarized Mac game with the full contents of this REVIEW2 document, the added playability recommendations, and the outstanding recovery tasks completed.

---

## Top 20 Things That Need Doing

1. **Formal Metal GPU profiling** — runtime counters exist but no actual Metal GPU frame capture or CPU/GPU bottleneck breakdown has been run. This is the most important diagnostic before optimising anything else.

2. **Cascaded Shadow Maps (CSM)** — the metadata scaffold is in place, but the actual multi-cascade renderer isn't implemented. The current single 8K shadow map wastes texels on nearby geometry and produces range artifacts.

3. **SSAO / HBAO pass** — the contact shadow is a simple 8-direction depth sample. A proper screen-space ambient occlusion pass is needed for realistic grounding at doorways, overhangs, and between buildings.

4. **Water system closeout** — ripple vertex displacement exists but the reflection, caustic, and specular layers are incomplete. Water is a visually prominent surface in a Canberra map and needs the polish.

5. **Procedural foliage animation via compute shader** — the current wind sway uses scene-authored motion curves. A noise-driven compute pass (Gerstner-style) would make vegetation feel alive without per-drawable authoring.

6. **Vegetation interaction mechanics** — traversal friction through foliage, occlusion feedback, and concealment state from vegetation cover are not wired up despite the wind/response system existing.

7. **Mission scripting layer** — checkpoints work, but conditional triggers, timed windows, and fail conditions aren't implemented. The rehearsal loop can't express real mission complexity without them.

8. **Minimap accuracy verification across all routes** — only the primary route has been formally checked. The two alternate routes need the same validation pass before distribution.

9. **Packaging, notarization, and CI automation** — build scripts exist but the full tester distribution flow (notarization, archive, automated build pipeline) is incomplete at ~40% maturity. This is a prerequisite for anyone else running the build.

10. **GPU-driven indirect rendering for material passes** — `enableShadowIndirectCommands` is hardcoded to `false`. Moving material pass draw calls to `MTLIndirectCommandBuffer` with GPU-side culling addresses the identified CPU bottleneck at 200+ world assets.

11. **Difficulty tuning regression** — the settings exist but haven't been validated against richer group AI behaviour and multiple routes simultaneously.

12. **NPC line-of-sight debug overlay** — currently only HUD telemetry. A proper in-world visualisation overlay is needed for route authoring and AI tuning.

13. **Full TAA with temporal reprojection** — the current scoped-safe edge AA handles the optics case well but shimmer on distant geometry needs a reprojection-based temporal solution.

14. **Clustered / deferred lighting** — the Forward+ prototype caps at 4 lights per drawable. Muzzle flashes, vehicle headlights, and ambient scene lights need a tiled or deferred clustering approach to scale past a handful of dynamic sources.

15. **First-person weapon animation and reload cycles** — no weapon animation system exists. Even a basic procedural sway + reload cycle would dramatically increase physical believability.

16. **Observer group tactics and coordination** — individual observer alertness and patrol offsets work, but genuine group coordination (flanking, suppression signalling, cover-bounding) is incomplete.

17. **Save / session replay** — checkpoint persistence works but full session replay (for after-action review, which matters for a rehearsal tool) is deferred.

18. **Automated gameplay test harness** — smoke tests are screenshot-based visual checks. A programmatic harness for ballistics, collision, and observer detection would catch regressions that pixel diffs miss.

19. **Black Mountain and outer district texture expansion** — sourced textures exist for Cycle 112 but coverage needs a completeness audit, particularly for outer districts with lower road and building density.

20. **Audio mix validation across routes** — the audio system (footsteps, observer cues, mix controls) is at ~85% but hasn't been formally validated against all three routes with observer group pressure fully active.

---

## Top 10 Graphics Engine Modernizations

1. **Cascaded Shadow Maps** — replace the single 8192×8192 shadow map with 3–4 cascades that allocate shadow texels by distance. Near-cascade resolution becomes dramatically better; far-cascade coverage stays. This is the highest-priority graphics task given visible range artifacts.

2. **Full Temporal Anti-Aliasing (TAA)** — add subpixel jitter to the projection matrix and accumulate frames via reprojection with a velocity buffer. Eliminates temporal shimmer on distant geometry and fine detail like fence posts or foliage edges. The existing scoped-safe AA can remain for the optics camera.

3. **SSAO / HBAO+** — a proper screen-space ambient occlusion pass using hemisphere ray sampling against the depth buffer. Adds perceptual grounding where geometry meets — door frames, building corners, footwear on ground — that the current contact shadow approximation misses.

4. **Tiled / Clustered Forward+ Lighting** — replace the 4-light-per-drawable cap with a view frustum subdivided into screen tiles (or 3D clusters), with a per-tile light list built on the GPU each frame. Enables hundreds of simultaneous dynamic lights for muzzle flashes, tracers, and area effects without shader branching overhead.

5. **GPU-Driven Indirect Rendering with GPU Culling** — move all draw call submission (not just shadows) to `MTLIndirectCommandBuffer` with a compute pass performing frustum culling and LOD selection on the GPU. Eliminates the documented CPU bottleneck at 200+ assets and unlocks draw count scaling.

6. **Volumetric Fog and Light Shafts** — replace the current distance-based fog blend with a raymarched volumetric fog volume. Add directional scattering (Henyey-Greenstein phase function) for godray effects from the sun. Transformative for early morning and dusk scenarios in an outdoor Canberra environment.

7. **Screen-Space Reflections with Hierarchical-Z Traversal** — upgrade the current SSR from a simple linear depth march to a Hi-Z pyramid traversal. This drastically reduces the number of samples needed for accurate reflections and allows SSR to work on all glossy surfaces (wet pavement, vehicle roofs) not just water and glass.

8. **Procedural Wind via Compute Shader** — replace the scene-authored motion curves with a compute shader generating spatially coherent wind noise (sum of Gerstner waves in a wind texture) sampled by foliage vertex world position. Eliminates per-drawable authoring burden and makes wind feel physically consistent across the map.

9. **Parallax Occlusion Mapping and Detail Normal Blending** — add POM to the material shader for surfaces like brick, concrete, and tiled ground to give them perceived depth without extra geometry. Pair with triplanar detail normals on terrain-adjacent surfaces to break up texture repetition at close range.

10. **HDR Display Output and Physical Camera Model** — expose full HDR10 / EDR output on supported macOS displays. Replace the current filmic tone map exposure control with a proper physical camera model (aperture, shutter, ISO) driving both exposure and depth-of-field. The scope system would benefit immediately from a physically motivated bokeh out-of-focus rendering for the lens periphery.

---

*Generated at Cycle 116 — April 2026*

---

## Cycle 116 Implementation Status Review

*Reviewed April 28, 2026 against the current Cycle 116 development line, `REVIEW.md`, and `Docs/DEVELOPMENT_BACKLOG.md`. This section uses the same honest rule as the recovery backlog: telemetry, planning metadata, and partial prototypes do not count as complete when REVIEW2 asks for a full player-facing or developer-facing system.*

### Top 20 Backlog Status

| # | REVIEW2 Item | Current Status | Cycle Allocation |
| --- | --- | --- | --- |
| 1 | Formal Metal GPU profiling | Not yet done. Runtime frame/core/LOS/world profiling readouts exist, and CSM/profile metadata exists, but no stored Metal GPU frame capture or CPU/GPU bottleneck artifact is present. | Cycle `117` is allocated. |
| 2 | Cascaded Shadow Maps | Not yet done. The renderer still uses the single sun shadow map path with CSM readiness/profile lines. | Cycle `126` is allocated. |
| 3 | SSAO / HBAO pass | Not yet done. The build has surface-fidelity/contact-darkening style reporting, but no proper SSAO/HBAO renderer pass. | Cycle `125` is allocated. |
| 4 | Water system closeout | Partly done. Water material, motion, shoreline ripple, and bounded SSR/IBL reflection evidence exist; caustic/specular/reflection polish remains incomplete. | Cycle `120` is allocated. |
| 5 | Procedural foliage animation via compute shader | Partly done by vertex-shader/scene-authored wind motion, not by the requested compute/noise system. | Cycle `127` is allocated. |
| 6 | Vegetation interaction mechanics | Partly done. Concealment/traversal/readout evidence exists, but the backlog still calls for live traversal friction, occlusion feedback, and concealment mechanics closeout. | Cycle `118` is allocated. |
| 7 | Mission scripting layer | Partly done. Checkpoint mission hooks and phase/objective metadata exist, but conditional triggers, timed windows, fail conditions, and alternate objectives are not complete. | Cycle `122` is allocated. |
| 8 | Minimap accuracy across all routes | Partly done. Multi-route selection and map readouts exist; formal all-route geometry/threat/sector verification remains open. | Cycle `123` is allocated. |
| 9 | Packaging, notarization, and CI automation | Partly done. Packaging validation, archive naming, tester handoff docs, and distribution checks exist; notarization and CI automation remain incomplete. | Cycle `124` is allocated. |
| 10 | GPU-driven indirect rendering for material passes | Partly done. Cycle 105 added a fallback-safe indirect path for shadow casters only; material-pass indirect draws and GPU culling are still deferred. | Cycle `137` is allocated after Cycle `117` profiling. |
| 11 | Difficulty tuning regression | Partly done. Difficulty presets affect suspicion, decay, fail threshold, and weapon cycle; regression against group AI and multiple routes remains. | Cycle `119` is allocated. |
| 12 | NPC line-of-sight debug overlay | Partly done. LOS telemetry/readouts exist, but a proper in-world route-author visualization overlay is not complete. | Cycle `121` is allocated. |
| 13 | Full TAA with temporal reprojection | Not yet done. Cycle 103 delivered scoped-safe depth-aware edge AA specifically without temporal history; full reprojection, jitter, and velocity buffers are not implemented. | Cycle `138` is allocated. |
| 14 | Clustered / deferred lighting | Partly done. Cycle 102 added a bounded Forward+ start with CPU-side drawable light selection and up to four local lights; a tiled/deferred GPU cluster grid is not complete. | Cycle `139` is allocated. |
| 15 | First-person weapon animation and reload cycles | Partly done. Muzzle flash, recoil, shot timing, and hit/miss feedback exist; weapon model animation, sway, reload cycles, and richer first-person presentation do not. | Cycle `140` is allocated, with polish in Cycle `161`. |
| 16 | Observer group tactics and coordination | Partly done. Patrol pairs, formation movement, alert halt/resume, relay metadata, and map positions exist; flanking, suppression signalling, and cover-bounding are not complete. | Cycle `141` is allocated, with tactic polish in Cycles `159`-`160`. |
| 17 | Save / session replay | Partly done. Cycle 116 completed guarded save/resume for route-bound checkpoint progress and checkpoint performance; full after-action session replay is not implemented. | Basic AAR is Cycle `133`; replay capture is Cycle `142`; replay/AAR integration is Cycle `174`. |
| 18 | Automated gameplay test harness | Partly done. There are smoke docs, capture tooling, and some earlier focused regression checks, but no broad programmatic gameplay harness for ballistics, collision, and observer detection. | Foundation is Cycle `136`; ballistics/collision/observer suites are Cycles `162`-`164`; CI integration is Cycle `188`. |
| 19 | Black Mountain and outer district texture expansion | Partly done. Cycle 112 delivered source-backed Black Mountain/West Basin/Belconnen material coverage and acceptance docs; REVIEW2's outer-district completeness audit remains open. | Cycle `143` is allocated, with density/content follow-up in Cycle `182`. |
| 20 | Audio mix validation across routes | Partly done. Cycle 109 delivered authored audio mix controls and smoke readouts; formal all-route validation under group observer pressure is not complete. | Cycle `134` is allocated, with polish in Cycle `156` and all-route regression in Cycle `180`. |

### Graphics Modernization Status

| # | REVIEW2 Modernization | Current Status | Cycle Allocation |
| --- | --- | --- | --- |
| G1 | Cascaded Shadow Maps | Not yet done; only readiness/profile metadata and the current single-shadow-map renderer are present. | Cycle `126` is allocated. |
| G2 | Full Temporal Anti-Aliasing | Not yet done; scoped-safe edge AA is implemented as the current alternative. | Cycle `138` is allocated. |
| G3 | SSAO / HBAO+ | Not yet done as a real screen-space AO pass. | Cycle `125` is allocated. |
| G4 | Tiled / Clustered Forward+ Lighting | Partly done as a bounded Forward+ start; not a GPU tiled/clustered light-list system. | Cycle `139` is allocated. |
| G5 | GPU-driven indirect rendering with GPU culling | Partly done for shadow casters; not implemented for material passes, terrain, LOD selection, or GPU-side culling. | Cycle `137` is allocated after Cycle `117` profiling. |
| G6 | Volumetric fog and light shafts | Not yet done. Current atmosphere/fog is scenario-authored physical sky and distance haze, not raymarched volumetrics. | Cycle `144` is allocated. |
| G7 | Screen-space reflections with Hierarchical-Z traversal | Partly done. Bounded SSR with IBL/probe fallback exists, but Hi-Z traversal and broader material-masked glossy reflection support are not complete. | Cycle `145` is allocated. |
| G8 | Procedural wind via compute shader | Partly done through scene-authored shader wind; not a compute-generated wind texture/noise system. | Cycle `127` is allocated for procedural foliage animation closeout. |
| G9 | Parallax Occlusion Mapping and detail normal blending | Not yet done. Texture/normal/roughness/AO assets exist for some materials, but POM and triplanar detail normal blending are not implemented. | Cycle `146` is allocated. |
| G10 | HDR display output and physical camera model | Not yet done. The roadmap mentions HDR/tone mapping as future renderer work, but HDR10/EDR output, aperture/shutter/ISO, depth of field, and bokeh are not implemented. | Cycle `147` is allocated. |

### Allocation Summary

- Already scheduled in the current eighty-cycle plan: `117` profiling, `118` vegetation interaction, `119` difficulty regression, `120` water, `121` LOS overlay, `122` mission scripting, `123` minimap accuracy, `124` packaging/distribution, `125` SSAO/HBAO, `126` CSM, `127` procedural foliage animation, and `128` final recovery audit.
- Completed slices that should not be overstated as full REVIEW2 closeout: Cycle `102` Forward+ start, Cycle `103` scoped-safe AA, Cycle `105` shadow-only indirect rendering, Cycle `107` bounded SSR/IBL, Cycle `109` audio mix, Cycle `110` firing feedback, Cycle `111` patrol-pair behavior, Cycle `112` district texture closeout, Cycle `113` multi-route playability, and Cycle `116` save/resume.
- Newly allocated REVIEW2/playability work now lands in Cycles `129`-`196`: route tutorial, simplified HUD, sniper kill objectives, recommended campaign, AAR, all-route audio validation, performance presets, gameplay harnesses, renderer modernizations, weapon animation, advanced observer tactics, replay, texture audit, release CI, final polish, tester feedback, and a fully playable game candidate.

### Added Playability Recommendations

| # | Recommendation | Cycle Allocation |
| --- | --- | --- |
| P1 | True playable mission fail/win loop | Cycle `148`, with stress testing in Cycle `187`. |
| P2 | Full sniper hit/kill objectives | Cycle `131`, with feedback polish in Cycle `150` and campaign integration in Cycle `173`. |
| P3 | Route tutorial | Cycle `129`, with usability closeout in Cycle `171`. |
| P4 | Simplified HUD mode | Cycle `130`, with accessibility/options in Cycle `152` and playtest closeout in Cycle `172`. |
| P5 | Notarized release package | Cycle `124`, dry run in Cycle `153`, external handoff in Cycle `176`, and RC lock in Cycle `191`. |
| P6 | Performance presets | Cycle `135`, QA in Cycle `154`, auto-detect in Cycle `177`, and RC performance lock in Cycle `190`. |
| P7 | All-route minimap validation | Cycle `123`, consistency audit in Cycle `155`, and all-route regression in Cycle `180`. |
| P8 | Audio mix validation | Cycle `134`, polish in Cycle `156`, and all-route regression in Cycle `180`. |
| P9 | Basic after-action report | Cycle `133`, comparison in Cycle `157`, and replay integration in Cycle `174`. |
| P10 | One polished recommended route campaign | Skeleton in Cycle `132`, content pass in Cycle `158`, vertical polish in Cycle `178`, and release candidate lock in Cycle `189`. |
