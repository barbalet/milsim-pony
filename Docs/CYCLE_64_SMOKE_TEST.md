# Cycle 64 Smoke Test

Verify that the Canberra demo now behaves as a cycle `64` manual-restore arming pass: the active Woden-to-Belconnen route remains the only bound playable route, while persisted review state reports whether a future restore prompt may be armed.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Manual Restore Arming Validation`.
3. Confirm the HUD title reads `Cycle 64 Manual Restore Arming`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, and `Manual Restore Arm:` lines or their no-persisted-state fallbacks.

## Persist And Arm

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app.
5. Confirm the title shell shows `Restore Readiness: eligible for future manual restore`.
6. Confirm the title shell shows `Manual Restore Arm: armed for future prompt`.
7. Confirm the arming line still says `no auto-restore`.

## Behavior Guardrails

1. Confirm relaunch does not automatically restore camera or checkpoint position yet.
2. Confirm starting from briefing still begins a fresh live run.
3. Confirm retry and restart behavior remains the same as cycle `63`.
4. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `64` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `64` manual-restore arming build.
