# Cycle 104 Smoke Test - Physical Atmosphere Baseline

## Goal

Verify that the renderer uses a scene-authored physical atmosphere baseline. The active time-of-day sun should drive sky color, horizon lift, and distance haze through deterministic Rayleigh, Mie, ozone, turbidity, and density controls.

## Build Checks

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
Tools/package_release.sh --validate-only
Tools/capture_review.sh --validate-only
```

## Runtime Checks

- The HUD title reads `Cycle 104 Physical Atmosphere Baseline`.
- The release display reports `v1.4.0 (104)`.
- The route details include a `Physical Atmosphere:` line with model, Rayleigh, Mie, ozone, turbidity, and density controls.
- Sky clear color, object fog, and terrain haze remain consistent while scoped and unscoped.
- Time-of-day lighting, Forward+ diagnostic lights, and scoped-safe anti-aliasing remain active.

## Regression Notes

- Preserve Cycle 99 capture tooling.
- Preserve Cycle 100 landmark LOD switching.
- Preserve Cycle 101 scenario time-of-day lighting.
- Preserve Cycle 102 Forward+ diagnostic lights.
- Preserve Cycle 103 scoped-safe anti-aliasing.
- Full volumetric clouds, IBL, and render-graph ownership remain later renderer gates.
