# Cycle 16 Smoke Test

## Goal

Verify that the Canberra demo now behaves as a cycle `16` Woden and inner-south district pass: the shell advertises the new cycle framing, the route includes explicit State Circle and Deakin verification markers ahead of Woden, and the overhead atlas shows denser, human-readable road labels through the inner-south and Woden sectors.

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

- The HUD title reads `Cycle 16 Woden And Inner-South District Pass`.
- The title shell title reads `Canberra Woden And Inner-South Atlas Review`.
- The route card describes `Canberra Woden And Inner-South Survey`.
- The world readout frames the package as `Canberra Woden And Inner-South Atlas`.

## Atlas Overlay

Expected result:

- Pressing `M` opens the overhead Canberra map.
- Road labels are human-readable rather than raw CamelCase strings.
- Woden and inner-south road labels now include names such as `Melrose Dr`, `Hindmarsh Dr`, `Adelaide Ave`, `Kent St`, and `Hopetoun Cct`.
- The atlas summary line reports more named road strips than the cycle `15` pass.

## District Readout

Expected result:

- In overlapping local areas, the sector readout prefers the most specific district instead of a broader parent slice.
- Moving through the Woden core reports `Woden Town Centre` instead of only `Woden Valley`.
- Moving through the southern connector markers reports `State Circle Approach` and `Deakin Escape Corridor` at the right points in the route.

## Route And Planning

Expected result:

- The title shell planning notes now frame the build as the cycle `16` Woden and inner-south pass.
- The review markers include `State Circle Review` and `Deakin Corridor Review` between the Parliament axis and Woden.
- The Woden route stop remains reachable through the normal shell flow without needing a developer reposition.

## Regression Check

Expected result:

- `W A S D`, mouse look, `Shift`, `Space`, `Return`, `M`, `R`, and `Esc` still behave as expected.
- Scoped rendering remains available during live play.
- The app still loads the authored world package instead of falling back to the procedural error scene.
