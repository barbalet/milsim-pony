# Cycle 63 Smoke Test

Verify that the Canberra demo now behaves as a cycle `63` restore-readiness report pass: the active Woden-to-Belconnen route remains the only bound playable route, while persisted review state reports whether a future manual checkpoint restore would be eligible or blocked.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Restore Readiness Report Validation`.
3. Confirm the HUD title reads `Cycle 63 Restore Readiness Report`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, and `Restore Readiness:` lines or their no-persisted-state fallbacks.

## Persist And Inspect

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app.
5. Confirm the title shell shows `Review Guardrail: stored review card valid`.
6. Confirm the title shell shows `Restore Preview: future resume target`.
7. Confirm the title shell shows `Restore Readiness: eligible for future manual restore`.
8. Confirm the readiness line still says launch starts fresh.

## Behavior Guardrails

1. Confirm relaunch does not automatically restore camera or checkpoint position yet.
2. Confirm starting from briefing still begins a fresh live run.
3. Confirm retry and restart behavior remains the same as cycle `62`.
4. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `63` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `63` restore-readiness report build.
