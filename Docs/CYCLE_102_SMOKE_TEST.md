# Cycle 102 Smoke Test - Forward+ Lighting Start

## Goal

Verify that the renderer has moved beyond a single static sun-only object-lighting path. Scene-authored diagnostic dynamic lights should feed the forward object shader while the Cycle 101 scenario sun and time-of-day lighting remain intact.

## Build Checks

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
Tools/package_release.sh --validate-only
Tools/capture_review.sh --validate-only
```

## Runtime Checks

- The HUD title reads `Cycle 102 Forward+ Lighting Start`.
- The release display reports `v1.2.0 (102)`.
- The `Lighting Plan:` line reports the Forward+ start and includes the dynamic light count and CPU cluster tags.
- The `Time Of Day:` line still reports the Cycle 101 late-afternoon scenario lighting.
- Woden, West Basin, Black Mountain, and Belconnen review areas show local diagnostic light influence on nearby concrete/facade surfaces.
- Scope readability and distant LOD switching remain stable while local lights are active.

## Regression Notes

- Preserve Cycle 99 capture tooling.
- Preserve Cycle 100 landmark LOD switching.
- Preserve Cycle 101 scenario time-of-day lighting.
- Treat this as the Forward+ implementation start: the shader supports a bounded per-drawable light list now, while a fuller tiled/cluster grid remains future expansion if dynamic light counts increase.
