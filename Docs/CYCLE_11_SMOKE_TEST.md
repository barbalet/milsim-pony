# Cycle 11 Smoke Test

## Goal

Verify that the Canberra demo now behaves as a cycle `11` macro-readability pass: basin landmarks remain resident at longer distances, Parliament House is back in the live basin package, and the review route proves Lake Burley Griffin, Woden, Black Mountain, and Belconnen from authored viewpoints.

## Build

Run:

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
```

Expected result:

- Build completes successfully.
- `MilsimPonyGame.app` is produced under `/tmp/MilsimPonyDerived/Build/Products/Debug/`.

## Launch

Run:

```bash
open /tmp/MilsimPonyDerived/Build/Products/Debug/MilsimPonyGame.app
```

Expected result:

- The HUD title reads `Cycle 11 Macro Canberra Readability`.
- The title shell title reads `Canberra Basin Readability Review`.
- The world readout still frames the package as `Canberra Woden-Belconnen Basin`.
- The route card and shell copy describe a sightline review rather than the earlier basin preview pass.

## Residency And Coverage

Expected result:

- The player spawns at `East Basin Survey Terrace`.
- Lake Burley Griffin remains readable from the spawn terrace.
- Parliament House and its immediate triangle edge are loaded as part of the same live basin package.
- The overlay `Sectors:` detail lists `Lake Burley Griffin East Lookout`, `Parliamentary Triangle Edge`, `Parliament Precinct`, `Central Lake Basin`, `Woden Valley`, and `Black Mountain And Belconnen`.
- The overlay `Residency:` detail reports `1 always / 2 far-field / 3 local`.
- The streaming summary reports both near sectors and resident sectors rather than only one active count.

## Sightline Route

Expected result:

- The route summary reads `Canberra Macro Sightline Review`.
- The five review markers are `East Basin Sightline`, `Parliament Forecourt View`, `Woden Valley Frame`, `Black Mountain Frame`, and `Belconnen Basin Horizon`.
- Guidance markers include `Lake Burley Griffin Axis`, `Parliament Forecourt`, `Woden Valley`, `Black Mountain`, `Belconnen Basin`, and `4x Scope Review Lane`.
- Restarting from a checkpoint places the player back on the review route without requiring an exact vertical match to the beacon height.

## Regression Check

Expected result:

- `W A S D`, mouse look, `Shift`, `Esc`, restart, and return-to-briefing still work.
- The app still loads world data through the scene package path without falling back to the procedural error scene.
- Frame timing, route metrics, sector residency, and camera telemetry still update in the HUD while the player surveys the basin.
