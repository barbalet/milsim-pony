# Rendering Roadmap

This roadmap turns the current rendering feedback into a repo-specific implementation plan for `milsim-pony`.

The intent is to improve the current Metal renderer without discarding the existing architecture:

- `SwiftUI shell` owns app and input flow.
- `GameRenderer` owns Metal submission.
- `BootstrapScene` owns scene package assembly and visibility decisions.
- `WorldSceneData` owns what world JSON can describe.
- `GameCore` remains authoritative for gameplay and simulation.

## REVIEW Recovery Priority

The stricter Cycle 98 REVIEW audit supersedes the older loose sequencing below when there is a conflict. Renderer items that were previously treated as deferred now have fixed recovery slots:

| Cycle | Renderer Work |
| --- | --- |
| `100` | Actual distant-building LOD/impostor renderer switching. |
| `101` | Dynamic time-of-day lighting controls complete; scenario time now drives sun, sky/fog, haze, ambient/diffuse light, and shadow coverage. |
| `102` | Forward+/clustered lighting implementation start complete; scene dynamic lights feed a bounded per-drawable shader light list. |
| `103` | Scoped-safe anti-aliasing prototype complete; depth-aware post edge AA avoids temporal ghosting in scope. |
| `104` | Physically based atmosphere and sky baseline complete; scene Rayleigh/Mie/ozone controls now feed time-of-day sky and haze. |
| `105` | GPU-driven indirect rendering prototype complete for shadow-casting object draws, using a fallback-safe per-frame ICB. |
| `106` | SDF font/UI rendering complete for HUD, scope, and map labels using a scalable outlined text path. |
| `107` | SSR with IBL/probe fallback complete as a bounded postprocess reflection prototype. |
| `108` | Render graph/frame graph scaffolding complete for the current shadow, scene, and presentation passes. |
| `125` | SSAO/HBAO-class closeout. |
| `126` | CSM implementation closeout. |
| `127` | Procedural foliage animation closeout. |

No renderer modernization from REVIEW.md should remain in a "future" bucket beyond Cycle `128` without a new explicit review decision.

## Current Renderer Baseline

The renderer already has a clean split between world assembly and GPU drawing, but it is still visually closer to a strong prototype than a production material pipeline.

- Solid objects are shaded with `vertex color * one texture * one scenario-driven directional light * optional local dynamic lights * physical-atmosphere fog`, then postprocessed with depth-aware edge anti-aliasing and bounded SSR/probe reflection in `MilsimPonyGame/Renderer/BootstrapShaders.metal`.
- Shadow-casting object draws now have an indirect-command prototype in `MilsimPonyGame/Renderer/GameRenderer.swift`; material draws and terrain remain direct until profiling justifies broader ICB/GPU-culling work.
- The current shadow, scene geometry, and presentation postprocess passes are represented by a lightweight frame graph descriptor with imported/transient resources and read-before-write validation in `MilsimPonyGame/Renderer/GameRenderer.swift`.
- Terrain now shares the scene physical-atmosphere clear color and haze controls, but it is still color-driven rather than material-driven in `MilsimPonyGame/Renderer/GameRenderer.swift`.
- Scene data only exposes flat colors for `terrainPatches`, `roadStrips`, and `grayboxBlocks` in `MilsimPonyGame/World/WorldSceneData.swift`.
- `SceneTextureKey` only exposes four shared albedo textures in `MilsimPonyGame/Renderer/BootstrapScene.swift`.
- Scoped stability is currently driven mostly by `drawDistanceMultiplier` and view-dot culling in `MilsimPonyGame/Renderer/BootstrapScene.swift`.
- The OBJ loader currently ignores UVs and texture map references, so authored assets cannot yet take real albedo/normal/roughness/AO inputs in `MilsimPonyGame/Renderer/BootstrapScene.swift`.

## Historical Sequencing

The original recommended order for this repo was:

1. Shared groundwork for scene/material schema.
2. Cascaded sun shadows.
3. Real material inputs.
4. Tone mapping, exposure, and light grading.
5. Scope stability in two passes:
   `SMAA + HLOD/impostors` first, `TAA` second if ghosting risk is under control.
6. Decals and landmark-specific material breakup.

That order was deliberate, but it is now subordinate to the REVIEW recovery priority above:

- Shadows improve readability immediately with the least asset churn.
- Materials are not worth doing properly until the schema and asset path can carry them.
- Tone mapping only pays off after lighting and materials become more physically plausible.
- TAA before stable HLOD often makes scoped long-range viewing worse, not better.
- Decals are most valuable after the base material system is in place.

