# Cycle 1 Smoke Test

## Build

Use:

```sh
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
```

## Launch Checks

1. The app opens into a lit 3D scene instead of a text-only clear screen.
2. A checkerboard ground plane is visible with two pedestal blocks.
3. The scene includes imported props from `PrimaryAssets/Props`, currently `Compass_Open` and `Knife`.
4. The overlay reports the scene asset summary and a valid Metal device.

## Input Checks

1. `W`, `A`, `S`, and `D` move the camera relative to the current view direction.
2. Mouse movement changes the camera yaw and pitch and changes what part of the scene is visible.
3. `Shift` increases movement speed and updates the debug overlay.
4. The app remains stable while moving and looking around continuously.

## Exit Gate

Cycle `1` is complete when the build boots into visible 3D content, supports first-person look and movement, and renders imported prop geometry from the repo assets.
