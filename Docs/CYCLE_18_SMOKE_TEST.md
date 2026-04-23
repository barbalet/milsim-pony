# Cycle 18 Smoke Test

## Goal

Verify that the Canberra demo now behaves as a cycle `18` Belconnen and Black Mountain pass: the shell advertises the northern-district framing, the review route starts from the Black Mountain perch instead of the east-basin terrace, and the overhead atlas reads Black Mountain, Bruce, UC, Belconnen Town Centre, Emu Bank, and Ginninderra as separate connected north-west districts.

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

- The HUD title reads `Cycle 18 Belconnen And Black Mountain Pass`.
- The title shell title reads `Canberra Belconnen And Black Mountain Atlas Review`.
- The route card describes `Canberra Northern District Survey`.
- The world readout frames the package as `Canberra Northern District Atlas`.

## Atlas Overlay

Expected result:

- Pressing `M` opens the overhead Canberra map.
- The northern atlas now shows more named roads around Black Mountain, Bruce, and Belconnen.
- Road labels include names such as `Belconnen Way`, `Benjamin Way`, `Emu Bank`, `Ginninderra Dr`, `William Hovell Dr`, `College St`, `Cameron Ave`, and `Joynton Smith Dr`.
- The shell details now include a `Long Range:` line in addition to the existing `Texture Coverage:` and `Telemetry:` lines.

## District Readout

Expected result:

- Moving around the perch reports `Black Mountain Scope Perch`.
- Moving into the broad northern basin reports `Black Mountain And Belconnen`.
- Moving through the dense town core reports `Belconnen Town Centre`.
- The route metrics line still reports checkpoint progress, distance, and restarts.

## Route And Props

Expected result:

- The title shell planning notes now frame the build as the cycle `18` northern-district pass.
- The review markers include `Black Mountain Scope Perch`, `Telstra Tower Frame`, `Bruce Saddle Review`, `UC Bruce Connector Review`, `Belconnen Town Centre Review`, `Emu Bank Review`, and `Ginninderra Drive Review`.
- Authored OBJ props now appear in the northern route slice instead of the scene remaining on pure graybox content only.

## Regression Check

Expected result:

- `W A S D`, mouse look, `Shift`, `Space`, `Return`, `M`, `R`, and `Esc` still behave as expected.
- Scoped rendering remains available during live play.
- The app still loads the authored world package instead of falling back to the procedural error scene.