## Shared Groundwork

### Goal

Create the data and runtime seams needed by all later phases, without changing the visual output yet.

### First files to touch

- `MilsimPonyGame/World/WorldSceneData.swift`
- `MilsimPonyGame/Renderer/BootstrapScene.swift`
- `MilsimPonyGame/Renderer/RenderMath.swift`
- `MilsimPonyGame/Renderer/GameRenderer.swift`
- `MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json`
- `MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Sectors/woden_scope_perch_sector.json`
- `MilsimPonyGame/Assets/Textures/README.md`

### Changes

- Add render-facing scene configuration types:
  - `ShadowConfiguration`
  - `PostProcessConfiguration`
  - `MaterialSetConfiguration`
  - `LODConfiguration`
  - `DecalConfiguration`
- Extend drawable metadata so the renderer knows:
  - whether a drawable casts shadows
  - whether it receives shadows
  - which material set it uses
  - whether it is a full mesh, low-LOD mesh, or impostor
- Replace implicit material routing such as `textureKey(for:)` with explicit world-data assignments.
- Keep defaults generous so old scene JSON still loads while the schema rolls forward.

### Exit gate

- The scene builder can decode render settings and material references from JSON.
- Existing world data still loads with defaults.
- No visual regressions yet; this is a plumbing pass.

## Step 1: Cascaded Sun Shadows For Terrain, Buildings, And Props

### Goal

Add stable directional-light shadows that remain useful in the 4x scope path.

### First files to touch

- `MilsimPonyGame/Renderer/RenderMath.swift`
- `MilsimPonyGame/Renderer/GameRenderer.swift`
- `MilsimPonyGame/Renderer/BootstrapShaders.metal`
- `MilsimPonyGame/Renderer/BootstrapScene.swift`
- `MilsimPonyGame/World/WorldSceneData.swift`
- `MilsimPonyGame/Renderer/MetalGameView.swift`

### Implementation order

1. Add one shadow map first.
2. Promote that to three cascades once sampling, bias, and receiver rules are correct.
3. Tune scoped cascade splits and bias with Canberra long sightlines.

### Concrete work

- In `RenderMath.swift`:
  - add shadow matrix types and cascade split helpers
  - add light-view and orthographic projection helpers
- In `GameRenderer.swift`:
  - allocate depth textures for cascades
  - render a shadow pass for terrain, graybox, and asset meshes
  - bind cascade transforms and shadow textures into the main draw path
  - use tighter near and far logic for scope mode so cascade precision holds up
- In `BootstrapShaders.metal`:
  - sample the cascade shadow maps
  - apply shadow attenuation to the object lighting path
- In `BootstrapScene.swift`:
  - add `castsShadow` and `receivesShadow` to `SceneDrawable`
  - set sane defaults:
    - terrain: cast and receive
    - roads: receive, usually not cast
    - graybox blocks: cast and receive
    - authored assets: cast and receive
    - helper shadows and HUD markers: neither
- In `WorldSceneData.swift`:
  - add optional override flags for per-element shadow behavior
- In `MetalGameView.swift`:
  - only adjust view formats if the chosen shadow path requires related depth or sample-count changes

### Acceptance

- Midday sun produces readable building and terrain shadows across Woden, Civic, and Belconnen.
- Scope mode does not shimmer badly while panning over skyline silhouettes.
- Temporary fake ground shadows from `grayboxShadowDrawable` can be removed or reduced once real shadows are trustworthy.

## Step 2: Real Material Inputs For Albedo, Normal, Roughness, And AO

### Goal

Replace the current shared albedo-only surface model with explicit material sets for roads, terrain, facades, props, and landmark surfaces.

### First files to touch

- `MilsimPonyGame/World/WorldSceneData.swift`
- `MilsimPonyGame/Renderer/BootstrapScene.swift`
- `MilsimPonyGame/Renderer/RenderMath.swift`
- `MilsimPonyGame/Renderer/GameRenderer.swift`
- `MilsimPonyGame/Renderer/BootstrapShaders.metal`
- `MilsimPonyGame/Assets/Textures/README.md`
- `MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json`
- `MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Sectors/woden_scope_perch_sector.json`

### Critical prerequisite

The OBJ loader must be upgraded first. Right now it parses positions and normals, but not usable UVs or texture map references. That means authored assets cannot benefit fully from real materials until `OBJAssetLoader` is extended.

### Concrete work

- In `WorldSceneData.swift`:
  - add material references to:
    - `TerrainPatchConfiguration`
    - `RoadStripConfiguration`
    - `GrayboxBlockConfiguration`
    - `AssetInstanceConfiguration`
  - define a scene-level material table or reusable named material sets
