# Cycle 0 Smoke Test

## Build

Use:

```sh
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

## Launch Checks

1. The app opens a window with a dark Metal clear pass and bootstrap overlays.
2. The overlay reports `Mode: bootstrap` unless overridden by scheme environment variables.
3. The overlay reports a valid Metal device name.
4. Console output includes a `[GameCore] Bootstrap mode:` line.

## Input Checks

1. Clicking the Metal view gives it input focus.
2. Pressing `W`, `A`, `S`, `D`, or `Shift` changes the pressed-input list and intent values in the overlay.
3. Moving the mouse changes the debug look values in the overlay.
4. Pressing `Space` or `Escape` updates the status line without crashing the app.

## Exit Gate

Cycle `0` is complete when the app can be built, launched, and interacted with as a stable bootstrap shell for later rendering and world work.
