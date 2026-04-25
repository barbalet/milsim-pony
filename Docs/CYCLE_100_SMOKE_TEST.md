# Cycle 100 Smoke Test - Distant Building LOD Implementation

Verify that the Canberra demo now behaves as a cycle `100` distant-building LOD pass: the app advertises the new cycle, landmark graybox drawables have renderer-side impostor replacements, and the live readouts report actual LOD switching rather than metadata only.

## Build

From the repository root:

```sh
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
```

## App Identity

Launch the build and confirm:

- The briefing shell identifies `Canberra Distant Building LOD Implementation`.
- The HUD title reads `Cycle 100 Distant Building LOD Implementation`.
- The release display reports `v1.0.0 (100)`.

## LOD Readouts

- Start the route from briefing.
- Confirm the overlay details include `LOD Switching:` with a non-zero landmark impostor count and the configured swap distance.
- Confirm `Distant LOD:` reports renderer impostors in addition to the configured target count.
- Open the overhead map and confirm the `Distant LOD:` footer still appears with the LOD/reflection lines.

## Scope And Capture Regression

- Raise the 4x scope at Woden, West Basin, Black Mountain, or Belconnen sightlines.
- Confirm scoped rendering remains stable and the `Scope Calibration:`, `Distant LOD:`, and `LOD Reflection:` lines remain visible.
- Run `Tools/capture_review.sh --validate-only` and confirm the Cycle 99 capture pipeline remains available.
- Run `Tools/package_release.sh --validate-only` and confirm Cycle 100 release docs validate.
