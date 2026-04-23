# Cycle 19 Smoke Test

## Goal

Verify that the Canberra demo now behaves as a cycle `19` cross-district integration pass: the shell advertises the longer Woden-to-Belconnen framing, the route starts in Woden instead of the Black Mountain perch, and the overhead atlas now supports a longer continuous review line with planned-distance and footprint readouts.

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

- The HUD title reads `Cycle 19 Cross-District Route Integration`.
- The title shell title reads `Canberra Cross-District Atlas Review`.
- The route card describes the cross-district survey instead of the previous north-only pass.
- The world readout frames the package as `Canberra Cross-District Atlas`.

## Route

Expected result:

- The route begins at `Woden Town Centre Staging`.
- Review markers then lead through `Woden Scope Perch`, `State Circle Transfer`, `Kings Avenue East Review`, `East Basin Lookout`, `Constitution Axis Review`, `Civic Interchange Review`, `West Basin Promenade Review`, `Telstra Tower Frame`, `Black Mountain Scope Perch`, `Belconnen Way Overlook`, `Belconnen Town Centre Review`, and `Ginninderra Drive Review`.
- The completion shell now describes the route as a continuous cross-district line rather than a single district slice.

## Atlas Overlay

Expected result:

- Pressing `M` opens the overhead Canberra map.
- The map footer now includes planned route distance and a start-to-goal footprint line.
- The dashed yellow route still shows the full authored path, while completed route segments render as a solid green line.
- The atlas still shows named road strips and current-sector highlighting across the wider Canberra package.

## Comparison Set

Expected result:

- The authored route supports screenshot-ready comparison stops in Woden, East Basin, Civic, West Basin, Black Mountain, and Belconnen.
- The planning notes frame the run as a cross-district comparison set tied to those major slices.

## Regression Check

Expected result:

- `W A S D`, mouse look, `Shift`, `Space`, `Return`, `M`, `R`, and `Esc` still behave as expected.
- Scoped rendering remains available during live play.
- The app still loads the authored world package instead of falling back to the procedural error scene.
