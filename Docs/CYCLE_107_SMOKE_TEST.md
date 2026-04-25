# Cycle 107 Smoke Test - SSR IBL Reflection Prototype

## Goal

Verify that the renderer has a bounded screen-space reflection path with an IBL/probe fallback. Lake and glass reads should gain reflection response without destabilizing scope readability, physical atmosphere, SDF UI, or the Cycle 105 shadow indirect path.

## Build Checks

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
Tools/package_release.sh --validate-only
Tools/capture_review.sh --validate-only
```

## Runtime Checks

- The HUD title reads `Cycle 107 SSR IBL Reflection Prototype`.
- The release display reports `v1.7.0 (107)`.
- The route details include a `Water Reflection:` line with SSR active, probe fallback, SSR strength, and probe strength.
- West Basin water gains a subtle reflected sky/scene response while retaining readable shoreline motion.
- Scope view over West Basin, Civic, Black Mountain, and Belconnen remains stable without reflection shimmer dominating the silhouette.
- SDF UI, physical atmosphere, scoped-safe anti-aliasing, Forward+ diagnostic lights, and shadow indirect rendering remain active.

## Regression Notes

- Preserve Cycle 99 capture tooling.
- Preserve Cycle 100 landmark LOD switching.
- Preserve Cycle 101 scenario time-of-day lighting.
- Preserve Cycle 102 Forward+ diagnostic lights.
- Preserve Cycle 103 scoped-safe anti-aliasing.
- Preserve Cycle 104 physical atmosphere.
- Preserve Cycle 105 shadow-caster indirect rendering.
- Preserve Cycle 106 SDF-style HUD, scope, and map text.
- Material-masked SSR and richer reflection probes remain future expansions after render graph/material-ID support.
