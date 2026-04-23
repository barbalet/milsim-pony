# Cycle 20 Smoke Test

## Goal

Verify that the Canberra demo now behaves as a cycle `20` reference-backed review pack: the shell advertises the review-pack framing, the overhead atlas surfaces comparison-stop notes, and the supporting review docs line up with the live Woden-to-Belconnen route.

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

- The HUD title reads `Cycle 20 Reference-Backed Review Pack`.
- The title shell title reads `Canberra Reference-Backed Atlas Review Pack`.
- The route card describes `Canberra Reference-Backed Survey`.
- The world readout frames the package as `Canberra Reference-Backed Atlas`.

## Atlas Overlay

Expected result:

- Pressing `M` opens the overhead Canberra map.
- The map subtitle now identifies the next comparison district when the next checkpoint is a tagged review stop.
- The map footer includes:
  `Route:` planned distance,
  `Footprint:` start-to-goal sectors,
  `Review Pack:` reference pack status,
  and a `Compare:` line that ties the next stop to a source focus and combat lane.
- The dashed yellow full route and the solid green cleared route both render correctly.

## Review Pack

Expected result:

- The shell details include `Review Pack:`, `Reference Pack:`, `Capture Framing:`, and `Texture Audit:` lines.
- Pausing mid-route surfaces comparison or capture guidance instead of only generic route text.
- Completing the route surfaces the review-pack summary instead of the old cross-district follow-up prompt.

## Documentation

Expected result:

- [Docs/CYCLE_20_REVIEW_PACK.md](/Users/barbalet/github/milsim-pony/Docs/CYCLE_20_REVIEW_PACK.md) matches the live route districts and combat-lane notes.
- [Docs/CYCLE_20_CAPTURE_NOTES.md](/Users/barbalet/github/milsim-pony/Docs/CYCLE_20_CAPTURE_NOTES.md) matches the live checkpoint names.
- [Docs/CanberraReferenceGallery/README.md](/Users/barbalet/github/milsim-pony/Docs/CanberraReferenceGallery/README.md) and [MilsimPonyGame/Assets/Textures/README.md](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/Textures/README.md) describe the review pack and texture audit in cycle `20` terms.

## Regression Check

Expected result:

- `W A S D`, mouse look, `Shift`, `Space`, `Return`, `M`, `R`, and `Esc` still behave as expected.
- Scoped rendering remains available during live play.
- The app still loads the authored world package instead of falling back to the procedural error scene.
