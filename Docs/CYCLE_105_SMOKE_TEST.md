# Cycle 105 Smoke Test - Shadow Indirect Rendering Prototype

## Goal

Verify that the renderer has a fallback-safe indirect rendering prototype. Shadow-casting object commands should be encoded into a per-frame `MTLIndirectCommandBuffer` and executed during the sun shadow pass, while terrain and material draws remain on the proven direct path.

## Build Checks

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
Tools/package_release.sh --validate-only
Tools/capture_review.sh --validate-only
```

## Runtime Checks

- The HUD title reads `Cycle 105 Shadow Indirect Rendering Prototype`.
- The release display reports `v1.5.0 (105)`.
- The route details include an `Indirect Rendering:` line with ICB mode, draw class, capacity, and coverage note.
- Scope view keeps stable shadows on Woden, Civic, West Basin, Black Mountain, and Belconnen silhouettes.
- Time-of-day lighting, Forward+ diagnostic lights, scoped-safe anti-aliasing, and physical atmosphere remain active.

## Regression Notes

- Preserve Cycle 99 capture tooling.
- Preserve Cycle 100 landmark LOD switching.
- Preserve Cycle 101 scenario time-of-day lighting.
- Preserve Cycle 102 Forward+ diagnostic lights.
- Preserve Cycle 103 scoped-safe anti-aliasing.
- Preserve Cycle 104 physical atmosphere.
- Material-pass indirect draws, GPU culling, and indirect argument generation remain later expansions after capture and profiling evidence.
