# Cycle 101 Smoke Test - Dynamic Time-Of-Day System

## Goal

Verify that the Canberra scene no longer treats time of day as planning text only. Scenario data should drive the renderer sun angle, sky color, fog tint, haze, ambient/diffuse light, shadow strength, and shadow coverage.

## Build Checks

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
Tools/package_release.sh --validate-only
Tools/capture_review.sh --validate-only
```

## Runtime Checks

- The HUD title reads `Cycle 101 Dynamic Time-Of-Day System`.
- The release display reports `v1.1.0 (101)`.
- The route details include a `Time Of Day:` line with the authored 16.75 hour, sun azimuth/elevation, ambient/diffuse values, and shadow multiplier.
- The `Lighting Plan:` line names the dynamic scenario-lighting path and points to this smoke test.
- In live and scope views, the scene reads as late-afternoon light: warmer horizon/fog, lower sun direction, stronger directional contrast, and longer shadow coverage than the previous static daylight setup.
- Scope mode remains readable across Woden, Civic, West Basin, Black Mountain, and Belconnen landmark silhouettes.

## Regression Notes

- Preserve Cycle 99 capture tooling.
- Preserve Cycle 100 landmark LOD switching and impostor readouts.
- Treat physical atmosphere as Cycle 104 work; Cycle 101 closes configurable scenario time and lighting inputs.
