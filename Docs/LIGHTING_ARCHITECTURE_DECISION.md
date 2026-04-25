# Lighting Architecture Decision

Cycle `98` recorded the fixed-daylight renderer decision. Cycle `101` promotes the time-of-day portion of that decision into configurable renderer inputs. Cycle `102` starts the Forward+/clustered lighting path with scene-authored dynamic lights and bounded forward shader accumulation. Cycle `103` adds a scoped-safe postprocess anti-aliasing alternative with depth rejection. Cycle `104` adds a physical atmosphere baseline tied to the active time-of-day sun. Cycle `105` adds a fallback-safe indirect command path for shadow-casting object draws. Cycle `106` adds scalable SDF-style UI text for HUD, scope, and map labels. Cycle `107` adds bounded postprocess SSR with sky-probe fallback for lake/glass readability. Cycle `108` adds render graph/frame graph scaffolding for the current shadow, scene, and presentation passes. Cycle `109` keeps those renderer decisions stable while closing the audio-system REVIEW item with scene-authored mix controls. The remaining renderer items stay scheduled in the Cycle `99`-`128` recovery plan in [DEVELOPMENT_BACKLOG.md](/Users/barbalet/github/milsim-pony/Docs/DEVELOPMENT_BACKLOG.md).

## Decision

The current shipping path remains a data-authored single-sun model:

- `timeOfDay`, `sky`, `sun`, `atmosphere`, `physicalAtmosphere`, `indirectRendering`, `sdfUI`, `renderGraph`, `audioMix`, `shadow`, `postProcess`, `antiAliasing`, and diagnostic `dynamicLights` stay scene-authored.
- Cycle 101 closes the configurable time-of-day gap by letting scenario time drive sun angle, sky/fog colors, haze, ambient/diffuse light, shadow strength, and shadow coverage.
- Cycle 102 starts clustered/Forward+ lighting with CPU-side drawable light selection and up to four local point lights accumulated in the object shader.
- Cycle 103 uses depth-aware postprocess edge anti-aliasing instead of temporal history so scope silhouettes do not ghost.
- Cycle 104 derives clear color, horizon lift, and distance haze from scene-authored Rayleigh/Mie/ozone controls tied to the time-of-day sun.
- Cycle 105 executes shadow-casting object commands through a per-frame `MTLIndirectCommandBuffer`, with direct draw fallback if the ICB path is unavailable.
- Cycle 106 renders critical HUD, scope, and map labels through a scalable SDF-style outline path for crisp capture readability.
- Cycle 107 blends bounded screen-space reflection samples with a sky-probe fallback in postprocess for lake/glass material read.
- Cycle 108 represents the current shadow, scene geometry, and presentation postprocess passes as a frame graph scaffold with imported/transient resources and dependency validation.
- Cycle 109 routes audio through scene-authored category gains and a persisted user master gain while retaining the renderer baselines above.

## Current Scenario

- Scenario: `Canberra late-afternoon review`
- Time of day: `16:45 late-summer low sun`
- Sun policy: scenario time controls the single renderer sun for sky, shadow, terrain, and material lighting.
- Atmosphere policy: the `timeOfDay` block supplies the sun and base fog/sky colors; `physicalAtmosphere` supplies Rayleigh, Mie, ozone, turbidity, horizon lift, and density controls for the renderer baseline.
- Forward+ policy: diagnostic point lights are selected per drawable on CPU and layered over the single-sun path until higher light counts justify a full tiled/cluster grid.
- Anti-aliasing policy: scoped-safe edge smoothing runs after scene render with depth rejection and no temporal history.
- Indirect policy: object shadow casters use a CPU-filled ICB in the sun shadow pass; terrain, material draws, GPU command generation, and GPU culling remain direct/deferred until profiling justifies the next expansion.
- Render graph policy: current pass ordering is mirrored by a lightweight graph descriptor; resource aliasing and automatic scheduling wait until more renderer passes are promoted into graph nodes.

## Recovery Prerequisites

The following measurements still matter, but they must support the allocated recovery cycles rather than block them indefinitely:

- Frame timing with the current scene, route, map, and scope readouts active.
- CSM profile evidence for cascade split targets, coverage, and bias.
- LOD/reflection evidence for skyline shimmer and water/reflection stability.
- Dynamic light count proof from real gameplay needs rather than speculative renderer design.
- Pass-count pressure from CSM, postprocess, capture, water reflection, and future lighting work, now measured against the Cycle 108 frame graph scaffold.

## Next Renderer Gates

- Cycle `101`: dynamic time-of-day implementation complete; keep it in smoke/capture regression.
- Cycle `102`: Forward+/clustered lighting implementation start complete; keep diagnostic lights in smoke/capture regression.
- Cycle `103`: scoped-safe anti-aliasing implementation complete; keep it in scope/capture regression.
- Cycle `104`: physically based atmosphere/sky baseline complete; keep it in time-of-day and scope/capture regression.
- Cycle `105`: GPU-driven indirect rendering prototype complete for shadow casters; keep it in frame timing and shadow capture regression.
- Cycle `106`: SDF font/UI rendering complete for HUD, scope, and map labels; keep it in capture readability regression.
- Cycle `107`: SSR/IBL reflection prototype complete for lake/glass readability; keep it in West Basin and scope capture regression.
- Cycle `108`: render graph/frame graph scaffolding complete for current pass/resource ordering; expand it only as new renderer passes become real.
