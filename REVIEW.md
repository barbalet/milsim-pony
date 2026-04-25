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