- In `BootstrapScene.swift`:
  - replace `SceneTextureKey` with a richer material binding model
  - extend `SceneDrawable` to carry:
    - albedo map key
    - normal map key
    - roughness map key
    - AO map key
    - scalar overrides for roughness and AO when a map is absent
  - remove the current `textureKey(for:)` fallback as the primary routing mechanism
  - upgrade `assetDrawable()` and `OBJAssetLoader` to parse:
    - `vt`
    - UV indices in faces
    - diffuse texture references from `.mtl`
  - keep triplanar or generated fallback options for terrain and rough procedural surfaces
- In `RenderMath.swift`:
  - add tangent-space support to `SceneVertex` if tangent-space normal mapping is chosen
- In `GameRenderer.swift`:
  - load grouped material textures instead of one shared texture dictionary
  - provide fallback neutral maps:
    - white albedo fallback
    - flat normal fallback
    - mid roughness fallback
    - white AO fallback
- In `BootstrapShaders.metal`:
  - move from the current diffuse-only lighting model to a PBR-lite or full GGX path
  - sample albedo, normal, roughness, and AO
  - preserve current fog and sun direction logic while the BRDF changes
- In `Assets/Textures/README.md` and `Assets/Textures/Final/`:
  - move from one-file-per-surface naming to grouped sets such as:
    - `woden_concrete_albedo.png`
    - `woden_concrete_normal.png`
    - `woden_concrete_roughness.png`
    - `woden_concrete_ao.png`

### Acceptance

- Roads, curbs, towers, podiums, retaining walls, and props no longer read as the same surface family.
- Authored OBJ props use real UV-based textures instead of flat material colors.
- Distant landmarks stay readable because roughness and normal variation survive scope magnification.

## Step 3: Tone Mapping, Exposure, And Light Color Grading

### Goal

Move the frame from direct LDR output to an HDR-to-LDR pipeline with scene-tunable exposure and grading.

### First files to touch

- `MilsimPonyGame/Renderer/GameRenderer.swift`
- `MilsimPonyGame/Renderer/BootstrapShaders.metal`
- `MilsimPonyGame/Renderer/MetalGameView.swift`
- `MilsimPonyGame/Renderer/BootstrapScene.swift`
- `MilsimPonyGame/World/WorldSceneData.swift`
- `MilsimPonyGame/Gameplay/GameSession.swift`

### Concrete work

- In `GameRenderer.swift`:
  - render the main scene into an HDR intermediate target
  - add a fullscreen post pass for:
    - tone mapping
    - exposure application
    - color grading
  - keep the swapchain drawable as the final LDR presentation target
  - store exposure history if auto exposure is used
- In `BootstrapShaders.metal`:
  - keep lighting in linear HDR values
  - stop baking final presentation contrast into the material shader
- In `MetalGameView.swift`:
  - revisit output format and sample-count choices after the HDR path is in place
- In `WorldSceneData.swift`:
  - add optional post-process scene settings:
    - exposure bias
    - min and max exposure
    - white point
    - grading tint
    - contrast and saturation
- In `BootstrapScene.swift`:
  - decode and publish post-process settings to the renderer
- In `GameSession.swift`:
  - surface debug overlay lines for exposure mode and current value while tuning

### Acceptance

- Bright Canberra sky no longer forces the ground plane into flat haze.
- Scoped observation remains legible when the player alternates between open sky and dark structure silhouettes.
- Different districts can carry slightly different exposure and grade choices without forking the renderer.

## Step 4: Scope Stability With SMAA Or TAA Plus Better Distant HLOD And Impostors

### Goal

Reduce long-range shimmer, crawling edges, and hard LOD pops in the sniper-view path.

### Recommendation

For this repo, implement this step in two sub-phases:

1. `SMAA + HLOD/impostors`
2. `TAA` only if the history path behaves well in scope mode

That recommendation is specific to `milsim-pony`: sniper optics punish TAA ghosting more than ordinary third-person cameras do.

### First files to touch

- `MilsimPonyGame/Renderer/GameRenderer.swift`
- `MilsimPonyGame/Renderer/RenderMath.swift`
- `MilsimPonyGame/Renderer/BootstrapShaders.metal`
- `MilsimPonyGame/Renderer/BootstrapScene.swift`
- `MilsimPonyGame/World/WorldSceneData.swift`
- `MilsimPonyGame/Gameplay/GameSession.swift`
- `MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json`
- `MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Sectors/woden_scope_perch_sector.json`

### Sub-phase A: SMAA And HLOD/Impostors

