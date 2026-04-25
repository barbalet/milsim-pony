# Cycle 108 Smoke Test - Render Graph Scaffolding

## Goal

Verify that the renderer exposes a real frame-graph scaffold for the current pass order. The existing shadow, scene, and presentation postprocess passes should be represented as graph nodes with explicit imported/transient resources and dependency validation.

## Build Checks

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
Tools/package_release.sh --validate-only
Tools/capture_review.sh --validate-only
```

## Runtime Checks

- The HUD title reads `Cycle 108 Render Graph Scaffolding`.
- The release display reports `v1.8.0 (108)`.
- The route details include a `Render Graph:` line with pass count, transient resources, imported resources, and pass order.
- Metal capture labels use the graph pass names: `SunShadowPass`, `SceneGeometryPass`, and `PresentationPostProcessPass`.
- SSR/IBL reflections, SDF UI, physical atmosphere, scoped-safe anti-aliasing, Forward+ lights, and shadow indirect rendering remain active.

## Regression Notes

- Preserve Cycle 99 capture tooling.
- Preserve Cycle 100 landmark LOD switching.
- Preserve Cycle 101 scenario time-of-day lighting.
- Preserve Cycle 102 Forward+ diagnostic lights.
- Preserve Cycle 103 scoped-safe anti-aliasing.
- Preserve Cycle 104 physical atmosphere.
- Preserve Cycle 105 shadow-caster indirect rendering.
- Preserve Cycle 106 SDF-style HUD, scope, and map text.
- Preserve Cycle 107 SSR/IBL reflection prototype.
- Resource aliasing, graph-managed material masks, and richer pass scheduling remain future expansions.
