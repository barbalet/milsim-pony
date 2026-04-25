# Cycle 106 Smoke Test - SDF UI Rendering

## Goal

Verify that HUD, scope, and map labels use the scalable SDF-style text path. Critical UI text should keep crisp outlines and readable contrast at review scale without clipping or losing prior renderer features.

## Build Checks

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
Tools/package_release.sh --validate-only
Tools/capture_review.sh --validate-only
```

## Runtime Checks

- The HUD title reads `Cycle 106 SDF UI Rendering`.
- The release display reports `v1.6.0 (106)`.
- The route details include an `SDF UI:` line with mode, coverage, outline, shadow, and minimum-scale settings.
- Scope status, instruction, presentation, and shot-cadence labels remain crisp over the aperture and reticle.
- Map sector labels, road labels, and the north marker remain readable as the map scales.
- Time-of-day lighting, Forward+ diagnostic lights, scoped-safe anti-aliasing, physical atmosphere, and shadow indirect rendering remain active.

## Regression Notes

- Preserve Cycle 99 capture tooling.
- Preserve Cycle 100 landmark LOD switching.
- Preserve Cycle 101 scenario time-of-day lighting.
- Preserve Cycle 102 Forward+ diagnostic lights.
- Preserve Cycle 103 scoped-safe anti-aliasing.
- Preserve Cycle 104 physical atmosphere.
- Preserve Cycle 105 shadow-caster indirect rendering.
- A generated MSDF atlas remains a future expansion if custom font atlas generation becomes necessary.
