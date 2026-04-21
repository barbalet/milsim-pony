# Cycle 15 Smoke Test

## Goal

Verify that the Canberra demo now behaves as a cycle `15` street-atlas expansion pass: the shell advertises the new cycle and scene labels, the overhead map shows named roads across a larger district set, and the review route now frames Canberra as a district-by-district atlas rather than only a scope-validation lane.

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

- The HUD title reads `Cycle 15 Canberra Street Atlas Expansion`.
- The title shell title reads `Canberra Street Atlas Review`.
- The route card describes `Canberra District Atlas Survey`.
- The world readout frames the package as `Canberra Basin Street Atlas`.

## Atlas Overlay

Expected result:

- Pressing `M` opens the overhead Canberra map.
- The map shows named road strips instead of only sector rectangles and route dots.
- The atlas summary line reports named road strips across the active Canberra sectors.
- District labels include the new major additions such as Civic, Barton-Russell, west basin, Woden Town Centre, and Belconnen Town Centre.

## Route And Planning

Expected result:

- The title shell includes the cycle `15` plan notes describing the wider cycle `15` to `20` atlas program.
- The review markers include the new district stops `Russell Causeway Review`, `City Hill Arterial Review`, `Woden Town Centre Review`, and `Belconnen Town Centre Review`.
- The route can still be started, restarted, paused, and completed through the normal shell flow.

## Regression Check

Expected result:

- `W A S D`, mouse look, `Shift`, `Space`, `Return`, `M`, `R`, and `Esc` still behave as expected.
- Scoped rendering remains available during live play.
- The app still loads the authored world package instead of falling back to the procedural error scene.
