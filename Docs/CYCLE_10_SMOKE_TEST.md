# Cycle 10 Smoke Test

## Goal

Verify that the Canberra demo now loads a basin-scale preview instead of only the narrow Parliament corridor, with Lake Burley Griffin visible, Woden readable to the south, Belconnen readable to the north-west, and the shell framing the build as a survey pass toward future 4x sniper support.

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

- The HUD title reads `Cycle 10 Basin Preview`.
- The title shell title reads `Canberra Basin Survey`.
- The shell describes the build as a Canberra survey rather than the old southbound escape route.

## Basin Coverage

Expected result:

- The player spawns at `East Basin Overlook`.
- Lake Burley Griffin is visible as a central blue water landmark.
- Terrain and landmark massing extend south toward Woden.
- Terrain and skyline massing extend north-west toward Black Mountain and Belconnen.
- The overlay `Sectors:` detail lists `East Basin Overlook`, `Central Lake Basin`, `Woden Valley`, and `Black Mountain And Belconnen`.

## Survey Route

Expected result:

- The route summary reads `Canberra Basin Survey`.
- The four review markers are `Lake Basin Marker`, `Parliament Axis Marker`, `Woden South Marker`, and `Belconnen Horizon`.
- Guidance markers include a `4x Scope Planned` signpost as a sniper-driven planning cue.

## Regression Check

Expected result:

- `W A S D`, mouse look, `Shift`, `Esc`, restart, and return-to-briefing still work.
- The app still loads world data through the scene package path without falling back to the procedural error scene.
- Frame timing, route metrics, and camera telemetry still update in the HUD while the player surveys the basin.
