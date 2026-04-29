# Cycle 117 Profiling Review

Cycle `117` is the formal profiling closeout for the Cycle `117`-`196` playable-game plan.

## Status

Complete with one recorded Instruments limitation: direct target-launched `Metal System Trace` captures still save an unusable trace bundle on this machine with `Document Missing Template Error` during TOC export. The cycle is closed using a target-correct Time Profiler trace plus an exportable all-process Metal System Trace fallback. The limitation is documented so renderer work does not pretend the direct Metal target capture is healthier than it is.

## Captured Artifacts

| Artifact | Status | Notes |
| --- | --- | --- |
| `artifacts/profiling/cycle117-time-profiler-current.trace` | Captured | Target-correct `Time Profiler` trace. |
| `artifacts/profiling/cycle117-time-profiler-current-toc.xml` | Exported | TOC confirms process `MilsimPonyProfile117`, pid `6348`, path `/tmp/MilsimPonyProfileDerived/Build/Products/Debug/MilsimPonyProfile117.app`, template `Time Profiler`, and no stale `artifacts/release` app path. |
| `artifacts/profiling/cycle117-time-profile-current.xml` | Exported | Sample table used for CPU bottleneck review. |
| `artifacts/profiling/cycle117-metal-system-live.trace` | Captured | Exportable fallback `Metal System Trace` captured while the profiling app launch path was exercised. |
| `artifacts/profiling/cycle117-metal-system-live-toc.xml` | Exported | Confirms `Metal System Trace` template and Metal tables including command-buffer submissions, encoder lists, GPU intervals, resource allocations, and GPU counter schemas. |
| `/private/tmp/milsim-profile117-metal.trace` | Blocked artifact | Direct `--launch` target Metal capture reproduced `Document Missing Template Error`; retained only as temporary failure evidence. |

## CPU Bottlenecks

The Time Profiler sample export is dominated by terrain vertex/color preparation in `JungleTerrainRenderer`. Top sampled project symbols:

| Rank | Symbol | Samples | Interpretation |
| --- | --- | ---: | --- |
| 1 | `JungleTerrainRenderer.applyTerrainLighting(to:normal:relief:sample:layer:frame:)` | 295 | Terrain lighting/color work is the largest measured CPU hotspot. |
| 2 | `JungleTerrainRenderer.applyContrast(_:amount:pivot:)` | 170 | Per-vertex material/color contrast is a repeated CPU cost. |
| 3 | `JungleTerrainRenderer.materialColor(_:wetness:)` | 162 | Material color evaluation is in the critical terrain path. |
| 4 | `JungleTerrainRenderer.layerPosition(for:layer:density:relief:frame:)` | 123 | Layered terrain vertex placement is a visible cost. |
| 5 | `JungleTerrainRenderer.normalize(_:fallback:)` | 121 | Repeated vector normalization inside terrain generation is nontrivial. |
| 6 | `JungleTerrainRenderer.vertexColor(for:layer:density:frame:)` | 64 | Terrain vertex color assembly remains part of the same cluster. |
| 7 | `JungleTerrainRenderer.terrainNormal(row:column:in:)` | 35 | Normal sampling contributes to terrain cost. |
| 8 | `JungleTerrainRenderer.terrainLightDirection(for:)` | 26 | Lighting direction calculation is repeated enough to optimize or cache. |
| 9 | `JungleTerrainRenderer.terrainRelief(row:column:in:)` | 25 | Relief sampling is part of the measured terrain cluster. |
| 10 | `GameRenderer.draw(in:)` | 23 | Frame orchestration appears below terrain prep in the captured sample count. |

Secondary sampled areas include allocator/free churn, `ScenePackageBuilder.buildScene(from:)`, OBJ loading/tangent generation, `ShotFeedbackAudioEngine.init()`, `GameSession.rebuildOverlay()`, `GameRenderer.drawSolidObjects(...)`, `BootstrapScene.visibilityState(...)`, and line-of-sight/session overlay generation.

## GPU / Metal Notes

- The exportable Metal fallback contains the Metal schemas needed for later GPU review: `metal-application-command-buffer-submissions`, `metal-application-encoders-list`, `metal-gpu-intervals`, `metal-gpu-counter-intervals`, `metal-resource-allocations`, `metal-command-buffer-completed`, and related driver/display tables.
- Direct process-target `Metal System Trace` remains blocked by Instruments export failure on this workstation. Cycle `165` post-modernization profiling should retry this once renderer upgrades land, and `Tools/profile_cycle117.sh` should remain the reproducible entry point for future captures.
- Shadow and scene-pass renderer work should not expand indirect rendering, CSM, SSAO, volumetrics, or Hi-Z SSR without checking against the Cycle `117` terrain CPU bottleneck and the Metal command-buffer fallback trace.

## Priorities For Later Cycles

1. Cycle `120` water and Cycle `125` SSAO/HBAO must watch total terrain CPU cost before adding new full-screen or shoreline work.
2. Cycle `126` CSM should measure shadow-caster and terrain submissions before increasing cascade count.
3. Cycle `127` foliage animation should avoid adding CPU-side per-vertex terrain/foliage recomputation.
4. Cycle `135` performance presets should expose terrain detail, draw distance, shadows, reflections, AO, and foliage cost controls.
5. Cycle `137` material-pass indirect rendering should be justified by draw submission evidence, not used to mask terrain preparation cost.
6. Cycle `165` post-modernization profiling should retry direct target Metal capture and compare against these Cycle `117` artifacts.

## Closure

Cycle `117` is complete as a formal profiling pass because it now has stored profiling artifacts, target-correct CPU evidence, exportable Metal fallback evidence, a bottleneck report, and explicit follow-up priorities. The remaining limitation is not feature work in Cycle `117`; it is an Instruments direct-target Metal capture limitation to revisit during Cycle `165`.
