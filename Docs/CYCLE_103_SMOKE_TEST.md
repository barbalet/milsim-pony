# Cycle 103 Smoke Test - Scoped-Safe Anti-Aliasing

## Goal

Verify that the renderer has a scoped-safe anti-aliasing prototype. The postprocess pass should smooth high-contrast edges while rejecting blends across depth discontinuities so scope silhouettes do not gain temporal ghosting.

## Build Checks

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
Tools/package_release.sh --validate-only
Tools/capture_review.sh --validate-only
```

## Runtime Checks

- The HUD title reads `Cycle 103 Scoped-Safe Anti-Aliasing`.
- The release display reports `v1.3.0 (103)`.
- The route details include an `Anti-Aliasing:` line with mode, edge threshold, blend strength, depth rejection, and scope-stability rule.
- Scope view remains readable on Woden, Civic, West Basin, Black Mountain, and Belconnen silhouettes.
- Distant LOD swapping and Forward+ diagnostic lights remain active while AA is enabled.
- No temporal-history ghosting should appear because the Cycle 103 path is depth-aware post edge AA, not frame-history TAA.

## Regression Notes

- Preserve Cycle 99 capture tooling.
- Preserve Cycle 100 landmark LOD switching.
- Preserve Cycle 101 scenario time-of-day lighting.
- Preserve Cycle 102 Forward+ diagnostic lights.
- Full temporal reprojection can still be evaluated later if scoped shimmer persists, but Cycle 103 closes the REVIEW item with a scoped-safe anti-aliasing alternative.
