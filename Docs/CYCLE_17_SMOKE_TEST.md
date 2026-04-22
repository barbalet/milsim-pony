# Cycle 17 Smoke Test

## Goal

Verify that the Canberra demo now behaves as a cycle `17` Civic, Barton, Russell, and east-basin pass: the shell advertises the new cycle framing, the route walks through the central districts instead of the inner-south handoff, and the overhead atlas shows denser named roads and clearer district separation through Civic, Barton, Russell, and Mount Ainslie.

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

- The HUD title reads `Cycle 17 Civic, Barton, Russell, And East-Basin Pass`.
- The title shell title reads `Canberra Civic, Barton, And Russell Atlas Review`.
- The route card describes `Canberra Central District Survey`.
- The world readout frames the package as `Canberra Central District Atlas`.

## Atlas Overlay

Expected result:

- Pressing `M` opens the overhead Canberra map.
- The central atlas now shows more named roads around Civic, Barton, Russell, the east basin, and Mount Ainslie.
- Road labels now include names such as `Kings Ave`, `Brisbane Ave`, `Ainslie Ave`, `Marcus Clarke St`, `Macquarie St`, `Cooyong St`, and `Limestone Ave`.
- The shell details now include a `Texture Coverage:` line and a `Telemetry:` line for the live district package.

## District Readout

Expected result:

- Moving near the lake edge and bridge approaches reports `Barton And Russell` instead of collapsing into a generic basin label.
- Moving through the city core reports `City Hill And Civic`.
- Moving into the north-east route markers reports `Mount Ainslie And Campbell`.
- The route metrics line now reports checkpoint progress in addition to distance and restarts.

## Route And Planning

Expected result:

- The title shell planning notes now frame the build as the cycle `17` central-district pass.
- The review markers include `Kings Avenue Bridge Review`, `Barton Foreshore Review`, `Civic Centre Grid Review`, `Anzac Parade North Review`, and `Mount Ainslie Rise Review`.
- The route can still be started from the normal shell flow without developer repositioning.

## Regression Check

Expected result:

- `W A S D`, mouse look, `Shift`, `Space`, `Return`, `M`, `R`, and `Esc` still behave as expected.
- Scoped rendering remains available during live play.
- The app still loads the authored world package instead of falling back to the procedural error scene.