- In `BootstrapScene.swift`:
  - extend `SceneDrawable` with LOD and impostor metadata
  - add selection rules that choose:
    - full mesh nearby
    - reduced mesh at medium range
    - impostor card or skyline proxy at long range
  - make scope mode bias toward more stable far representations instead of just multiplying draw distance
- In `WorldSceneData.swift`:
  - add optional HLOD or impostor config on assets and graybox landmarks
  - allow sector-level landmark proxies
- In `GameRenderer.swift`:
  - add the anti-aliasing pass
  - add any additional buffers required for edge detection or resolved color history
- In `RenderMath.swift`:
  - add camera jitter utilities only if TAA follows immediately
- In `GameSession.swift`:
  - expose a debug mode showing current AA mode, visible LODs, and impostor counts

### Sub-phase B: TAA

- In `GameRenderer.swift`:
  - add previous-frame history textures
  - add reprojection and velocity support
  - gate TAA sharpening differently for scoped and unscoped modes
- In `BootstrapShaders.metal`:
  - output motion vectors if per-pixel velocity is chosen
- In `RenderMath.swift`:
  - add jitter sequence and reprojection helpers

### Acceptance

- Skyline towers and ridgelines shimmer less while strafing and scoped panning.
- Woden towers, Telstra Tower, and Belconnen silhouettes do not pop distractingly at LOD boundaries.
- Scope mode remains crisp enough for landmark validation and future sniper use.

## Step 5: Decals And Landmark-Specific Material Breakup For Roads, Curbs, Walls, And Roofs

### Goal

Break the current shared-material look by layering road markings, curb edges, facade accents, roof treatments, and Canberra-specific wear patterns on top of the new material system.

### First files to touch

- `MilsimPonyGame/World/WorldSceneData.swift`
- `MilsimPonyGame/Renderer/BootstrapScene.swift`
- `MilsimPonyGame/Renderer/GameRenderer.swift`
- `MilsimPonyGame/Renderer/BootstrapShaders.metal`
- `MilsimPonyGame/Assets/Textures/README.md`
- `MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Sectors/woden_scope_perch_sector.json`
- `MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Sectors/city_hill_civic_sector.json`
- `MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Sectors/black_mountain_belconnen_sector.json`

### Concrete work

- In `WorldSceneData.swift`:
  - add `DecalConfiguration`
  - add optional material overrides for wall, roof, curb, shoulder, and facade surfaces
- In `BootstrapScene.swift`:
  - build decal drawables or projected decal instances
  - add landmark-specific material overrides during sector build
  - stop routing all structures to `.concrete` by name alone
- In `GameRenderer.swift`:
  - add a decal pass that respects depth and blends into the material response
  - keep the first version simple:
    - mesh decals or projected decals on roads and walls
    - no need to start with a fully general decal editor
- In `BootstrapShaders.metal`:
  - blend decal albedo, normal, and roughness contributions
- In world JSON:
  - assign district-specific breakup to:
    - roads and shoulders
    - curbs and medians
    - podiums and retaining walls
    - tower facades and rooflines
- In `Assets/Textures/README.md` and `Assets/Textures/Final/`:
  - add naming and provenance rules for decal atlases and district-specific variants

### Acceptance

- Roads read as layered road systems instead of one asphalt sheet.
- Walls, roofs, and landmark facades stop collapsing into the same concrete family.
- District transitions become readable from material language, not only geometry.

## Suggested Delivery Slices

If this work is scheduled across cycles, the least risky breakdown is:

1. `Groundwork + single shadow map`
2. `Cascades + receiver rules + remove fake shadow quads`
3. `Material schema + OBJ UV upgrade + albedo/normal`
4. `Roughness/AO + HDR tone mapping`
5. `SMAA + HLOD/impostors for key landmarks`
6. `Decals + district-specific material breakup`
7. `Optional TAA` if scope ghosting stays acceptable

## First Working Set To Open This Week

If the next implementation pass starts now, these are the first files worth opening together:

- `MilsimPonyGame/Renderer/GameRenderer.swift`
- `MilsimPonyGame/Renderer/BootstrapShaders.metal`
- `MilsimPonyGame/Renderer/BootstrapScene.swift`
- `MilsimPonyGame/Renderer/RenderMath.swift`
- `MilsimPonyGame/World/WorldSceneData.swift`
- `MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json`
- `MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Sectors/woden_scope_perch_sector.json`
- `MilsimPonyGame/Assets/Textures/README.md`

That set covers the renderer, the runtime scene bridge, the world-data schema, the current live scene, and the current texture library contract.
